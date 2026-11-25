#import <UIKit/UIKit.h>
#import "H2ConfigManager.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <errno.h>
#import <stdio.h>
#import <string.h>
#import <dlfcn.h>

static BOOL H2FakeEnabled(void) {
    return [[H2ConfigManager sharedManager] isFakeActiveForBundleID:[NSBundle mainBundle].bundleIdentifier];
}

static NSDictionary<NSString *, NSString *> *H2Profile(void) {
    NSString *name = [[H2ConfigManager sharedManager] effectiveConfigForBundleID:[NSBundle mainBundle].bundleIdentifier][@"profile"];
    return [H2ConfigManager profileNamed:name];
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

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return;
    %init;
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    void *copyAnswer = gestalt ? dlsym(gestalt, "MGCopyAnswer") : NULL;
    if (copyAnswer) %init(H2MobileGestalt, MGCopyAnswer = copyAnswer);
}
