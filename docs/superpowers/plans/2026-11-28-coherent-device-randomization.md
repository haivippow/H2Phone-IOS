# Coherent Device Randomization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate and activate an internally consistent fake iPhone profile from the user's configured model and iOS ranges.

**Architecture:** Extend the bundled catalog with compatible firmware data, then use a pure Swift generator to select one device, board, firmware, and reviewed hardware specification as a unit. Persist the generated profile through a narrow Objective-C bridge and let the existing tweak consume its established keys.

**Tech Stack:** Swift 5, Foundation, Objective-C, Theos, PowerShell tests and catalog generation

**Spec:** `docs/superpowers/specs/2026-11-28-coherent-device-randomization-design.md`

## Global Constraints

- No runtime network access.
- Keep native `UIScreen` unhooked.
- Fail without mutating config when no compatible combination exists.
- Preserve schema-1 config migration and selected application bundle IDs.
- Do not commit or push without an explicit `push` request.

## Review Focus

- A marketing-name range containing multiple ProductTypes must never combine one ProductType with another device's board.
- An iOS range with no firmware for the chosen device must retry valid candidates, then fail without saving.
- Missing catalog resources must return a user-visible unavailable error rather than crash.
- Existing schema-1 configs must retain enabled apps after migration.
- Runtime notify state must resolve custom profiles without an array-index limit.

---

### Task 1: Bundled compatibility catalog

**Files:**
- Modify: `Scripts/generate-device-catalog.ps1`
- Modify: `H2PHONE/Resources/DeviceCatalog.json`
- Modify: `H2PhoneSwiftUI/Models/DeviceCatalog.swift`
- Modify: `Tests/DeviceCatalogTests.ps1`

**Interfaces:**
- Produces: `DeviceFirmware`, `DeviceCatalogEntry.firmwares`, and exact ProductType/board/model tuples.

- [ ] Add a failing fixture test proving firmware is filtered by ProductType, sorted, deduplicated, and preserves iOS version/build/Darwin.
- [ ] Run the test and confirm it fails because firmware is absent.
- [ ] Extend the generator with optional OS fixture input and AppleDB iOS endpoint input.
- [ ] Extend Codable catalog types and regenerate the bundled JSON.
- [ ] Run catalog and integrity tests.

### Task 2: Pure coherent profile generator

**Files:**
- Create: `H2PhoneSwiftUI/Models/GeneratedDeviceProfile.swift`
- Create: `H2PhoneSwiftUI/Services/DeviceProfileGenerator.swift`
- Create: `Tests/DeviceProfileGeneratorTests.swift`

**Interfaces:**
- Consumes: `ProfileGenerationSettings`, `DeviceCatalogDocument`.
- Produces: `DeviceProfileGenerator.generate(settings:randomIndex:) throws -> GeneratedDeviceProfile` and `GeneratedDeviceProfile.propertyList`.

- [ ] Add failing Swift tests for matched ProductType/board, compatible firmware, deterministic injected randomness, and empty-candidate failure.
- [ ] Run tests and confirm generator symbols are missing.
- [ ] Add reviewed hardware specs for supported devices and implement candidate filtering plus generation.
- [ ] Run focused Swift tests.

### Task 3: Atomic native config activation

**Files:**
- Modify: `H2PHONE/H2ConfigManager.h`
- Modify: `H2PHONE/H2ConfigManager.m`
- Create: `H2PHONE/H2ProfileActivationService.h`
- Create: `H2PHONE/H2ProfileActivationService.m`
- Modify: `H2PHONE/H2PHONE-Bridging-Header.h`
- Modify: `H2PHONE/Makefile`
- Modify: `Tests/SourceTests.ps1`

**Interfaces:**
- Consumes: generated property-list dictionary and selected bundle IDs.
- Produces: `+activateProfile:enabledApps:error:` and schema-2 snapshots containing `generatedProfile`.

- [ ] Add failing source/integration assertions for schema migration, validation, atomic save, and direct generated-profile lookup.
- [ ] Run tests and confirm the bridge/config behavior is absent.
- [ ] Implement validation and schema-2 persistence while preserving schema-1 migration.
- [ ] Change runtime notification to signal activation while profile data remains sourced from the atomic plist.
- [ ] Run source tests.

### Task 4: Connect Change to generation and activation

**Files:**
- Modify: `H2PhoneSwiftUI/Services/DeviceService.swift`
- Modify: `H2PhoneSwiftUI/Core/H2Store.swift`
- Modify: `H2PhoneSwiftUI/App/H2PhoneRootViewControllerFactory.swift`
- Modify: `Tests/SourceTests.ps1`

**Interfaces:**
- Consumes: `DeviceProfileGenerator` and `H2ProfileActivationService`.
- Produces: `DeviceService.change(to:apps:settings:)` that returns the activated UI snapshot.

- [ ] Add failing assertions that Change passes settings, generator output reaches activation, and activation errors preserve the current profile.
- [ ] Run tests and confirm failure at the disconnected service boundary.
- [ ] Inject the generator, activate selected fake-info apps, and map the generated profile to `DeviceProfile`.
- [ ] Run all repository tests, catalog integrity checks, and `git diff --check`.

No task includes a commit step because repository instructions prohibit Git operations without an explicit `push` request.
