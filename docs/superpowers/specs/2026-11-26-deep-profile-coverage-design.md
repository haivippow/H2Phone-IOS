# Deep profile coverage design

## Intent

Expand the selected-process profile across additional native and browser-facing fingerprint APIs while keeping Fake OFF and unselected processes untouched. The capability matrix must distinguish API-level spoofing from real hardware, network, entitlement, and server state.

## Approach

Use public Objective-C APIs and C symbols that are stable enough for rootless iOS 16+, plus the existing document-start script for browser surfaces. Native hooks return deterministic profile values. Browser hooks return deterministic values and filter WebRTC host candidates rather than claiming to change the actual public IP.

Version-specific WebKit internals are excluded because they are OS-specific and crash-prone. A VPN/proxy/server is a separate component with its own entitlements and infrastructure and is also excluded.

## Included

- Filesystem capacity/free-space APIs.
- Process uptime, system uptime and `kern.boottime`.
- Thermal state and Low Power Mode.
- CaptiveNetwork SSID/BSSID results when that API is called.
- Canvas blob/OffscreenCanvas readback, audio samples, font measurements/checks, media codec/capability queries, permissions/media-device enumeration, and WebRTC host-candidate filtering.
- Honest capability documentation.

## Excluded

- Keychain mutation or namespace virtualization.
- Signed App Store receipts, StoreKit history, DeviceCheck/App Attest and APNs identity.
- Real modem/SIM, MAC address, public IP, DNS or TLS fingerprint changes.
- Automatic discovery of every helper/extension bundle.

## Constraints

- Apply only when the global switch and current bundle selection are active.
- Keep native UIKit screen geometry real.
- Do not run tests or a local package build, per the user's explicit request.
- Let the release workflow build the tagged package.
