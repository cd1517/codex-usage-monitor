#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
configuration=${1:-debug}
build_dir="$project_root/.build/$configuration"
mkdir -p "$build_dir"

optimization=(-Onone)
if [[ "$configuration" == "release" ]]; then
  optimization=(-O -whole-module-optimization)
fi

swiftc \
  -swift-version 5 \
  -parse-as-library \
  "${optimization[@]}" \
  -framework AppKit \
  -framework SwiftUI \
  -framework CoreGraphics \
  "$project_root"/Sources/CodexUsageMonitorCore/*.swift \
  "$project_root"/Sources/CodexUsageMonitorApp/*.swift \
  -o "$build_dir/CodexUsageMonitor"

echo "$build_dir/CodexUsageMonitor"
