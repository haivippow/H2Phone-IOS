#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface H2InstalledAppService : NSObject
+ (NSArray<NSDictionary<NSString *, id> *> *)installedApplications;
@end

NS_ASSUME_NONNULL_END
