#import "H2WebFingerprint.h"
#import <objc/runtime.h>

static NSString * const H2ScriptMarker = @"/* H2Changer fingerprint */";
static char H2FingerprintAppliedKey;

static NSString *H2JSONValue(id value, NSString *fallback) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingFragmentsAllowed error:nil];
    NSString *literal = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : fallback;
    literal = [literal stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    return [literal stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
}

static NSDictionary<NSString *, id> *H2BrowserProfile(NSDictionary<NSString *, id> *profile) {
    return @{
        @"screenWidth": profile[@"screenWidth"] ?: @0,
        @"screenHeight": profile[@"screenHeight"] ?: @0,
        @"screenScale": profile[@"screenScale"] ?: @1,
        @"cores": profile[@"cores"] ?: @1,
        @"maxTouchPoints": profile[@"maxTouchPoints"] ?: @1,
        @"webglVendor": profile[@"webglVendor"] ?: @"Apple Inc.",
        @"webglRenderer": profile[@"webglRenderer"] ?: @"Apple GPU"
    };
}

NSString *H2WebFingerprintScript(NSString *userAgent, NSDictionary<NSString *, id> *profile, NSUInteger seed) {
    NSString *source =
    @"/* H2Changer fingerprint */"
    @"(function(){try{"
    @"var n=__H2_PAYLOAD__;"
    @"var s=window.__h2changerFingerprint;"
    @"if(s){s.enabled=true;s.seed=n.seed;s.userAgent=n.userAgent;s.profile=n.profile;return;}"
    @"s={enabled:true,seed:n.seed,userAgent:n.userAgent,profile:n.profile};"
    @"Object.defineProperty(window,'__h2changerFingerprint',{value:s,configurable:true});"
    @"function prop(o,k,f){var d=Object.getOwnPropertyDescriptor(o,k);if(!d||!d.configurable)return;"
    @"Object.defineProperty(o,k,{configurable:true,enumerable:d.enumerable,get:function(){"
    @"return s.enabled?f():d.get?d.get.call(this):d.value;}});}"
    @"prop(Navigator.prototype,'userAgent',function(){return s.userAgent;});"
    @"prop(Navigator.prototype,'appVersion',function(){return s.userAgent.slice(8);});"
    @"prop(Navigator.prototype,'language',function(){return 'vi-VN';});"
    @"prop(Navigator.prototype,'languages',function(){return ['vi-VN','en-US'];});"
    @"prop(Navigator.prototype,'platform',function(){return 'iPhone';});"
    @"prop(Navigator.prototype,'vendor',function(){return 'Apple Computer, Inc.';});"
    @"prop(Navigator.prototype,'hardwareConcurrency',function(){return s.profile.cores;});"
    @"prop(Navigator.prototype,'maxTouchPoints',function(){return s.profile.maxTouchPoints;});"
    @"if(typeof Screen!=='undefined'){"
    @"prop(Screen.prototype,'width',function(){return s.profile.screenWidth;});"
    @"prop(Screen.prototype,'height',function(){return s.profile.screenHeight;});"
    @"prop(Screen.prototype,'availWidth',function(){return s.profile.screenWidth;});"
    @"prop(Screen.prototype,'availHeight',function(){return s.profile.screenHeight;});"
    @"prop(Screen.prototype,'colorDepth',function(){return 24;});"
    @"prop(Screen.prototype,'pixelDepth',function(){return 24;});}"
    @"prop(window,'devicePixelRatio',function(){return s.profile.screenScale;});"
    @"if(typeof Intl!=='undefined'&&Intl.DateTimeFormat){"
    @"var ro=Intl.DateTimeFormat.prototype.resolvedOptions;"
    @"Intl.DateTimeFormat.prototype.resolvedOptions=function(){var r=ro.apply(this,arguments);"
    @"if(s.enabled)r.timeZone='Asia/Ho_Chi_Minh';return r;};}"
    @"var tz=Date.prototype.getTimezoneOffset;"
    @"Date.prototype.getTimezoneOffset=function(){return s.enabled?-420:tz.apply(this,arguments);};"
    @"if(typeof CanvasRenderingContext2D!=='undefined'){"
    @"var get=CanvasRenderingContext2D.prototype.getImageData;"
    @"CanvasRenderingContext2D.prototype.getImageData=function(){var d=get.apply(this,arguments);"
    @"if(s.enabled&&d.data.length>=4){d.data[0]^=s.seed;if(!d.data[3])d.data[3]=1;}return d;};"
    @"if(typeof HTMLCanvasElement!=='undefined'){var url=HTMLCanvasElement.prototype.toDataURL;"
    @"HTMLCanvasElement.prototype.toDataURL=function(){if(!s.enabled||!this.width||!this.height)return url.apply(this,arguments);"
    @"var c=this.getContext('2d');if(!c)return url.apply(this,arguments);"
    @"var p;try{p=get.call(c,0,0,1,1);}catch(e){return url.apply(this,arguments);}"
    @"var q=get.call(c,0,0,1,1);q.data[0]^=s.seed;if(!q.data[3])q.data[3]=1;"
    @"try{c.putImageData(q,0,0);return url.apply(this,arguments);}"
    @"finally{c.putImageData(p,0,0);}};}}"
    @"function webgl(C){if(typeof C==='undefined')return;var gp=C.prototype.getParameter;"
    @"C.prototype.getParameter=function(p){if(s.enabled&&p===37445)return s.profile.webglVendor;"
    @"if(s.enabled&&p===37446)return s.profile.webglRenderer;return gp.apply(this,arguments);};}"
    @"webgl(typeof WebGLRenderingContext==='undefined'?undefined:WebGLRenderingContext);"
    @"webgl(typeof WebGL2RenderingContext==='undefined'?undefined:WebGL2RenderingContext);"
    @"}catch(e){}})();";
    NSDictionary *payload = @{
        @"userAgent": userAgent ?: @"",
        @"profile": H2BrowserProfile(profile ?: @{}),
        @"seed": @(seed & 0xff)
    };
    return [source stringByReplacingOccurrencesOfString:@"__H2_PAYLOAD__" withString:H2JSONValue(payload, @"{}")];
}

void H2ConfigureWebContent(WKWebViewConfiguration *configuration, NSString *userAgent, NSDictionary<NSString *, id> *profile, NSUInteger seed, BOOL enabled) {
    WKUserContentController *controller = configuration.userContentController;
    if (!controller) return;
    NSString *desired = enabled ? H2WebFingerprintScript(userAgent, profile, seed) : nil;
    BOOL hasOld = NO;
    BOOL hasDesired = NO;
    NSMutableArray<WKUserScript *> *otherScripts = [NSMutableArray array];
    for (WKUserScript *script in controller.userScripts) {
        if ([script.source hasPrefix:H2ScriptMarker]) {
            hasOld = YES;
            if ([script.source isEqualToString:desired]) hasDesired = YES;
        } else [otherScripts addObject:script];
    }
    if ((!enabled && !hasOld) || (enabled && hasDesired)) return;
    [controller removeAllUserScripts];
    for (WKUserScript *script in otherScripts) [controller addUserScript:script];
    if (desired) {
        WKUserScript *script = [[WKUserScript alloc] initWithSource:desired injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [controller addUserScript:script];
    }
}

void H2UpdateWebFingerprint(WKWebView *webView, NSString *userAgent, NSDictionary<NSString *, id> *profile, NSUInteger seed, BOOL enabled) {
    BOOL wasApplied = [objc_getAssociatedObject(webView, &H2FingerprintAppliedKey) boolValue];
    H2ConfigureWebContent(webView.configuration, userAgent, profile, seed, enabled);
    if (enabled) {
        objc_setAssociatedObject(webView, &H2FingerprintAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *currentScript = H2WebFingerprintScript(userAgent, profile, seed);
        if (webView.URL) [webView evaluateJavaScript:currentScript completionHandler:nil];
    } else if (wasApplied) {
        objc_setAssociatedObject(webView, &H2FingerprintAppliedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *currentScript = @"if(window.__h2changerFingerprint)window.__h2changerFingerprint.enabled=false;";
        if (webView.URL) [webView evaluateJavaScript:currentScript completionHandler:nil];
    }
}
