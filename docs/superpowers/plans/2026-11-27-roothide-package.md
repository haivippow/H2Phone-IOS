# RootHide Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce installable rootless and RootHide H2PHONE packages from the same tagged source.

**Architecture:** The release workflow uses separate official and RootHide Theos checkouts and builds the aggregate project once per scheme. Both application targets receive the RootHide-compatible entitlement set, while shared preferences continue using `/var/mobile` paths.

**Tech Stack:** Theos, Logos, GitHub Actions, Debian packages, ldid entitlements

**Spec:** `docs/superpowers/specs/2026-11-27-roothide-package-design.md`

## Global Constraints

- Preserve rootless support and package identifier `com.h2phone.ios`.
- Output `com.h2phone.ios-rootless.deb` and `com.h2phone.ios-roothide.deb`.
- Do not commit, push, tag, release, or trigger Actions without an explicit `push` request.

## Review Focus

- Rootless and RootHide builds must not overwrite one another.
- RootHide must use the RootHide Theos fork and `THEOS_PACKAGE_SCHEME=roothide`.
- Both app executables need the required RootHide storage and sandbox entitlements.
- The release command must upload exactly both named packages.
- Existing source and structure tests must remain green.

---

### Task 1: Packaging regression checks and entitlements

**Files:**
- Modify: `Tests/SourceTests.ps1`
- Modify: `H2PHONE/H2PHONE.entitlements`
- Create: `H2DEV/H2DEV.entitlements`
- Modify: `H2DEV/Makefile`

- [ ] Add failing source assertions for all required RootHide entitlements and H2DEV code signing.
- [ ] Run `Tests/SourceTests.ps1` and verify failure.
- [ ] Add the entitlement keys to both apps and configure H2DEV signing.
- [ ] Run `Tests/SourceTests.ps1` and verify success.

### Task 2: Dual-scheme release workflow

**Files:**
- Modify: `Tests/SourceTests.ps1`
- Modify: `.github/workflows/release.yml`

- [ ] Add failing assertions for both Theos checkouts, both package schemes, both asset names, and the two-asset release command.
- [ ] Run the source tests and verify failure.
- [ ] Update the workflow to build and retain both packages without filename collisions.
- [ ] Run the source and structure tests.

### Task 3: Documentation and final local verification

**Files:**
- Modify: `README.md`
- Modify: `docs/build-install.md`

- [ ] Document which package matches each jailbreak and the manual tag-triggered release process.
- [ ] Run source, Web fingerprint, and structure tests.
- [ ] Inspect `git diff --check` and leave all changes uncommitted.
