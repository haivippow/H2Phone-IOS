# H2Changer-iOS

Native iPhone controller and isolated API test tweak for iPhone XS on iOS 16.1 with Dopamine rootless. The repository is independent of H2PHONE Android.

## Modules

- `App/`: UIKit controller with Dashboard, installed user app selection, Profiles, Fake ON/OFF, Restore Original, and Debug Logs.
- `Tweak/`: Logos hook, loaded in UIKit apps with a per-app allowlist check before returning fake values.
- `App/H2ConfigManager.*`: file-based Config Manager; a future C# agent can write the same schema.
- `DeviceTest/`: real UIKit app showing values returned by `UIDevice` APIs.
- `Scripts/`: local structure verification.
- `docs/`: build, installation, and architecture notes.

The tweak changes values returned inside selected apps for `UIDevice.name`, `model`, `systemVersion`, and `identifierForVendor`. It also covers `NSProcessInfo` OS version, `sysctlbyname` model/board/iOS version, `uname` machine, and selected MobileGestalt answers (`HardwareModel`, `ProductType`, `ProductVersion`). Fake OFF and unselected apps call the original methods. DeviceTest is selected by default. It never writes hardware identifiers or system settings. The package installs both apps and the tweak as a rootless `.deb` via Sileo. TrollStore is part of the target environment but is not needed for this package; it does not inject the tweak.

Profiles include iPhone 13 Pro Max (iOS 17.7), 14 Pro Max (iOS 17.6), 15 Pro Max (iOS 18.0), and 16 Pro Max (iOS 18.1). Each profile returns its matching model identifier through `sysctlbyname("hw.machine")` and `uname` inside selected apps. DeviceTest shows both values for verification. Fake OFF returns the original API values. These values do not upgrade the actual iOS installation.

Safari appears in Test Apps and can be selected explicitly. Version 0.1.9 applies an experimental Safari `WKWebView` User-Agent override when Safari is selected and Fake is ON, including new loads and reloads. It restores the prior `WKWebView` User-Agent on Fake OFF. Safari uses separate WebKit processes, so both `navigator.userAgent` and the HTTP User-Agent header need on-device verification. Other JavaScript fingerprint values are outside this hook's scope.

Apps such as AIDA64 may read other APIs or cache results. Selecting an app does not guarantee that every value it displays changes. DeviceTest now shows separate readings from the added APIs so remaining gaps can be identified on the phone.

Version 0.1.10 adds selected-app hooks for IDFA (only when ATT already exposes a nonzero identifier), GPS coordinates (Hanoi), Vietnamese locale/time zone, Viettel carrier fields, LTE radio technology, battery level/state, and selected CoreMotion vectors. Public IP, IMEI, and full web fingerprinting are not spoofed by these hooks.

Version 0.1.11 adds synthetic primary/secondary IMEI responses for the MobileGestalt API inside selected apps, plus experimental JavaScript language/time-zone/User-Agent and Canvas readout overrides in selected apps' `WKWebView` pages. DeviceTest reads the IMEI keys and shows additional native/WebKit API values for comparison. These changes do not alter the modem IMEI and do not cover every browser fingerprint surface.

## Quick start

Run setup and build commands using [docs/build-install.md](docs/build-install.md). On WSL2 Ubuntu 24.04, run `bash Scripts/build.sh`. A rootless `.deb` has been built in `packages/`; installation and behavior on an iPhone have not yet been tested.
