#import <UIKit/UIKit.h>
#import "H2ConfigManager.h"
#import "H2WebFingerprint.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <errno.h>
#import <stdio.h>
#import <string.h>
#import <dlfcn.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <AdSupport/AdSupport.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreMotion/CoreMotion.h>
#import <notify.h>

static char H2OriginalUserAgentKey;
static __thread BOOL H2SettingWebUserAgent;
static __thread BOOL H2ReadingConfig;
static NSHashTable<WKWebView *> *H2TrackedWebViews;
static int H2RuntimeNotificationToken = -1;

static NSDictionary<NSString *, id> *H2CurrentConfig(void) {
    if (H2ReadingConfig) return nil;
    H2ReadingConfig = YES;
    NSDictionary *config = [[H2ConfigManager sharedManager] effectiveConfigForBundleID:[NSBundle mainBundle].bundleIdentifier];
    H2ReadingConfig = NO;
    return config;
}

static BOOL H2FakeEnabled(void) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!bundleID.length || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return NO;
    return [H2CurrentConfig()[@"enabled"] boolValue];
}

static NSDictionary<NSString *, id> *H2Profile(void) {
    NSString *name = H2CurrentConfig()[@"profile"];
    return [H2ConfigManager profileNamed:name];
}

static NSDictionary<NSString *, id> *H2EnabledProfile(void) {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (!bundleID.length || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return nil;
    NSDictionary *config = H2CurrentConfig();
    if (![config[@"enabled"] boolValue]) return nil;
    return [H2ConfigManager profileNamed:config[@"profile"]];
}

static NSString *H2WebUserAgentForProfile(NSDictionary<NSString *, id> *profile) {
    NSString *version = profile[@"ios"];
    NSString *cpuVersion = [version stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    return [NSString stringWithFormat:@"Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1", cpuVersion, version];
}

static void H2ApplyWebUserAgent(WKWebView *webView) {
    NSDictionary<NSString *, id> *profile = H2EnabledProfile();
    BOOL enabled = profile != nil;
    id original = objc_getAssociatedObject(webView, &H2OriginalUserAgentKey);
    if (enabled) {
        if (!original) objc_setAssociatedObject(webView, &H2OriginalUserAgentKey, webView.customUserAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *fake = H2WebUserAgentForProfile(profile);
        if (![webView.customUserAgent isEqualToString:fake]) {
            H2SettingWebUserAgent = YES;
            webView.customUserAgent = fake;
            H2SettingWebUserAgent = NO;
        }
    } else if (original) {
        H2SettingWebUserAgent = YES;
        webView.customUserAgent = original == NSNull.null ? nil : original;
        H2SettingWebUserAgent = NO;
        objc_setAssociatedObject(webView, &H2OriginalUserAgentKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *board = profile[@"board"] ?: @"";
    NSUInteger seed = board.length > 1 ? [board characterAtIndex:1] : 1;
    H2UpdateWebFingerprint(webView, enabled ? H2WebUserAgentForProfile(profile) : @"", profile ?: @{}, seed, enabled);
}

static void H2ConfigureWebView(WKWebViewConfiguration *configuration) {
    NSDictionary<NSString *, id> *profile = H2EnabledProfile();
    NSString *board = profile[@"board"] ?: @"";
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
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"name"];
}

- (NSString *)model {
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"name"];
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
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"ios"];
}

- (NSUUID *)identifierForVendor {
    if (!H2FakeEnabled()) return %orig;
    NSString *uuid = H2Profile()[@"uuid"];
    return [[NSUUID alloc] initWithUUIDString:uuid];
}

- (float)batteryLevel {
    float original = %orig;
    return H2FakeEnabled() && original >= 0 ? [H2Profile()[@"battery"] floatValue] : original;
}

- (UIDeviceBatteryState)batteryState {
    UIDeviceBatteryState original = %orig;
    return H2FakeEnabled() && original != UIDeviceBatteryStateUnknown ? UIDeviceBatteryStateUnplugged : original;
}

%end

%hook ASIdentifierManager
- (NSUUID *)advertisingIdentifier {
    NSUUID *original = %orig;
    if (!H2FakeEnabled() || !original || [original.UUIDString isEqualToString:@"00000000-0000-0000-0000-000000000000"]) return original;
    return [[NSUUID alloc] initWithUUIDString:H2Profile()[@"idfa"]];
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
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"carrier"];
}
- (NSString *)mobileCountryCode {
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"mcc"];
}
- (NSString *)mobileNetworkCode {
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"mnc"];
}
- (NSString *)isoCountryCode {
    if (!H2FakeEnabled()) return %orig;
    return H2Profile()[@"country"];
}
%end

%hook CTTelephonyNetworkInfo
- (NSString *)currentRadioAccessTechnology {
    NSString *original = %orig;
    return H2FakeEnabled() && original ? CTRadioAccessTechnologyLTE : original;
}
- (NSDictionary<NSString *, NSString *> *)serviceCurrentRadioAccessTechnology {
    NSDictionary<NSString *, NSString *> *original = %orig;
    if (!H2FakeEnabled() || !original.count) return original;
    NSMutableDictionary *fake = [NSMutableDictionary dictionaryWithCapacity:original.count];
    for (NSString *service in original) fake[service] = CTRadioAccessTechnologyLTE;
    return fake;
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

- (unsigned long long)physicalMemory {
    if (!H2FakeEnabled()) return %orig;
    return [H2Profile()[@"memory"] unsignedLongLongValue];
}

- (NSUInteger)processorCount {
    if (!H2FakeEnabled()) return %orig;
    return [H2Profile()[@"cores"] unsignedIntegerValue];
}

- (NSUInteger)activeProcessorCount {
    if (!H2FakeEnabled()) return %orig;
    return [H2Profile()[@"cores"] unsignedIntegerValue];
}

- (NSOperatingSystemVersion)operatingSystemVersion {
    if (!H2FakeEnabled()) return %orig;
    NSArray<NSString *> *parts = [H2Profile()[@"ios"] componentsSeparatedByString:@"."];
    NSOperatingSystemVersion version = { parts.count > 0 ? parts[0].integerValue : 0,
        parts.count > 1 ? parts[1].integerValue : 0,
        parts.count > 2 ? parts[2].integerValue : 0 };
    return version;
}

- (NSString *)operatingSystemVersionString {
    if (!H2FakeEnabled()) return %orig;
    return [@"Version " stringByAppendingString:H2Profile()[@"ios"]];
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
    if (!name || newp || !H2FakeEnabled()) return %orig;
    if (strcmp(name, "hw.memsize") == 0) {
        uint64_t memory = [H2Profile()[@"memory"] unsignedLongLongValue];
        return H2CopySysctlScalar(&memory, sizeof(memory), oldp, oldlenp);
    }
    if (strcmp(name, "hw.ncpu") == 0 || strcmp(name, "hw.physicalcpu") == 0 || strcmp(name, "hw.logicalcpu") == 0) {
        int cores = [H2Profile()[@"cores"] intValue];
        return H2CopySysctlScalar(&cores, sizeof(cores), oldp, oldlenp);
    }
    NSString *value = nil;
    if (strcmp(name, "hw.machine") == 0) value = H2Profile()[@"model"];
    else if (strcmp(name, "hw.model") == 0) value = H2Profile()[@"board"];
    else if (strcmp(name, "kern.osproductversion") == 0) value = H2Profile()[@"ios"];
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
    if (result == 0 && name && H2FakeEnabled()) {
        snprintf(name->machine, sizeof(name->machine), "%s", [H2Profile()[@"model"] UTF8String]);
    }
    return result;
}

%group H2MobileGestalt
%hookf(CFTypeRef, MGCopyAnswer, CFStringRef key) {
    if (!key || !H2FakeEnabled()) return %orig;
    NSString *answer = nil;
    if (CFStringCompare(key, CFSTR("HardwareModel"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"board"];
    else if (CFStringCompare(key, CFSTR("ProductType"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"model"];
    else if (CFStringCompare(key, CFSTR("ProductVersion"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"ios"];
    else if (CFStringCompare(key, CFSTR("InternationalMobileEquipmentIdentity"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"imei"];
    else if (CFStringCompare(key, CFSTR("InternationalMobileEquipmentIdentity2"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"imei2"];
    else if (CFStringCompare(key, CFSTR("DeviceClass"), 0) == kCFCompareEqualTo) answer = @"iPhone";
    else if (CFStringCompare(key, CFSTR("DeviceName"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"name"];
    else if (CFStringCompare(key, CFSTR("UserAssignedDeviceName"), 0) == kCFCompareEqualTo) answer = H2Profile()[@"name"];
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
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return;
    dlopen("/System/Library/Frameworks/AdSupport.framework/AdSupport", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreLocation.framework/CoreLocation", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreMotion.framework/CoreMotion", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_LAZY);
    H2TrackedWebViews = [NSHashTable weakObjectsHashTable];
    NSString *runtimeName = [@"com.h2changer.runtime." stringByAppendingString:bundleID];
    notify_register_dispatch(runtimeName.UTF8String, &H2RuntimeNotificationToken, dispatch_get_main_queue(), ^(int token) {
        H2RefreshTrackedWebViews();
    });
    %init;
    %init(H2WebUA);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    void *copyAnswer = gestalt ? dlsym(gestalt, "MGCopyAnswer") : NULL;
    if (copyAnswer) %init(H2MobileGestalt, MGCopyAnswer = copyAnswer);
}
