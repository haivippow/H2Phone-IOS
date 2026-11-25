#import "H2TestController.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <dlfcn.h>

static NSString *H2SysctlValue(const char *key) {
    char value[128] = {0};
    size_t size = sizeof(value);
    return sysctlbyname(key, value, &size, NULL, 0) == 0 ? [NSString stringWithUTF8String:value] : @"(unavailable)";
}

static NSString *H2GestaltValue(CFStringRef key) {
    void *library = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    CFTypeRef (*copyAnswer)(CFStringRef) = library ? dlsym(library, "MGCopyAnswer") : NULL;
    if (!copyAnswer) return @"(unavailable)";
    CFTypeRef answer = copyAnswer(key);
    if (!answer) return @"(unavailable)";
    NSString *value = [(__bridge id)answer description];
    CFRelease(answer);
    return value;
}

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
    NSString *machine = H2SysctlValue("hw.machine");
    struct utsname systemInfo = {0};
    NSString *unameMachine = uname(&systemInfo) == 0 ? [NSString stringWithUTF8String:systemInfo.machine] : @"(unavailable)";
    self.values = @[
        @[@"Device name", device.name ?: @"(nil)"],
        @[@"Model", device.model ?: @"(nil)"],
        @[@"System version", device.systemVersion ?: @"(nil)"],
        @[@"Identifier for vendor", device.identifierForVendor.UUIDString ?: @"(nil)"],
        @[@"Hardware model (sysctl)", machine ?: @"(nil)"],
        @[@"Hardware model (uname)", unameMachine ?: @"(nil)"],
        @[@"Board (sysctl)", H2SysctlValue("hw.model")],
        @[@"iOS (sysctl)", H2SysctlValue("kern.osproductversion")],
        @[@"iOS (NSProcessInfo)", NSProcessInfo.processInfo.operatingSystemVersionString],
        @[@"Board (MobileGestalt)", H2GestaltValue(CFSTR("HardwareModel"))],
        @[@"iOS (MobileGestalt)", H2GestaltValue(CFSTR("ProductVersion"))]
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
