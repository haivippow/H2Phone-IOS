$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$fingerprint = Get-Content -Raw (Join-Path $repoRoot 'Tweak/H2WebFingerprint.m')
$tweak = Get-Content -Raw (Join-Path $repoRoot 'Tweak/Tweak.xm')
$config = Get-Content -Raw (Join-Path $repoRoot 'H2PHONE/H2ConfigManager.m')
$rootMakefile = Get-Content -Raw (Join-Path $repoRoot 'Makefile')
$phoneEntitlements = Get-Content -Raw (Join-Path $repoRoot 'H2PHONE/H2PHONE.entitlements')
$phoneRootHideEntitlementsPath = Join-Path $repoRoot 'H2PHONE/H2PHONE.roothide.entitlements'
$phoneRootHideEntitlements = if (Test-Path $phoneRootHideEntitlementsPath) { Get-Content -Raw $phoneRootHideEntitlementsPath } else { '' }
$phoneMakefile = Get-Content -Raw (Join-Path $repoRoot 'H2PHONE/Makefile')
$phoneAppDelegate = Get-Content -Raw (Join-Path $repoRoot 'H2PHONE/H2PhoneAppDelegate.m')
$swiftFactoryPath = Join-Path $repoRoot 'H2PhoneSwiftUI/App/H2PhoneRootViewControllerFactory.swift'
$swiftFactory = if (Test-Path $swiftFactoryPath) { Get-Content -Raw $swiftFactoryPath } else { '' }
$dashboardViews = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Features/DashboardAndProfilesViews.swift')
$targetAppViews = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Features/TargetAppsAndOperationsViews.swift')
$swiftStore = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Core/H2Store.swift')
$swiftModels = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Models/H2Models.swift')
$swiftDeviceService = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Services/DeviceService.swift')
$deviceProfileGenerator = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Services/DeviceProfileGenerator.swift')
$generatedDeviceProfile = Get-Content -Raw (Join-Path $repoRoot 'H2PhoneSwiftUI/Models/GeneratedDeviceProfile.swift')
$profileSettingsModelPath = Join-Path $repoRoot 'H2PhoneSwiftUI/Models/ProfileGenerationSettings.swift'
$profileSettingsModel = if (Test-Path $profileSettingsModelPath) { Get-Content -Raw $profileSettingsModelPath } else { '' }
$profileSettingsServicePath = Join-Path $repoRoot 'H2PhoneSwiftUI/Services/ProfileSettingsService.swift'
$profileSettingsService = if (Test-Path $profileSettingsServicePath) { Get-Content -Raw $profileSettingsServicePath } else { '' }
$profileSettingsViewPath = Join-Path $repoRoot 'H2PhoneSwiftUI/Features/ProfileSettingsView.swift'
$profileSettingsView = if (Test-Path $profileSettingsViewPath) { Get-Content -Raw $profileSettingsViewPath } else { '' }
$installedAppServicePath = Join-Path $repoRoot 'H2PHONE/H2InstalledAppService.m'
$installedAppService = if (Test-Path $installedAppServicePath) { Get-Content -Raw $installedAppServicePath } else { '' }
$activationServicePath = Join-Path $repoRoot 'H2PHONE/H2ProfileActivationService.m'
$activationService = if (Test-Path $activationServicePath) { Get-Content -Raw $activationServicePath } else { '' }
$bridgingHeaderPath = Join-Path $repoRoot 'H2PHONE/H2PHONE-Bridging-Header.h'
$bridgingHeader = if (Test-Path $bridgingHeaderPath) { Get-Content -Raw $bridgingHeaderPath } else { '' }
$devEntitlementsPath = Join-Path $repoRoot 'H2DEV/H2DEV.entitlements'
$devEntitlements = if (Test-Path $devEntitlementsPath) { Get-Content -Raw $devEntitlementsPath } else { '' }
$devMakefile = Get-Content -Raw (Join-Path $repoRoot 'H2DEV/Makefile')
$releaseWorkflow = Get-Content -Raw (Join-Path $repoRoot '.github/workflows/release.yml')
$buildDocs = Get-Content -Raw (Join-Path $repoRoot 'docs/build-install.md')

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
Assert-SourceContains $config '(?s)@"schema":\s*@2.*?@"generatedProfile".*?NSPropertyListSerialization.*?NSDataWritingAtomic' `
    'Generated profiles must be stored atomically in schema 2.'
Assert-SourceContains $config '(?s)\[value\[@"schema"\]\s+isEqual:@1\].*?generatedProfile.*?enabledApps' `
    'Schema-1 configs must migrate their preset and enabled applications.'
Assert-SourceContains $tweak '(?s)H2Profile\(void\).*?config\[@"generatedProfile"\]' `
    'The tweak must consume the generated profile directly from effective config.'
Assert-SourceContains $activationService '(?s)activateProfile:.*?enabledApps:.*?activateGeneratedProfile' `
    'The Swift bridge must activate a generated profile and its selected applications.'
Assert-SourceContains $config '(?s)activateGeneratedProfile:.*?previousApps.*?unionSet.*?publishRuntimeStateForBundleID' `
    'Profile activation must notify both newly selected and removed applications.'
Assert-SourceContains $config '(?s)restoreOriginal:.*?@"enabled":\s*@\(NO\).*?@"generatedProfile":\s*current\[@"generatedProfile"\].*?NSDataWritingAtomic' `
    'Restore Original must disable a generated profile without resolving it through legacy presets.'
Assert-SourceContains $tweak 'physicalMemory' 'Selected apps must receive profile physical memory.'
if ($tweak -match '%hook\s+UIScreen') {
    throw 'UIScreen must not be hooked because fake native bounds break app and Safari keyboard layout.'
}
Assert-SourceContains $fingerprint "prop\(Screen\.prototype,'width'" `
    'Browser screen width must remain isolated to JavaScript.'
Assert-SourceContains $fingerprint "prop\(window,'devicePixelRatio'" `
    'Browser DPR must remain isolated to JavaScript.'
Assert-SourceContains $tweak 'notify_register_dispatch' 'Open web views must refresh after runtime configuration changes.'
Assert-SourceContains $tweak 'kern\.osrelease' 'Selected processes must receive the profile Darwin release.'
Assert-SourceContains $tweak 'SystemVersion\.plist' 'Selected processes must receive a fake SystemVersion dictionary.'
Assert-SourceContains $tweak '%hook\s+UIWebView' 'Legacy UIWebView User-Agent reads must be covered.'
Assert-SourceContains $tweak '%hook\s+NSUserDefaults' 'Cached User-Agent reads must be covered.'
Assert-SourceContains $tweak '%hook\s+NSMutableURLRequest' 'Outgoing User-Agent headers must be covered.'
Assert-SourceContains $rootMakefile 'ARCHS = arm64 arm64e' 'Safari support requires an arm64e tweak slice.'

foreach ($entitlements in @($phoneRootHideEntitlements, $devEntitlements)) {
    Assert-SourceContains $entitlements '<key>platform-application</key>\s*<true\s*/>' `
        'RootHide apps require the platform-application entitlement.'
    Assert-SourceContains $entitlements '<key>com\.apple\.private\.security\.no-sandbox</key>\s*<true\s*/>' `
        'RootHide apps require the no-sandbox entitlement.'
    Assert-SourceContains $entitlements '<key>com\.apple\.private\.security\.storage\.AppBundles</key>\s*<true\s*/>' `
        'RootHide apps require AppBundles storage access.'
    Assert-SourceContains $entitlements '<key>com\.apple\.private\.security\.storage\.AppDataContainers</key>\s*<true\s*/>' `
        'RootHide apps require AppDataContainers storage access.'
}
if ($phoneEntitlements -match 'no-sandbox|storage\.AppBundles|storage\.AppDataContainers') {
    throw 'The standard rootless H2PHONE entitlement file must not gain RootHide-only privileges.'
}
Assert-SourceContains $phoneMakefile '(?s)ifeq\s*\(\$\(THEOS_PACKAGE_SCHEME\),roothide\).*?H2PHONE_CODESIGN_FLAGS\s*=\s*-S\$\(THEOS_PROJECT_DIR\)/H2PHONE/H2PHONE\.roothide\.entitlements.*?else.*?H2PHONE_CODESIGN_FLAGS\s*=\s*-S\$\(THEOS_PROJECT_DIR\)/H2PHONE/H2PHONE\.entitlements.*?endif' `
    'H2PHONE must select RootHide entitlements only for the roothide scheme.'
Assert-SourceContains $phoneMakefile '(?s)H2PHONE_SWIFT_FILES\s*=.*?H2PhoneSwiftUI' `
    'The Theos application must compile the H2PhoneSwiftUI sources.'
Assert-SourceContains $phoneAppDelegate '#import\s+<H2PHONE-Swift\.h>' `
    'The Objective-C app delegate must import the generated H2PHONE Swift header.'
Assert-SourceContains $phoneAppDelegate 'H2PhoneRootViewControllerFactory\s+makeRootViewController' `
    'The app delegate must install the SwiftUI root view controller.'
Assert-SourceContains $swiftFactory '(?s)let rootView\s*=\s*RootView\(\).*?UIHostingController\s*\(rootView:\s*rootView\)' `
    'The Swift factory must host RootView in a UIHostingController.'
Assert-SourceContains $dashboardViews 'struct\s+DashboardView[\s\S]*?ScrollView\s*\{' `
    'The dashboard must remain vertically scrollable.'
Assert-SourceContains $dashboardViews 'struct\s+H2BrandIcon:\s*View' `
    'The dashboard header must use the bundled cat app icon.'
Assert-SourceContains $dashboardViews '(?s)ToolbarItem\s*\(placement:\s*\.principal\).*?HStack.*?H2BrandIcon\(\).*?Text\s*\(\s*"H2PHONE"\s*\)' `
    'The cat icon and H2PHONE title must form a centered dashboard header.'
Assert-SourceContains $dashboardViews '(?s)struct\s+ProfilesView.*?onTapGesture\s*\{\s*if\s+profile\.id\s*!=\s*store\.activeID\s*\{\s*rollbackTarget\s*=\s*profile' `
    'Inactive profile cards must open rollback confirmation when tapped.'
Assert-SourceContains $dashboardViews '(?s)let\s+recent\s*=.*?ForEach\(Array\(recent\)\).*?H2Card.*?contentShape\(RoundedRectangle\(cornerRadius:\s*18\)\).*?onTapGesture\s*\{\s*rollbackTarget\s*=\s*profile' `
    'Recent profile cards must open rollback confirmation when the card is tapped.'
if ($dashboardViews -match 'arrow\.uturn\.backward\.circle\.fill') {
    throw 'Recent profile cards must not show a redundant rollback icon.'
}
Assert-SourceContains $profileSettingsModel 'struct\s+ProfileGenerationSettings:\s*Codable,\s*Equatable' `
    'Profile generation settings must be persistable and value-comparable.'
Assert-SourceContains $profileSettingsModel '(?s)iPhone 7.*?iPhone 18 Pro Max.*?10\.0.*?18\.7.*?26\.5' `
    'Profile settings must expose the expanded iPhone and iOS catalog.'
Assert-SourceContains $profileSettingsModel '(?s)mutating\s+func\s+normalizeRanges.*?modelMinimumIndex.*?modelMaximumIndex.*?iosMinimumIndex.*?iosMaximumIndex' `
    'Profile settings must normalize inverted model and iOS ranges.'
Assert-SourceContains $profileSettingsModel '(?s)legacyModelOptions.*?legacyIOSOptions.*?migrateCatalogIfNeeded' `
    'Expanded catalogs must migrate indexes saved by the previous release.'
Assert-SourceContains $profileSettingsModel '(?s)struct\s+DeviceCompatibility.*?minimumIOS.*?maximumIOS.*?compatibleIOSOptions' `
    'The model catalog must expose compatible iOS bounds instead of allowing impossible pairs.'
Assert-SourceContains $deviceProfileGenerator '(?s)allowedNames.*?DeviceHardwareSpec\.forMarketingName.*?device\.firmwares\.filter.*?noCompatibleProfile' `
    'Device generation must select only reviewed devices with compatible firmware.'
Assert-SourceContains $deviceProfileGenerator '(?s)productType:\s*device\.identifier.*?board:\s*board.*?iosVersion:\s*firmware\.version.*?build:\s*firmware\.build.*?darwin:\s*firmware\.darwin' `
    'A generated profile must keep ProductType, board, iOS build, and Darwin from one coherent selection.'
Assert-SourceContains $generatedDeviceProfile '(?s)var\s+propertyList:.*?"model":\s*productType.*?"board":\s*board.*?"build":\s*build.*?"darwin":\s*darwin' `
    'Generated profiles must expose the native keys consumed by the tweak.'
Assert-SourceContains $profileSettingsModel '(?s)enum\s+ProfileRandomField.*?deviceName.*?deviceModel.*?iosVersion.*?idfv.*?idfa.*?imei.*?imei2.*?batteryLevel.*?timeZone.*?wifi.*?location.*?webGL' `
    'Profile settings must enumerate the full native and web fake capability catalog.'
Assert-SourceContains $profileSettingsModel '(?s)enum\s+ProfileCapabilityGroup.*?device.*?operatingSystem.*?identifiers.*?batteryAndSystem.*?network.*?location.*?locale.*?sensors.*?webFingerprint' `
    'Every fake capability must be organized into a visible settings group.'
Assert-SourceContains $profileSettingsView '(?s)ForEach\(ProfileCapabilityGroup\.allCases.*?DisclosureGroup.*?ProfileRandomField\.allCases.*?Cố định hiện tại' `
    'The settings UI must show every capability and identify hooks that are currently fixed.'
Assert-SourceContains $profileSettingsService '(?s)protocol\s+ProfileSettingsService.*?load\(\).*?save\(_\s+settings:\s*ProfileGenerationSettings\).*?UserDefaults' `
    'Profile settings must use an injectable UserDefaults persistence service.'
Assert-SourceContains $swiftStore '(?s)@Published\s+var\s+generationSettings:\s*ProfileGenerationSettings.*?func\s+updateGenerationSettings.*?settingsService\.save' `
    'H2Store must publish and automatically persist generation settings.'
Assert-SourceContains $phoneMakefile '(?s)ProfileSettingsView\.swift.*?ProfileGenerationSettings\.swift.*?ProfileSettingsService\.swift' `
    'The Theos application must compile every Profile settings source file.'
Assert-SourceContains $dashboardViews '(?s)@State\s+private\s+var\s+showProfileSettings.*?navigationDestination\(isPresented:\s*\$showProfileSettings\).*?ProfileSettingsView\(\).*?Image\(systemName:\s*"gearshape\.fill"\)' `
    'Dashboard gear navigation must open Profile settings.'
Assert-SourceContains ($profileSettingsView + $profileSettingsModel) '(?s)ScrollView.*?Model, ProductType & Board.*?Phiên bản iOS.*?Nhà mạng, MCC, MNC & quốc gia.*?Tọa độ latitude & longitude.*?Múi giờ' `
    'Profile settings must provide all five approved random-field toggles in a scrollable screen.'
Assert-SourceContains $profileSettingsView '(?s)Picker\("Từ iPhone".*?Picker\("Đến iPhone".*?Picker\("Từ iOS".*?Picker\("Đến iOS"' `
    'Profile settings must provide minimum and maximum pickers for iPhone and iOS.'
if ($profileSettingsView -match 'Button\s*\(\s*"Lưu"') { throw 'Profile settings must auto-save without a Save button.' }
Assert-SourceContains $targetAppViews '(?s)generationSettings\.enabledFieldNames.*?modelRangeText.*?iosRangeText' `
    'Change confirmation must summarize enabled random fields and ranges.'
if ($dashboardViews -match 'Button\s*\(\s*"Quay lại bản này"') {
    throw 'Profile cards must not show a separate rollback button.'
}
Assert-SourceContains $phoneMakefile 'H2InstalledAppService\.m' `
    'The Theos application must compile the installed-app bridge.'
Assert-SourceContains $bridgingHeader '#import\s+"H2InstalledAppService\.h"' `
    'Swift must receive the installed-app bridge through the bridging header.'
Assert-SourceContains $installedAppService 'allInstalledApplications' `
    'Installed applications must come from LSApplicationWorkspace on the device.'
Assert-SourceContains $installedAppService '_applicationIconImageForBundleIdentifier:format:scale:' `
    'The installed-app bridge must load each real application icon.'
Assert-SourceContains $swiftFactory 'InstalledAppDeviceService\s*\(' `
    'The packaged SwiftUI app must use the real installed-app service.'
Assert-SourceContains $swiftDeviceService 'iconPNGData' `
    'The Swift device service must map native app icon data.'
Assert-SourceContains $swiftModels 'let\s+iconPNGData:\s*Data\?' `
    'TargetApp must carry optional real icon PNG data.'
Assert-SourceContains $targetAppViews '\.task\s*\{\s*await\s+store\.discover' `
    'The target-app tab must discover installed apps when it opens.'
Assert-SourceContains $targetAppViews 'AppIconView\s*\(app:\s*app\)' `
    'Target app cards must render a reusable real-icon view.'
Assert-SourceContains $targetAppViews '(?s)struct\s+AppIconView.*?NSCache<NSString,\s*UIImage>' `
    'Decoded application icons must be cached across app-row updates.'
Assert-SourceContains $targetAppViews '(?s)struct\s+AppIconView.*?@State\s+private\s+var\s+decodedIcon:\s*UIImage\?.*?Task\.detached.*?UIImage\(data:' `
    'Application icons must decode away from the main interaction thread.'
if ($targetAppViews -match 'if\s+let\s+data\s*=\s*app\.iconPNGData,\s*let\s+image\s*=\s*UIImage\(data:') {
    throw 'AppIconView body must not synchronously decode PNG data during every toggle update.'
}
Assert-SourceContains $dashboardViews '(?s)struct\s+ProfilesView.*?List\s*\{.*?swipeActions.*?role:\s*\.destructive' `
    'Profile history must expose a destructive swipe action.'
Assert-SourceContains $swiftStore '(?s)func\s+deleteProfile.*?profile\.id\s*!=\s*activeID.*?!profile\.isOriginal' `
    'Profile deletion must protect the active and original profiles.'
Assert-SourceContains $swiftModels 'struct\s+ProfileAppBackup:\s*Identifiable,\s*Hashable' `
    'Profile snapshots must model each backed-up application.'
Assert-SourceContains $swiftModels 'var\s+isSelected:\s*Bool\s*\{\s*fakeInfo\s*\|\|\s*backupData\s*\}' `
    'Target-app selection must depend only on Fake Info or Backup and Clean.'
if ($swiftModels -match 'resetOnChange') { throw 'The separate resetOnChange model option must be removed.' }
Assert-SourceContains $targetAppViews 'title:\s*"Backup\s*&' `
    'The app UI must present the combined Backup and Clean choice.'
Assert-SourceContains $targetAppViews 'subtitle:\s*"Ch.*backup.*x.*c minh.*th.*nh c.*ng' `
    'The app UI must explain the verified-backup safety rule.'
if ($targetAppViews -match 'Reset Data on Change|resetOnChange|Reset không có backup') {
    throw 'The app UI must not expose a separate or unsafe reset option.'
}
Assert-SourceContains $swiftModels 'let\s+backedUpApps:\s*\[ProfileAppBackup\]' `
    'Each profile must retain its backup application manifest.'
Assert-SourceContains $targetAppViews 'ForEach\s*\(profile\.backedUpApps\)' `
    'Rollback confirmation must list the applications stored in the profile backup.'
Assert-SourceContains $targetAppViews '\.safeAreaInset\s*\(edge:\s*\.bottom\)' `
    'Rollback actions must stay visible above the bottom safe area.'
Assert-SourceContains $dashboardViews '(?s)RollbackSheet\(profile:\s*\$0\).*?presentationDetents\s*\(\[\.large\]\)' `
    'Rollback confirmation must open at the large sheet detent.'
if ($dashboardViews -match 'tabItem\s*\{\s*Label\(\s*"App mục tiêu"') {
    throw 'Target apps must not occupy a bottom-tab item.'
}
Assert-SourceContains $dashboardViews '(?s)@State\s+private\s+var\s+showTargetApps.*?sheet\s*\(isPresented:\s*\$showTargetApps\).*?AppsView\(\).*?presentationDetents\s*\(\[\.large\]\)' `
    'RootView must present target-app management as a large sheet.'
Assert-SourceContains $dashboardViews 'Button\s*\{\s*showTargetApps\s*=\s*true\s*\}' `
    'The dashboard app scope card must open the target-app sheet.'
Assert-SourceContains $targetAppViews '(?s)navigationBarLeading.*?dismiss\(\)' `
    'The target-app sheet must provide an explicit close button.'
Assert-SourceContains $dashboardViews '(?s)struct\s+DashboardView.*?NavigationStack\s*\{.*?ToolbarItem\s*\(placement:\s*\.principal\)' `
    'The dashboard must use a compact centered navigation header.'
Assert-SourceContains $dashboardViews '(?s)ToolbarItem\s*\(placement:\s*\.principal\).*?H2BrandIcon\(\).*?frame\(width:\s*28,\s*height:\s*28\).*?Text\("H2PHONE"\)' `
    'The dashboard header must show the small cat icon beside H2PHONE.'
if ($dashboardViews -match 'frame\(width:\s*76,\s*height:\s*76\)') {
    throw 'The dashboard scroll content must not repeat the large app logo.'
}
Assert-SourceContains $dashboardViews '(?s)Bundle\.main\.path\(forResource:\s*"Icon-1024",\s*ofType:\s*"png"\).*?UIImage\(contentsOfFile:' `
    'The dashboard brand icon must load the loose Theos PNG directly from the app bundle.'
Assert-SourceContains $targetAppViews '(?s)struct\s+AppRow.*?H2Card\s*\{\s*VStack\(alignment:\s*\.leading' `
    'Each target app header and its settings must remain inside one card container.'
Assert-SourceContains $targetAppViews '(?s)LazyVGrid\(columns:\s*filterColumns.*?ForEach\(AppFilter\.allCases' `
    'Target-app filters must use a small-screen-friendly grid.'
Assert-SourceContains $swiftDeviceService '(?s)withCheckedContinuation.*?DispatchQueue\.global\(qos:\s*\.userInitiated\)\.async.*?installedApplications\(\)' `
    'Installed-app discovery and icon processing must run away from the main animation thread.'
Assert-SourceContains $swiftDeviceService '(?s)func\s+change\(to\s+name:\s*String,\s*apps:\s*\[TargetApp\],\s*settings:\s*ProfileGenerationSettings\).*?generator\.generate\(settings:\s*settings\).*?H2ProfileActivationService\.activateProfile' `
    'Change must generate a coherent profile from settings and activate it through the native bridge.'
Assert-SourceContains $swiftStore 'service\.change\(to:\s*name,\s*apps:\s*selectedApps,\s*settings:\s*generationSettings\)' `
    'H2Store must pass persisted generation settings into Change.'
Assert-SourceContains $targetAppViews '(?s)ScrollView\s*\{\s*LazyVStack\(alignment:\s*\.leading' `
    'The target-app sheet must lazily construct application cards.'
Assert-SourceContains $devMakefile '(?s)ifeq\s*\(\$\(THEOS_PACKAGE_SCHEME\),roothide\).*?H2DEV_CODESIGN_FLAGS\s*=\s*-S\$\(THEOS_PROJECT_DIR\)/H2DEV/H2DEV\.entitlements.*?endif' `
    'H2DEV must use its privileged entitlements only for the roothide scheme.'
Assert-SourceContains $releaseWorkflow 'https://github\.com/theos/theos\.git' `
    'The release workflow must retain the official Theos checkout for rootless builds.'
Assert-SourceContains $releaseWorkflow 'https://github\.com/(?:RootHide|roothide)/theos\.git' `
    'The release workflow must use RootHide Theos for RootHide builds.'
Assert-SourceContains $releaseWorkflow 'THEOS_PACKAGE_SCHEME=rootless' `
    'The rootless build must select the rootless package scheme explicitly.'
Assert-SourceContains $releaseWorkflow 'THEOS_PACKAGE_SCHEME=roothide' `
    'The RootHide build must select the roothide package scheme explicitly.'
Assert-SourceContains $releaseWorkflow 'com\.h2phone\.ios-rootless\.deb' `
    'The rootless release asset must have a stable, distinct filename.'
Assert-SourceContains $releaseWorkflow 'com\.h2phone\.ios-roothide\.deb' `
    'The RootHide release asset must have a stable, distinct filename.'
Assert-SourceContains $releaseWorkflow '(?s)gh release create.*packages/com\.h2phone\.ios-rootless\.deb.*packages/com\.h2phone\.ios-roothide\.deb' `
    'The release command must publish both jailbreak-specific packages.'
Assert-SourceContains $buildDocs '(?s)1\. Update the package version in `control`\..*2\. Commit and push source changes to `develop`\.' `
    'Release instructions must commit the updated package version before tagging.'

Write-Output 'Source tests passed: 126 assertions.'
