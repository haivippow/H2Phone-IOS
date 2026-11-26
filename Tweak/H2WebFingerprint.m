#import "H2WebFingerprint.h"
#import <objc/runtime.h>

static NSString * const H2ScriptMarker = @"/* H2PHONE fingerprint */";
static char H2FingerprintAppliedKey;

static NSString *H2JSONValue(id value, NSString *fallback) {
    if (([value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSArray.class]) &&
        ![NSJSONSerialization isValidJSONObject:value]) return fallback;
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
    @"/* H2PHONE fingerprint */"
    @"(function(){try{"
    @"var n=__H2_PAYLOAD__;"
    @"var s=window.__h2phoneFingerprint;"
    @"if(s){s.enabled=true;s.seed=n.seed;s.userAgent=n.userAgent;s.profile=n.profile;if(s.installed)return;}"
    @"else{s={enabled:true,installed:false,seed:n.seed,userAgent:n.userAgent,profile:n.profile};"
    @"Object.defineProperty(window,'__h2phoneFingerprint',{value:s,configurable:true});}"
    @"s.installed=true;s.restorers=[];"
    @"s.disable=function(){if(!s.installed){s.enabled=false;return;}s.enabled=false;"
    @"for(var i=s.restorers.length-1;i>=0;i--){try{s.restorers[i]();}catch(e){}}"
    @"s.restorers=[];s.installed=false;};"
    @"function remember(o,k){if(!o)return;var own=Object.prototype.hasOwnProperty.call(o,k);"
    @"var d=own?Object.getOwnPropertyDescriptor(o,k):null;s.restorers.push(function(){"
    @"try{if(own)Object.defineProperty(o,k,d);else delete o[k];}catch(e){}});}"
    @"function nativeValue(o,k){var v=Reflect.get(o,k,o);return typeof v==='function'?v.bind(o):v;}"
    @"function prop(o,k,f){var d=Object.getOwnPropertyDescriptor(o,k);if(!d||!d.configurable)return;"
    @"s.restorers.push(function(){try{Object.defineProperty(o,k,d);}catch(e){}});"
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
    @"remember(Intl.DateTimeFormat.prototype,'resolvedOptions');"
    @"Intl.DateTimeFormat.prototype.resolvedOptions=function(){var r=ro.apply(this,arguments);"
    @"if(s.enabled)r.timeZone='Asia/Ho_Chi_Minh';return r;};}"
    @"var tz=Date.prototype.getTimezoneOffset;"
    @"remember(Date.prototype,'getTimezoneOffset');"
    @"Date.prototype.getTimezoneOffset=function(){return s.enabled?-420:tz.apply(this,arguments);};"
    @"function noise(a,salt,first){if(!s.enabled||!a||!a.length)return a;var i=first?0:(s.seed*131+(salt||0)*17)%a.length;"
    @"if(typeof a[i]==='number')a[i]=a[i]+(((s.seed+(salt||0))%7)+1)*1e-7;return a;}"
    @"if(typeof CanvasRenderingContext2D!=='undefined'){"
    @"var get=CanvasRenderingContext2D.prototype.getImageData;"
    @"remember(CanvasRenderingContext2D.prototype,'getImageData');"
    @"CanvasRenderingContext2D.prototype.getImageData=function(){var d=get.apply(this,arguments);"
    @"if(s.enabled&&d.data.length>=4){d.data[0]^=s.seed;if(!d.data[3])d.data[3]=1;}return d;};"
    @"if(typeof HTMLCanvasElement!=='undefined'){var url=HTMLCanvasElement.prototype.toDataURL;"
    @"remember(HTMLCanvasElement.prototype,'toDataURL');"
    @"HTMLCanvasElement.prototype.toDataURL=function(){if(!s.enabled||!this.width||!this.height)return url.apply(this,arguments);"
    @"var c=this.getContext('2d');if(!c)return url.apply(this,arguments);"
    @"var p;try{p=get.call(c,0,0,1,1);}catch(e){return url.apply(this,arguments);}"
    @"var q=get.call(c,0,0,1,1);q.data[0]^=s.seed;if(!q.data[3])q.data[3]=1;"
    @"try{c.putImageData(q,0,0);return url.apply(this,arguments);}"
    @"finally{c.putImageData(p,0,0);}};"
    @"var blob=HTMLCanvasElement.prototype.toBlob;if(blob){remember(HTMLCanvasElement.prototype,'toBlob');HTMLCanvasElement.prototype.toBlob=function(cb){"
    @"if(!s.enabled||!this.width||!this.height)return blob.apply(this,arguments);"
    @"var clone=document.createElement('canvas');clone.width=this.width;clone.height=this.height;"
    @"var cc=clone.getContext('2d');cc.drawImage(this,0,0);var z=cc.getImageData(0,0,1,1);"
    @"z.data[0]^=s.seed;if(!z.data[3])z.data[3]=1;cc.putImageData(z,0,0);"
    @"return blob.call(clone,cb,arguments[1],arguments[2]);};}}}"
    @"if(typeof OffscreenCanvasRenderingContext2D!=='undefined'){var og=OffscreenCanvasRenderingContext2D.prototype.getImageData;"
    @"remember(OffscreenCanvasRenderingContext2D.prototype,'getImageData');"
    @"OffscreenCanvasRenderingContext2D.prototype.getImageData=function(){var d=og.apply(this,arguments);"
    @"if(s.enabled&&d.data.length>=4){d.data[0]^=s.seed;if(!d.data[3])d.data[3]=1;}return d;};}"
    @"var audioSeen=typeof WeakSet==='undefined'?null:new WeakSet();"
    @"function audio(C){if(typeof C==='undefined')return;var gd=C.prototype.getChannelData;if(gd){remember(C.prototype,'getChannelData');C.prototype.getChannelData=function(ch){"
    @"var a=gd.apply(this,arguments);if(s.enabled&&(!audioSeen||!audioSeen.has(a))){noise(a,ch);if(audioSeen)audioSeen.add(a);}return a;};}var cf=C.prototype.copyFromChannel;"
    @"if(cf){remember(C.prototype,'copyFromChannel');C.prototype.copyFromChannel=function(dst,ch){var r=cf.apply(this,arguments);if(s.enabled)noise(dst,ch,true);return r;};}}"
    @"audio(typeof AudioBuffer==='undefined'?undefined:AudioBuffer);"
    @"if(typeof CanvasRenderingContext2D!=='undefined'){var mt=CanvasRenderingContext2D.prototype.measureText;"
    @"remember(CanvasRenderingContext2D.prototype,'measureText');"
    @"CanvasRenderingContext2D.prototype.measureText=function(){var r=mt.apply(this,arguments);if(!s.enabled)return r;"
    @"var horizontal={width:1,actualBoundingBoxLeft:1,actualBoundingBoxRight:1,fontBoundingBoxAscent:0,fontBoundingBoxDescent:0};"
    @"return new Proxy(r,{get:function(o,k){var v=nativeValue(o,k);return horizontal[k]?v+(s.seed%10)*0.001:v;}});};}"
    @"if(typeof document!=='undefined'&&document.fonts&&document.fonts.check){var fc=document.fonts.check.bind(document.fonts);remember(document.fonts,'check');document.fonts.check=function(font,text){"
    @"if(!s.enabled)return fc(font,text);var f=String(font).toLowerCase();"
    @"return /(^|\\s)(-apple-system|arial|helvetica|sans-serif|serif|monospace)(\\s|$)/.test(f);};}"
    @"function codec(t){t=String(t||'').toLowerCase();if(/(mp4|m4a|aac|avc1|h264|hevc|hvc1|mp3)/.test(t))return 'probably';return ''; }"
    @"if(typeof HTMLMediaElement!=='undefined'){var cp=HTMLMediaElement.prototype.canPlayType;"
    @"remember(HTMLMediaElement.prototype,'canPlayType');"
    @"HTMLMediaElement.prototype.canPlayType=function(t){return s.enabled?codec(t):cp.apply(this,arguments);};}"
    @"if(typeof MediaSource!=='undefined'&&MediaSource.isTypeSupported){var mis=MediaSource.isTypeSupported;"
    @"remember(MediaSource,'isTypeSupported');"
    @"MediaSource.isTypeSupported=function(t){return s.enabled?!!codec(t):mis.apply(this,arguments);};}"
    @"if(navigator.mediaCapabilities&&navigator.mediaCapabilities.decodingInfo){var di=navigator.mediaCapabilities.decodingInfo.bind(navigator.mediaCapabilities);"
    @"remember(navigator.mediaCapabilities,'decodingInfo');"
    @"navigator.mediaCapabilities.decodingInfo=function(c){if(!s.enabled)return di(c);var t=(c.video&&c.video.contentType)||(c.audio&&c.audio.contentType)||'';"
    @"var ok=!!codec(t);return Promise.resolve({supported:ok,smooth:ok,powerEfficient:ok});};}"
    @"if(navigator.permissions&&navigator.permissions.query){var pq=navigator.permissions.query.bind(navigator.permissions);"
    @"remember(navigator.permissions,'query');"
    @"navigator.permissions.query=function(q){return pq(q).then(function(r){if(!s.enabled)return r;"
    @"return new Proxy(r,{get:function(o,k){return k==='state'?'prompt':nativeValue(o,k);}});});};}"
    @"if(navigator.mediaDevices&&navigator.mediaDevices.enumerateDevices){var ed=navigator.mediaDevices.enumerateDevices.bind(navigator.mediaDevices);"
    @"remember(navigator.mediaDevices,'enumerateDevices');"
    @"navigator.mediaDevices.enumerateDevices=function(){if(!s.enabled)return ed();return Promise.resolve(["
    @"{deviceId:'default',groupId:'h2-audio',kind:'audioinput',label:''},"
    @"{deviceId:'default',groupId:'h2-video',kind:'videoinput',label:''},"
    @"{deviceId:'default',groupId:'h2-output',kind:'audiooutput',label:''}]);};}"
    @"if(typeof RTCIceCandidate!=='undefined'){var cd=Object.getOwnPropertyDescriptor(RTCIceCandidate.prototype,'candidate');"
    @"if(cd&&cd.configurable){remember(RTCIceCandidate.prototype,'candidate');Object.defineProperty(RTCIceCandidate.prototype,'candidate',{configurable:true,enumerable:cd.enumerable,get:function(){"
    @"var v=cd.get.call(this);return s.enabled&&/ typ host(?: |$)/.test(v)?'':v;}});}"
    @"var ca=Object.getOwnPropertyDescriptor(RTCIceCandidate.prototype,'address');if(ca&&ca.configurable)"
    @"{remember(RTCIceCandidate.prototype,'address');Object.defineProperty(RTCIceCandidate.prototype,'address',{configurable:true,enumerable:ca.enumerable,get:function(){"
    @"var v=ca.get.call(this);return s.enabled&&this.candidate===''?null:v;}});}"
    @"var cj=RTCIceCandidate.prototype.toJSON;if(cj){remember(RTCIceCandidate.prototype,'toJSON');RTCIceCandidate.prototype.toJSON=function(){var r=cj.apply(this,arguments);"
    @"if(s.enabled&&/ typ host(?: |$)/.test(r.candidate||'')){r.candidate='';r.address=null;}return r;};}}"
    @"function webgl(C){if(typeof C==='undefined')return;var gp=C.prototype.getParameter;"
    @"remember(C.prototype,'getParameter');"
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
    if (!configuration) return;
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
        NSString *currentScript = @"if(window.__h2phoneFingerprint){var s=window.__h2phoneFingerprint;if(typeof s.disable==='function')s.disable();else s.enabled=false;}";
        if (webView.URL) [webView evaluateJavaScript:currentScript completionHandler:nil];
    }
}
