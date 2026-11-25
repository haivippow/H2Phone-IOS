# Spoof coverage (0.1.10)

The tweak checks Fake ON and the current app bundle ID before returning profile values. Fake OFF calls the original API. Build and on-device status must be checked separately.

| Surface | Source behavior | Limit |
| --- | --- | --- |
| Model / board / iOS | `UIDevice`, `NSProcessInfo`, `sysctlbyname`, `uname`, selected MobileGestalt keys | Other system paths may remain real. |
| IDFV | Profile UUID from `UIDevice.identifierForVendor` | Same UUID is used across selected apps for the same profile. |
| IDFA | Profile UUID from `ASIdentifierManager.advertisingIdentifier` | All-zero value remains all zeros when tracking access is not granted. |
| GPS | `CLLocation.coordinate` reports 21.0285, 105.8542 (Hanoi) | Does not move the radio or change server-derived location. Other location properties remain original. |
| Locale / time zone | `vi_VN`, `vi-VN`, `Asia/Ho_Chi_Minh` | Does not change all JavaScript or system locale paths. |
| Carrier / cellular radio | Viettel, MCC 452, MNC 04, ISO `vn`, LTE for existing radio services | Does not change SIM, Wi-Fi state, cellular connection, or public IP. |
| Battery | 85% and unplugged when monitoring is enabled | Other battery/power APIs remain original. |
| Motion | Selected acceleration, gravity, and rotation vector getters | Other sensor data and timestamps remain original. |
| Web User-Agent | `WKWebView.customUserAgent` for selected apps | Safari and other apps require on-device verification; canvas and broader fingerprint properties remain original. |

IMEI is not available through the public app APIs used here. A server observes the real public IP unless network traffic is routed through a proxy or VPN. Canvas and full browser fingerprint spoofing need separate WebKit process work and device tests; the current source does not claim them.
