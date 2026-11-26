#import "H2ConfigManager.h"
#import <notify.h>

NSString * const H2ConfigChangedNotification = @"com.h2changer.config.changed";
NSString * const H2TargetBundleID = @"com.h2phone.devicetest";
NSString * const H2SafariBundleID = @"com.apple.mobilesafari";
static NSString * const H2ConfigPath = @"/var/mobile/Library/Preferences/com.h2changer.config.plist";
static NSString * const H2LogPath = @"/var/mobile/Library/Preferences/com.h2changer.debug.log";
static uint64_t const H2RuntimeMagic = 0x4832434900000000ULL;

@interface H2ConfigManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *runtimeTokens;
@end

@implementation H2ConfigManager

+ (NSArray<NSDictionary<NSString *, id> *> *)profiles {
    static NSArray<NSDictionary<NSString *, id> *> *profiles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ profiles = @[
        @{ @"name": @"iPhone 13 Pro Max", @"model": @"iPhone14,3", @"board": @"D64AP", @"ios": @"17.7", @"build": @"21H16", @"darwin": @"23.6.0", @"uuid": @"9B625883-76C1-47D2-9D80-2EB2A397A134", @"idfa": @"74CB69A9-1D45-4AAB-8A44-013A42E479B2", @"imei": @"990000000000010", @"imei2": @"990000000000028", @"memory": @6442450944ULL, @"cores": @6, @"screenWidth": @428, @"screenHeight": @926, @"nativeWidth": @1284, @"nativeHeight": @2778, @"screenScale": @3, @"maxTouchPoints": @5, @"carrier": @"Viettel", @"mcc": @"452", @"mnc": @"04", @"country": @"vn", @"latitude": @21.0285, @"longitude": @105.8542, @"battery": @0.85, @"webglVendor": @"Apple Inc.", @"webglRenderer": @"Apple GPU" },
        @{ @"name": @"iPhone 14 Pro Max", @"model": @"iPhone15,3", @"board": @"D74AP", @"ios": @"17.6", @"build": @"21G80", @"darwin": @"23.6.0", @"uuid": @"B91D7391-E48A-47D4-A217-6A99A7E7C0B2", @"idfa": @"0B8CE521-D67F-43E9-9CE1-91EAA4101C47", @"imei": @"990000000000036", @"imei2": @"990000000000044", @"memory": @6442450944ULL, @"cores": @6, @"screenWidth": @430, @"screenHeight": @932, @"nativeWidth": @1290, @"nativeHeight": @2796, @"screenScale": @3, @"maxTouchPoints": @5, @"carrier": @"Viettel", @"mcc": @"452", @"mnc": @"04", @"country": @"vn", @"latitude": @21.0285, @"longitude": @105.8542, @"battery": @0.85, @"webglVendor": @"Apple Inc.", @"webglRenderer": @"Apple GPU" },
        @{ @"name": @"iPhone 15 Pro Max", @"model": @"iPhone16,2", @"board": @"D84AP", @"ios": @"18.0", @"build": @"22A3354", @"darwin": @"24.0.0", @"uuid": @"A729AE2B-9B2A-4DBF-8E45-4ACCC1F17608", @"idfa": @"D6BA9728-0FD5-42F3-AD91-381C56DC5F80", @"imei": @"990000000000051", @"imei2": @"990000000000069", @"memory": @8589934592ULL, @"cores": @6, @"screenWidth": @430, @"screenHeight": @932, @"nativeWidth": @1290, @"nativeHeight": @2796, @"screenScale": @3, @"maxTouchPoints": @5, @"carrier": @"Viettel", @"mcc": @"452", @"mnc": @"04", @"country": @"vn", @"latitude": @21.0285, @"longitude": @105.8542, @"battery": @0.85, @"webglVendor": @"Apple Inc.", @"webglRenderer": @"Apple GPU" },
        @{ @"name": @"iPhone 16 Pro Max", @"model": @"iPhone17,2", @"board": @"D94AP", @"ios": @"18.1", @"build": @"22B83", @"darwin": @"24.1.0", @"uuid": @"85E8AB49-0F63-4E66-A854-C95126E85E1D", @"idfa": @"E75DA473-C9B4-4863-9F0B-6D96944AFC31", @"imei": @"990000000000077", @"imei2": @"990000000000085", @"memory": @8589934592ULL, @"cores": @6, @"screenWidth": @440, @"screenHeight": @956, @"nativeWidth": @1320, @"nativeHeight": @2868, @"screenScale": @3, @"maxTouchPoints": @5, @"carrier": @"Viettel", @"mcc": @"452", @"mnc": @"04", @"country": @"vn", @"latitude": @21.0285, @"longitude": @105.8542, @"battery": @0.85, @"webglVendor": @"Apple Inc.", @"webglRenderer": @"Apple GPU" }
    ]; });
    return profiles;
}

+ (NSDictionary<NSString *, id> *)profileNamed:(NSString *)name {
    for (NSDictionary *profile in [self profiles]) if ([profile[@"name"] isEqualToString:name]) return profile;
    return [self profiles][0];
}

+ (instancetype)sharedManager {
    static H2ConfigManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [H2ConfigManager new]; });
    return manager;
}

- (NSDictionary<NSString *, id> *)snapshot {
    NSDictionary *value = [NSDictionary dictionaryWithContentsOfFile:H2ConfigPath];
    if (![value isKindOfClass:NSDictionary.class] || ![value[@"schema"] isEqual:@1]) {
        return @{ @"schema": @1, @"enabled": @(NO), @"profile": [H2ConfigManager profiles][0][@"name"], @"enabledApps": @[H2TargetBundleID] };
    }
    NSString *profile = value[@"profile"];
    profile = [H2ConfigManager profileNamed:profile][@"name"];
    NSArray *apps = value[@"enabledApps"];
    if (![apps isKindOfClass:NSArray.class]) apps = @[H2TargetBundleID];
    NSMutableArray *validApps = [NSMutableArray array];
    for (id bundleID in apps) {
        if ([bundleID isKindOfClass:NSString.class] && [bundleID length] > 0) [validApps addObject:bundleID];
    }
    return @{ @"schema": @1, @"enabled": @([value[@"enabled"] boolValue]), @"profile": profile, @"enabledApps": validApps };
}

- (BOOL)saveEnabled:(BOOL)enabled profile:(NSString *)profile error:(NSError **)error {
    if (![[H2ConfigManager profileNamed:profile][@"name"] isEqualToString:profile]) {
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
    uint64_t profileCode = 0;
    NSArray *profiles = [H2ConfigManager profiles];
    for (NSUInteger i = 0; i < profiles.count; i++) if ([profiles[i][@"name"] isEqualToString:profile]) { profileCode = i; break; }
    uint64_t state = H2RuntimeMagic | (profileCode << 8) | (active ? 1 : 0);
    notify_set_state(token, state);
    notify_post([self runtimeNameForBundleID:bundleID].UTF8String);
}

- (void)publishRuntimeState {
    for (NSString *bundleID in [self snapshot][@"enabledApps"]) [self publishRuntimeStateForBundleID:bundleID];
}

- (NSDictionary<NSString *, id> *)effectiveConfigForBundleID:(NSString *)bundleID {
    if (bundleID.length > 0) {
        int token = [self runtimeTokenForBundleID:bundleID];
        uint64_t state = 0;
        if (token >= 0 && notify_get_state(token, &state) == 0 && (state & 0xffffffff00000000ULL) == H2RuntimeMagic) {
            uint64_t code = (state >> 8) & 0xff;
            NSArray *profiles = [H2ConfigManager profiles];
            NSString *profile = profiles[code < profiles.count ? code : 0][@"name"];
            return @{ @"enabled": @((state & 1) != 0), @"profile": profile };
        }
    }
    NSDictionary *fallback = [self snapshot];
    if (bundleID.length == 0) return @{ @"enabled": @(NO), @"profile": fallback[@"profile"] };
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
