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

%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!name || strcmp(name, "hw.machine") != 0 || newp || !H2FakeEnabled()) return %orig;
    const char *model = [H2Profile()[@"model"] UTF8String];
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
    if (result == 0 && name && H2FakeEnabled()) {
        snprintf(name->machine, sizeof(name->machine), "%s", [H2Profile()[@"model"] UTF8String]);
    }
    return result;
}

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return;
    %init;
}
