# H2Changer-iOS

Native iPhone controller and isolated API test tweak for iPhone XS on iOS 16.1 with Dopamine rootless. The repository is independent of H2PHONE Android.

## Modules

- `App/`: UIKit controller with Dashboard, Test Apps, Profiles, Fake ON/OFF, Restore Original, and Debug Logs.
- `Tweak/`: Logos hook, filtered to `com.h2phone.devicetest` only.
- `App/H2ConfigManager.*`: file-based Config Manager; a future C# agent can write the same schema.
- `DeviceTest/`: real UIKit app showing values returned by `UIDevice` APIs.
- `Scripts/`: local structure verification.
- `docs/`: build, installation, and architecture notes.

The tweak changes values returned inside DeviceTest for `UIDevice.name`, `model`, `systemVersion`, and `identifierForVendor`. Fake OFF calls the original methods. It never writes hardware identifiers or system settings. The package installs both apps and the tweak as a rootless `.deb` via Sileo. TrollStore is part of the target environment but is not needed for this package; it does not inject the tweak.

## Quick start

Run setup and build commands yourself using [docs/build-install.md](docs/build-install.md). Build on macOS or a configured Theos environment. Windows here has no Theos/iOS SDK, so a device build has not been executed in this workspace.
