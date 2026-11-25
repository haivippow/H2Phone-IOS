# Build and install

Target: iPhone XS, iOS 16.1, Dopamine rootless, Sileo. The package is `iphoneos-arm64`; `ARCHS = arm64` is intentional because these apps are ordinary app binaries and the hook targets only DeviceTest.

## Setup on macOS

Install Xcode command line tools and Theos with an iPhoneOS SDK. Follow the current [Theos installation guide](https://theos.dev/docs/installation). Then run:

```sh
export THEOS="$HOME/theos"
cd H2Changer-iOS
make clean package FINALPACKAGE=1
```

The package appears in `packages/`. The Makefile sets `THEOS_PACKAGE_SCHEME=rootless`, which places installed files under `/var/jb` and uses the rootless package architecture.

## Install on the iPhone

Copy the produced `.deb` to the phone, open it in Sileo, and install. Alternatively, with SSH configured:

```sh
scp packages/*.deb mobile@IPHONE_IP:/var/mobile/
ssh mobile@IPHONE_IP 'sudo dpkg -i /var/mobile/com.h2changer.ios_*.deb && sudo uicache -a'
```

If the package filename differs, replace the wildcard with the actual name. Run `uicache -a` after install if the icons are absent. Launch H2Changer, select a profile, turn Fake ON, and open DeviceTest. Tap Refresh in DeviceTest after each change. Turn Fake OFF or tap Restore Original, then refresh again to see original API results.

## Verification

On Windows, run `powershell -File Scripts/verify-structure.ps1` for a source/layout check. On the iPhone, compare the four DeviceTest rows before enabling Fake, after enabling it, and after Restore Original. With Fake OFF, the values should match the initial readings. Confirm other apps remain unaffected because `Tweak/H2ChangerHook.plist` filters to DeviceTest's bundle ID.

If H2Changer reports a save error, inspect the controller app's entitlement signing and write access to `/var/mobile/Library/Preferences`. The config file is created on first save; no package script writes it.
