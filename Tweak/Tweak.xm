#import <UIKit/UIKit.h>
#import "H2ConfigManager.h"
#import "H2WebFingerprint.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <errno.h>
#import <stdio.h>
#import <stdlib.h>
#import <math.h>
#import <string.h>
#import <dlfcn.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <AdSupport/AdSupport.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreMotion/CoreMotion.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <notify.h>
#import <sys/time.h>

static char H2OriginalUserAgentKey;
static __thread BOOL H2SettingWebUserAgent;
static __thread BOOL H2ReadingConfig;
static __thread BOOL H2ReadingFilesystemProfile;
static NSHashTable<WKWebView *> *H2TrackedWebViews;
static int H2RuntimeNotificationToken = -1;

static NSString *H2StringOrEmpty(id value) {
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) {
        NSString *string = [value stringValue];
        if ([string isKindOfClass:NSString.class]) return string;
    }
    return @"";
}

static const char *H2CStringOrEmpty(id value) {
    return H2StringOrEmpty(value).UTF8String ?: "";
}

static BOOL H2IsExcludedBundle(NSString *bundleID) {
    if (!bundleID.length || [bundleID isEqualToString:@"com.h2phone.app"]) return YES;
    return [bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID];
}

static NSDictionary<NSString *, id> *H2CurrentConfig(void) {
    if (H2ReadingConfig) return nil;
    H2ReadingConfig = YES;
    NSDictionary *config = nil;
    @try {
        NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
        if (bundleID.length) config = [[H2ConfigManager sharedManager] effectiveConfigForBundleID:bundleID];
    } @finally {
        H2ReadingConfig = NO;
    }
    return [config isKindOfClass:NSDictionary.class] ? config : nil;
}

static BOOL H2FakeEnabled(void) {
    if (H2ReadingConfig) return NO;
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (H2IsExcludedBundle(bundleID)) return NO;
    return [H2CurrentConfig()[@"enabled"] boolValue];
}

static NSDictionary<NSString *, id> *H2Profile(void) {
    if (H2ReadingConfig) return nil;
    NSDictionary *config = H2CurrentConfig();
    NSDictionary *profile = config[@"generatedProfile"];
    if (![profile isKindOfClass:NSDictionary.class]) profile = [H2ConfigManager profileNamed:H2StringOrEmpty(config[@"profile"])];
    return [profile isKindOfClass:NSDictionary.class] ? profile : nil;
}

static NSDictionary<NSString *, id> *H2EnabledProfile(void) {
    if (H2ReadingConfig) return nil;
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (H2IsExcludedBundle(bundleID)) return nil;
    NSDictionary *config = H2CurrentConfig();
    if (![config[@"enabled"] boolValue]) return nil;
    NSDictionary *profile = config[@"generatedProfile"];
    if (![profile isKindOfClass:NSDictionary.class]) profile = [H2ConfigManager profileNamed:H2StringOrEmpty(config[@"profile"])];
    return [profile isKindOfClass:NSDictionary.class] ? profile : nil;
}

static NSString *H2WebUserAgentForProfile(NSDictionary<NSString *, id> *profile) {
    NSString *version = H2StringOrEmpty(profile[@"ios"]);
    if (!version.length) return nil;
    NSString *cpuVersion = [version stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    return [NSString stringWithFormat:@"Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1", cpuVersion, version];
}

static BOOL H2IsUserAgentKey(NSString *key) {
    if (![key isKindOfClass:NSString.class]) return NO;
    NSString *normalized = key.lowercaseString;
    return [normalized isEqualToString:@"useragent"] || [normalized isEqualToString:@"user-agent"];
}

static NSNumber *H2UnsignedNumber(id value) {
    if ([value isKindOfClass:NSNumber.class]) return @([value unsignedLongLongValue]);
    if (![value isKindOfClass:NSString.class] || [value length] == 0) return nil;
    const char *text = [value UTF8String];
    char *end = NULL;
    errno = 0;
    unsigned long long parsed = strtoull(text, &end, 10);
    if (errno != 0 || end == text || (end && *end != '\0')) return nil;
    return @(parsed);
}

static BOOL H2IsDirectUserAgentScript(NSString *script) {
    if (![script isKindOfClass:NSString.class]) return NO;
    NSString *normalized = [[script stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] stringByReplacingOccurrencesOfString:@";" withString:@""];
    return [normalized isEqualToString:@"navigator.userAgent"] || [normalized isEqualToString:@"window.navigator.userAgent"];
}

static NSDictionary *H2FakeSystemVersionDictionary(NSDictionary *original, NSDictionary<NSString *, id> *profile) {
    if (!original || !profile) return original;
    NSMutableDictionary *fake = [original mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString *ios = H2StringOrEmpty(profile[@"ios"]);
    NSString *build = H2StringOrEmpty(profile[@"build"]);
    fake[@"ProductName"] = @"iPhone OS";
    if (ios.length) fake[@"ProductVersion"] = ios;
    if (build.length) fake[@"ProductBuildVersion"] = build;
    return fake;
}

static void H2ApplyWebUserAgent(WKWebView *webView) {
    if (!webView) return;
    NSDictionary<NSString *, id> *profile = H2EnabledProfile();
    BOOL enabled = profile != nil;
    id original = objc_getAssociatedObject(webView, &H2OriginalUserAgentKey);
    if (enabled) {
        if (!original) objc_setAssociatedObject(webView, &H2OriginalUserAgentKey, webView.customUserAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *fake = H2WebUserAgentForProfile(profile);
        if (fake.length && ![webView.customUserAgent isEqualToString:fake]) {
            H2SettingWebUserAgent = YES;
            @try {
                webView.customUserAgent = fake;
            } @finally {
                H2SettingWebUserAgent = NO;
            }
        }
    } else if (original) {
        H2SettingWebUserAgent = YES;
        @try {
            webView.customUserAgent = original == NSNull.null ? nil : original;
        } @finally {
            H2SettingWebUserAgent = NO;
        }
        objc_setAssociatedObject(webView, &H2OriginalUserAgentKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *board = H2StringOrEmpty(profile[@"board"]);
    NSUInteger seed = board.length > 1 ? [board characterAtIndex:1] : 1;
    H2UpdateWebFingerprint(webView, enabled ? H2WebUserAgentForProfile(profile) : @"", profile ?: @{}, seed, enabled);
}

static void H2ConfigureWebView(WKWebViewConfiguration *configuration) {
    NSDictionary<NSString *, id> *profile = H2EnabledProfile();
    NSString *board = H2StringOrEmpty(profile[@"board"]);
    NSUInteger seed = board.length > 1 ? [board characterAtIndex:1] : 1;
    H2ConfigureWebContent(configuration, profile ? H2WebUserAgentForProfile(profile) : @"", profile ?: @{}, seed, profile != nil);
}

static void H2TrackWebView(WKWebView *webView) {
    if (!webView) return;
    @synchronized (H2TrackedWebViews) { [H2TrackedWebViews addObject:webView]; }
}

static void H2RefreshTrackedWebViews(void) {
    NSArray<WKWebView *> *webViews;
    @synchronized (H2TrackedWebViews) { webViews = H2TrackedWebViews.allObjects; }
    for (WKWebView *webView in webViews) H2ApplyWebUserAgent(webView);
}

%hook UIDevice

- (NSString *)name {
    NSDictionary *profile = H2EnabledProfile();
    NSString *value = profile[@"name"];
    if (!value) return %orig;
    return value;
}

- (NSString *)model {
    if (!H2FakeEnabled()) return %orig;
    return @"iPhone";
}

- (NSString *)localizedModel {
    if (!H2FakeEnabled()) return %orig;
    return @"iPhone";
}

- (NSString *)systemName {
    if (!H2FakeEnabled()) return %orig;
    return @"iOS";
}

- (NSString *)systemVersion {
    NSDictionary *profile = H2EnabledProfile();
    NSString *value = profile[@"ios"];
    if (!value) return %orig;
    return value;
}

- (NSUUID *)identifierForVendor {
    NSUUID *original = %orig;
    NSDictionary *profile = H2EnabledProfile();
    NSString *uuid = profile[@"uuid"];
    if (![uuid isKindOfClass:NSString.class] || uuid.length == 0) return original;
    NSUUID *fake = [[NSUUID alloc] initWithUUIDString:uuid];
    return fake ?: original;
}

- (float)batteryLevel {
    float original = %orig;
    NSDictionary *profile = H2EnabledProfile();
    NSNumber *battery = [profile[@"battery"] isKindOfClass:NSNumber.class] ? profile[@"battery"] : nil;
    return profile && battery && original >= 0 ? battery.floatValue : original;
}

- (UIDeviceBatteryState)batteryState {
    UIDeviceBatteryState original = %orig;
    return H2FakeEnabled() && original != UIDeviceBatteryStateUnknown ? UIDeviceBatteryStateUnplugged : original;
}

%end

%hook NSDictionary
+ (instancetype)dictionaryWithContentsOfFile:(NSString *)path {
    NSDictionary *original = %orig;
    if (![path isEqualToString:@"/System/Library/CoreServices/SystemVersion.plist"]) return original;
    return H2FakeSystemVersionDictionary(original, H2EnabledProfile());
}
- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSDictionary *original = %orig;
    if (![path isEqualToString:@"/System/Library/CoreServices/SystemVersion.plist"]) return original;
    return H2FakeSystemVersionDictionary(original, H2EnabledProfile());
}
%end

%hook NSBundle
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([self.bundlePath isEqualToString:@"/System/Library/CoreServices/SystemVersion.bundle"]) {
        NSDictionary *profile = H2EnabledProfile();
        if (profile) {
            if ([key isEqualToString:@"ProductVersion"] && H2StringOrEmpty(profile[@"ios"]).length) return H2StringOrEmpty(profile[@"ios"]);
            if ([key isEqualToString:@"ProductBuildVersion"] && H2StringOrEmpty(profile[@"build"]).length) return H2StringOrEmpty(profile[@"build"]);
            if ([key isEqualToString:@"ProductName"]) return @"iPhone OS";
        }
    }
    return %orig;
}
- (NSDictionary<NSString *, id> *)infoDictionary {
    NSDictionary *original = %orig;
    if (![self.bundlePath isEqualToString:@"/System/Library/CoreServices/SystemVersion.bundle"]) return original;
    return H2FakeSystemVersionDictionary(original, H2EnabledProfile());
}
%end

static NSDictionary<NSFileAttributeKey, id> *H2FakeFilesystemAttributes(NSDictionary<NSFileAttributeKey, id> *original, NSDictionary<NSString *, id> *profile) {
    if (!original || !profile) return original;
    NSMutableDictionary *fake = [original mutableCopy];
    if (!fake) return original;
    NSNumber *total = H2UnsignedNumber(profile[@"diskTotal"]);
    NSNumber *free = H2UnsignedNumber(profile[@"diskFree"]);
    if (total) fake[NSFileSystemSize] = total;
    if (free) fake[NSFileSystemFreeSize] = free;
    return fake;
}

static NSDictionary *H2FilesystemProfile(void);

%hook NSFileManager
- (NSDictionary<NSFileAttributeKey, id> *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error {
    NSDictionary *original = %orig;
    return H2FakeFilesystemAttributes(original, H2FilesystemProfile());
}
%end

static BOOL H2IsVolumeCapacityKey(NSURLResourceKey key) {
    return [key isEqualToString:NSURLVolumeTotalCapacityKey] ||
        [key isEqualToString:NSURLVolumeAvailableCapacityKey] ||
        [key isEqualToString:NSURLVolumeAvailableCapacityForImportantUsageKey] ||
        [key isEqualToString:NSURLVolumeAvailableCapacityForOpportunisticUsageKey];
}

static NSNumber *H2VolumeCapacityValue(NSURLResourceKey key, NSDictionary *profile) {
    id value = [key isEqualToString:NSURLVolumeTotalCapacityKey] ? profile[@"diskTotal"] : profile[@"diskFree"];
    return H2UnsignedNumber(value);
}

static NSDictionary *H2FilesystemProfile(void) {
    if (H2ReadingFilesystemProfile || H2ReadingConfig) return nil;
    NSDictionary *profile = nil;
    H2ReadingFilesystemProfile = YES;
    @try {
        profile = H2EnabledProfile();
    } @finally {
        H2ReadingFilesystemProfile = NO;
    }
    return profile;
}

%hook NSURL
- (BOOL)getResourceValue:(id _Nullable *)value forKey:(NSURLResourceKey)key error:(NSError **)error {
    NSDictionary *profile = H2IsVolumeCapacityKey(key) ? H2FilesystemProfile() : nil;
    NSNumber *capacity = profile ? H2VolumeCapacityValue(key, profile) : nil;
    if (capacity) {
        if (value) *value = capacity;
        return YES;
    }
    return %orig;
}
- (NSDictionary<NSURLResourceKey, id> *)resourceValuesForKeys:(NSArray<NSURLResourceKey> *)keys error:(NSError **)error {
    NSDictionary *original = %orig;
    if (!original) return original;
    NSDictionary *profile = H2FilesystemProfile();
    if (!profile) return original;
    NSMutableDictionary *fake = [original mutableCopy];
    for (NSURLResourceKey key in keys) {
        if (!H2IsVolumeCapacityKey(key)) continue;
        NSNumber *capacity = H2VolumeCapacityValue(key, profile);
        if (capacity) fake[key] = capacity;
    }
    return fake;
}
%end

%hook NSUserDefaults
- (NSString *)stringForKey:(NSString *)key {
    if (H2IsUserAgentKey(key) && H2FakeEnabled()) return H2WebUserAgentForProfile(H2Profile());
    return %orig;
}
- (id)objectForKey:(NSString *)key {
    if (H2IsUserAgentKey(key) && H2FakeEnabled()) return H2WebUserAgentForProfile(H2Profile());
    return %orig;
}
%end

%hook NSMutableURLRequest
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (value && [field caseInsensitiveCompare:@"User-Agent"] == NSOrderedSame && H2FakeEnabled()) value = H2WebUserAgentForProfile(H2Profile());
    %orig(value, field);
}
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if ([field caseInsensitiveCompare:@"User-Agent"] == NSOrderedSame && H2FakeEnabled()) return [self setValue:H2WebUserAgentForProfile(H2Profile()) forHTTPHeaderField:field];
    return %orig;
}
- (void)setAllHTTPHeaderFields:(NSDictionary<NSString *, NSString *> *)fields {
    if (!H2FakeEnabled()) return %orig;
    NSMutableDictionary *fake = [fields mutableCopy] ?: [NSMutableDictionary dictionary];
    fake[@"User-Agent"] = H2WebUserAgentForProfile(H2Profile());
    return %orig(fake);
}
%end

%hook UIWebView
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    if (H2IsDirectUserAgentScript(script) && H2FakeEnabled()) return H2WebUserAgentForProfile(H2Profile());
    return %orig;
}
- (void)loadRequest:(NSURLRequest *)request {
    if (H2FakeEnabled()) {
        NSMutableURLRequest *fake = [request mutableCopy];
        [fake setValue:H2WebUserAgentForProfile(H2Profile()) forHTTPHeaderField:@"User-Agent"];
        return %orig(fake);
    }
    return %orig;
}
%end

%hook ASIdentifierManager
- (NSUUID *)advertisingIdentifier {
    NSUUID *original = %orig;
    NSDictionary *profile = H2EnabledProfile();
    if (!profile || !original || [original.UUIDString isEqualToString:@"00000000-0000-0000-0000-000000000000"]) return original;
    NSString *idfa = profile[@"idfa"];
    if (![idfa isKindOfClass:NSString.class] || idfa.length == 0) return original;
    NSUUID *fake = [[NSUUID alloc] initWithUUIDString:idfa];
    return fake ?: original;
}
%end

%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
    if (!H2FakeEnabled()) return %orig;
    return CLLocationCoordinate2DMake([H2Profile()[@"latitude"] doubleValue], [H2Profile()[@"longitude"] doubleValue]);
}
- (CLLocationDistance)altitude { if (!H2FakeEnabled()) return %orig; return 12.0; }
- (CLLocationAccuracy)horizontalAccuracy { if (!H2FakeEnabled()) return %orig; return 5.0; }
- (CLLocationAccuracy)verticalAccuracy { if (!H2FakeEnabled()) return %orig; return 8.0; }
- (CLLocationSpeed)speed { if (!H2FakeEnabled()) return %orig; return 0.0; }
- (CLLocationDirection)course { if (!H2FakeEnabled()) return %orig; return -1.0; }
%end

%hook NSLocale
+ (NSLocale *)currentLocale {
    if (!H2FakeEnabled()) return %orig;
    return [NSLocale localeWithLocaleIdentifier:@"vi_VN"];
}
+ (NSLocale *)autoupdatingCurrentLocale {
    if (!H2FakeEnabled()) return %orig;
    return [NSLocale localeWithLocaleIdentifier:@"vi_VN"];
}
+ (NSArray<NSString *> *)preferredLanguages {
    if (!H2FakeEnabled()) return %orig;
    return @[@"vi-VN", @"en-US"];
}
%end

%hook NSTimeZone
+ (NSTimeZone *)localTimeZone {
    if (!H2FakeEnabled()) return %orig;
    return [NSTimeZone timeZoneWithName:@"Asia/Ho_Chi_Minh"];
}
+ (NSTimeZone *)systemTimeZone {
    if (!H2FakeEnabled()) return %orig;
    return [NSTimeZone timeZoneWithName:@"Asia/Ho_Chi_Minh"];
}
%end

%hook CTCarrier
- (NSString *)carrierName {
    NSDictionary *profile = H2EnabledProfile();
    NSString *value = H2StringOrEmpty(profile[@"carrier"]);
    if (!value.length) return %orig;
    return value;
}
- (NSString *)mobileCountryCode {
    NSDictionary *profile = H2EnabledProfile();
    NSString *value = H2StringOrEmpty(profile[@"mcc"]);
    if (!value.length) return %orig;
    return value;
}
- (NSString *)mobileNetworkCode {
    NSDictionary *profile = H2EnabledProfile();
    NSString *value = H2StringOrEmpty(profile[@"mnc"]);
    if (!value.length) return %orig;
    return value;
}
- (NSString *)isoCountryCode {
    NSDictionary *profile = H2EnabledProfile();
    NSString *value = H2StringOrEmpty(profile[@"country"]);
    if (!value.length) return %orig;
    return value;
}
%end

%hook CTTelephonyNetworkInfo
- (NSString *)currentRadioAccessTechnology {
    if (H2FakeEnabled()) return CTRadioAccessTechnologyLTE;
    return %orig;
}
- (NSDictionary<NSString *, NSString *> *)serviceCurrentRadioAccessTechnology {
    NSDictionary<NSString *, NSString *> *original = %orig;
    if (!H2FakeEnabled()) return original;
    if (!original.count) return @{ @"H2PHONEPrimaryService": CTRadioAccessTechnologyLTE };
    NSMutableDictionary *fake = [NSMutableDictionary dictionaryWithCapacity:original.count];
    for (id service in original) if ([service isKindOfClass:NSString.class]) fake[service] = CTRadioAccessTechnologyLTE;
    return fake.count ? fake : @{ @"H2PHONEPrimaryService": CTRadioAccessTechnologyLTE };
}
%end

%hook CMAccelerometerData
- (CMAcceleration)acceleration {
    if (!H2FakeEnabled()) return %orig;
    CMAcceleration value = { 0, 0, -1 };
    return value;
}
%end

%hook CMGyroData
- (CMRotationRate)rotationRate {
    if (!H2FakeEnabled()) return %orig;
    CMRotationRate value = { 0, 0, 0 };
    return value;
}
%end

%hook CMDeviceMotion
- (CMAcceleration)gravity {
    if (!H2FakeEnabled()) return %orig;
    CMAcceleration value = { 0, 0, -1 };
    return value;
}
- (CMAcceleration)userAcceleration {
    if (!H2FakeEnabled()) return %orig;
    CMAcceleration value = { 0, 0, 0 };
    return value;
}
- (CMRotationRate)rotationRate {
    if (!H2FakeEnabled()) return %orig;
    CMRotationRate value = { 0, 0, 0 };
    return value;
}
%end

%hook NSProcessInfo

- (NSTimeInterval)systemUptime {
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    return [profile[@"uptime"] doubleValue];
}

- (NSProcessInfoThermalState)thermalState {
    if (!H2FakeEnabled()) return %orig;
    return NSProcessInfoThermalStateNominal;
}

- (BOOL)isLowPowerModeEnabled {
    if (!H2FakeEnabled()) return %orig;
    return NO;
}

- (unsigned long long)physicalMemory {
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    return [profile[@"memory"] unsignedLongLongValue];
}

- (NSUInteger)processorCount {
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    return [profile[@"cores"] unsignedIntegerValue];
}

- (NSUInteger)activeProcessorCount {
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    return [profile[@"cores"] unsignedIntegerValue];
}

- (NSOperatingSystemVersion)operatingSystemVersion {
    NSDictionary *profile = H2EnabledProfile();
    NSString *ios = profile[@"ios"];
    if (!ios) return %orig;
    NSArray<NSString *> *parts = [ios componentsSeparatedByString:@"."];
    NSOperatingSystemVersion version = { parts.count > 0 ? parts[0].integerValue : 0,
        parts.count > 1 ? parts[1].integerValue : 0,
        parts.count > 2 ? parts[2].integerValue : 0 };
    return version;
}

- (NSString *)operatingSystemVersionString {
    NSDictionary *profile = H2EnabledProfile();
    NSString *ios = profile[@"ios"];
    if (!ios) return %orig;
    return [@"Version " stringByAppendingString:ios];
}

- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version {
    if (!H2FakeEnabled()) return %orig;
    NSOperatingSystemVersion current = [self operatingSystemVersion];
    if (current.majorVersion != version.majorVersion) return current.majorVersion > version.majorVersion;
    if (current.minorVersion != version.minorVersion) return current.minorVersion > version.minorVersion;
    return current.patchVersion >= version.patchVersion;
}

%end

static int H2CopySysctlScalar(const void *value, size_t valueSize, void *oldp, size_t *oldlenp) {
    if (!oldlenp) { errno = EINVAL; return -1; }
    if (!oldp) { *oldlenp = valueSize; return 0; }
    if (*oldlenp < valueSize) { *oldlenp = valueSize; errno = ENOMEM; return -1; }
    memcpy(oldp, value, valueSize);
    *oldlenp = valueSize;
    return 0;
}

%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!name || newp) return %orig;
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    if (strcmp(name, "hw.memsize") == 0) {
        uint64_t memory = [profile[@"memory"] unsignedLongLongValue];
        return H2CopySysctlScalar(&memory, sizeof(memory), oldp, oldlenp);
    }
    if (strcmp(name, "hw.ncpu") == 0 || strcmp(name, "hw.physicalcpu") == 0 || strcmp(name, "hw.logicalcpu") == 0) {
        int cores = [profile[@"cores"] intValue];
        return H2CopySysctlScalar(&cores, sizeof(cores), oldp, oldlenp);
    }
    if (strcmp(name, "kern.boottime") == 0) {
        NSTimeInterval now = NSDate.date.timeIntervalSince1970;
        NSTimeInterval uptime = [profile[@"uptime"] doubleValue];
        if (!isfinite(uptime) || uptime < 0) uptime = 0;
        if (uptime > now) uptime = now;
        struct timeval boot = { (time_t)(now - uptime), 0 };
        return H2CopySysctlScalar(&boot, sizeof(boot), oldp, oldlenp);
    }
    NSString *value = nil;
    if (strcmp(name, "hw.machine") == 0) value = profile[@"model"];
    else if (strcmp(name, "hw.model") == 0) value = profile[@"board"];
    else if (strcmp(name, "kern.osproductversion") == 0) value = profile[@"ios"];
    else if (strcmp(name, "kern.osrelease") == 0) value = profile[@"darwin"];
    else if (strcmp(name, "kern.version") == 0 && profile[@"darwin"] && profile[@"build"]) value = [NSString stringWithFormat:@"Darwin Kernel Version %@: H2PHONE; root:xnu-%@/RELEASE_ARM64", profile[@"darwin"], profile[@"build"]];
    if (!value) return %orig;
    const char *text = value.UTF8String;
    size_t required = strlen(text) + 1;
    if (!oldlenp) { errno = EINVAL; return -1; }
    if (!oldp) { *oldlenp = required; return 0; }
    if (*oldlenp < required) { *oldlenp = required; errno = ENOMEM; return -1; }
    memcpy(oldp, text, required);
    *oldlenp = required;
    return 0;
}

%hookf(int, uname, struct utsname *name) {
    int result = %orig;
    if (result == 0 && name) {
        NSDictionary *profile = H2EnabledProfile();
        const char *model = H2CStringOrEmpty(profile[@"model"]);
        const char *darwin = H2CStringOrEmpty(profile[@"darwin"]);
        const char *build = H2CStringOrEmpty(profile[@"build"]);
        if (!*model || !*darwin || !*build) return result;
        snprintf(name->machine, sizeof(name->machine), "%s", model);
        snprintf(name->release, sizeof(name->release), "%s", darwin);
        snprintf(name->version, sizeof(name->version), "Darwin Kernel Version %s: H2PHONE; root:xnu-%s/RELEASE_ARM64", darwin, build);
    }
    return result;
}

%hookf(CFArrayRef, CNCopySupportedInterfaces) {
    if (!H2EnabledProfile()) return %orig;
    NSArray *interfaces = @[ @"en0" ];
    return (CFArrayRef)CFBridgingRetain(interfaces);
}

%hookf(CFDictionaryRef, CNCopyCurrentNetworkInfo, CFStringRef interfaceName) {
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    NSString *ssid = [profile[@"ssid"] isKindOfClass:NSString.class] ? profile[@"ssid"] : @"";
    NSString *bssid = [profile[@"bssid"] isKindOfClass:NSString.class] ? profile[@"bssid"] : @"";
    NSDictionary *network = @{
        (__bridge NSString *)kCNNetworkInfoKeySSID: ssid,
        (__bridge NSString *)kCNNetworkInfoKeyBSSID: bssid,
        (__bridge NSString *)kCNNetworkInfoKeySSIDData: [ssid dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData data]
    };
    return (CFDictionaryRef)CFBridgingRetain(network);
}

%group H2MobileGestalt
%hookf(CFTypeRef, MGCopyAnswer, CFStringRef key) {
    if (!key) return %orig;
    NSDictionary *profile = H2EnabledProfile();
    if (!profile) return %orig;
    NSString *answer = nil;
    if (CFStringCompare(key, CFSTR("HardwareModel"), 0) == kCFCompareEqualTo) answer = profile[@"board"];
    else if (CFStringCompare(key, CFSTR("ProductType"), 0) == kCFCompareEqualTo) answer = profile[@"model"];
    else if (CFStringCompare(key, CFSTR("ProductVersion"), 0) == kCFCompareEqualTo) answer = profile[@"ios"];
    else if (CFStringCompare(key, CFSTR("InternationalMobileEquipmentIdentity"), 0) == kCFCompareEqualTo) answer = profile[@"imei"];
    else if (CFStringCompare(key, CFSTR("InternationalMobileEquipmentIdentity2"), 0) == kCFCompareEqualTo) answer = profile[@"imei2"];
    else if (CFStringCompare(key, CFSTR("DeviceClass"), 0) == kCFCompareEqualTo) answer = @"iPhone";
    else if (CFStringCompare(key, CFSTR("DeviceName"), 0) == kCFCompareEqualTo) answer = profile[@"name"];
    else if (CFStringCompare(key, CFSTR("UserAssignedDeviceName"), 0) == kCFCompareEqualTo) answer = profile[@"name"];
    else if (CFStringCompare(key, CFSTR("CPUArchitecture"), 0) == kCFCompareEqualTo) answer = @"arm64";
    if (answer) return CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)answer);
    return %orig;
}
%end

%group H2WebUA
%hook WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    H2ConfigureWebView(configuration);
    WKWebView *webView = %orig;
    if (webView) {
        H2TrackWebView(webView);
        H2ApplyWebUserAgent(webView);
    }
    return webView;
}

- (WKNavigation *)loadRequest:(NSURLRequest *)request {
    H2ApplyWebUserAgent(self);
    NSString *scheme = request.URL.scheme.lowercaseString;
    NSDictionary<NSString *, id> *profile = H2EnabledProfile();
    if (profile && ([@"https" isEqualToString:scheme] || [@"http" isEqualToString:scheme])) {
        NSMutableURLRequest *fakeRequest = [request mutableCopy];
        [fakeRequest setValue:H2WebUserAgentForProfile(profile) forHTTPHeaderField:@"User-Agent"];
        return %orig(fakeRequest);
    }
    return %orig;
}

- (WKNavigation *)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    H2ApplyWebUserAgent(self);
    return %orig;
}

- (WKNavigation *)reload {
    H2ApplyWebUserAgent(self);
    return %orig;
}

- (void)setCustomUserAgent:(NSString *)userAgent {
    if (H2SettingWebUserAgent) return %orig;
    NSDictionary<NSString *, id> *profile = H2EnabledProfile();
    if (!profile) {
        objc_setAssociatedObject(self, &H2OriginalUserAgentKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return %orig;
    }
    objc_setAssociatedObject(self, &H2OriginalUserAgentKey, userAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return %orig(H2WebUserAgentForProfile(profile));
}

%end
%end

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (H2IsExcludedBundle(bundleID)) return;
    dlopen("/System/Library/Frameworks/AdSupport.framework/AdSupport", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreLocation.framework/CoreLocation", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreMotion.framework/CoreMotion", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_LAZY);
    H2TrackedWebViews = [NSHashTable weakObjectsHashTable];
    NSString *runtimeName = [@"com.h2phone.runtime." stringByAppendingString:bundleID];
    notify_register_dispatch(runtimeName.UTF8String, &H2RuntimeNotificationToken, dispatch_get_main_queue(), ^(int token) {
        H2RefreshTrackedWebViews();
    });
    %init;
    %init(H2WebUA);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    void *copyAnswer = gestalt ? dlsym(gestalt, "MGCopyAnswer") : NULL;
    if (copyAnswer) %init(H2MobileGestalt, MGCopyAnswer = copyAnswer);
}
