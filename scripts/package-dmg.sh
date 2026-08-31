#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
app_path="$project_root/dist/Codex Usage Monitor.app"
dmg_path="$project_root/dist/Codex Usage Monitor.dmg"
staging="$project_root/dist/dmg-staging"

"$project_root/scripts/package-app.sh" >/dev/null

rm -rf "$staging"
mkdir -p "$staging"
cp -R "$app_path" "$staging/"
ln -s /Applications "$staging/Applications"

hdiutil create \
  -volname "Codex Usage Monitor" \
  -srcfolder "$staging" \
  -ov \
  -format UDZO \
  "$dmg_path"

rm -rf "$staging"
echo "$dmg_path"
