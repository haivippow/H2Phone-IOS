# Build on Windows with WSL2 Ubuntu

Target: iPhone XS, iOS 16.1, Dopamine rootless, Sileo. The `.deb` package architecture is `iphoneos-arm64`. All three binaries (H2Changer, DeviceTest and H2ChangerHook) use `arm64`. The tweak targets ordinary third-party apps, not an arm64e system binary, so an arm64e slice and the macOS-only new arm64e ABI toolchain are unnecessary. Theos [documents this distinction](https://theos.dev/docs/rootless). The build uses an iOS 16.0 deployment target and an SDK version 16.0 or newer; SDK 16.5 can build for iOS 16.1.

## Environment status checked in this workspace

The Windows host reports **Windows 10 Home Single Language, build 19045**. WSL2 Ubuntu 24.04, Theos, iPhoneOS16.5.sdk, clang and ldid were subsequently installed. `Scripts/build.sh` produced `packages/com.h2changer.ios_0.1.1_iphoneos-arm64.deb` and verified its metadata and rootless payload. The package has not been installed or tested on an iPhone yet.

## Install WSL2 Ubuntu (run in an elevated PowerShell)

Windows 10 build 19045 supports WSL2. Follow [Microsoft's WSL install guide](https://learn.microsoft.com/en-us/windows/wsl/install). Use Ubuntu **24.04 LTS** for the current Theos Linux installer:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart Windows, launch Ubuntu 24.04 once and create a Linux user. Verify with `wsl --list --verbose`; `Ubuntu-24.04` must show version **2**. If `wsl --install` only prints help, use [Microsoft's manual installation steps](https://learn.microsoft.com/en-us/windows/wsl/install-manual), including the two optional features, reboot, WSL2 kernel/update and Ubuntu installation. These commands require Administrator rights and are intentionally left for you to run.

Ubuntu 26.04 (`resolute`) renamed the `libxml2` runtime package to `libxml2-16`. The current Theos installer still asks apt for `libxml2` and stops before installing Theos. Keep that distribution if you use it for other work; install `Ubuntu-24.04` alongside it for this build. [Ubuntu package listings](https://packages.ubuntu.com/search?keywords=libxml2&searchon=names&suite=all) show the version difference.

## Install Theos in Ubuntu

Start the supported distribution with `wsl -d Ubuntu-24.04` from PowerShell. Use the [official Theos Linux/WSL guide](https://theos.dev/docs/installation-linux). In Ubuntu 24.04:

```sh
sudo apt update
sudo apt install -y bash curl sudo git make perl python3 dpkg-dev xz-utils
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
export THEOS="$HOME/theos"
```

The Theos installer supplies its toolchain. Check `$THEOS/makefiles/common.mk`, `$THEOS/toolchain/`, and `ldid` before building. The official [Theos SDK repository](https://github.com/theos/sdks) offers iPhoneOS16.5.sdk. If the installer did not provide a suitable SDK, install this release asset:

```sh
mkdir -p "$THEOS/sdks"
curl -fL -o /tmp/iPhoneOS16.5.sdk.tar.xz https://github.com/theos/sdks/releases/download/master-146e41f/iPhoneOS16.5.sdk.tar.xz
tar -xJf /tmp/iPhoneOS16.5.sdk.tar.xz -C "$THEOS/sdks"
```

## Build

From Ubuntu, run the script against the Windows checkout:

```sh
cd /mnt/d/H2PHONE-IOS
bash Scripts/build.sh
```

The script checks WSL2, Theos, SDK, toolchain, rootless settings and output package contents. It prints `DEB_OK: ...` only after a new non-empty `.deb` passes package ID, architecture and file checks. The output is in `/mnt/d/H2PHONE-IOS/packages/` (`D:\H2PHONE-IOS\packages` in Windows). `THEOS_PACKAGE_SCHEME=rootless` puts payload files under `/var/jb`.

## Install on the iPhone

Before installing H2Changer on Dopamine, check that **ElleKit** is installed in Sileo. If Sileo cannot resolve `ellekit`, add the [official ElleKit source](https://ellekit.space/) (`https://ellekit.space/`) and install ElleKit there, then retry the H2Changer package. H2Changer 0.1.1 depends on `ellekit` directly instead of the virtual package `mobilesubstrate`.

Copy the produced `.deb` to the phone, open it in Sileo, and install. Alternatively, with SSH configured:

```sh
scp packages/*.deb mobile@IPHONE_IP:/var/mobile/
ssh mobile@IPHONE_IP 'sudo dpkg -i /var/mobile/com.h2changer.ios_*.deb && sudo uicache -a'
```

If the package filename differs, replace the wildcard with the actual name. Run `uicache -a` after install if the icons are absent. Launch H2Changer, select a profile, open Test Apps and select apps that should read fake values, then turn Fake ON. Tap the info button beside an app to open it. Close and reopen an app if it was already running before the tweak was installed. In DeviceTest, tap Refresh after each change. Turn Fake OFF or tap Restore Original, then refresh again to see original API results.

## Verification

On Windows, run `powershell -File Scripts/verify-structure.ps1` for a source/layout check. On the iPhone, compare the four DeviceTest rows before enabling Fake, after enabling it, and after Restore Original. With Fake OFF, the values should match the initial readings. Other apps should read fake values only while selected in Test Apps. The tweak is injected into UIKit apps, so validate on a test phone before selecting more apps.

If H2Changer reports a save error, inspect the controller app's entitlement signing and write access to `/var/mobile/Library/Preferences`. The config file is created on first save; no package script writes it.
