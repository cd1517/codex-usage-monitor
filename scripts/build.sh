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
  "$project_root"/Sources/ComoniCore/*.swift \
  "$project_root"/Sources/ComoniApp/*.swift \
  -o "$build_dir/Comoni"

echo "$build_dir/Comoni"
