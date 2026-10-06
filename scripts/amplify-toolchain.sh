#!/usr/bin/env bash
# Installs the build toolchain into .toolchain/ on a Linux build machine such
# as the AWS Amplify build image: Qt (desktop tools plus the WebAssembly kit),
# Emscripten, CMake and Ninja. Does nothing for parts that are already there,
# so a cached .toolchain/ makes later builds fast.
set -euo pipefail

QT_VERSION="${QT_VERSION:-6.12.0}"
EMSCRIPTEN_VERSION="${EMSCRIPTEN_VERSION:-5.0.5}"   # the version Qt 6.12 expects
root="$(cd "$(dirname "$0")/.." && pwd)"
tools="$root/.toolchain"
mkdir -p "$tools"

# Qt's build tools are ordinary Linux programs and need these system libraries.
if command -v dnf >/dev/null 2>&1; then
  dnf install -y -q mesa-libGL libxkbcommon fontconfig >/dev/null || true
fi

if [ ! -d "$tools/venv" ]; then
  python3 -m venv "$tools/venv"
  "$tools/venv/bin/pip" install --quiet aqtinstall cmake ninja
fi

if [ ! -d "$tools/qt/$QT_VERSION/gcc_64" ]; then
  "$tools/venv/bin/python" -m aqt install-qt linux desktop "$QT_VERSION" linux_gcc_64 -O "$tools/qt"
fi
if [ ! -d "$tools/qt/$QT_VERSION/wasm_singlethread" ]; then
  "$tools/venv/bin/python" -m aqt install-qt all_os wasm "$QT_VERSION" wasm_singlethread -O "$tools/qt"
fi

if [ ! -d "$tools/emsdk/upstream/emscripten" ]; then
  rm -rf "$tools/emsdk"
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$tools/emsdk"
  "$tools/emsdk/emsdk" install "$EMSCRIPTEN_VERSION"
  "$tools/emsdk/emsdk" activate "$EMSCRIPTEN_VERSION"
fi

echo "Toolchain ready in $tools"
