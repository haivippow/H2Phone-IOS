# Build and install

## Build with GitHub Actions

Release packages are built on the macOS runner defined in `.github/workflows/release.yml`. No Ubuntu, WSL or local Theos installation is required on the Windows computer.

The workflow runs only when a version tag matching `v*` is pushed. A normal `git push origin develop` does not trigger it. The runner installs the official Theos toolchain for the standard rootless build and RootHide's Theos fork for the RootHide build, then attaches both packages to the matching GitHub Release.

1. Update the package version in `control`.
2. Commit and push source changes to `develop`.
3. Create and push a new matching tag, for example `v0.1.31`. Never reuse an existing release tag.
4. Open GitHub Actions and wait for **Build rootless and RootHide release** to complete.
5. Download the package matching the active jailbreak:
   - `com.h2phone.ios-rootless.deb` for standard Dopamine rootless.
   - `com.h2phone.ios-roothide.deb` for RootHide.

The workflow isolates the two build outputs before copying both stable filenames into `packages/`, so one scheme cannot overwrite the other.

## Install on the iPhone

Transfer the matching `.deb` to the jailbroken iPhone and install it with Sileo or another compatible package manager. RootHide users must install the `-roothide.deb` asset; Sileo will reject the standard rootless asset in a RootHide environment. Restart the selected target app after changing its profile. For Safari, fully close and reopen Safari so newly created web views receive the document-start script.

Device behavior must be verified on the target iPhone. A successful CI build proves compilation and packaging only; it does not prove that every private API or fingerprint path behaves identically on every iOS/jailbreak combination.
