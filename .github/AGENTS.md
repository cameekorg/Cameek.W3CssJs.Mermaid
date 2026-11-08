# GitHub workflow conventions

- Follow the readable style of Cameek.Run67's publish workflow: use concise,
  descriptive emoji-prefixed workflow, job, and step names and blank lines
  between steps.
- Format long single commands with YAML folded blocks (`run: >-`), putting
  arguments on separate lines. Use literal blocks (`run: |`) for shell scripts.
- Preserve triggers, conditions, permissions, command arguments, and execution
  order when making formatting changes. Keep release, dependency, and action
  version updates separate from formatting work.
- NuGet publishing uses `NuGet/login@v1` with `secrets.NUGET_USER`, job-scoped
  `id-token: write` and `contents: read`, and the action's temporary API key.
  Obtain the key immediately before publishing and pass it through a step
  environment variable; do not restore a long-lived publishing-key secret.
