#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
app_path="$project_root/dist/Comoni.app"
contents_path="$app_path/Contents"
binary_path=$($project_root/scripts/build.sh release | tail -n 1)

mkdir -p "$contents_path/MacOS" "$contents_path/Resources"
install -m 755 "$binary_path" "$contents_path/MacOS/Comoni"
install -m 644 "$project_root/Resources/Info.plist" "$contents_path/Info.plist"

plutil -lint "$contents_path/Info.plist"
codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

echo "$app_path"
