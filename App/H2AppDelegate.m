#import "H2AppDelegate.h"
#import "H2MainController.h"
#import "H2ConfigManager.h"

@implementation H2AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[H2MainController new]];
    [self.window makeKeyAndVisible];
    [[H2ConfigManager sharedManager] publishRuntimeState];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[H2ConfigManager sharedManager] publishRuntimeState];
}
@end
