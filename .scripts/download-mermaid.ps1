# Enable robust error handling
$ErrorActionPreference = 'Stop'

# ----------------------------------------
# Configure Project Absolute Directory
# ----------------------------------------

$projectDir = Resolve-Path "$PSScriptRoot\.."
Write-Host "Project directory detected: $projectDir"

# ----------------------------------------
# Configuration
# ----------------------------------------

$version = "11.6.0"
$urlJs = "https://cdn.jsdelivr.net/npm/mermaid@$version/dist/mermaid.min.js"
$urlEsmJs = "https://cdn.jsdelivr.net/npm/mermaid@$version/dist/mermaid.esm.min.mjs"
$urlLicense = "https://raw.githubusercontent.com/mermaid-js/mermaid/develop/LICENSE"

$targetWwwDir = Join-Path $projectDir "wwwroot"
$targetJsDir = Join-Path $targetWwwDir "js"

$targetJsFile = Join-Path $targetJsDir "mermaid.min.js"
$targetEsmJsFile = Join-Path $targetJsDir "mermaid.esm.min.mjs"
$targetLicense = Join-Path $targetWwwDir "LICENSE-mermaid.txt"

# ----------------------------------------
# Create Directories
# ----------------------------------------

if (-not (Test-Path $targetJsDir)) {
    New-Item -ItemType Directory -Path $targetJsDir | Out-Null
}

# ----------------------------------------
# Download Core Files
# ----------------------------------------

Write-Host "Downloading core files..."

Invoke-WebRequest -Uri $urlJs -OutFile $targetJsFile
Invoke-WebRequest -Uri $urlEsmJs -OutFile $targetEsmJsFile
Invoke-WebRequest -Uri $urlLicense -OutFile $targetLicense

# ----------------------------------------
# Detect and Download additional ESM modules
# ----------------------------------------

Write-Host "`nDetecting additional ESM dependencies..."

$esmContent = Get-Content -Path $targetEsmJsFile -Raw

# Regex to match any relative .mjs module path like ./chunks/mermaid.esm.min/chunk-XYZ.mjs
$mjsMatches = [regex]::Matches($esmContent, "(?<=['""])\.\/.*?\.mjs(?=['""])") | ForEach-Object {
    $_.Value.TrimStart("./")
} | Sort-Object -Unique

if ($mjsMatches.Count -eq 0) {
    Write-Host "No additional .mjs files detected."
} else {
    foreach ($relativePath in $mjsMatches) {
        $downloadUrl = "https://cdn.jsdelivr.net/npm/mermaid@$version/dist/$relativePath"
        $localPath = Join-Path $targetJsDir $relativePath

        # Ensure subdirectories exist
        $localDir = Split-Path $localPath
        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }

        Write-Host "Downloading $relativePath ..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $localPath
    }
}

# ----------------------------------------
# Done
# ----------------------------------------

Write-Host ""
Write-Host "==================================="
Write-Host "Finished downloading MermaidJS files"
Write-Host "==================================="
