#!/usr/bin/env bash
# All mutations and pushes are confined to temporary repositories and local bare remotes.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/cameek-release-tests.XXXXXX")"
trap 'rm -rf -- "$fixture_root"' EXIT
count=0
fixture() {
  count=$((count + 1))
  fixture_repo="$fixture_root/case $count/project with spaces"
  fixture_remote="$fixture_root/case $count/remote.git"
  mkdir -p "$fixture_repo/.scripts" "$fixture_repo/Library With Spaces"
  cp "$script_dir/"{release-common,read-version,increase-version,tag-latest-version,increase-and-tag-version}.sh "$fixture_repo/.scripts/"
  printf '%s\n' 'VERSION_FILE="Library With Spaces/Library.csproj"' > "$fixture_repo/.scripts/release.conf"
  printf '%s\n' '<Project><PropertyGroup><Version>1.2.3</Version></PropertyGroup></Project>' > "$fixture_repo/Library With Spaces/Library.csproj"
  git -C "$fixture_repo" init -q -b main
  git -C "$fixture_repo" config user.name 'Release fixture'
  git -C "$fixture_repo" config user.email 'release-fixture@example.invalid'
  git -C "$fixture_repo" config commit.gpgsign false
  git -C "$fixture_repo" add .
  git -C "$fixture_repo" commit -qm Initial
  git init -q --bare "$fixture_remote"
  git -C "$fixture_repo" remote add origin "$fixture_remote"
  git -C "$fixture_repo" push -q origin HEAD:refs/heads/main
}
run() { (cd "$fixture_repo" && bash ".scripts/$1.sh" "${@:2}") > "$fixture_root/output.log" 2>&1; }
fails() {
  if run "$@"; then cat "$fixture_root/output.log" >&2; echo "Expected failure: $*" >&2; exit 1; fi
}
version() { (cd "$fixture_repo" && bash .scripts/read-version.sh); }
assert_equal() { [[ "$1" == "$2" ]] || { echo "Expected '$2', got '$1'." >&2; exit 1; }; }
assert_clean() { [[ -z "$(git -C "$fixture_repo" status --porcelain)" ]]; }
passed() { echo "ok $count - $*"; }

fixture
run increase-version --patch
assert_equal "$(version)" 1.2.4
run increase-version --minor
assert_equal "$(version)" 1.3.0
run increase-version --major
assert_equal "$(version)" 2.0.0
run increase-version --custom 4.5.6
assert_equal "$(version)" 4.5.6
passed 'bump aliases/custom edit a configured nested path containing spaces'

fixture
git -C "$fixture_repo" remote set-url origin "$fixture_root/does-not-exist.git"
run increase-version --minor --dry-run
run increase-and-tag-version --patch --dry-run
run tag-latest-version --dry-run
assert_equal "$(version)" 1.2.3
assert_clean
assert_equal "$(git -C "$fixture_repo" tag)" ''
passed 'all dry runs leave bytes/refs/index unchanged and do not access the remote'

fixture
run increase-and-tag-version --minor
assert_equal "$(version)" 1.3.0
assert_clean
head="$(git -C "$fixture_repo" rev-parse HEAD)"
assert_equal "$(git --git-dir="$fixture_remote" rev-parse refs/heads/main)" "$head"
assert_equal "$(git --git-dir="$fixture_remote" rev-parse refs/tags/v1.3.0)" "$head"
assert_equal "$(git -C "$fixture_repo" diff-tree --no-commit-id --name-only -r HEAD)" 'Library With Spaces/Library.csproj'
passed 'release commits only the version file and pushes exact branch/tag commits'

fixture
printf 'user work\n' > "$fixture_repo/unrelated.txt"
git -C "$fixture_repo" add unrelated.txt
fails increase-and-tag-version --patch
assert_equal "$(version)" 1.2.3
assert_equal "$(git -C "$fixture_repo" diff --cached --name-only)" unrelated.txt
passed 'unrelated staged user changes cannot enter a release commit'

fixture
run increase-version --patch
fails increase-and-tag-version --minor
fails tag-latest-version --yes
assert_equal "$(version)" 1.2.4
assert_equal "$(git -C "$fixture_repo" tag)" ''
passed 'dirty metadata cannot be released or tagged as a different committed version'

fixture
fails increase-version --custom 01.2.3
fails increase-version --custom 1.2.3-preview
assert_equal "$(version)" 1.2.3
assert_clean
passed 'invalid/leading-zero/prerelease versions fail without mutation'

fixture
sed -i 's|</PropertyGroup>|<VersionPrefix>1.2.3</VersionPrefix></PropertyGroup>|' "$fixture_repo/Library With Spaces/Library.csproj"
fails read-version
sed -i 's|<VersionPrefix>1.2.3</VersionPrefix>|<VersionPrefix/>|' "$fixture_repo/Library With Spaces/Library.csproj"
fails read-version
sed -i 's|<VersionPrefix/>|<Version>2.0.0</Version>|' "$fixture_repo/Library With Spaces/Library.csproj"
fails increase-version --patch
passed 'ambiguous version declarations and VersionPrefix are rejected'

fixture
sed -i 's|<Project>|<Project><!-- <Version>9.9.9</Version> -->|' "$fixture_repo/Library With Spaces/Library.csproj"
run increase-version --patch
assert_equal "$(version)" 1.2.4
grep -q '<!-- <Version>9.9.9</Version> -->' "$fixture_repo/Library With Spaces/Library.csproj"
passed 'commented XML versions do not participate in reading/replacement'

fixture
if (cd "$fixture_repo" && TARGET_BRANCH=other bash .scripts/increase-and-tag-version.sh --patch) > "$fixture_root/output.log" 2>&1; then exit 1; fi
assert_equal "$(version)" 1.2.3
assert_clean
git -C "$fixture_repo" checkout -q --detach
fails increase-and-tag-version --patch
assert_equal "$(version)" 1.2.3
passed 'mismatched TARGET_BRANCH and detached HEAD fail before version edits'

fixture
git -C "$fixture_repo" tag v1.2.4
fails increase-and-tag-version --patch
assert_equal "$(version)" 1.2.3
assert_clean
passed 'existing local next-version tag is rejected before editing the version'

fixture
git -C "$fixture_repo" tag v1.2.4
git -C "$fixture_repo" push -q origin refs/tags/v1.2.4
git -C "$fixture_repo" tag -d v1.2.4 > /dev/null
fails increase-and-tag-version --patch
assert_equal "$(version)" 1.2.3
assert_clean
passed 'existing remote next-version tag is rejected before editing the version'

fixture
git -C "$fixture_repo" remote set-url origin "$fixture_root/no-remote.git"
fails increase-and-tag-version --patch
assert_equal "$(version)" 1.2.3
assert_clean
passed 'unreachable remote fails before changing the version or creating a commit'

fixture
mkdir "$fixture_root/other clone"
git clone -q "$fixture_remote" "$fixture_root/other clone" 2>/dev/null
git -C "$fixture_root/other clone" checkout -q main
git -C "$fixture_root/other clone" config user.name Fixture
git -C "$fixture_root/other clone" config user.email fixture@example.invalid
printf 'other change\n' > "$fixture_root/other clone/remote.txt"
git -C "$fixture_root/other clone" add remote.txt
git -C "$fixture_root/other clone" -c commit.gpgsign=false commit -qm Other
git -C "$fixture_root/other clone" push -q origin HEAD:refs/heads/main
fails increase-and-tag-version --patch
assert_equal "$(version)" 1.2.3
assert_clean
passed 'an unseen remote branch commit cannot be overwritten or cause a local bump'

fixture
run tag-latest-version --yes
old="$(git --git-dir="$fixture_remote" rev-parse refs/tags/v1.2.3)"
git -C "$fixture_repo" -c commit.gpgsign=false commit -qm 'New source' --allow-empty
fails tag-latest-version --yes
run tag-latest-version --yes --force
head="$(git -C "$fixture_repo" rev-parse HEAD)"
[[ "$head" != "$old" ]]
assert_equal "$(git --git-dir="$fixture_remote" rev-parse refs/tags/v1.2.3)" "$head"
passed 'tag-only publishes committed versions and explicit force replaces without delete-first'

fixture
# Move the remote tag in a pre-push hook after the lease was captured.
run tag-latest-version --yes
previous="$(git -C "$fixture_repo" rev-parse refs/tags/v1.2.3)"
git -C "$fixture_repo" -c commit.gpgsign=false commit -qm Candidate --allow-empty
candidate="$(git -C "$fixture_repo" rev-parse HEAD)"
# Make the candidate object available to the bare repository before the hook runs.
git -C "$fixture_repo" push -q origin HEAD:refs/heads/fixture-object
cat > "$fixture_repo/.git/hooks/pre-push" <<HOOK
#!/usr/bin/env bash
git --git-dir="$fixture_remote" update-ref refs/tags/v1.2.3 "$candidate"
HOOK
chmod +x "$fixture_repo/.git/hooks/pre-push"
fails tag-latest-version --yes --force
assert_equal "$(git -C "$fixture_repo" rev-parse refs/tags/v1.2.3)" "$previous"
assert_equal "$(git --git-dir="$fixture_remote" rev-parse refs/tags/v1.2.3)" "$candidate"
passed 'remote tag races fail the lease and restore the previous local tag'

printf 'Passed %s release-script fixture cases.\n' "$count"
