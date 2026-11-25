#import <WebKit/WebKit.h>

#ifdef __cplusplus
extern "C" {
#endif
void H2UpdateWebFingerprint(WKWebView *webView, NSString *userAgent, NSUInteger seed, BOOL enabled);
#ifdef __cplusplus
}
#endif
