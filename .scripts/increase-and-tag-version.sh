#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/release-common.sh"
if [[ " ${*:-} " == *' --help '* || " ${*:-} " == *' -h '* ]]; then
  cat <<'USAGE'
Usage: .scripts/increase-and-tag-version.sh [patch|minor|major|--custom VERSION] [--interactive] [--force] [--dry-run]

Bump VERSION_FILE, commit only that file, push HEAD to the checked-out branch,
then create/push vMAJOR.MINOR.PATCH. This is an explicit release command.
Requires a clean working tree and index. GIT_REMOTE defaults to origin.
TARGET_BRANCH, if set, must match the checked-out branch. --dry-run performs no
writes or remote calls. --force intentionally replaces an existing tag with a lease.
USAGE
  exit 0
fi
release_parse_bump "$@"
release_select_version
[[ "$release_new_version" != "$release_current_version" ]] || release_die 'Version did not change; no commit or tag was created.'
release_branch
if [[ "$release_dry_run" == true ]]; then
  echo "Would update $release_version_path: $release_current_version -> $release_new_version"
  echo "Would commit the version, push HEAD to $release_remote/$release_branch_name, and publish v$release_new_version."
  exit 0
fi
release_require_clean
release_check_remote_branch
release_check_tag "$release_new_version"
release_write_version
release_git add -- "$release_version_path"
release_git commit -m "Bump version to $release_current_version" --only -- "$release_version_path"
release_require_clean
release_git -c push.followTags=false push "$release_remote" "HEAD:refs/heads/$release_branch_name"
# Keep the preflight tag objects: the local update and remote lease reject races.
release_publish_tag
