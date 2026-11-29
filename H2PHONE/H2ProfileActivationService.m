#import "H2ProfileActivationService.h"
#import "H2ConfigManager.h"

@implementation H2ProfileActivationService

+ (BOOL)activateProfile:(NSDictionary<NSString *, id> *)profile
            enabledApps:(NSArray<NSString *> *)enabledApps
                  error:(NSError **)error {
    return [[H2ConfigManager sharedManager] activateGeneratedProfile:profile enabledApps:enabledApps error:error];
}

@end
