# Refresh the pinned Mermaid runtime, including all transitive browser modules.
$ErrorActionPreference = 'Stop'
$downloader = Join-Path $PSScriptRoot 'download-mermaid.py'

if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 $downloader
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    & python3 $downloader
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python $downloader
} else {
    throw 'Python 3 is required to refresh Mermaid assets.'
}

if ($LASTEXITCODE -ne 0) {
    throw "Mermaid asset refresh failed (exit code $LASTEXITCODE)."
}
