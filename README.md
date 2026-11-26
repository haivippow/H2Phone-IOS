# H2Changer-iOS

Native iPhone controller and isolated API test tweak for iPhone XS on iOS 16.1 with Dopamine rootless. The repository is independent of H2PHONE Android.

## Modules

- `App/`: UIKit controller with Dashboard, installed user app selection, Profiles, Fake ON/OFF, Restore Original, and Debug Logs.
- `Tweak/`: Logos hook, loaded in UIKit apps with a per-app allowlist check before returning fake values.
- `App/H2ConfigManager.*`: file-based Config Manager; a future C# agent can write the same schema.
- `DeviceTest/`: real UIKit app showing values returned by `UIDevice` APIs.
- `Scripts/`: local structure verification.
- `docs/`: build, installation, and architecture notes.

See [docs/capability-matrix.md](docs/capability-matrix.md) for the complete implemented/partial/not-implemented coverage matrix and known limits.

The tweak changes values returned inside selected apps for `UIDevice.name`, `model`, `systemVersion`, and `identifierForVendor`. It also covers `NSProcessInfo` OS version, `sysctlbyname` model/board/iOS version, `uname` machine, and selected MobileGestalt answers (`HardwareModel`, `ProductType`, `ProductVersion`). Fake OFF and unselected apps call the original methods. DeviceTest is selected by default. It never writes hardware identifiers or system settings. The package installs both apps and the tweak as a rootless `.deb` via Sileo. TrollStore is part of the target environment but is not needed for this package; it does not inject the tweak.

Profiles include iPhone 13 Pro Max (iOS 17.7), 14 Pro Max (iOS 17.6), 15 Pro Max (iOS 18.0), and 16 Pro Max (iOS 18.1). Each profile returns its matching model identifier through `sysctlbyname("hw.machine")` and `uname` inside selected apps. DeviceTest shows both values for verification. Fake OFF returns the original API values. These values do not upgrade the actual iOS installation.

Safari appears in Test Apps and can be selected explicitly. The tweak attaches its `WKUserScript` to Safari's `WKWebViewConfiguration` before the web view is initialized; WebKit then transfers that document-start script to the separate WebContent process. It also applies the profile User-Agent to Safari loads while Fake is ON and restores the prior custom User-Agent after Fake is turned OFF. Both `navigator.userAgent` and the HTTP User-Agent header still require on-device verification.

Apps such as AIDA64 may read other APIs or cache results. Selecting an app does not guarantee that every value it displays changes. DeviceTest now shows separate readings from the added APIs so remaining gaps can be identified on the phone.

Version 0.1.10 adds selected-app hooks for IDFA (only when ATT already exposes a nonzero identifier), GPS coordinates (Hanoi), Vietnamese locale/time zone, Viettel carrier fields, LTE radio technology, battery level/state, and selected CoreMotion vectors. Public IP, IMEI, and full web fingerprinting are not spoofed by these hooks.

Version 0.1.11 adds synthetic primary/secondary IMEI responses for the MobileGestalt API inside selected apps, plus experimental JavaScript language/time-zone/User-Agent and Canvas readout overrides in selected apps' `WKWebView` pages. DeviceTest reads the IMEI keys and shows additional native/WebKit API values for comparison. These changes do not alter the modem IMEI and do not cover every browser fingerprint surface.

Version 0.1.12 replaces the tiny background DeviceTest WebKit probe with a visible table header and shows navigation, JavaScript, process termination, or timeout errors per row.

Version 0.1.12 also aligns `navigator.appVersion` with the selected iOS profile and sets the top-level WebKit request's User-Agent header. These affect values reported to websites, not the installed Safari/WebKit engine; a website can still detect iOS 16.1 through engine behavior.

The current source safely JSON-encodes profile-controlled User-Agent text before embedding it in JavaScript and installs the fingerprint script before `WKWebView` initialization so the first document can receive it at document start. It does not call `WKUserContentController` from inside the WebContent process or hook version-specific WebKit C++ internals.

Selected apps now consume one expanded profile for native model/OS identifiers, RAM/CPU, carrier, location and battery values. Native `UIScreen` geometry stays real so keyboards, safe areas and responsive layouts remain correct. Their `WKWebView` pages consume profile screen/DPR values only inside JavaScript, together with CPU/touch counts, WebGL identity, User-Agent, locale/time zone and Canvas output. These are API-level overrides only; actual hardware, resource limits, WebKit engine, TLS and public IP remain unchanged.

Full-process mode also overrides Darwin/kernel version, SystemVersion plist/bundle reads, legacy UIWebView User-Agent queries, common cached User-Agent keys, and mutable request User-Agent headers for selected processes. This intentionally exposes the fake OS version to Apple frameworks inside that process and can make WebKit/UIKit take incompatible code paths; the user accepted that stability risk. Native screen geometry remains the safety exception.

## Quick start

Run setup and build commands using [docs/build-install.md](docs/build-install.md). On WSL2 Ubuntu 24.04, run `bash Scripts/build.sh`. A rootless `.deb` has been built in `packages/`; installation and behavior on an iPhone have not yet been tested.
