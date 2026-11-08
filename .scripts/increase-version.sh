#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/release-common.sh"
if [[ " ${*:-} " == *' --help '* || " ${*:-} " == *' -h '* ]]; then
  cat <<'USAGE'
Usage: .scripts/increase-version.sh [patch|minor|major|--custom VERSION] [--interactive] [--dry-run]

Update the configured VERSION_FILE (default Directory.Build.props).
Aliases: --patch, --minor, --major, -c VERSION, -i, -n, -h.
Only stable MAJOR.MINOR.PATCH versions without leading zeroes are accepted.
This command edits the version file; it never commits, tags or pushes.
USAGE
  exit 0
fi
release_parse_bump "$@"
[[ "$release_force" == false ]] || release_die '--force applies only to tag/release commands.'
release_select_version
if [[ "$release_new_version" == "$release_current_version" ]]; then
  echo "Version is already $release_current_version in $release_version_path."
elif [[ "$release_dry_run" == true ]]; then
  echo "Would update $release_version_path: $release_current_version -> $release_new_version"
else
  previous="$release_current_version"
  release_write_version
  echo "Updated $release_version_path: $previous -> $release_current_version"
fi
