$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$fingerprint = Get-Content -Raw (Join-Path $repoRoot 'Tweak/H2WebFingerprint.m')
$tweak = Get-Content -Raw (Join-Path $repoRoot 'Tweak/Tweak.xm')
$config = Get-Content -Raw (Join-Path $repoRoot 'H2PHONE/H2ConfigManager.m')
$rootMakefile = Get-Content -Raw (Join-Path $repoRoot 'Makefile')

function Assert-SourceContains {
    param([string]$Source, [string]$Pattern, [string]$Message)
    if ($Source -notmatch $Pattern) { throw $Message }
}

Assert-SourceContains $fingerprint 'NSJSONSerialization\s+dataWithJSONObject' `
    'Fingerprint User-Agent must be encoded with NSJSONSerialization.'
Assert-SourceContains $fingerprint 'NSJSONWritingFragmentsAllowed' `
    'Top-level User-Agent JSON encoding must allow scalar fragments.'
Assert-SourceContains $fingerprint 'H2WebFingerprintScript\s*\(' `
    'The fingerprint script builder must be exposed for focused tests.'

$initHook = [regex]::Match(
    $tweak,
    '(?s)-\s*\(instancetype\)initWithFrame:\(CGRect\)frame configuration:\(WKWebViewConfiguration \*\)configuration\s*\{(?<body>.*?)\n\}'
)
if (-not $initHook.Success) { throw 'WKWebView configuration initializer hook was not found.' }
$body = $initHook.Groups['body'].Value
$configureIndex = $body.IndexOf('H2ConfigureWebView(configuration)')
$origIndex = $body.IndexOf('%orig')
if ($configureIndex -lt 0 -or $origIndex -lt 0 -or $configureIndex -gt $origIndex) {
    throw 'Fingerprint user script must be attached to the configuration before WKWebView initialization.'
}

Assert-SourceContains $fingerprint '(?s)if\s*\(enabled\).*?NSString \*currentScript\s*=\s*H2WebFingerprintScript' `
    'Runtime evaluation must build the enabled script in H2UpdateWebFingerprint.'
Assert-SourceContains $fingerprint 'objc_getAssociatedObject\s*\(webView,\s*&H2FingerprintAppliedKey\)' `
    'Runtime disable must be gated by per-web-view H2 state.'
Assert-SourceContains $fingerprint 'WKUserScriptInjectionTimeAtDocumentStart' `
    'Fingerprint injection must occur at document start.'
Assert-SourceContains $fingerprint 'forMainFrameOnly:NO' `
    'Fingerprint injection must include subframes.'
Assert-SourceContains $fingerprint 'H2BrowserProfile\s*\(' `
    'Only a browser-safe subset of the native profile may be serialized into JavaScript.'

$plist = Get-Content -Raw (Join-Path $repoRoot 'Tweak/H2PHONEHook.plist')
Assert-SourceContains $plist 'com\.apple\.mobilesafari' `
    'The tweak filter must explicitly include MobileSafari.'

foreach ($key in @('memory', 'cores', 'screenWidth', 'screenHeight', 'screenScale', 'carrier', 'latitude', 'longitude', 'battery', 'build', 'darwin')) {
    Assert-SourceContains $config ('@"' + $key + '"') "Profiles must define $key."
}
Assert-SourceContains $tweak 'physicalMemory' 'Selected apps must receive profile physical memory.'
if ($tweak -match '%hook\s+UIScreen') {
    throw 'UIScreen must not be hooked because fake native bounds break app and Safari keyboard layout.'
}
if ($fingerprint -match "prop\(Screen\.prototype,'(?:width|height|availWidth|availHeight)'" -or
    $fingerprint -match "prop\(window,'devicePixelRatio'") {
    throw 'Safari screen geometry must stay native so text-selection touch coordinates remain aligned.'
}
Assert-SourceContains $tweak 'notify_register_dispatch' 'Open web views must refresh after runtime configuration changes.'
Assert-SourceContains $tweak 'kern\.osrelease' 'Selected processes must receive the profile Darwin release.'
Assert-SourceContains $tweak 'SystemVersion\.plist' 'Selected processes must receive a fake SystemVersion dictionary.'
Assert-SourceContains $tweak '%hook\s+UIWebView' 'Legacy UIWebView User-Agent reads must be covered.'
Assert-SourceContains $tweak '%hook\s+NSUserDefaults' 'Cached User-Agent reads must be covered.'
Assert-SourceContains $tweak '%hook\s+NSMutableURLRequest' 'Outgoing User-Agent headers must be covered.'
Assert-SourceContains $rootMakefile 'ARCHS = arm64 arm64e' 'Safari support requires an arm64e tweak slice.'

Write-Output 'Source tests passed: 33 assertions.'
