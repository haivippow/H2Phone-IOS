#import <UIKit/UIKit.h>
#import "H2ConfigManager.h"

static BOOL H2FakeEnabled(void) {
    return [[H2ConfigManager sharedManager] isFakeActiveForBundleID:[NSBundle mainBundle].bundleIdentifier];
}

static BOOL H2ProfileB(void) {
    return [[[[H2ConfigManager sharedManager] snapshot] objectForKey:@"profile"] isEqualToString:@"Test B"];
}

%hook UIDevice

- (NSString *)name {
    if (!H2FakeEnabled()) return %orig;
    return H2ProfileB() ? @"H2 Test Phone B" : @"H2 Test Phone A";
}

- (NSString *)model {
    if (!H2FakeEnabled()) return %orig;
    return @"iPhone";
}

- (NSString *)systemVersion {
    if (!H2FakeEnabled()) return %orig;
    return H2ProfileB() ? @"16.2" : @"16.1";
}

- (NSUUID *)identifierForVendor {
    if (!H2FakeEnabled()) return %orig;
    NSString *uuid = H2ProfileB() ? @"B91D7391-E48A-47D4-A217-6A99A7E7C0B2" : @"A729AE2B-9B2A-4DBF-8E45-4ACCC1F17608";
    return [[NSUUID alloc] initWithUUIDString:uuid];
}

%end

%ctor {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if (bundleID.length == 0 || [bundleID hasPrefix:@"com.apple."] || [bundleID isEqualToString:@"com.h2changer.app"]) return;
    %init;
}
