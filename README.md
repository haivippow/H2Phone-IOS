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

Safari appears in Test Apps and can be selected explicitly. The current hooks affect native API reads in the Safari app process; web pages run in separate WebKit processes and JavaScript fingerprint values are outside this MVP.

Apps such as AIDA64 may read other APIs or cache results. Selecting an app does not guarantee that every value it displays changes. DeviceTest now shows separate readings from the added APIs so remaining gaps can be identified on the phone.

## Quick start

Run setup and build commands using [docs/build-install.md](docs/build-install.md). On WSL2 Ubuntu 24.04, run `bash Scripts/build.sh`. A rootless `.deb` has been built in `packages/`; installation and behavior on an iPhone have not yet been tested.
