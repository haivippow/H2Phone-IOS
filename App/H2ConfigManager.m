#import "H2ConfigManager.h"
#import <notify.h>

NSString * const H2ConfigChangedNotification = @"com.h2changer.config.changed";
NSString * const H2TargetBundleID = @"com.h2phone.devicetest";
NSString * const H2SafariBundleID = @"com.apple.mobilesafari";
static NSString * const H2ConfigPath = @"/var/mobile/Library/Preferences/com.h2changer.config.plist";
static NSString * const H2LogPath = @"/var/mobile/Library/Preferences/com.h2changer.debug.log";
static uint64_t const H2RuntimeMagic = 0x4832434800000000ULL;

@interface H2ConfigManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *runtimeTokens;
@end

@implementation H2ConfigManager

+ (instancetype)sharedManager {
    static H2ConfigManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [H2ConfigManager new]; });
    return manager;
}

- (NSDictionary<NSString *, id> *)snapshot {
    NSDictionary *value = [NSDictionary dictionaryWithContentsOfFile:H2ConfigPath];
    if (![value isKindOfClass:NSDictionary.class] || ![value[@"schema"] isEqual:@1]) {
        return @{ @"schema": @1, @"enabled": @(NO), @"profile": @"Test A", @"enabledApps": @[H2TargetBundleID] };
    }
    NSString *profile = value[@"profile"];
    if (![profile isKindOfClass:NSString.class] || ![@[@"Test A", @"Test B", @"iPhone 13 Pro Max"] containsObject:profile]) profile = @"Test A";
    NSArray *apps = value[@"enabledApps"];
    if (![apps isKindOfClass:NSArray.class]) apps = @[H2TargetBundleID];
    NSMutableArray *validApps = [NSMutableArray array];
    for (id bundleID in apps) {
        if ([bundleID isKindOfClass:NSString.class] && [bundleID length] > 0) [validApps addObject:bundleID];
    }
    return @{ @"schema": @1, @"enabled": @([value[@"enabled"] boolValue]), @"profile": profile, @"enabledApps": validApps };
}

- (BOOL)saveEnabled:(BOOL)enabled profile:(NSString *)profile error:(NSError **)error {
    if (![@[@"Test A", @"Test B", @"iPhone 13 Pro Max"] containsObject:profile]) {
        if (error) *error = [NSError errorWithDomain:@"H2Config" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown profile"}];
        return NO;
    }
    NSDictionary *value = @{ @"schema": @1, @"enabled": @(enabled), @"profile": profile, @"enabledApps": [self snapshot][@"enabledApps"] };
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:value format:NSPropertyListBinaryFormat_v1_0 options:0 error:error];
    if (!data || ![data writeToFile:H2ConfigPath options:NSDataWritingAtomic error:error]) return NO;
    notify_post(H2ConfigChangedNotification.UTF8String);
    [self publishRuntimeState];
    [self appendLog:[NSString stringWithFormat:@"Config: %@ / %@", enabled ? @"ON" : @"OFF", profile]];
    return YES;
}

- (BOOL)restoreOriginal:(NSError **)error {
    NSDictionary *current = [self snapshot];
    return [self saveEnabled:NO profile:current[@"profile"] error:error];
}

- (BOOL)setAppEnabled:(BOOL)enabled bundleID:(NSString *)bundleID error:(NSError **)error {
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) {
        if (error) *error = [NSError errorWithDomain:@"H2Config" code:2 userInfo:@{NSLocalizedDescriptionKey: @"This app cannot be selected."}];
        return NO;
    }
    NSDictionary *current = [self snapshot];
    NSMutableOrderedSet *apps = [NSMutableOrderedSet orderedSetWithArray:current[@"enabledApps"]];
    if (enabled) [apps addObject:bundleID]; else [apps removeObject:bundleID];
    NSDictionary *value = @{ @"schema": @1, @"enabled": current[@"enabled"], @"profile": current[@"profile"], @"enabledApps": apps.array };
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:value format:NSPropertyListBinaryFormat_v1_0 options:0 error:error];
    if (!data || ![data writeToFile:H2ConfigPath options:NSDataWritingAtomic error:error]) return NO;
    notify_post(H2ConfigChangedNotification.UTF8String);
    [self publishRuntimeState];
    [self publishRuntimeStateForBundleID:bundleID];
    [self appendLog:[NSString stringWithFormat:@"App %@: %@", enabled ? @"enabled" : @"disabled", bundleID]];
    return YES;
}

- (BOOL)isFakeActiveForBundleID:(NSString *)bundleID {
    if (bundleID.length == 0 || ([bundleID hasPrefix:@"com.apple."] && ![bundleID isEqualToString:H2SafariBundleID]) || [bundleID isEqualToString:@"com.h2changer.app"]) return NO;
    return [[self effectiveConfigForBundleID:bundleID][@"enabled"] boolValue];
}

- (NSString *)runtimeNameForBundleID:(NSString *)bundleID {
    return [@"com.h2changer.runtime." stringByAppendingString:bundleID];
}

- (int)runtimeTokenForBundleID:(NSString *)bundleID {
    @synchronized (self) {
        if (!self.runtimeTokens) self.runtimeTokens = [NSMutableDictionary dictionary];
        NSNumber *cached = self.runtimeTokens[bundleID];
        if (cached) return cached.intValue;
        int token = -1;
        if (notify_register_check([self runtimeNameForBundleID:bundleID].UTF8String, &token) != 0) return -1;
        self.runtimeTokens[bundleID] = @(token);
        return token;
    }
}

- (void)publishRuntimeStateForBundleID:(NSString *)bundleID {
    NSDictionary *config = [self snapshot];
    int token = [self runtimeTokenForBundleID:bundleID];
    if (token < 0) return;
    BOOL active = [config[@"enabled"] boolValue] && [config[@"enabledApps"] containsObject:bundleID];
    NSString *profile = config[@"profile"];
    uint64_t profileCode = [profile isEqualToString:@"iPhone 13 Pro Max"] ? 2 : ([profile isEqualToString:@"Test B"] ? 1 : 0);
    uint64_t state = H2RuntimeMagic | (profileCode << 8) | (active ? 1 : 0);
    notify_set_state(token, state);
    notify_post([self runtimeNameForBundleID:bundleID].UTF8String);
}

- (void)publishRuntimeState {
    for (NSString *bundleID in [self snapshot][@"enabledApps"]) [self publishRuntimeStateForBundleID:bundleID];
}

- (NSDictionary<NSString *, id> *)effectiveConfigForBundleID:(NSString *)bundleID {
    NSDictionary *fallback = [self snapshot];
    if (bundleID.length == 0) return @{ @"enabled": @(NO), @"profile": fallback[@"profile"] };
    int token = [self runtimeTokenForBundleID:bundleID];
    uint64_t state = 0;
    if (token >= 0 && notify_get_state(token, &state) == 0 && (state & 0xffffffff00000000ULL) == H2RuntimeMagic) {
        uint64_t code = (state >> 8) & 0xff;
        NSString *profile = code == 2 ? @"iPhone 13 Pro Max" : (code == 1 ? @"Test B" : @"Test A");
        return @{ @"enabled": @((state & 1) != 0), @"profile": profile };
    }
    BOOL active = [fallback[@"enabled"] boolValue] && [fallback[@"enabledApps"] containsObject:bundleID];
    return @{ @"enabled": @(active), @"profile": fallback[@"profile"] };
}

- (void)appendLog:(NSString *)message {
    @synchronized (self) {
        NSString *line = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], message];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:H2LogPath];
        if (!handle) {
            [line writeToFile:H2LogPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            return;
        }
        @try {
            [handle seekToEndOfFile];
            [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        } @catch (NSException *exception) { [handle closeFile]; }
    }
}

- (NSArray<NSString *> *)recentLogs {
    NSString *content = [NSString stringWithContentsOfFile:H2LogPath encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    NSUInteger start = lines.count > 100 ? lines.count - 100 : 0;
    return [lines subarrayWithRange:NSMakeRange(start, lines.count - start)];
}
@end
