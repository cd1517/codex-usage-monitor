#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
temporary_root=$(mktemp -d)
iconset_path="$temporary_root/AppIcon.iconset"
master_path="$temporary_root/AppIcon-1024.png"
output_path="$project_root/Resources/AppIcon.icns"

cleanup() {
    rm -rf "$temporary_root"
}
trap cleanup EXIT

mkdir -p "$iconset_path"
swift "$project_root/scripts/generate-icon.swift" "$master_path"

for specification in \
    "16 icon_16x16.png" \
    "32 icon_16x16@2x.png" \
    "32 icon_32x32.png" \
    "64 icon_32x32@2x.png" \
    "128 icon_128x128.png" \
    "256 icon_128x128@2x.png" \
    "256 icon_256x256.png" \
    "512 icon_256x256@2x.png" \
    "512 icon_512x512.png" \
    "1024 icon_512x512@2x.png"; do
    size=${specification%% *}
    filename=${specification#* }
    sips -z "$size" "$size" "$master_path" --out "$iconset_path/$filename" >/dev/null
done

iconutil -c icns "$iconset_path" -o "$output_path"
echo "$output_path"
