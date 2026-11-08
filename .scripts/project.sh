#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"
# Repository-owned configuration; no paths are inferred from the caller's directory.
source "$script_dir/release.conf"
configuration="${CONFIGURATION:-Release}"
dry_run=false
if [[ ${1:-} == --dry-run ]]; then dry_run=true; shift; fi
action="${1:---help}"
if (($#)); then shift; fi

fail() { printf 'error: %s\n' "$*" >&2; exit 2; }
execute() {
  if [[ "$dry_run" == true ]]; then printf 'Would run:'; printf ' %q' "$@"; printf '\n';
  else "$@"; fi
}
require_file() { [[ -f "$repo_root/$1" ]] || fail "Configured project file does not exist: $1"; }

case "$action" in
  --help|-h|help)
    cat <<'USAGE'
Usage: .scripts/project.sh [--dry-run] restore|build|test|pack|clean|snapshot|status|run

Commands use .scripts/release.conf and run from this repository's root.
Set CONFIGURATION to override the default Release build configuration.
Snapshot accepts an optional positive commit count (default 1), archives committed
HEAD plus the recent commit diff, and retains older snapshots in artifacts/snapshots.
Clean runs dotnet clean for Debug and Release; it does not remove source or snapshots.
USAGE
    ;;
  restore|build)
    (($# == 0)) || fail "$action does not accept arguments."
    require_file "$BUILD_TARGET"
    if [[ "$action" == restore ]]; then execute dotnet restore "$BUILD_TARGET";
    else execute dotnet build "$BUILD_TARGET" --configuration "$configuration"; fi
    ;;
  test)
    (($# == 0)) || fail 'test does not accept arguments.'
    if [[ -n "${TEST_TARGET:-}" ]]; then require_file "$TEST_TARGET"; fi
    execute bash "$script_dir/test-release-scripts.sh"
    execute bash "$script_dir/test-project-scripts.sh"
    if [[ -n "${TEST_TARGET:-}" ]]; then
      execute dotnet test "$TEST_TARGET" --configuration "$configuration"
    else printf 'This repository has no .NET test project; release-script regression tests are its local test action.\n'; fi
    ;;
  pack)
    (($# == 0)) || fail 'pack does not accept arguments.'
    if [[ -n "${PACK_SCRIPT:-}" ]]; then
      require_file "$PACK_SCRIPT"
      execute bash "$repo_root/$PACK_SCRIPT"
    else
      ((${#PACK_PROJECTS[@]})) || fail 'No package projects are configured.'
      for project in "${PACK_PROJECTS[@]}"; do require_file "$project"; done
      for project in "${PACK_PROJECTS[@]}"; do
        execute dotnet pack "$project" --configuration "$configuration" \
          -p:GeneratePackageOnBuild=false --output "$repo_root/artifacts/nuget"
      done
    fi
    ;;
  clean)
    (($# == 0)) || fail 'clean does not accept arguments.'
    require_file "$BUILD_TARGET"
    execute dotnet clean "$BUILD_TARGET" --configuration Debug
    execute dotnet clean "$BUILD_TARGET" --configuration Release
    ;;
  status)
    (($# == 0)) || fail 'status does not accept arguments.'
    execute git -C "$repo_root" status --short --branch
    execute bash "$script_dir/read-version.sh"
    ;;
  run)
    (($# == 0)) || fail 'run does not accept arguments.'
    [[ -n "${RUN_PROJECT:-}" ]] || fail 'This library has no runnable demo host; use build or pack.'
    require_file "$RUN_PROJECT"
    execute dotnet run --project "$RUN_PROJECT" --configuration "$configuration"
    ;;
  snapshot)
    (($# <= 1)) || fail 'snapshot accepts only a commit count.'
    count="${1:-1}"
    [[ "$count" =~ ^[1-9][0-9]*$ ]] || fail 'Snapshot commit count must be a positive integer.'
    git rev-parse --verify HEAD >/dev/null
    if [[ "$dry_run" == true ]]; then
      printf 'Would archive committed HEAD and the latest %s commits under %s/artifacts/snapshots.\n' "$count" "$repo_root"
      exit 0
    fi
    mkdir -p "$repo_root/artifacts/snapshots"
    name="${repo_root##*/}"
    stamp="$(date -u +%Y%m%d-%H%M%S)"
    destination="$(mktemp -d "$repo_root/artifacts/snapshots/$name-$stamp-XXXXXX")"
    git archive --format=tar.gz --output="$destination/$name.tar.gz" HEAD
    git log --binary --format=fuller --patch -n "$count" HEAD > "$destination/$name.commit.diff"
    (
      cd "$destination"
      if command -v sha256sum >/dev/null; then sha256sum "$name.tar.gz" "$name.commit.diff" > SHA256SUMS;
      else shasum -a 256 "$name.tar.gz" "$name.commit.diff" > SHA256SUMS; fi
    )
    printf 'Snapshot: %s\nCommitted HEAD only; uncommitted and untracked files are excluded.\n' "$destination"
    ;;
  *) fail "Unknown project action: $action" ;;
esac
