# Profile Generation Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the approved auto-saved Profile randomization settings UI.

**Architecture:** Add a Codable settings model and injected persistence service, publish settings through `H2Store`, and push a dedicated SwiftUI settings view from Dashboard. Change confirmation reads the same published settings.

**Tech Stack:** Swift 5, SwiftUI, Combine, Foundation/UserDefaults, iOS 16+.

**Spec:** `docs/superpowers/specs/2026-11-28-profile-generation-settings-design.md`

## Global Constraints

- No Save button; every change persists automatically.
- Normalize inverted min/max ranges.
- Migrate indexes saved by the original iPhone XS–16 Pro Max catalog before applying the expanded catalog.
- Restrict generated iOS values to the compatibility bounds of the selected iPhone model.
- Do not report backend success.
- Preserve the two-tab layout and Dashboard scrolling.
- Surface the complete hook capability catalog, including identifiers, system state, connectivity, sensors, and web fingerprint behavior.

## Review Focus

- Empty/corrupt saved data falls back to safe defaults.
- Changing a minimum past the maximum adjusts the maximum.
- Changing a maximum below the minimum adjusts the minimum.
- Disabled fields remain visible but are excluded from the Change summary.
- The screen remains scrollable on iPhone XS.

### Task 1: Settings model and persistence

**Files:** `H2PhoneSwiftUI/Models/ProfileGenerationSettings.swift`, `H2PhoneSwiftUI/Services/ProfileSettingsService.swift`, `H2PhoneSwiftUI/Core/H2Store.swift`, `Tests/SourceTests.ps1`

- [ ] Add failing tests for Codable defaults, injected persistence, and range normalization.
- [ ] Implement the model, service, and store bindings.
- [ ] Run source tests.

### Task 2: Settings navigation and UI

**Files:** `H2PhoneSwiftUI/Features/ProfileSettingsView.swift`, `H2PhoneSwiftUI/Features/DashboardAndProfilesViews.swift`, `H2PHONE/Makefile`, `Tests/SourceTests.ps1`

- [ ] Add failing tests for the gear navigation, five toggles, range pickers, scrolling, and no Save button.
- [ ] Implement the approved screen and automatic persistence bindings.
- [ ] Run source tests.

### Task 3: Change summary and verification

**Files:** `H2PhoneSwiftUI/Features/TargetAppsAndOperationsViews.swift`, `Tests/SourceTests.ps1`

- [ ] Add failing tests for enabled-field and range summaries.
- [ ] Add the summary while retaining the unavailable notice.
- [ ] Run the complete repository verification suite without building or publishing.

