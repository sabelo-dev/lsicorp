# Renders a route of the desktop build to a PNG, without opening a window,
# and prints any warnings the app logged while doing so.
# Usage: scripts/shot.ps1 -Route /work/1145 -Out page.png [-Size 1200x1600] [-Dark]
# Set LSI_SUPABASE_URL and LSI_SUPABASE_KEY first to render live content.
param(
    [Parameter(Mandatory)] [string] $Route,
    [Parameter(Mandatory)] [string] $Out,
    [string] $Size = '1200x1600',
    [switch] $Dark,
    [string] $Action,
    [string] $Qt = 'C:\Qt\6.12.0\mingw_64',
    [string] $MinGW = 'C:\Qt\Tools\mingw1310_64'
)

$env:PATH = "$Qt\bin;$MinGW\bin;$env:PATH"
$env:QT_QPA_PLATFORM = 'offscreen'
$env:QT_QUICK_BACKEND = 'software'
$env:QT_QPA_FONTDIR = 'C:\Windows\Fonts'
$env:QT_FORCE_STDERR_LOGGING = '1'

$dir = (Resolve-Path (Join-Path $PSScriptRoot '..\build\desktop')).Path
$arguments = @('--route', $Route, '--size', $Size, '--screenshot', "`"$Out`"")
if ($Dark) { $arguments += '--dark' }
if ($Action) { $arguments += @('--action', $Action) }

$log = Join-Path $dir 'shot.err'
$process = Start-Process -FilePath (Join-Path $dir 'lsitools.exe') -ArgumentList $arguments -WorkingDirectory $dir `
    -RedirectStandardError $log -RedirectStandardOutput (Join-Path $dir 'shot.out') -PassThru -NoNewWindow
if (-not $process.WaitForExit(60000)) { $process.Kill(); Write-Output "timed out rendering $Route"; exit 124 }

Get-Content $log | Where-Object { $_ -and $_ -notmatch 'propertyCache.append' } | Select-Object -Unique -First 20
exit $process.ExitCode
