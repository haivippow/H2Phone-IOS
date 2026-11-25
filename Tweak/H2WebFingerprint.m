#import "H2WebFingerprint.h"

static NSString * const H2ScriptMarker = @"/* H2Changer fingerprint */";

static NSString *H2Script(NSString *userAgent, NSUInteger seed) {
    NSString *source =
    @"/* H2Changer fingerprint */"
    @"(function(){try{"
    @"var s=window.__h2changerFingerprint;"
    @"if(s){s.enabled=true;s.seed=__SEED__;s.userAgent='__UA__';return;}"
    @"s={enabled:true,seed:__SEED__,userAgent:'__UA__'};"
    @"Object.defineProperty(window,'__h2changerFingerprint',{value:s,configurable:true});"
    @"function prop(o,k,f){var d=Object.getOwnPropertyDescriptor(o,k);if(!d||!d.configurable)return;"
    @"Object.defineProperty(o,k,{configurable:true,enumerable:d.enumerable,get:function(){"
    @"return s.enabled?f():d.get?d.get.call(this):d.value;}});}"
    @"prop(Navigator.prototype,'userAgent',function(){return s.userAgent;});"
    @"prop(Navigator.prototype,'appVersion',function(){return s.userAgent.slice(8);});"
    @"prop(Navigator.prototype,'language',function(){return 'vi-VN';});"
    @"prop(Navigator.prototype,'languages',function(){return ['vi-VN','en-US'];});"
    @"prop(Navigator.prototype,'platform',function(){return 'iPhone';});"
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
    @"}catch(e){}})();";
    source = [source stringByReplacingOccurrencesOfString:@"__SEED__" withString:[NSString stringWithFormat:@"%lu", (unsigned long)(seed & 0xff)]];
    return [source stringByReplacingOccurrencesOfString:@"__UA__" withString:userAgent ?: @""];
}

void H2UpdateWebFingerprint(WKWebView *webView, NSString *userAgent, NSUInteger seed, BOOL enabled) {
    WKUserContentController *controller = webView.configuration.userContentController;
    if (!controller) return;
    NSString *desired = enabled ? H2Script(userAgent, seed) : nil;
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
    if (webView.URL) [webView evaluateJavaScript:desired ?: @"if(window.__h2changerFingerprint)window.__h2changerFingerprint.enabled=false;" completionHandler:nil];
}
