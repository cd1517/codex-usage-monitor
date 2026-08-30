#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
build_dir="$project_root/.build/tests"
mkdir -p "$build_dir"

swiftc \
  -swift-version 5 \
  -parse-as-library \
  -module-name CodexUsageMonitorCoreTests \
  "$project_root"/Sources/CodexUsageMonitorCore/*.swift \
  "$project_root"/Tests/CodexUsageMonitorCoreTests/*.swift \
  -o "$build_dir/CodexUsageMonitorCoreTests"

"$build_dir/CodexUsageMonitorCoreTests" "$@"
