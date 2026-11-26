# Spoof coverage (0.1.17)

The tweak checks Fake ON and the current app bundle ID before returning profile values. Fake OFF calls the original API. Build and on-device status must be checked separately.

| Surface | Source behavior | Limit |
| --- | --- | --- |
| Model / board / iOS | `UIDevice`, `NSProcessInfo`, `sysctlbyname`, `uname`, selected MobileGestalt keys | Other system paths may remain real. |
| Full-process OS identity | Darwin release/version, `SystemVersion.plist` and `SystemVersion.bundle` reads use the selected profile | Deliberately affects Apple frameworks in the selected process and may cause incompatible code paths or crashes. |
| IDFV | Profile UUID from `UIDevice.identifierForVendor` | Same UUID is used across selected apps for the same profile. |
| IDFA | Profile UUID from `ASIdentifierManager.advertisingIdentifier` | All-zero value remains all zeros when tracking access is not granted. |
| GPS | `CLLocation.coordinate` reports 21.0285, 105.8542 (Hanoi) | Does not move the radio or change server-derived location. Other location properties remain original. |
| Locale / time zone | `vi_VN`, `vi-VN`, `Asia/Ho_Chi_Minh` | Does not change all JavaScript or system locale paths. |
| Carrier / cellular radio | Viettel, MCC 452, MNC 04, ISO `vn`, and LTE; a stable synthetic service entry is returned when the radio-service dictionary is empty | Does not change SIM, Wi-Fi state, cellular connection, or public IP. |
| Battery | 85% and unplugged when monitoring is enabled | Other battery/power APIs remain original. |
| Motion | Selected acceleration, gravity, and rotation vector getters | Other sensor data and timestamps remain original. |
| Memory / CPU | `NSProcessInfo` physical memory and CPU counts plus `hw.memsize`, `hw.ncpu`, `hw.physicalcpu`, and `hw.logicalcpu` | Does not change real resource limits, scheduling, performance, or jetsam behavior. |
| Display | JavaScript `screen` dimensions and DPR use the selected profile; native `UIScreen` stays original | Keeping native geometry real prevents broken keyboards, safe areas, rotations, and app layouts. |
| Web User-Agent | `WKWebView.customUserAgent` for selected apps | Safari and other apps require on-device verification; broader fingerprint properties remain original. |
| Legacy/cached User-Agent | UIWebView JavaScript reads, common `NSUserDefaults` UA keys, mutable request UA headers | Apps can still use custom caches, encrypted storage, server-side values, or helper processes. |
| IMEI 1 / 2 | Synthetic 15-digit values returned for two MobileGestalt IMEI keys in selected apps | Real modem and carrier IMEI are unchanged. Other IMEI APIs are not covered. |
| Web fingerprint | A document-start, all-frames `WKUserScript` overrides JavaScript User-Agent, locale/time zone, screen/DPR, CPU/touch, WebGL identity, common Canvas/blob/OffscreenCanvas and audio samples, font checks/metrics, media capabilities, permission/device enumeration, and host ICE candidate getters | Safari receives the script through its preconfigured web view. This remains API-level and partial: the real WebKit engine, rendering, capture/decode behavior, public IP, TLS and server-side state do not change. Requires on-device verification. |

IMEI is not available through a public app API; the new hook targets private MobileGestalt queries only. A server observes the real public IP unless network traffic is routed through a proxy or VPN. Safari's separate WebKit processes and all browser fingerprint paths still need on-device testing; the current source does not claim full coverage.
