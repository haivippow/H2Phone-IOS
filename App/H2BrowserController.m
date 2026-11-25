#import "H2BrowserController.h"
#import "H2ConfigManager.h"
#import <WebKit/WebKit.h>

@interface H2BrowserController () <UITextFieldDelegate, WKNavigationDelegate>
@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *appliedUserAgent;
@end

@implementation H2BrowserController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Web UA";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.addressField = [UITextField new];
    self.addressField.borderStyle = UITextBorderStyleRoundedRect;
    self.addressField.keyboardType = UIKeyboardTypeURL;
    self.addressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.addressField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.addressField.returnKeyType = UIReturnKeyGo;
    self.addressField.placeholder = @"Enter website URL";
    self.addressField.delegate = self;
    self.addressField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.addressField];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
    self.webView.navigationDelegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.addressField.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:12],
        [self.addressField.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-12],
        [self.addressField.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:8],
        [self.addressField.heightAnchor constraintEqualToConstant:38],
        [self.webView.topAnchor constraintEqualToAnchor:self.addressField.bottomAnchor constant:8],
        [self.webView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]
    ]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadPage)];
    [self applyProfile];
    [self showHomePage];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyProfile];
}

- (void)applyProfile {
    NSDictionary *config = [H2ConfigManager.sharedManager snapshot];
    NSString *newUserAgent = nil;
    if ([config[@"enabled"] boolValue]) {
        NSDictionary *profile = [H2ConfigManager profileNamed:config[@"profile"]];
        NSString *version = profile[@"ios"];
        NSString *cpuVersion = [version stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        newUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1", cpuVersion, version];
    }
    if ((self.appliedUserAgent == nil && newUserAgent == nil) || [self.appliedUserAgent isEqualToString:newUserAgent]) return;
    self.appliedUserAgent = newUserAgent;
    self.webView.customUserAgent = newUserAgent;
    if (self.webView.URL) [self.webView reload]; else [self showHomePage];
}

- (void)showHomePage {
    NSString *html = @"<!doctype html><meta name='viewport' content='width=device-width,initial-scale=1'><style>body{font:16px -apple-system;padding:18px;overflow-wrap:anywhere}code{font-size:14px}</style><h2>Web User-Agent</h2><p>JavaScript sees:</p><code id='ua'></code><p><a href='https://httpbin.org/headers'>Check HTTP headers</a></p><script>document.getElementById('ua').textContent=navigator.userAgent</script>";
    [self.webView loadHTMLString:html baseURL:nil];
    self.addressField.text = @"";
}

- (void)reloadPage {
    [self applyProfile];
    if (self.webView.URL) [self.webView reload]; else [self showHomePage];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *input = [textField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!input.length) return NO;
    NSString *address = [input containsString:@"://"] ? input : [@"https://" stringByAppendingString:input];
    NSURL *url = [NSURL URLWithString:address];
    if (url.host.length && ([@"https" isEqualToString:url.scheme.lowercaseString] || [@"http" isEqualToString:url.scheme.lowercaseString])) {
        [self applyProfile];
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([webView.URL.scheme isEqualToString:@"http"] || [webView.URL.scheme isEqualToString:@"https"]) self.addressField.text = webView.URL.absoluteString;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Page could not load" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
