# Safari WebContent Fingerprint Injection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inject H2PHONE's existing fingerprint script into Safari WebContent documents on rootless iOS 16+ and safely encode the configured User-Agent.

**Architecture:** Extend tweak process targeting to Safari/WebContent while retaining runtime allow-listing, and make the script builder independently testable. Reuse `WKUserScript` at document start rather than binding to version-specific WebKit C++ symbols.

**Tech Stack:** Theos, Logos, Objective-C/Objective-C++, WebKit, ElleKit, rootless iOS 16+

**Spec:** `docs/superpowers/specs/2026-11-26-safari-webcontent-fingerprint-design.md`

## Global Constraints

- Deployment target remains iOS 16.0+, arm64, rootless, with ElleKit.
- Preserve third-party selected-app hooks and exclude unrelated Apple processes.
- Do not claim complete fingerprint spoofing; on-device Safari verification remains required.

## Review Focus

- A UA containing quotes, backslashes, Unicode, or line separators must still produce valid JS.
- Fake OFF must not delete unrelated user scripts and must disable an already-running H2 script.
- WebContent process detection must work when the bundle identifier is missing or differs from MobileSafari.
- Unrelated Apple processes must continue to receive original behavior.
- Reapplying an unchanged profile must not duplicate H2 user scripts.

---

### Task 1: Safe, testable fingerprint script builder

**Files:**
- Modify: `Tweak/H2WebFingerprint.h`
- Modify: `Tweak/H2WebFingerprint.m`
- Create: `Tests/H2WebFingerprintTests.m`
- Create: `Tests/Makefile`

**Interfaces:**
- Produces: `NSString *H2WebFingerprintScript(NSString *userAgent, NSUInteger seed)`
- Consumes: Foundation JSON serialization and existing `H2UpdateWebFingerprint`

- [ ] Write tests asserting special-character UA round-trips as a JavaScript string literal, seed is masked to one byte, and the marker is present.
- [ ] Run the focused test target and verify the special-character test fails because the public builder and JSON encoding are absent.
- [ ] Expose the builder and replace raw quote interpolation with `NSJSONSerialization` encoding.
- [ ] Run the focused tests and verify they pass.

### Task 2: Safari pre-initialization targeting

**Files:**
- Modify: `Tweak/H2PHONEHook.plist`
- Modify: `Tweak/Tweak.xm`
- Modify: `Tweak/Makefile`
- Test: `Tests/SourceTests.ps1`

**Interfaces:**
- Produces: pre-initialization configuration of Safari/selected-app `WKWebView` instances
- Consumes: bundle identifier, H2ConfigManager configuration, and `H2ConfigureWebContent`

- [ ] Write a source regression test requiring MobileSafari targeting and configuration before `%orig`.
- [ ] Run it and verify the pre-initialization requirement fails under the original hook.
- [ ] Configure the supplied `WKWebViewConfiguration` before Safari constructs its web view; do not call `WKUserContentController` inside WebContent.
- [ ] Track H2 application state per web view so unselected/Fake-OFF pages are never touched.
- [ ] Run focused source and executable JavaScript tests. Defer the package build until explicitly requested.

### Task 3: Documentation and package verification

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/build-install.md`
- Modify: `docs/spoof-coverage.md`

**Interfaces:**
- Consumes: behavior delivered by Tasks 1-2
- Produces: exact install/restart and HTTP-header-versus-JS verification steps

- [ ] Update documentation to distinguish MobileSafari UA-header handling from WebContent JS injection and list known gaps.
- [ ] Run all host tests.
- [ ] When explicitly requested, run `make clean package` and confirm a rootless arm64 package is produced without new warnings/errors.
- [ ] When explicitly requested, inspect the package filter/control metadata and record the required target-device respring/process restart checks.
