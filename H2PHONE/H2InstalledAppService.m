#import "H2InstalledAppService.h"
#import "H2ConfigManager.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>

@implementation H2InstalledAppService

+ (nullable NSData *)iconPNGDataForBundleID:(NSString *)bundleID {
    SEL selector = NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
    if (![UIImage respondsToSelector:selector]) return nil;
    UIImage *icon = ((UIImage *(*)(id, SEL, id, NSInteger, CGFloat))objc_msgSend)(
        UIImage.class,
        selector,
        bundleID,
        2,
        UIScreen.mainScreen.scale
    );
    return icon ? UIImagePNGRepresentation(icon) : nil;
}

+ (NSArray<NSDictionary<NSString *, id> *> *)installedApplications {
    dlopen("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices", RTLD_LAZY);
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    id workspace = [workspaceClass respondsToSelector:defaultSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultSelector)
        : nil;
    SEL listSelector = NSSelectorFromString(@"allInstalledApplications");
    NSArray *proxies = [workspace respondsToSelector:listSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(workspace, listSelector)
        : @[];
    NSSet *enabledApps = [NSSet setWithArray:[H2ConfigManager.sharedManager snapshot][@"enabledApps"] ?: @[]];
    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray array];

    for (id proxy in proxies) {
        @try {
            NSString *bundleID = [proxy valueForKey:@"applicationIdentifier"];
            NSString *type = [proxy valueForKey:@"applicationType"];
            BOOL allowedSystemApp = [bundleID isEqualToString:H2TargetBundleID] || [bundleID isEqualToString:H2SafariBundleID];
            if (![bundleID isKindOfClass:NSString.class] ||
                (![type isEqualToString:@"User"] && !allowedSystemApp) ||
                [bundleID isEqualToString:@"com.h2phone.app"]) continue;

            NSString *localizedName = [proxy valueForKey:@"localizedName"];
            NSString *name = [localizedName isKindOfClass:NSString.class] && localizedName.length
                ? localizedName
                : bundleID;
            NSMutableDictionary<NSString *, id> *item = [@{
                @"id": bundleID,
                @"name": name,
                @"fakeInfo": @([enabledApps containsObject:bundleID])
            } mutableCopy];
            NSData *iconPNGData = [self iconPNGDataForBundleID:bundleID];
            if (iconPNGData.length) item[@"iconPNGData"] = iconPNGData;
            [items addObject:item];
        } @catch (__unused NSException *exception) {
            continue;
        }
    }

    BOOL hasSafari = [items indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger index, BOOL *stop) {
        return [item[@"id"] isEqualToString:H2SafariBundleID];
    }] != NSNotFound;
    if (!hasSafari) {
        NSMutableDictionary<NSString *, id> *safari = [@{
            @"id": H2SafariBundleID,
            @"name": @"Safari",
            @"fakeInfo": @([enabledApps containsObject:H2SafariBundleID])
        } mutableCopy];
        NSData *iconPNGData = [self iconPNGDataForBundleID:H2SafariBundleID];
        if (iconPNGData.length) safari[@"iconPNGData"] = iconPNGData;
        [items addObject:safari];
    }

    [items sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"name"] localizedCaseInsensitiveCompare:right[@"name"]];
    }];
    return items;
}

@end
