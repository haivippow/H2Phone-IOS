# Safari WebContent Fingerprint Injection Design

## Intent

Make H2PHONE's existing web fingerprint profile reach Safari documents on a rootless iOS 16+ jailbreak, rather than only `WKWebView` objects created inside `MobileSafari` or ordinary selected apps.

## Goals

- Keep the current Theos/ElleKit rootless package.
- Load the tweak in MobileSafari and configure Safari web views early enough for WebKit to transport the script to WebContent.
- Inject the existing fingerprint script at document start for every frame.
- Encode profile-controlled strings as valid JavaScript values.
- Preserve the existing selected-app behavior and Fake ON/OFF control.

## Non-goals

- Claim complete browser fingerprint anonymity.
- Hook WebKit C++ internals whose ABI changes between iOS releases.
- Spoof public IP, TLS characteristics, the physical modem IMEI, or every WebGL/font surface.
- Add a Safari Web Extension.

## Constraints

- Deployment target remains iOS 16.0+, arm64, rootless, with ElleKit.
- Safari uses separate UI and WebContent processes; bundle-only checks cannot assume every process has `com.apple.mobilesafari` as its main bundle identifier.
- Configuration continues to come from H2ConfigManager's shared preferences.
- Private WebKit behavior must be verified on a target device after package build/install.

## Approaches

1. Hook private WebKit C++ document/frame internals. This can run earliest but is tightly coupled to a particular WebKit build and is crash-prone across iOS updates.
2. Load the tweak in MobileSafari and attach a `WKUserScript` to Safari's WebKit configuration before web-view initialization. WebKit transports the script to WebContent for document-start execution. This reuses the current implementation and avoids private C++ symbols. Selected.
3. Ship a Safari Web Extension. This is safer but requires extension enablement and does not match the repository's automatic jailbreak-tweak workflow.

## Design

The substrate filter explicitly admits MobileSafari while preserving existing UIKit-app injection, and runtime guards continue to exclude unrelated Apple processes. The script builder JSON-encodes the UA and exposes a small testable function. MobileSafari's configuration receives the user script before `WKWebView` initialization; WebKit transports it to WebContent. HTTP User-Agent handling remains in the MobileSafari `WKWebView` hook and requires on-device verification.

## Safety and failure behavior

If configuration or WebKit classes are unavailable, hooks return original behavior. Fake OFF disables H2 state only in web views where H2 was previously applied and restores the stored custom UA. Existing non-H2 user scripts are retained. The current main frame can be updated immediately at a hooked navigation boundary; existing subframes adopt changes on their next navigation/reload.
