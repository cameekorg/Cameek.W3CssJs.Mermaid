# Cameek.W3CssJs.Mermaid project actions

Start Run67 from this checkout or one of its subdirectories:

```bash
cd /path/to/Cameek.W3CssJs.Mermaid
run67
```

The project scope uses [app-run67.yaml](app-run67.yaml) after the normal project-trust
decision. The favorites are ordinary Flows; Plan Review, approval and explicit
confirmation for mutation actions still apply.

| Action | Purpose |
| --- | --- |
| [♻️ Restore](flows/dotnet/restore.run67.yaml) | Restore the configured solution/project |
| [🔨 Build](flows/dotnet/build.run67.yaml) | Build in Release |
| [🧪 Test](flows/dotnet/test.run67.yaml) | Run the configured Release tests |
| [📦 Package](flows/dotnet/package.run67.yaml) | Create local NuGet packages |
| [🧹 Cleanup](flows/dotnet/cleanup.run67.yaml) | Confirm cleaning generated Debug and Release output |
| [🌿 Git status](flows/git/status.run67.yaml) | Show the branch, version and local changes |
| [📸 Git snapshot](flows/git/create-git-project-snapshot.run67.yaml) | Archive committed source, recent commit patches and checksums |
| [🏷️ Increase version](flows/git/increase-version.run67.yaml) | Preview and apply a patch/minor/major version change |
| [🏷️ Tag current version](flows/git/tag-latest-version.run67.yaml) | Preview and push the current committed version tag |
| [🚀 Increase & release](flows/git/increase-and-release-version.run67.yaml) | Preview, confirm, bump, commit, push and tag |

The .NET, status and snapshot Flows delegate to `.scripts/project.sh`. Repository
configuration selects the correct solution, test command, package projects and
optional development host. Targets are listed in `.scripts/release.conf`. Libraries without a .NET test
project run the release-script regression tests rather than an empty test command.

The three version entrypoints are `.scripts/increase-version.sh`,
`.scripts/tag-latest-version.sh` and `.scripts/increase-and-tag-version.sh`.
The version actions expose `bumpType` (`patch`, `minor`, `major`, default `patch`).
Use the scripts directly for custom versions, interactive selection and dry runs;
see [the script guide](../.scripts/README.md).

Snapshots go under `artifacts/snapshots` and contain **committed HEAD only**, plus
a patch for the requested recent commits and checksums. Previous snapshots are
retained. This replaces the older snapshot Flow's working-tree/untracked archive
and automatic removal of previous snapshots; commit source changes first when
they belong in the shared snapshot.

Flows resolve the Git root before calling repository-relative scripts, so they
work from nested directories inside the checkout. Launching a Flow by absolute
path from an unrelated directory does not switch the caller's repository; change
to the intended checkout first. Relative favorites resolve against this layout.
