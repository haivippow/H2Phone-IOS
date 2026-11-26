#import "H2TestController.h"
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <dlfcn.h>
#import <AdSupport/AdSupport.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreMotion/CoreMotion.h>
#import <WebKit/WebKit.h>

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

@interface H2TestController () <CLLocationManagerDelegate, WKNavigationDelegate>
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *values;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) WKWebView *webProbe;
@property (nonatomic, strong) WKNavigation *webNavigation;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *webValues;
@property (nonatomic, copy) NSString *webProbeStatus;
@property (nonatomic) NSUInteger webProbeGeneration;
@end

@implementation H2TestController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DeviceTest";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAll)];
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    self.motionManager = [CMMotionManager new];
    if (self.motionManager.accelerometerAvailable) [self.motionManager startAccelerometerUpdates];
    if (self.motionManager.deviceMotionAvailable) [self.motionManager startDeviceMotionUpdates];
    self.webProbe = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 56) configuration:[WKWebViewConfiguration new]];
    self.webProbe.navigationDelegate = self;
    self.tableView.tableHeaderView = self.webProbe;
    [self beginWebProbe];
    [self refreshValues];
}

- (void)refreshAll {
    [self refreshValues];
    [self beginWebProbe];
}

- (void)beginWebProbe {
    self.webProbeGeneration++;
    NSUInteger generation = self.webProbeGeneration;
    self.webProbeStatus = @"Loading WebKit page";
    self.webValues = @{ @"ua": @"(loading)", @"appVersion": @"(loading)", @"language": @"(loading)", @"timezone": @"(loading)", @"screen": @"(loading)", @"hardware": @"(loading)", @"webgl": @"(loading)", @"canvas": @"(loading)" };
    self.webNavigation = [self.webProbe loadHTMLString:@"<html><head><meta name='viewport' content='width=device-width,initial-scale=1'></head><body style='font:14px -apple-system;padding:4px'>WebKit API probe</body></html>" baseURL:nil];
    [self refreshValues];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (generation != self.webProbeGeneration) return;
        if ([self.webProbeStatus isEqualToString:@"Loading WebKit page"]) {
            self.webProbeStatus = @"WebKit timeout: no navigation callback";
            [self setWebProbeError:self.webProbeStatus];
        } else {
            NSMutableDictionary *updated = [self.webValues mutableCopy];
            BOOL timedOut = NO;
            for (NSString *key in @[@"ua", @"appVersion", @"language", @"timezone", @"screen", @"hardware", @"webgl", @"canvas"]) {
                if ([updated[key] isEqualToString:@"(loading)"]) {
                    updated[key] = @"(JavaScript timeout)";
                    timedOut = YES;
                }
            }
            if (timedOut) {
                self.webProbeStatus = @"WebKit loaded; JavaScript timeout";
                self.webValues = updated;
                [self refreshValues];
            }
        }
    });
}

- (void)setWebProbeError:(NSString *)message {
    self.webValues = @{ @"ua": message, @"appVersion": message, @"language": message, @"timezone": message, @"screen": message, @"hardware": message, @"webgl": message, @"canvas": message };
    [self refreshValues];
}

- (void)runWebScript:(NSString *)script key:(NSString *)key {
    NSUInteger generation = self.webProbeGeneration;
    [self.webProbe evaluateJavaScript:script completionHandler:^(id value, NSError *error) {
        if (generation != self.webProbeGeneration) return;
        NSMutableDictionary *updated = [self.webValues mutableCopy] ?: [NSMutableDictionary dictionary];
        updated[key] = error ? error.localizedDescription : ([value description] ?: @"(nil)");
        self.webValues = updated;
        [self refreshValues];
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (self.webNavigation && navigation != self.webNavigation) return;
    self.webProbeStatus = @"WebKit loaded";
    [self runWebScript:@"navigator.userAgent" key:@"ua"];
    [self runWebScript:@"navigator.appVersion" key:@"appVersion"];
    [self runWebScript:@"navigator.language" key:@"language"];
    [self runWebScript:@"Intl.DateTimeFormat().resolvedOptions().timeZone" key:@"timezone"];
    [self runWebScript:@"screen.width+'x'+screen.height+' @'+devicePixelRatio+'x'" key:@"screen"];
    [self runWebScript:@"navigator.hardwareConcurrency+' cores / '+navigator.maxTouchPoints+' touches'" key:@"hardware"];
    [self runWebScript:@"(function(){var c=document.createElement('canvas');var g=c.getContext('webgl');if(!g)return '(unavailable)';var e=g.getExtension('WEBGL_debug_renderer_info');return e?g.getParameter(e.UNMASKED_VENDOR_WEBGL)+' / '+g.getParameter(e.UNMASKED_RENDERER_WEBGL):'(extension unavailable)';})()" key:@"webgl"];
    [self runWebScript:@"(function(){var c=document.createElement('canvas');c.width=200;c.height=40;var x=c.getContext('2d');x.font='16px Arial';x.fillText('H2Canvas',8,24);var s=c.toDataURL();var h=2166136261;for(var i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return (h>>>0).toString(16);})()" key:@"canvas"];
    [self refreshValues];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.webNavigation && navigation != self.webNavigation) return;
    self.webProbeStatus = [@"WebKit load failed: " stringByAppendingString:error.localizedDescription];
    [self setWebProbeError:self.webProbeStatus];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.webNavigation && navigation != self.webNavigation) return;
    self.webProbeStatus = [@"WebKit start failed: " stringByAppendingString:error.localizedDescription];
    [self setWebProbeError:self.webProbeStatus];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    self.webProbeStatus = @"WebKit content process terminated";
    [self setWebProbeError:self.webProbeStatus];
}

- (void)dealloc {
    [self.locationManager stopUpdatingLocation];
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopDeviceMotionUpdates];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self refreshValues];
}

- (void)refreshValues {
    UIDevice *device = UIDevice.currentDevice;
    NSString *machine = H2SysctlValue("hw.machine");
    struct utsname systemInfo = {0};
    NSString *unameMachine = uname(&systemInfo) == 0 ? [NSString stringWithUTF8String:systemInfo.machine] : @"(unavailable)";
    CLLocation *location = self.locationManager.location;
    NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *gps = location ? [NSString stringWithFormat:@"%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude] : @"(permission/location unavailable)";
    CTCarrier *carrier = [CTTelephonyNetworkInfo new].subscriberCellularProvider;
    CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
    NSString *motion = self.motionManager.accelerometerData ? [NSString stringWithFormat:@"%.2f, %.2f, %.2f", acceleration.x, acceleration.y, acceleration.z] : @"(waiting for sensor)";
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
        @[@"Darwin (sysctl)", H2SysctlValue("kern.osrelease")],
        @[@"SystemVersion.plist", [NSString stringWithFormat:@"%@ (%@)", systemVersion[@"ProductVersion"] ?: @"-", systemVersion[@"ProductBuildVersion"] ?: @"-"]],
        @[@"Cached UserAgent", [NSUserDefaults.standardUserDefaults stringForKey:@"UserAgent"] ?: @"(nil)"],
        @[@"RAM / CPU", [NSString stringWithFormat:@"%.0f MB / %lu cores", NSProcessInfo.processInfo.physicalMemory / 1048576.0, (unsigned long)NSProcessInfo.processInfo.processorCount]],
        @[@"Native layout (kept real)", [NSString stringWithFormat:@"%.0fx%.0f @%.1fx", UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.scale]],
        @[@"Native panel (kept real)", [NSString stringWithFormat:@"%.0fx%.0f", UIScreen.mainScreen.nativeBounds.size.width, UIScreen.mainScreen.nativeBounds.size.height]],
        @[@"Board (MobileGestalt)", H2GestaltValue(CFSTR("HardwareModel"))],
        @[@"iOS (MobileGestalt)", H2GestaltValue(CFSTR("ProductVersion"))],
        @[@"IMEI 1 (MobileGestalt)", H2GestaltValue(CFSTR("InternationalMobileEquipmentIdentity"))],
        @[@"IMEI 2 (MobileGestalt)", H2GestaltValue(CFSTR("InternationalMobileEquipmentIdentity2"))],
        @[@"IDFA (ATT dependent)", ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString ?: @"(unavailable)"],
        @[@"GPS (CoreLocation)", gps],
        @[@"Locale", NSLocale.currentLocale.localeIdentifier],
        @[@"Time zone", NSTimeZone.localTimeZone.name],
        @[@"Carrier", carrier.carrierName ?: @"(no carrier)"],
        @[@"MCC / MNC", [NSString stringWithFormat:@"%@ / %@", carrier.mobileCountryCode ?: @"-", carrier.mobileNetworkCode ?: @"-"]],
        @[@"Radio", [CTTelephonyNetworkInfo new].currentRadioAccessTechnology ?: @"(unavailable)"],
        @[@"Battery", device.batteryLevel >= 0 ? [NSString stringWithFormat:@"%.0f%%", device.batteryLevel * 100] : @"(unavailable)"],
        @[@"Accelerometer", motion],
        @[@"WebKit probe", self.webProbeStatus ?: @"(starting)"],
        @[@"Web UA (JavaScript)", self.webValues[@"ua"] ?: @"(loading)"],
        @[@"Web appVersion", self.webValues[@"appVersion"] ?: @"(loading)"],
        @[@"Web language", self.webValues[@"language"] ?: @"(loading)"],
        @[@"Web time zone", self.webValues[@"timezone"] ?: @"(loading)"],
        @[@"Web screen", self.webValues[@"screen"] ?: @"(loading)"],
        @[@"Web hardware", self.webValues[@"hardware"] ?: @"(loading)"],
        @[@"WebGL", self.webValues[@"webgl"] ?: @"(loading)"],
        @[@"Canvas hash", self.webValues[@"canvas"] ?: @"(loading)"]
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
