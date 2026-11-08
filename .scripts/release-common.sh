#!/usr/bin/env bash
# Shared implementation for the three public release commands.
set -euo pipefail

release_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
release_repo_root="$(cd -- "$release_script_dir/.." && pwd)"
if [[ -f "$release_script_dir/release.conf" ]]; then
  # Repository-owned configuration; never supplied by command-line input.
  source "$release_script_dir/release.conf"
fi
release_version_path="${VERSION_FILE:-Directory.Build.props}"
[[ "$release_version_path" != /* && "$release_version_path" != -* && "/$release_version_path/" != */../* ]] || {
  echo 'error: VERSION_FILE must be a relative path inside the repository.' >&2
  exit 1
}
release_version_file="$release_repo_root/$release_version_path"
release_remote="${GIT_REMOTE:-origin}"
[[ -n "$release_remote" && "$release_remote" != -* ]] || {
  echo 'error: GIT_REMOTE must name a remote or URL, not a Git option.' >&2
  exit 1
}

release_die() { echo "error: $*" >&2; exit 1; }
release_git() { git -C "$release_repo_root" "$@"; }
release_validate_version() { [[ "$1" =~ ^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$ ]]; }
release_extract_version() {
  perl -0777 -e '
    local $/; my $text = <>; $text =~ s/<!--.*?-->//sg;
    my @v = $text =~ m{<Version>\s*([^<]+?)\s*</Version>}sg;
    die "Expected exactly one <Version> value.\n" unless @v == 1;
    die "Expected no <VersionPrefix>.\n" if $text =~ m{<VersionPrefix(?:\s|/|>)};
    print "$v[0]\n";
  ' "$@"
}
release_read_version() {
  [[ -f "$release_version_file" ]] || release_die "Version file not found: $release_version_file"
  release_current_version="$(release_extract_version "$release_version_file")" || release_die "Cannot read $release_version_path."
  release_validate_version "$release_current_version" || release_die "Invalid version '$release_current_version'; use MAJOR.MINOR.PATCH without leading zeroes."
}
release_parse_bump() {
  release_bump=patch; release_custom=''; release_interactive=false; release_dry_run=false; release_force=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      patch|--patch|minor|--minor|major|--major) release_bump="${1#--}"; release_custom='' ;;
      --custom|-c) shift; [[ $# -gt 0 ]] || release_die '--custom requires a version.'; release_custom="$1" ;;
      --custom=*) release_custom="${1#--custom=}" ;;
      --interactive|-i) release_interactive=true ;;
      --dry-run|-n) release_dry_run=true ;;
      --force) release_force=true ;;
      --yes|-y) : ;;
      *) release_die "Unknown argument '$1'. Use --help." ;;
    esac
    shift
  done
}
release_bumped() {
  # Perl avoids shell octal interpretation and fixed-width shell arithmetic overflow.
  perl -e 'my ($v,$kind)=@ARGV; my @n=split /\./,$v; if($kind eq "patch"){$n[2]++}elsif($kind eq "minor"){$n[1]++;$n[2]=0}else{$n[0]++;$n[1]=$n[2]=0} print join(".",@n),"\n"' "$1" "$2"
}
release_select_version() {
  release_read_version
  if [[ "$release_interactive" == true ]]; then
    local selection
    echo "Current version: $release_current_version" >&2
    echo '1) patch  2) minor  3) major  4) custom' >&2
    read -r -p 'Selection [1]: ' selection || release_die 'No version selection was provided.'
    case "${selection:-1}" in
      1) release_bump=patch; release_custom='' ;;
      2) release_bump=minor; release_custom='' ;;
      3) release_bump=major; release_custom='' ;;
      4) read -r -p 'Custom MAJOR.MINOR.PATCH: ' release_custom || release_die 'No custom version was provided.' ;;
      *) release_die "Unknown selection '$selection'." ;;
    esac
  fi
  release_new_version="${release_custom:-$(release_bumped "$release_current_version" "$release_bump")}"
  release_validate_version "$release_new_version" || release_die "Invalid version '$release_new_version'; use MAJOR.MINOR.PATCH without leading zeroes."
}
release_write_version() {
  CURRENT_VERSION="$release_current_version" NEW_VERSION="$release_new_version" perl -0777 -i -pe '
    my $count=0;
    s{(<!--.*?-->)|(<Version>\s*)\Q$ENV{CURRENT_VERSION}\E(\s*</Version>)}{
      defined($1) ? $1 : do { $count++; $2.$ENV{NEW_VERSION}.$3 }
    }sge;
    die "Expected one version replacement.\n" unless $count == 1;
  ' "$release_version_file"
  local expected="$release_new_version"
  release_read_version
  [[ "$release_current_version" == "$expected" ]] || release_die 'Version update verification failed.'
}
release_branch() {
  release_git rev-parse --is-inside-work-tree >/dev/null
  release_branch_name="$(release_git symbolic-ref --quiet --short HEAD)" || release_die 'Detached HEAD cannot be released; check out a branch first.'
  [[ -z "${TARGET_BRANCH:-}" || "$TARGET_BRANCH" == "$release_branch_name" ]] || release_die "TARGET_BRANCH '$TARGET_BRANCH' must match checked-out branch '$release_branch_name'."
  release_git check-ref-format --branch "$release_branch_name" >/dev/null || release_die 'Invalid branch name.'
}
release_require_clean() {
  [[ -z "$(release_git status --porcelain)" ]] || release_die 'Commit or stash working-tree and staged changes before releasing.'
  release_git ls-files --error-unmatch -- "$release_version_path" >/dev/null || release_die 'The configured version file must be tracked.'
  local committed
  committed="$(release_git show "HEAD:$release_version_path" | release_extract_version)" || release_die 'Cannot read the committed version.'
  [[ "$committed" == "$release_current_version" ]] || release_die 'The working and committed versions differ.'
}
release_check_remote_branch() {
  local result status remote_commit
  if result="$(release_git ls-remote --exit-code --heads "$release_remote" "refs/heads/$release_branch_name")"; then
    remote_commit="${result%%$'\t'*}"
    release_git cat-file -e "$remote_commit^{commit}" 2>/dev/null || release_die 'Remote branch has commits not available locally; fetch and integrate them first.'
    release_git merge-base --is-ancestor "$remote_commit" HEAD || release_die 'Remote branch is ahead or diverged; integrate it before releasing.'
  else
    status=$?
    [[ "$status" == 2 ]] || release_die "Cannot read remote '$release_remote'."
  fi
}
release_check_tag() {
  release_tag_name="v$1"; release_tag_ref="refs/tags/$release_tag_name"
  release_local_tag="$(release_git rev-parse --quiet --verify "$release_tag_ref" 2>/dev/null || true)"
  release_remote_tag=''
  [[ -z "$release_local_tag" || "$release_force" == true ]] || release_die "Local tag $release_tag_name already exists; use --force only for an intentional replacement."
  if [[ "$release_dry_run" == false ]]; then
    local result status
    if result="$(release_git ls-remote --exit-code --refs "$release_remote" "$release_tag_ref")"; then
      release_remote_tag="${result%%$'\t'*}"
    else
      status=$?
      [[ "$status" == 2 ]] || release_die "Cannot read tags from '$release_remote'."
    fi
    [[ -z "$release_remote_tag" || "$release_force" == true ]] || release_die "Remote tag $release_tag_name already exists; use --force only for an intentional replacement."
  fi
}
release_publish_tag() {
  local commit new_tag previous="$release_local_tag"
  commit="$(release_git rev-parse HEAD)"
  release_git update-ref "$release_tag_ref" "$commit" "$previous"
  new_tag="$(release_git rev-parse "$release_tag_ref")"
  # The expected old remote object prevents overwriting a concurrent publication.
  if ! release_git -c push.followTags=false push "--force-with-lease=$release_tag_ref:$release_remote_tag" "$release_remote" "$release_tag_ref:$release_tag_ref"; then
    if [[ -n "$previous" ]]; then
      release_git update-ref "$release_tag_ref" "$previous" "$new_tag"
    else
      release_git update-ref -d "$release_tag_ref" "$new_tag"
    fi
    release_die "Could not push $release_tag_name; the previous local tag was restored."
  fi
  echo "Created and pushed $release_tag_name to $release_remote."
}
