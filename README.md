# H2Changer-iOS

Native iPhone controller and isolated API test tweak for iPhone XS on iOS 16.1 with Dopamine rootless. The repository is independent of H2PHONE Android.

## Modules

- `App/`: UIKit controller with Dashboard, installed user app selection, Profiles, Fake ON/OFF, Restore Original, and Debug Logs.
- `Tweak/`: Logos hook, loaded in UIKit apps with a per-app allowlist check before returning fake values.
- `App/H2ConfigManager.*`: file-based Config Manager; a future C# agent can write the same schema.
- `DeviceTest/`: real UIKit app showing values returned by `UIDevice` APIs.
- `Scripts/`: local structure verification.
- `docs/`: build, installation, and architecture notes.

The tweak changes values returned inside selected apps for `UIDevice.name`, `model`, `systemVersion`, and `identifierForVendor`. Fake OFF and unselected apps call the original methods. DeviceTest is selected by default. It never writes hardware identifiers or system settings. The package installs both apps and the tweak as a rootless `.deb` via Sileo. TrollStore is part of the target environment but is not needed for this package; it does not inject the tweak.

Apps such as AIDA64 may read other APIs (for example hardware model via `sysctl`) and may cache results. Selecting an app does not guarantee that every value it displays changes; this MVP covers only the four `UIDevice` methods above.

## Quick start

Run setup and build commands yourself using [docs/build-install.md](docs/build-install.md). On WSL2 Ubuntu, run `bash Scripts/build.sh`. The current host has no usable WSL distribution or Theos/iOS SDK, so a device build has not been executed in this workspace.
