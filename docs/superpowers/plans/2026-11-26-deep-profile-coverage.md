# Deep Profile Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. The user explicitly waived test and local-build steps.

**Goal:** Extend the selected-process profile across feasible native and browser surfaces currently marked not implemented.

**Architecture:** Add deterministic profile fields and stable API hooks in `Tweak.xm`; extend the document-start script in `H2WebFingerprint.m`. Keep network/server/Apple-signed identity out of scope and document partial coverage honestly.

**Tech Stack:** Objective-C/Logos, Theos, UIKit/Foundation/WebKit/SystemConfiguration.

**Spec:** `docs/superpowers/specs/2026-11-26-deep-profile-coverage-design.md`

## Global Constraints

- Fake ON plus selected bundle only.
- Do not hook native `UIScreen` geometry.
- Do not mutate Keychain, receipts, App Attest, APNs or server state.
- Do not run tests or a local package build.

### Task 1: Native process surfaces

- [ ] Add storage, uptime, boot-time, power-state and Wi-Fi profile values.
- [ ] Hook Foundation process/filesystem APIs, `kern.boottime`, and CaptiveNetwork functions.

### Task 2: Browser surfaces

- [ ] Extend Canvas, audio, fonts, codecs/media, permissions/devices and WebRTC coverage.
- [ ] Preserve original behavior whenever Fake is disabled.

### Task 3: Documentation and release

- [ ] Update capability documentation with precise limits.
- [ ] Bump version, commit, push `develop`, and push a release tag.
