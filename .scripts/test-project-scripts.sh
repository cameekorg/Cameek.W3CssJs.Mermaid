#!/usr/bin/env bash
# Exercise only temporary checkouts and fake dotnet; no real builds, cleans or releases.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/cameek-project-tests.XXXXXX")"
trap 'rm -rf -- "$fixture_root"' EXIT
count=0

fixture() {
  count=$((count + 1))
  fixture_repo="$fixture_root/case $count/project with spaces"
  outside="$fixture_root/case $count/caller elsewhere"
  fake_bin="$fixture_root/case $count/fake tools"
  calls="$fixture_root/case $count/dotnet calls"
  release_calls="$fixture_root/case $count/release calls"
  project_calls="$fixture_root/case $count/project calls"
  expected="$fixture_root/case $count/expected calls"
  output="$fixture_root/case $count/output.log"
  mkdir -p "$fixture_repo/.scripts" "$fixture_repo/Library With Spaces" "$outside" "$fake_bin"
  cp "$script_dir/project.sh" "$fixture_repo/.scripts/"
  cat > "$fixture_repo/.scripts/release.conf" <<'CONF'
VERSION_FILE='Library With Spaces/Core.csproj'
BUILD_TARGET='Solution With Spaces.sln'
TEST_TARGET='Tests With Spaces.csproj'
PACK_PROJECTS=('Library With Spaces/Core.csproj' 'Library With Spaces/Images.csproj')
PACK_SCRIPT=''
RUN_PROJECT='Demo With Spaces.csproj'
CONF
  printf '%s\n' '<Project><PropertyGroup><Version>1.2.3</Version></PropertyGroup></Project>' > "$fixture_repo/Library With Spaces/Core.csproj"
  touch "$fixture_repo/Solution With Spaces.sln" "$fixture_repo/Tests With Spaces.csproj" "$fixture_repo/Library With Spaces/Images.csproj" "$fixture_repo/Demo With Spaces.csproj"
  printf 'artifacts/\nignored.log\n' > "$fixture_repo/.gitignore"
  printf 'committed source\n' > "$fixture_repo/tracked.txt"
  cat > "$fake_bin/dotnet" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '<%s>\n' "$PWD" "$@" >> "$DOTNET_CALLS"
printf 'END\n' >> "$DOTNET_CALLS"
FAKE
  cat > "$fixture_repo/.scripts/test-release-scripts.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$PWD" >> "$RELEASE_CALLS"
STUB
  cat > "$fixture_repo/.scripts/test-project-scripts.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$PWD" >> "$PROJECT_CALLS"
STUB
  printf '#!/usr/bin/env bash\nprintf "1.2.3\\n"\n'  > "$fixture_repo/.scripts/read-version.sh"
  chmod +x "$fake_bin/dotnet"
  git -C "$fixture_repo" init -q -b main
  git -C "$fixture_repo" config user.name 'Project fixture'
  git -C "$fixture_repo" config user.email 'project-fixture@example.invalid'
  git -C "$fixture_repo" config commit.gpgsign false
  git -C "$fixture_repo" add .
  git -C "$fixture_repo" commit -qm Initial
  reset_calls
}
reset_calls() { : > "$calls"; : > "$release_calls"; : > "$project_calls"; : > "$expected"; }
run() {
  (cd "$outside" && PATH="$fake_bin:$PATH" DOTNET_CALLS="$calls" RELEASE_CALLS="$release_calls" PROJECT_CALLS="$project_calls" bash "$fixture_repo/.scripts/project.sh" "$@") > "$output" 2>&1
}
fails() {
  local status
  if run "$@"; then cat "$output" >&2; echo "Expected failure: $*" >&2; exit 1; else status=$?; fi
  [[ "$status" == 2 ]] || { cat "$output" >&2; echo "Expected configuration/usage exit 2, got $status." >&2; exit 1; }
}
expect_call() { printf '<%s>\n' "$fixture_repo" "$@" >> "$expected"; printf 'END\n' >> "$expected"; }
assert_calls() { cmp -s "$expected" "$calls" || { echo 'Unexpected dotnet cwd/arguments:' >&2; diff -u "$expected" "$calls" >&2 || true; exit 1; }; }
assert_equal() { [[ "$1" == "$2" ]] || { printf "Expected '%s', got '%s'.\n" "$2" "$1" >&2; exit 1; }; }
passed() { printf 'ok %s - %s\n' "$count" "$*"; }

fixture
run restore
expect_call restore 'Solution With Spaces.sln'
run build
expect_call build 'Solution With Spaces.sln' --configuration Release
CONFIGURATION=Debug run build
expect_call build 'Solution With Spaces.sln' --configuration Debug
assert_calls
passed 'restore/build resolve the configured checkout from another directory and preserve spaces/configuration'

fixture
run test
expect_call test 'Tests With Spaces.csproj' --configuration Release
assert_calls
assert_equal "$(cat "$release_calls")" "$fixture_repo"
assert_equal "$(cat "$project_calls")" "$fixture_repo"
printf "\nTEST_TARGET=''\n" >> "$fixture_repo/.scripts/release.conf"
reset_calls
run test
assert_calls
assert_equal "$(cat "$release_calls")" "$fixture_repo"
assert_equal "$(cat "$project_calls")" "$fixture_repo"
grep -q 'no .NET test project' "$output"
passed 'test executes local release regressions and only configured real .NET tests'

fixture
run pack
expect_call pack 'Library With Spaces/Core.csproj' --configuration Release -p:GeneratePackageOnBuild=false --output "$fixture_repo/artifacts/nuget"
expect_call pack 'Library With Spaces/Images.csproj' --configuration Release -p:GeneratePackageOnBuild=false --output "$fixture_repo/artifacts/nuget"
assert_calls
passed 'multi-package pack preserves package order, arguments, configuration and checkout-relative output'

fixture
cat > "$fixture_repo/.scripts/custom pack.sh" <<'PACK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$PWD" > "$RELEASE_CALLS"
PACK
printf "\nPACK_SCRIPT='.scripts/custom pack.sh'\n" >> "$fixture_repo/.scripts/release.conf"
run pack
assert_calls
assert_equal "$(cat "$release_calls")" "$fixture_repo"
passed 'configured repository pack adapter is delegated once instead of packing extra projects'

fixture
run run
expect_call run --project 'Demo With Spaces.csproj' --configuration Release
assert_calls
printf "\nRUN_PROJECT=''\n" >> "$fixture_repo/.scripts/release.conf"
reset_calls
fails run
assert_calls
grep -q 'no runnable demo host' "$output"
passed 'run uses the configured demo while libraries without a runnable host fail clearly'

fixture
mkdir -p "$fixture_repo/artifacts/snapshots/older"
printf 'keep archive\n' > "$fixture_repo/artifacts/snapshots/older/archive.txt"
printf 'keep source\n' > "$fixture_repo/untracked source.txt"
CONFIGURATION=Custom run clean
expect_call clean 'Solution With Spaces.sln' --configuration Debug
expect_call clean 'Solution With Spaces.sln' --configuration Release
assert_calls
assert_equal "$(cat "$fixture_repo/artifacts/snapshots/older/archive.txt")" 'keep archive'
assert_equal "$(cat "$fixture_repo/untracked source.txt")" 'keep source'
passed 'clean targets Debug and Release only and never deletes snapshots or source files'

fixture
before="$(git -C "$fixture_repo" status --porcelain --untracked-files=all)"
for action in restore build test pack clean status run snapshot; do run --dry-run "$action"; done
assert_calls
[[ ! -s "$release_calls" && ! -s "$project_calls" && ! -e "$fixture_repo/artifacts" ]]
assert_equal "$(git -C "$fixture_repo" status --porcelain --untracked-files=all)" "$before"
passed 'all dry-run actions avoid writes, subprocess work and snapshot creation'

fixture
for action in restore build clean; do
  printf "\nBUILD_TARGET='missing target.sln'\n" >> "$fixture_repo/.scripts/release.conf"
  fails "$action"
  assert_calls
  grep -q 'Configured project file does not exist' "$output"
done
printf "\nRUN_PROJECT='missing demo.csproj'\n" >> "$fixture_repo/.scripts/release.conf"
fails run
assert_calls
printf "\nTEST_TARGET='missing tests.csproj'\n" >> "$fixture_repo/.scripts/release.conf"
fails test
assert_calls
printf "\nPACK_SCRIPT='missing pack.sh'\n" >> "$fixture_repo/.scripts/release.conf"
fails pack
assert_calls
passed 'missing build/test/run/pack-script targets fail before calling dotnet'

fixture
printf "\nPACK_PROJECTS=('Library With Spaces/Core.csproj' 'missing second.csproj')\n" >> "$fixture_repo/.scripts/release.conf"
fails pack
assert_calls
passed 'a missing later package target fails before any earlier package is built'

fixture
printf "\nPACK_PROJECTS=()\n" >> "$fixture_repo/.scripts/release.conf"
fails pack
assert_calls
grep -q 'No package projects' "$output"
for command in 'unknown' 'build extra' 'restore extra' 'test extra' 'pack extra' 'clean extra' 'run extra' 'status extra' 'snapshot 1 extra'; do
  read -r -a arguments <<< "$command"
  fails "${arguments[@]}"
  assert_calls
done
passed 'unsupported actions, empty package sets and surplus arguments fail without tool execution'

fixture
printf 'second committed source\n' >> "$fixture_repo/tracked.txt"
git -C "$fixture_repo" add tracked.txt
git -C "$fixture_repo" commit -qm Second
printf 'dirty local source\n' > "$fixture_repo/tracked.txt"
printf 'untracked private data\n' > "$fixture_repo/private.txt"
printf 'ignored private data\n' > "$fixture_repo/ignored.log"
mkdir -p "$fixture_repo/artifacts/snapshots/older"
printf 'retain me\n' > "$fixture_repo/artifacts/snapshots/older/sentinel"
head_before="$(git -C "$fixture_repo" rev-parse HEAD)"
status_before="$(git -C "$fixture_repo" status --porcelain --untracked-files=all)"
run snapshot 2
snapshot="$(sed -n 's/^Snapshot: //p' "$output")"
[[ -d "$snapshot" && "$snapshot" == "$fixture_repo/artifacts/snapshots/"* ]]
archive="$snapshot/project with spaces.tar.gz"
patch="$snapshot/project with spaces.commit.diff"
assert_equal "$(tar -xOf "$archive" tracked.txt)" $'committed source\nsecond committed source'
listing="$(tar -tzf "$archive")"
[[ "$listing" != *private.txt* && "$listing" != *ignored.log* && "$listing" != *artifacts/snapshots* && "$listing" != .git/* ]]
assert_equal "$(grep -c '^commit [0-9a-f]' "$patch")" 2
(cd "$snapshot" && if command -v sha256sum >/dev/null; then sha256sum -c SHA256SUMS; else shasum -a 256 -c SHA256SUMS; fi) > "$output"
assert_equal "$(cat "$fixture_repo/artifacts/snapshots/older/sentinel")" 'retain me'
assert_equal "$(git -C "$fixture_repo" rev-parse HEAD)" "$head_before"
assert_equal "$(git -C "$fixture_repo" status --porcelain --untracked-files=all)" "$status_before"
first_snapshot="$snapshot"
run snapshot
second_snapshot="$(sed -n 's/^Snapshot: //p' "$output")"
[[ "$second_snapshot" != "$first_snapshot" && -d "$first_snapshot" ]]
assert_equal "$(grep -c '^commit [0-9a-f]' "$second_snapshot/project with spaces.commit.diff")" 1
passed 'snapshots contain committed HEAD only, correct recent commit counts and checksums, retain old snapshots and preserve local work'

fixture
for invalid in 0 -1 01 nope 1.5; do
  fails snapshot "$invalid"
  [[ ! -e "$fixture_repo/artifacts" ]]
  grep -q 'positive integer' "$output"
done
passed 'snapshot rejects invalid commit counts without creating output directories'

fixture
run status
grep -q '^## main' "$output"
grep -q '^1.2.3$' "$output"
assert_calls
passed 'status displays the current checkout and canonical version without invoking dotnet'

printf 'Passed %s project-script fixture cases.\n' "$count"
