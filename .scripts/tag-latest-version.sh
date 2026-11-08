#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/release-common.sh"
assume_yes=false; release_force=false; release_dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) assume_yes=true ;;
    --force) release_force=true ;;
    --dry-run|-n) release_dry_run=true ;;
    --help|-h)
      cat <<'USAGE'
Usage: .scripts/tag-latest-version.sh [--yes] [--force] [--dry-run]

Tag the committed configured VERSION_FILE as vMAJOR.MINOR.PATCH and push it.
The working tree must be clean. --force replaces a tag with a remote lease;
no remote tag is deleted first. --dry-run performs no writes or remote calls.
GIT_REMOTE defaults to origin. TARGET_BRANCH, if set, must match the current branch.
USAGE
      exit 0 ;;
    *) release_die "Unknown argument '$1'. Use --help." ;;
  esac
  shift
done
release_read_version
release_branch
release_check_tag "$release_current_version"
if [[ "$release_dry_run" == true ]]; then
  echo "Would tag HEAD as $release_tag_name and push to $release_remote."
  exit 0
fi
release_require_clean
release_check_remote_branch
if [[ "$assume_yes" == false ]]; then
  [[ -t 0 ]] || release_die 'Confirmation required; use --yes for an intentional noninteractive release.'
  read -r -p "Create/push $release_tag_name to $release_remote (replace if --force)? [y/N] " reply || exit 1
  [[ "$reply" =~ ^([yY]|[yY][eE][sS])$ ]] || exit 1
fi
release_publish_tag
