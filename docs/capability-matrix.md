# H2Changer capability matrix

This file records what the current source can change, what it changes only partially, and what requires a different component. “Selected process” means Fake is ON and the process bundle ID is enabled in H2Changer.

## Status meanings

- **Supported**: implemented in the current source, subject to on-device verification.
- **Partial**: implemented for named APIs or conditions, but other paths can still expose the original value.
- **Not implemented**: no current hook or component covers it.
- **Outside tweak**: a website/server observes it outside the selected app process; a VPN, proxy, server, or Apple entitlement is required.

## Native app and process information

| Surface | Status | Current behavior and limits |
| --- | --- | --- |
| App selection and global Fake switch | Supported | Hooks return fake values only while Fake is ON and the current bundle ID is selected. H2Changer itself and unrelated Apple apps are excluded. |
| Device name/model/iOS | Supported | Covers `UIDevice` name/model/localizedModel/systemName/systemVersion. |
| Hardware model and board | Supported | Covers `sysctlbyname`, `uname`, and selected MobileGestalt model/board keys. |
| OS version paths | Supported, high risk | Covers `UIDevice`, `NSProcessInfo`, `kern.osproductversion`, Darwin release/version, `uname`, MobileGestalt, and the system `SystemVersion.plist`/bundle. Full-process OS spoofing can make Apple frameworks choose incompatible code paths. |
| IDFV | Supported | Returns the UUID stored in the selected profile. |
| IDFA | Partial | Returns the profile IDFA only when the original ATT result is nonzero. An all-zero ATT result remains all zero. |
| IMEI | Partial | Covers two private MobileGestalt keys. It does not change the modem, baseband, carrier records, or every private IMEI path. |
| RAM and CPU count | Supported | Covers `NSProcessInfo`, `hw.memsize`, `hw.ncpu`, `hw.physicalcpu`, and `hw.logicalcpu`. Real limits, scheduling and performance do not change. |
| Native screen geometry | Intentionally real | `UIScreen` is not hooked because fake native bounds broke Safari keyboard/safe-area layout. Browser JavaScript screen values can still be fake. |
| Battery | Partial | Covers `UIDevice` battery level and state when battery monitoring/API results are available. Other power APIs remain real. |
| Locale and languages | Supported | Covers current/autoupdating locale and preferred languages. Other formatting caches may remain real. |
| Time zone | Supported | Covers local/system time zone and JavaScript time-zone paths. The system clock itself is not changed. |
| GPS | Partial | Covers coordinate, altitude, accuracy, speed and course getters. Timestamps, authorization state and server-derived location can remain real. |
| Carrier and MCC/MNC | Partial | Covers `CTCarrier` name, MCC, MNC and country getters when a carrier object exists. |
| Cellular radio | Supported at API level | Returns LTE and creates a stable synthetic radio-service dictionary entry when the original dictionary is empty. This does not create a real SIM or cellular connection. |
| Motion sensors | Partial | Covers selected accelerometer, gyroscope and device-motion vector getters. Other sensors, timestamps and update cadence remain real. |
| Disk capacity/free space | Partial | Covers `NSFileManager` filesystem attributes and common `NSURL` volume-capacity keys. Raw `statfs`/`statvfs`, quotas and actual allocation remain real. |
| Uptime and boot time | Partial | Covers `NSProcessInfo.systemUptime` and `sysctlbyname("kern.boottime")`. Mach clocks, process start time and timing side channels remain real. |
| Thermal and low-power mode | Partial | Returns nominal thermal state and Low Power Mode off through `NSProcessInfo`. Notifications, battery discharge and performance remain real. |
| Keychain and prior installation state | Not implemented | Existing Keychain items, install identifiers and cached values are not reset or namespaced by profile. |
| App Store receipt and region | Not implemented | Receipt contents, storefront/account region and purchase history remain real. |
| Wi-Fi SSID/BSSID and interfaces | Partial | CaptiveNetwork copy APIs return profile SSID/BSSID and `en0`. NetworkExtension, `getifaddrs`, entitlement checks, MAC/radio state and the actual network remain real. |
| App extensions/helper processes | Not implemented generally | A helper or extension with a different bundle ID is not automatically selected with its parent app. |
| API-call audit tracing | Not implemented | Debug Logs currently record configuration changes, not every fingerprint API/key/caller used by an app. |

## Browser and embedded web content

| Surface | Status | Current behavior and limits |
| --- | --- | --- |
| Safari and WKWebView User-Agent | Supported, experimental | Applies profile UA through `WKWebView.customUserAgent`, document-start JavaScript and selected top-level request paths. Requires target-device verification. |
| HTTP User-Agent in mutable requests | Partial | Replaces explicit UA headers and bulk header dictionaries. Requests that never pass through these mutable setters or use a custom networking stack may remain real. |
| Legacy UIWebView User-Agent | Partial | Covers direct `navigator.userAgent` evaluation and UIWebView load requests. Compound/custom scripts and alternative engines may bypass it. |
| Cached User-Agent | Partial | Covers common `NSUserDefaults` keys `UserAgent` and `User-Agent`. Custom keys, files, databases, Keychain and encrypted caches remain untouched. |
| JavaScript language/time zone/platform | Supported | Overrides navigator language/languages/platform/vendor and common time-zone APIs at document start. |
| JavaScript screen/DPR | Supported | Overrides `screen` dimensions and `devicePixelRatio` without changing native UIKit layout. |
| JavaScript CPU/touch values | Supported | Overrides `hardwareConcurrency` and `maxTouchPoints` when Safari exposes configurable descriptors. |
| Canvas fingerprint | Partial | Covers 2D `getImageData`, `toDataURL`, `toBlob`, and OffscreenCanvas 2D `getImageData`. WebGL readback, image encoding differences and other paths can remain real. |
| WebGL fingerprint | Partial | Covers debug vendor/renderer parameters for WebGL/WebGL2. Extensions, limits, precision, shaders and rendered output can still expose the real engine/GPU. |
| AudioContext fingerprint | Partial | Perturbs `AudioBuffer.getChannelData` once per returned typed array and reapplies deterministic noise after each `copyFromChannel` copy without cumulative drift. Nodes, timing, hardware output and alternative readback paths remain real. |
| Font fingerprint | Partial | Stabilizes Canvas text width and `document.fonts.check` results. Installed fonts, glyph rasterization and DOM layout can still expose the real environment. |
| Media codecs/capabilities | Partial | Stabilizes common `canPlayType`, `MediaSource.isTypeSupported`, and decoding `MediaCapabilities` results. Real decode behavior and encoding paths remain real. |
| Permissions and media devices | Partial | Permission queries report `prompt` and enumeration returns deterministic unlabeled devices. Actual prompts, capture results, authorization and native AVFoundation remain real. |
| WebRTC | Partial | Redacts host ICE candidate/address getters and JSON output. Server-reflexive/relay candidates, SDP paths, public IP and WebRTC engine capabilities remain real. |
| WebKit engine behavior | Cannot be fully changed | Feature support, bugs, rendering, JavaScript engine and API availability still correspond to the installed iOS/WebKit version. |

## Network and server-side identity

| Surface | Status | Requirement/limit |
| --- | --- | --- |
| Local IP | Not implemented | Network interface addresses remain real. WebRTC host-candidate redaction only covers selected JavaScript getters and is not an interface-address change. |
| Public IP and geolocation | Outside tweak | Requires VPN/proxy routing; servers see the actual egress IP otherwise. |
| DNS resolver and DNS leaks | Outside tweak | Requires DNS/VPN configuration and leak protection. |
| TLS/JA3/JA4 fingerprint | Outside tweak | Requires a compatible proxy/network stack; WebKit/CFNetwork TLS behavior remains real. |
| DeviceCheck and App Attest | Outside ordinary hooks | Apple/server validation can bind results to the real device and app. Bypassing it reliably is not provided. |
| Push/APNs identity | Not implemented | Device tokens and server associations remain real. |
| Server-side account/device cache | Outside tweak | Previously collected fingerprints, account history and risk scores remain on the service. |
| VPN/proxy component | Not implemented | This repository currently contains no VPN tunnel, proxy client or companion server. |

## Verification rule

An API-level fake is considered verified only after comparing Fake OFF, Fake ON, profile switching, and Restore Original on the target iPhone. A matching value in DeviceTest proves only that named API path; it does not prove that every third-party app or server sees the same result.

For an already-open document, Fake OFF invokes the injected state's `disable()` routine, restores saved JavaScript descriptors/methods in reverse order, and removes the H2 user script from future navigations. Re-enabling can install the wrappers again in the same document. Native hooks call their original implementation for subsequent queries while disabled; values an app already cached remain the app's responsibility.
