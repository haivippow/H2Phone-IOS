$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    'App/main.m', 'App/H2MainController.m', 'App/H2AppListController.m', 'Tweak/Tweak.xm',
    'Tweak/H2ChangerHook.plist', 'App/H2ConfigManager.m',
    'DeviceTest/main.m', 'DeviceTest/H2TestController.m',
    'Makefile', 'control', 'README.md', 'docs/build-install.md'
)
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $item))) { throw "Missing: $item" }
}
$filter = Get-Content -Raw -LiteralPath (Join-Path $root 'Tweak/H2ChangerHook.plist')
if ($filter -notmatch 'com\.apple\.UIKit') { throw 'Missing UIKit application filter' }
$tweak = Get-Content -Raw -LiteralPath (Join-Path $root 'Tweak/Tweak.xm')
if ($tweak -notmatch 'isFakeActiveForBundleID') { throw 'Missing per-app guard' }
Write-Host 'Structure and per-app guard OK'
