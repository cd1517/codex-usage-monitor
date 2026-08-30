#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
build_dir="$project_root/.build/check"
mkdir -p "$build_dir"

swiftc \
  -swift-version 5 \
  -parse-as-library \
  -module-name ComoniCheck \
  "$project_root"/Sources/ComoniCore/*.swift \
  "$project_root"/Sources/ComoniCheck/*.swift \
  -o "$build_dir/ComoniCheck"

"$build_dir/ComoniCheck"
