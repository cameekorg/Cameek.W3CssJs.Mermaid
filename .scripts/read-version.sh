#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/release-common.sh"
[[ $# -eq 0 ]] || release_die 'read-version.sh does not accept arguments.'
release_read_version
printf '%s\n' "$release_current_version"
