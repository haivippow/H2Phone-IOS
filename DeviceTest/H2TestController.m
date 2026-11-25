#import "H2TestController.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>

@interface H2TestController ()
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *values;
@end

@implementation H2TestController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DeviceTest";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshValues)];
    [self refreshValues];
}

- (void)refreshValues {
    UIDevice *device = UIDevice.currentDevice;
    char model[128] = {0};
    size_t modelSize = sizeof(model);
    NSString *machine = sysctlbyname("hw.machine", model, &modelSize, NULL, 0) == 0 ? [NSString stringWithUTF8String:model] : @"(unavailable)";
    struct utsname systemInfo = {0};
    NSString *unameMachine = uname(&systemInfo) == 0 ? [NSString stringWithUTF8String:systemInfo.machine] : @"(unavailable)";
    self.values = @[
        @[@"Device name", device.name ?: @"(nil)"],
        @[@"Model", device.model ?: @"(nil)"],
        @[@"System version", device.systemVersion ?: @"(nil)"],
        @[@"Identifier for vendor", device.identifierForVendor.UUIDString ?: @"(nil)"],
        @[@"Hardware model (sysctl)", machine ?: @"(nil)"],
        @[@"Hardware model (uname)", unameMachine ?: @"(nil)"]
    ];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.values.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = self.values[indexPath.row][0];
    cell.detailTextLabel.text = self.values[indexPath.row][1];
    cell.detailTextLabel.numberOfLines = 2;
    return cell;
}
@end
