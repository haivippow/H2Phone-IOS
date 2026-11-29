#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface H2ProfileActivationService : NSObject
+ (BOOL)activateProfile:(NSDictionary<NSString *, id> *)profile
            enabledApps:(NSArray<NSString *> *)enabledApps
                  error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
