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

static char H2OriginalUserAgentKey;
static __thread BOOL H2SettingSafariUserAgent;

static BOOL H2FakeEnabled(void) {
    return [[H2ConfigManager sharedManager] isFakeActiveForBundleID:[NSBundle mainBundle].bundleIdentifier];
}

static NSDictionary<NSString *, NSString *> *H2Profile(void) {
    NSString *name = [[H2ConfigManager sharedManager] effectiveConfigForBundleID:[NSBundle mainBundle].bundleIdentifier][@"profile"];
    return [H2ConfigManager profileNamed:name];
}

static NSString *H2SafariUserAgent(void) {
    NSString *version = H2Profile()[@"ios"];
    NSString *cpuVersion = [version stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    return [NSString stringWithFormat:@"Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1", cpuVersion, version];
}

static void H2ApplySafariUserAgent(WKWebView *webView) {
    id original = objc_getAssociatedObject(webView, &H2OriginalUserAgentKey);
    if (H2FakeEnabled()) {
        if (!original) objc_setAssociatedObject(webView, &H2OriginalUserAgentKey, webView.customUserAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *fake = H2SafariUserAgent();
        if (![webView.customUserAgent isEqualToString:fake]) {
            H2SettingSafariUserAgent = YES;
            webView.customUserAgent = fake;
            H2SettingSafariUserAgent = NO;
        }
    } else if (original) {
        H2SettingSafariUserAgent = YES;
        webView.customUserAgent = original == NSNull.null ? nil : original;
        H2SettingSafariUserAgent = NO;
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

%group H2SafariUA
%hook WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKWebView *webView = %orig;
    if (webView) H2ApplySafariUserAgent(webView);
    return webView;
}

- (WKNavigation *)loadRequest:(NSURLRequest *)request {
    H2ApplySafariUserAgent(self);
    return %orig;
}

- (void)setCustomUserAgent:(NSString *)userAgent {
    if (H2SettingSafariUserAgent || !H2FakeEnabled()) return %orig;
    objc_setAssociatedObject(self, &H2OriginalUserAgentKey, userAgent ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return %orig(H2SafariUserAgent());
}

%end
%end

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return;
    %init;
    if ([bundleID isEqualToString:H2SafariBundleID]) %init(H2SafariUA);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    void *copyAnswer = gestalt ? dlsym(gestalt, "MGCopyAnswer") : NULL;
    if (copyAnswer) %init(H2MobileGestalt, MGCopyAnswer = copyAnswer);
}
