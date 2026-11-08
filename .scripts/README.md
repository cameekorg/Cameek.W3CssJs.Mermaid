# Repository scripts

## Unified repository commands

All nine Cameek NuGet repositories share these entrypoints. This repository keeps
its version in `Cameek.W3CssJs.Mermaid.csproj`; `.scripts/release.conf` selects its actual projects.

```bash
.scripts/read-version.sh
.scripts/increase-version.sh patch --dry-run
.scripts/increase-version.sh --interactive
.scripts/increase-version.sh --custom 11.17.2
.scripts/tag-latest-version.sh --dry-run
.scripts/tag-latest-version.sh
.scripts/increase-and-tag-version.sh patch --dry-run
.scripts/increase-and-tag-version.sh patch
```

`increase-version.sh` edits only the configured version file. `tag-latest-version.sh`
tags its committed version. `increase-and-tag-version.sh` bumps, commits only that
file, pushes the current branch, then pushes `vMAJOR.MINOR.PATCH`. Release/tag
commands require a clean checkout and verify remote/tag state before mutation.
Use `--yes` for intentional noninteractive tagging; `--force` is an explicit leased
tag replacement. Dry runs do not edit files or contact a remote. Versions use
three numeric components without prerelease suffixes or leading zeroes.
`GIT_REMOTE` defaults to `origin`; an explicit `TARGET_BRANCH` must match the
checked-out branch. A failed branch push does not publish a tag.

Common local actions:

```bash
.scripts/project.sh restore
.scripts/project.sh build
.scripts/project.sh test
.scripts/project.sh pack
.scripts/project.sh clean
.scripts/project.sh status
.scripts/project.sh snapshot 1
.scripts/project.sh --dry-run pack
```

Build/test default to Release. Test runs the release-script regression fixtures
and any configured .NET suite; libraries without a .NET test project say so.
Pack writes local packages under ignored `artifacts/nuget` and never publishes.
Run67 delegates packing to its existing tool-package script. Clean runs .NET
clean for Debug and Release, retaining packages and snapshots. Where configured,
`.scripts/project.sh run` starts the development host.

Snapshot archives committed HEAD, recent commit patches and checksums under
ignored `artifacts/snapshots`; it excludes uncommitted/untracked files and retains
previous snapshots. Bash, Git and Perl are required (WSL or Git Bash on Windows).
Existing PowerShell tag wrappers, where present, delegate to these same scripts.

[Run67 project actions](../.run67/README.md) provide the same operations through
normal project trust, Plan Review, approval and explicit mutation confirmations.
Publishing still uses the tag-triggered GitHub workflow with `NUGET_USER` and a
matching NuGet.org trusted-publishing policy; no NuGet credential is kept locally.
