# Mermaid Recursive MJS Downloader
$ErrorActionPreference = "Stop"

# --- Config ---
$version = "11.6.0"
$cdnRoot = "https://cdn.jsdelivr.net/npm/mermaid@$version/dist"
$projectDir = Resolve-Path "$PSScriptRoot\.."
$targetJsDir = Join-Path $projectDir "wwwroot\js"

# Set of already downloaded files to avoid cycles
$downloadedFiles = @{}

# Make sure directory exists
if (-not (Test-Path $targetJsDir)) {
    New-Item -ItemType Directory -Path $targetJsDir | Out-Null
}

function Download-And-Parse-Mjs {
    param (
        [string]$relativePath
    )

    if ($downloadedFiles.ContainsKey($relativePath)) {
        return  # Skip already downloaded
    }

    $downloadedFiles[$relativePath] = $true

    $url = "$cdnRoot/$relativePath"
    $localPath = Join-Path $targetJsDir $relativePath
    $localDir = Split-Path $localPath

    if (-not (Test-Path $localDir)) {
        New-Item -ItemType Directory -Path $localDir -Force | Out-Null
    }

    Write-Host "Downloading $relativePath ..."
    Invoke-WebRequest -Uri $url -OutFile $localPath

    # Only parse .mjs files
    if ($localPath -notlike "*.mjs") { return }

    # Read content and extract further imports
    $content = Get-Content -Raw -Path $localPath

    $matches = [regex]::Matches($content, "(?<=['""])\.\/.*?\.mjs(?=['""])")
    foreach ($match in $matches) {
        $nextPath = $match.Value.TrimStart("./")
        Download-And-Parse-Mjs -relativePath $nextPath
    }
}

# --- Start ---
Write-Host "Project directory detected: $projectDir"

# Core files
$minJs = "mermaid.min.js"
$esmMain = "mermaid.esm.min.mjs"
$licensePath = Join-Path $projectDir "wwwroot/LICENSE-mermaid.txt"

# Download base JS + LICENSE
Invoke-WebRequest -Uri "$cdnRoot/$minJs" -OutFile (Join-Path $targetJsDir $minJs)
Invoke-WebRequest -Uri "$cdnRoot/$esmMain" -OutFile (Join-Path $targetJsDir $esmMain)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mermaid-js/mermaid/develop/LICENSE" -OutFile $licensePath

# Start recursive .mjs resolution
Download-And-Parse-Mjs -relativePath $esmMain

Write-Host ""
Write-Host "=========================================="
Write-Host "Finished downloading MermaidJS recursively"
Write-Host "=========================================="
