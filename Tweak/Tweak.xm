#import <UIKit/UIKit.h>
#import "H2ConfigManager.h"
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

static char H2OriginalUserAgentKey;
static __thread BOOL H2SettingWebUserAgent;
static __thread BOOL H2ReadingConfig;

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

static NSDictionary<NSString *, NSString *> *H2Profile(void) {
    NSString *name = H2CurrentConfig()[@"profile"];
    return [H2ConfigManager profileNamed:name];
}

static NSString *H2WebUserAgent(void) {
    NSString *version = H2Profile()[@"ios"];
    NSString *cpuVersion = [version stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    return [NSString stringWithFormat:@"Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1", cpuVersion, version];
}

static void H2ApplyWebUserAgent(WKWebView *webView) {
    id original = objc_getAssociatedObject(webView, &H2OriginalUserAgentKey);
    if (H2FakeEnabled()) {
        if (!original) objc_setAssociatedObject(webView, &H2OriginalUserAgentKey, webView.customUserAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *fake = H2WebUserAgent();
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
    return H2FakeEnabled() && original >= 0 ? 0.85f : original;
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
    return CLLocationCoordinate2DMake(21.0285, 105.8542);
}
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
    return @"Viettel";
}
- (NSString *)mobileCountryCode {
    if (!H2FakeEnabled()) return %orig;
    return @"452";
}
- (NSString *)mobileNetworkCode {
    if (!H2FakeEnabled()) return %orig;
    return @"04";
}
- (NSString *)isoCountryCode {
    if (!H2FakeEnabled()) return %orig;
    return @"vn";
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

%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!name || newp || !H2FakeEnabled()) return %orig;
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
    if (answer) return CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)answer);
    return %orig;
}
%end

%group H2WebUA
%hook WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKWebView *webView = %orig;
    if (webView) H2ApplyWebUserAgent(webView);
    return webView;
}

- (WKNavigation *)loadRequest:(NSURLRequest *)request {
    H2ApplyWebUserAgent(self);
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
    if (!H2FakeEnabled()) {
        objc_setAssociatedObject(self, &H2OriginalUserAgentKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return %orig;
    }
    objc_setAssociatedObject(self, &H2OriginalUserAgentKey, userAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return %orig(H2WebUserAgent());
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
    %init;
    %init(H2WebUA);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    void *copyAnswer = gestalt ? dlsym(gestalt, "MGCopyAnswer") : NULL;
    if (copyAnswer) %init(H2MobileGestalt, MGCopyAnswer = copyAnswer);
}
