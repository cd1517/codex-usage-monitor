#!/bin/zsh
set -euo pipefail

project_root=${0:A:h:h}
build_dir="$project_root/.build/tests"
mkdir -p "$build_dir"

swiftc \
  -swift-version 5 \
  -parse-as-library \
  -module-name ComoniCoreTests \
  "$project_root"/Sources/ComoniCore/*.swift \
  "$project_root"/Tests/ComoniCoreTests/*.swift \
  -o "$build_dir/ComoniCoreTests"

"$build_dir/ComoniCoreTests" "$@"
