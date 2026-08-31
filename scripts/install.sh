#!/bin/bash
# Codex Usage Monitor 一键安装脚本
# 用法：curl -fsSL https://raw.githubusercontent.com/<用户名>/codex-usage-monitor/main/scripts/install.sh | bash
set -euo pipefail

# ⚠️ 若仓库归属不是 ManGo/codex-usage-monitor，改这一行
REPO="ManGo/codex-usage-monitor"
DMG_URL="https://github.com/$REPO/releases/latest/download/Codex%20Usage%20Monitor.dmg"
APP_NAME="Codex Usage Monitor.app"
INSTALL_DIR="/Applications"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "==> 下载最新版本"
curl -fL --progress-bar -o "$tmp/app.dmg" "$DMG_URL"

echo "==> 挂载 DMG"
mount_dir="$tmp/mnt"
mkdir -p "$mount_dir"
hdiutil attach "$tmp/app.dmg" -readonly -nobrowse -mountpoint "$mount_dir" >/dev/null

echo "==> 安装到 $INSTALL_DIR"
if [ -w "$INSTALL_DIR" ]; then
    cp -R "$mount_dir/$APP_NAME" "$INSTALL_DIR/"
else
    sudo cp -R "$mount_dir/$APP_NAME" "$INSTALL_DIR/"
fi

echo "==> 清除隔离标记（终端安装无需 Gatekeeper 确认）"
xattr -cr "$INSTALL_DIR/$APP_NAME"

hdiutil detach "$mount_dir" >/dev/null

echo "✅ 安装完成：$INSTALL_DIR/$APP_NAME"
echo "   首次启动建议在终端执行：open \"$INSTALL_DIR/$APP_NAME\""
