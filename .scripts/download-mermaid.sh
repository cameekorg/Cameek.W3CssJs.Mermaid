#!/bin/bash

echo
echo "Download MermaidJS"
echo "==================="
echo "https://www.jsdelivr.com/package/npm/mermaid"
echo

# Change directory to the script's location
cd "$(dirname "$0")" || exit

echo "Configuring Version and URLs"
echo "----------------------------"
VERSION="10.9.0"
URL_BASE="https://cdn.jsdelivr.net/npm/mermaid@${VERSION}/dist"

# License
URL_LICENSE="https://raw.githubusercontent.com/mermaid-js/mermaid/develop/LICENSE"

echo
echo "Configuring Target Directories and Files"
echo "----------------------------------------"
TARGET_WWW_DIR="../wwwroot"
TARGET_JS_DIR="${TARGET_WWW_DIR}/js"
TARGET_LICENSE="${TARGET_WWW_DIR}/LICENSE-mermaid.txt"

echo
echo "Creating Directories"
echo "--------------------"
mkdir -p "$TARGET_JS_DIR"

echo
echo "Downloading Files"
echo "-----------------"

# JavaScript Files
JS_FILES=(
  "mermaid.min.js"
  "mermaid.esm.min.mjs"
)

for f in "${JS_FILES[@]}"; do
  curl -o "${TARGET_JS_DIR}/${f}" "${URL_BASE}/${f}"
done

# License
curl -o "$TARGET_LICENSE" "$URL_LICENSE"

echo
echo "==================================="
echo "Finished downloading MermaidJS files"
echo
