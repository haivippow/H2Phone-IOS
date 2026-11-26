# Build and install

## Build with GitHub Actions

Release packages are built on the macOS runner defined in `.github/workflows/release.yml`. No Ubuntu, WSL or local Theos installation is required on the Windows computer.

The workflow runs when a version tag matching `v*` is pushed. It installs Theos and packaging tools, builds the rootless arm64/arm64e package, and attaches the generated `.deb` to the matching GitHub Release.

1. Commit and push source changes to `develop`.
2. Update the package version in `control`.
3. Create and push the matching tag, for example `v0.1.23`.
4. Open GitHub Actions and wait for **Build rootless release** to complete.
5. Download the `.deb` from the matching GitHub Release.

The workflow deletes old `packages/*.deb` files before each build, so only the package produced from the tagged commit is uploaded.

## Install on the iPhone

Transfer the downloaded rootless `.deb` to the jailbroken iPhone and install it with Sileo or another compatible package manager. Restart the selected target app after changing its profile. For Safari, fully close and reopen Safari so newly created web views receive the document-start script.

Device behavior must be verified on the target iPhone. A successful CI build proves compilation and packaging only; it does not prove that every private API or fingerprint path behaves identically on every iOS/jailbreak combination.
