#import "H2DevAppDelegate.h"
#import "H2DevController.h"

@implementation H2DevAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[H2DevController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
