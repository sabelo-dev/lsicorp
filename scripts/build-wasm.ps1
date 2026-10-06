# Builds the site for WebAssembly and assembles dist\, on Windows.
# Needs Qt 6.12 with the wasm_singlethread kit, a desktop Qt of the same
# version (its tools run during the build), and Emscripten 5.0.5.
param(
    [string] $QtWasm = 'C:\Qt\6.12.0\wasm_singlethread',
    [string] $QtHost = 'C:\Qt\6.12.0\mingw_64',
    [string] $QtTools = 'C:\Qt\Tools',
    [string] $Emsdk = "$env:USERPROFILE\emsdk"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot

$env:EMSDK_QUIET = '1'
& "$Emsdk\emsdk_env.ps1" | Out-Null
$env:PATH = "$QtTools\Ninja;$QtTools\CMake_64\bin;$QtTools\mingw1310_64\bin;$env:PATH"

& "$QtWasm\bin\qt-cmake.bat" -S "$root\app" -B "$root\build\wasm" -G Ninja "-DQT_HOST_PATH=$QtHost" -DCMAKE_BUILD_TYPE=MinSizeRel
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
cmake --build "$root\build\wasm"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Assemble dist\: hashed file names, the compressed module, config.js and robots.txt.
node (Join-Path $root 'scripts/package.mjs') (Join-Path $root 'build/wasm')
exit $LASTEXITCODE
