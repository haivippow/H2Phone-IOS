#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const H2ConfigChangedNotification;
FOUNDATION_EXPORT NSString * const H2TargetBundleID;

@interface H2ConfigManager : NSObject
+ (instancetype)sharedManager;
- (NSDictionary<NSString *, id> *)snapshot;
- (BOOL)saveEnabled:(BOOL)enabled profile:(NSString *)profile error:(NSError **)error;
- (BOOL)restoreOriginal:(NSError **)error;
- (BOOL)setAppEnabled:(BOOL)enabled bundleID:(NSString *)bundleID error:(NSError **)error;
- (BOOL)isFakeActiveForBundleID:(NSString *)bundleID;
- (void)appendLog:(NSString *)message;
- (NSArray<NSString *> *)recentLogs;
@end

NS_ASSUME_NONNULL_END
