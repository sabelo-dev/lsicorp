# Renders a route of the desktop build to a PNG, without opening a window.
# Usage: scripts/shot.ps1 -Route /products/1145 -Out page.png [-Size 1200x1600] [-Dark]
param(
    [Parameter(Mandatory)] [string] $Route,
    [Parameter(Mandatory)] [string] $Out,
    [string] $Size = '1200x1600',
    [switch] $Dark,
    [string] $Qt = 'C:\Qt\6.12.0\mingw_64',
    [string] $MinGW = 'C:\Qt\Tools\mingw1310_64'
)

$env:PATH = "$Qt\bin;$MinGW\bin;$env:PATH"
$env:QT_QPA_PLATFORM = 'offscreen'
$env:QT_QUICK_BACKEND = 'software'
$env:QT_QPA_FONTDIR = 'C:\Windows\Fonts'

$exe = Join-Path $PSScriptRoot '..\build\desktop\lsitools.exe'
$arguments = @('--route', $Route, '--size', $Size, '--screenshot', $Out)
if ($Dark) { $arguments += '--dark' }

Push-Location (Split-Path $exe)
try { & $exe @arguments } finally { Pop-Location }
exit $LASTEXITCODE
