#import "H2TestAppDelegate.h"
#import "H2TestController.h"

@implementation H2TestAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[H2TestController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
