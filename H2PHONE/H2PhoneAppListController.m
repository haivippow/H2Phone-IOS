#import "H2PhoneAppListController.h"
#import "H2ConfigManager.h"
#import <objc/message.h>
#import <dlfcn.h>

@interface H2PhoneAppListController ()
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *apps;
@end

@implementation H2PhoneAppListController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Test Apps";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    [self reloadApps];
}

- (void)reloadApps {
    dlopen("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices", RTLD_LAZY);
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    id workspace = [workspaceClass respondsToSelector:defaultSelector] ? ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultSelector) : nil;
    SEL listSelector = NSSelectorFromString(@"allInstalledApplications");
    NSArray *proxies = [workspace respondsToSelector:listSelector] ? ((id (*)(id, SEL))objc_msgSend)(workspace, listSelector) : @[];
    NSMutableArray *items = [NSMutableArray array];
    for (id proxy in proxies) {
        @try {
            NSString *bundleID = [proxy valueForKey:@"applicationIdentifier"];
            NSString *type = [proxy valueForKey:@"applicationType"];
            BOOL allowedSystemApp = [bundleID isEqualToString:H2TargetBundleID] || [bundleID isEqualToString:H2SafariBundleID];
            if (![bundleID isKindOfClass:NSString.class] || (![type isEqualToString:@"User"] && !allowedSystemApp) || [bundleID isEqualToString:@"com.h2phone.app"]) continue;
            NSString *name = [proxy valueForKey:@"localizedName"];
            [items addObject:@{ @"id": bundleID, @"name": [name isKindOfClass:NSString.class] && name.length ? name : bundleID }];
        } @catch (NSException *exception) { continue; }
    }
    BOOL hasSafari = NO;
    for (NSDictionary *item in items) {
        if ([item[@"id"] isEqualToString:H2SafariBundleID]) { hasSafari = YES; break; }
    }
    if (!hasSafari) {
        [items addObject:@{ @"id": H2SafariBundleID, @"name": @"Safari" }];
    }
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]]; }];
    self.apps = items;
    UILabel *emptyLabel = [UILabel new];
    emptyLabel.text = @"No user apps found. Check app list access on this device.";
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 0;
    self.tableView.backgroundView = items.count ? nil : emptyLabel;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.apps.count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"Tap to allow fake values; ⓘ to open app"; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *app = self.apps[indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    BOOL selected = [[H2ConfigManager.sharedManager snapshot][@"enabledApps"] containsObject:app[@"id"]];
    cell.textLabel.text = selected ? [@"✓ " stringByAppendingString:app[@"name"]] : app[@"name"];
    cell.detailTextLabel.text = app[@"id"];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *bundleID = self.apps[indexPath.row][@"id"];
    BOOL selected = [[H2ConfigManager.sharedManager snapshot][@"enabledApps"] containsObject:bundleID];
    NSError *error;
    if (![H2ConfigManager.sharedManager setAppEnabled:!selected bundleID:bundleID error:&error]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot save" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *bundleID = self.apps[indexPath.row][@"id"];
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    id workspace = [workspaceClass respondsToSelector:defaultSelector] ? ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultSelector) : nil;
    SEL openSelector = NSSelectorFromString(@"openApplicationWithBundleID:");
    if ([workspace respondsToSelector:openSelector]) ((void (*)(id, SEL, id))objc_msgSend)(workspace, openSelector, bundleID);
}
@end
