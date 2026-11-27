# RootHide Package Design

## Intent

Build H2PHONE for both standard Dopamine rootless and RootHide without changing runtime spoofing behavior. A tagged release must contain two clearly named packages so the user can install the package matching the active jailbreak environment.

## Constraints

- Preserve the existing `rootless` package and `com.h2phone.ios` package identifier.
- Add a separate `roothide` build using `roothide/theos`; do not attempt to install the rootless package on RootHide.
- Use RootHide's required app entitlements for H2PHONE and H2DEV.
- H2PHONE's `/var/mobile/Library/Preferences` paths are mobile-user paths, not jailbreak-root paths, so they remain unchanged.
- Release assets are `com.h2phone.ios-rootless.deb` and `com.h2phone.ios-roothide.deb`.
- Do not commit, push, tag, create a release, or trigger GitHub Actions unless the user explicitly says `push`.

## Approach

Keep one source package and build it twice in the existing GitHub Actions job. The standard Theos checkout produces the rootless package; the RootHide Theos checkout produces the RootHide package and rewrites its Debian architecture to `iphoneos-arm64e`. Both app executables are signed with a shared entitlement set accepted by RootHide.

Alternative approaches considered were replacing the rootless package entirely, which would break existing Dopamine users, and relying on an on-device package converter, which is less reproducible than an official source build.
