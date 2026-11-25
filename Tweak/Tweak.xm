#import <UIKit/UIKit.h>
#import "H2ConfigManager.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <errno.h>
#import <stdio.h>
#import <string.h>

static BOOL H2FakeEnabled(void) {
    return [[H2ConfigManager sharedManager] isFakeActiveForBundleID:[NSBundle mainBundle].bundleIdentifier];
}

static BOOL H2ProfileB(void) {
    return [[[[H2ConfigManager sharedManager] effectiveConfigForBundleID:[NSBundle mainBundle].bundleIdentifier] objectForKey:@"profile"] isEqualToString:@"Test B"];
}

static BOOL H2Profile13ProMax(void) {
    return [[[[H2ConfigManager sharedManager] effectiveConfigForBundleID:[NSBundle mainBundle].bundleIdentifier] objectForKey:@"profile"] isEqualToString:@"iPhone 13 Pro Max"];
}

%hook UIDevice

- (NSString *)name {
    if (!H2FakeEnabled()) return %orig;
    if (H2Profile13ProMax()) return @"iPhone 13 Pro Max";
    return H2ProfileB() ? @"H2 Test Phone B" : @"H2 Test Phone A";
}

- (NSString *)model {
    if (!H2FakeEnabled()) return %orig;
    if (H2Profile13ProMax()) return @"iPhone 13 Pro Max";
    return @"iPhone";
}

- (NSString *)systemVersion {
    if (!H2FakeEnabled()) return %orig;
    if (H2Profile13ProMax()) return @"16.1";
    return H2ProfileB() ? @"16.2" : @"16.1";
}

- (NSUUID *)identifierForVendor {
    if (!H2FakeEnabled()) return %orig;
    NSString *uuid = H2Profile13ProMax() ? @"9B625883-76C1-47D2-9D80-2EB2A397A134" : (H2ProfileB() ? @"B91D7391-E48A-47D4-A217-6A99A7E7C0B2" : @"A729AE2B-9B2A-4DBF-8E45-4ACCC1F17608");
    return [[NSUUID alloc] initWithUUIDString:uuid];
}

%end

%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!name || strcmp(name, "hw.machine") != 0 || newp || !H2FakeEnabled() || !H2Profile13ProMax()) return %orig;
    const char *model = "iPhone14,3";
    size_t required = strlen(model) + 1;
    if (!oldlenp) { errno = EINVAL; return -1; }
    if (!oldp) { *oldlenp = required; return 0; }
    if (*oldlenp < required) { *oldlenp = required; errno = ENOMEM; return -1; }
    memcpy(oldp, model, required);
    *oldlenp = required;
    return 0;
}

%hookf(int, uname, struct utsname *name) {
    int result = %orig;
    if (result == 0 && name && H2FakeEnabled() && H2Profile13ProMax()) {
        snprintf(name->machine, sizeof(name->machine), "%s", "iPhone14,3");
    }
    return result;
}

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return;
    %init;
}
