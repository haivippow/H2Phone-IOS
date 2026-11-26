#import <WebKit/WebKit.h>

#ifdef __cplusplus
extern "C" {
#endif
NSString *H2WebFingerprintScript(NSString *userAgent, NSDictionary<NSString *, id> *profile, NSUInteger seed);
void H2ConfigureWebContent(WKWebViewConfiguration *configuration, NSString *userAgent, NSDictionary<NSString *, id> *profile, NSUInteger seed, BOOL enabled);
void H2UpdateWebFingerprint(WKWebView *webView, NSString *userAgent, NSDictionary<NSString *, id> *profile, NSUInteger seed, BOOL enabled);
#ifdef __cplusplus
}
#endif
