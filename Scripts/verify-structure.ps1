$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    'H2PHONE/main.m', 'H2PHONE/H2PhoneController.m', 'H2PHONE/H2PhoneAppListController.m', 'Tweak/Tweak.xm',
    'Tweak/H2WebFingerprint.h', 'Tweak/H2WebFingerprint.m',
    'Tweak/H2PHONEHook.plist', 'H2PHONE/H2ConfigManager.m',
    'H2DEV/main.m', 'H2DEV/H2DevController.m',
    'Makefile', 'control', 'README.md', 'docs/build-install.md'
)
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $item))) { throw "Missing: $item" }
}
$filter = Get-Content -Raw -LiteralPath (Join-Path $root 'Tweak/H2PHONEHook.plist')
if ($filter -notmatch 'com\.apple\.UIKit') { throw 'Missing UIKit application filter' }
$tweak = Get-Content -Raw -LiteralPath (Join-Path $root 'Tweak/Tweak.xm')
if ($tweak -notmatch 'H2CurrentConfig' -or $tweak -notmatch 'bundleID' -or $tweak -notmatch '\[@"enabled"\]') { throw 'Missing per-app guard' }
Write-Host 'Structure and per-app guard OK'
