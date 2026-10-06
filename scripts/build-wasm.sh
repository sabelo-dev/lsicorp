#!/usr/bin/env bash
# Builds the site for WebAssembly and assembles dist/, on Linux or macOS.
# Uses the toolchain in .toolchain/ (see scripts/amplify-toolchain.sh) unless
# QT_WASM, QT_HOST and EMSDK point somewhere else.
set -euo pipefail

QT_VERSION="${QT_VERSION:-6.12.0}"
root="$(cd "$(dirname "$0")/.." && pwd)"
tools="$root/.toolchain"
QT_WASM="${QT_WASM:-$tools/qt/$QT_VERSION/wasm_singlethread}"
QT_HOST="${QT_HOST:-$tools/qt/$QT_VERSION/gcc_64}"
EMSDK_DIR="${EMSDK:-$tools/emsdk}"

if [ -d "$tools/venv/bin" ]; then export PATH="$tools/venv/bin:$PATH"; fi
export EMSDK_QUIET=1
# Emscripten's own script reads variables that may be unset, which "set -u" would treat as an error.
set +u
# shellcheck disable=SC1091
source "$EMSDK_DIR/emsdk_env.sh"
set -u

for tool in emcc cmake ninja node; do
  command -v "$tool" >/dev/null 2>&1 || { echo "error: '$tool' is not available. Run scripts/amplify-toolchain.sh first." >&2; exit 1; }
done
echo "Building with $(emcc --version | head -n 1), $(cmake --version | head -n 1), node $(node --version)"

"$QT_WASM/bin/qt-cmake" -S "$root/app" -B "$root/build/wasm" -G Ninja \
  -DQT_HOST_PATH="$QT_HOST" -DCMAKE_BUILD_TYPE=MinSizeRel
cmake --build "$root/build/wasm"

node "$root/scripts/package.mjs" "$root/build/wasm"
