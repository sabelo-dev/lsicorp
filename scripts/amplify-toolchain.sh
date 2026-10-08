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
  # Build machines usually run as an ordinary user that may use sudo without a password.
  local as_root=""
  if [ "$(id -u)" -ne 0 ]; then
    if sudo -n true 2>/dev/null; then as_root="sudo"; else echo "not root and no passwordless sudo" >&2; return 1; fi
  fi
  if command -v dnf >/dev/null 2>&1; then
    $as_root dnf install -y -q xz bzip2 mesa-libGL libxkbcommon fontconfig
  elif command -v yum >/dev/null 2>&1; then
    $as_root yum install -y -q xz bzip2 mesa-libGL libxkbcommon fontconfig
  elif command -v apt-get >/dev/null 2>&1; then
    $as_root apt-get update -qq
    $as_root apt-get install -y -qq xz-utils bzip2 libgl1 libxkbcommon0 libfontconfig1
  else
    echo "no supported package manager (dnf, yum or apt-get)" >&2
    return 1
  fi
}
install_packages || echo "note: system packages could not be installed; continuing with what the image has" >&2

# Without xz, tar cannot unpack the .tar.xz archives Emscripten downloads.
# Python can, so stand in for it: tar only ever asks xz to decompress a stream.
mkdir -p "$tools/bin"
if ! command -v xz >/dev/null 2>&1; then
  if ! python3 -c "import lzma" 2>/dev/null; then
    echo "error: neither 'xz' nor Python's lzma module is available, so Emscripten cannot be unpacked." >&2
    exit 1
  fi
  cat > "$tools/bin/xz" <<'SHIM'
#!/usr/bin/env python3
# Minimal stand-in for "xz -d": decompresses standard input to standard output.
import lzma
import shutil
import sys

with lzma.open(sys.stdin.buffer) as source:
    shutil.copyfileobj(source, sys.stdout.buffer)
SHIM
  chmod +x "$tools/bin/xz"
  echo "note: 'xz' is not installed; using a Python stand-in for it"
fi
export PATH="$tools/bin:$PATH"

# Fail here, with a clear reason, rather than deep inside a download step.
for tool in xz tar git python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: '$tool' is required to install the toolchain and is not available on this build image." >&2
    exit 1
  fi
done

# A Python environment cannot be moved: its programs start with the full path
# of the folder it was created in. A build machine may restore the cache into a
# differently named folder, so the programs are run here, and the environment
# is made again if they no longer start. It is small and takes seconds.
venv_works() {
  "$tools/venv/bin/cmake" --version >/dev/null 2>&1 \
    && "$tools/venv/bin/ninja" --version >/dev/null 2>&1 \
    && "$tools/venv/bin/python" -c "import aqt" >/dev/null 2>&1
}
if ! venv_works; then
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
