#import "H2AppDelegate.h"
#import "H2MainController.h"

@implementation H2AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[H2MainController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
