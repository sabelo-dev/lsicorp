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

# System packages the build image does not include:
#   xz, bzip2            Emscripten ships its tools as .tar.xz archives
#   libGL, xkbcommon...  Qt's own build tools are ordinary Linux programs that link to these
install_packages() {
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y -q xz bzip2 tar gzip git which mesa-libGL libxkbcommon fontconfig
  elif command -v yum >/dev/null 2>&1; then
    yum install -y -q xz bzip2 tar gzip git which mesa-libGL libxkbcommon fontconfig
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq xz-utils bzip2 tar gzip git libgl1 libxkbcommon0 libfontconfig1
  else
    echo "No supported package manager (dnf, yum or apt-get) found." >&2
    return 1
  fi
}
install_packages || echo "warning: could not install system packages; continuing with what the image has" >&2

# Fail here, with a clear reason, rather than deep inside a download step.
for tool in xz tar git python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: '$tool' is required to install the toolchain and is not available on this build image." >&2
    exit 1
  fi
done

if [ ! -x "$tools/venv/bin/ninja" ]; then
  rm -rf "$tools/venv"
  python3 -m venv "$tools/venv"
  "$tools/venv/bin/pip" install --quiet aqtinstall cmake ninja
fi

if [ ! -x "$tools/qt/$QT_VERSION/gcc_64/bin/qmake" ]; then
  "$tools/venv/bin/python" -m aqt install-qt linux desktop "$QT_VERSION" linux_gcc_64 -O "$tools/qt"
fi
if [ ! -f "$tools/qt/$QT_VERSION/wasm_singlethread/bin/qt-cmake" ]; then
  "$tools/venv/bin/python" -m aqt install-qt all_os wasm "$QT_VERSION" wasm_singlethread -O "$tools/qt"
fi
# The kit's helper scripts are not always marked executable after unpacking.
chmod +x "$tools/qt/$QT_VERSION/wasm_singlethread/bin/"* 2>/dev/null || true

# Emscripten counts as installed only once the compiler itself is present, so
# a download that failed part-way (and was cached) is started again cleanly.
if [ ! -f "$tools/emsdk/upstream/emscripten/emcc" ]; then
  rm -rf "$tools/emsdk"
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$tools/emsdk"
  "$tools/emsdk/emsdk" install "$EMSCRIPTEN_VERSION"
  "$tools/emsdk/emsdk" activate "$EMSCRIPTEN_VERSION"
fi

echo "Toolchain ready in $tools"
