$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    'App/main.m', 'App/H2MainController.m', 'Tweak/Tweak.xm',
    'Tweak/H2ChangerHook.plist', 'App/H2ConfigManager.m',
    'DeviceTest/main.m', 'DeviceTest/H2TestController.m',
    'Makefile', 'control', 'README.md', 'docs/build-install.md'
)
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $item))) { throw "Missing: $item" }
}
$filter = Get-Content -Raw -LiteralPath (Join-Path $root 'Tweak/H2ChangerHook.plist')
if ($filter -notmatch 'com\.h2phone\.devicetest') { throw 'Missing DeviceTest bundle filter' }
if ($filter -match 'springboard|com\.apple\.') { throw 'Unexpected system process filter' }
Write-Host 'Structure and target filter OK'
