# Mermaid Recursive MJS Downloader
$ErrorActionPreference = "Stop"

# --- Config ---
$version = "11.6.0"
$cdnRoot = "https://cdn.jsdelivr.net/npm/mermaid@$version/dist"
$projectDir = Resolve-Path "$PSScriptRoot\.."
$targetJsDir = Join-Path $projectDir "wwwroot\js"

# Option to strip 'dist/' from import paths
$removeDist = $true

# Track already downloaded files to prevent duplicates
$downloadedFiles = @{}

# Ensure JS target directory exists
if (-not (Test-Path $targetJsDir)) {
    New-Item -ItemType Directory -Path $targetJsDir | Out-Null
}

function Download-And-Parse-Mjs {
    param (
        [string]$relativePath,
        [string]$parentDir = ""
    )

    # Normalize the full path using parent directory
    if ($parentDir -ne "") {
        $relativePath = Join-Path $parentDir $relativePath -Resolve:$false
    }

    # Skip duplicates
    if ($downloadedFiles.ContainsKey($relativePath)) {
        return
    }
    $downloadedFiles[$relativePath] = $true

    # Construct full CDN and local paths
    $url = "$cdnRoot/$relativePath"
    $localPath = Join-Path $targetJsDir $relativePath
    $localDir = Split-Path $localPath

    # Create local directories if needed
    if (-not (Test-Path $localDir)) {
        New-Item -ItemType Directory -Path $localDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "Downloading $relativePath ..."
    Write-Host "(from $url to $localPath)"
    Invoke-WebRequest -Uri $url -OutFile $localPath

    # Skip non-MJS files
    if ($localPath -notlike "*.mjs") { return }

    # Read the file and extract imports
    $content = Get-Content -Raw -Path $localPath
    $matches = [regex]::Matches($content, '(?<=["''])(\./[a-zA-Z0-9/\.\-_]+\.mjs)(?=["''])')
    $currentParent = Split-Path $relativePath

    foreach ($match in $matches) {
        $nextPath = $match.Value
        Write-Host "match.value=$nextPath"

        $localParent = $currentParent

        # Handle ./dist/ prefix safely
        if ($removeDist -and $nextPath.StartsWith("./dist/")) {
            Write-Host "Removing 'dist/' from path: $nextPath"
    $nextPath = $nextPath -replace "^\.\/dist\/", "./"
    $localParent = ""  # override context
        }

        # Clean up path
        $nextPath = $nextPath.TrimStart("./")

        # Skip invalid suffixes
        if ($nextPath -notlike "*.mjs") {
            Write-Host "Skipping non-.mjs: $nextPath"
            continue
        }
        
        Download-And-Parse-Mjs -relativePath $nextPath -parentDir $localParent
    }
}

# --- Start ---

Write-Host "Project directory detected: $projectDir"

# Core files
$minJs = "mermaid.min.js"
$esmMain = "mermaid.esm.min.mjs"
$licensePath = Join-Path $projectDir "wwwroot/LICENSE-mermaid.txt"

# Download base files
Invoke-WebRequest -Uri "$cdnRoot/$minJs" -OutFile (Join-Path $targetJsDir $minJs)
Invoke-WebRequest -Uri "$cdnRoot/$esmMain" -OutFile (Join-Path $targetJsDir $esmMain)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mermaid-js/mermaid/develop/LICENSE" -OutFile $licensePath

# Start recursive .mjs traversal
Download-And-Parse-Mjs -relativePath $esmMain -parentDir ""

Write-Host ""
Write-Host "=========================================="
Write-Host "Finished downloading MermaidJS recursively"
Write-Host "=========================================="
