#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
build_dir="$project_root/.build/check"
mkdir -p "$build_dir"

swiftc \
  -swift-version 5 \
  -parse-as-library \
  -module-name CodexUsageMonitorCheck \
  "$project_root"/Sources/CodexUsageMonitorCore/*.swift \
  "$project_root"/Sources/CodexUsageMonitorCheck/*.swift \
  -o "$build_dir/CodexUsageMonitorCheck"

"$build_dir/CodexUsageMonitorCheck"
