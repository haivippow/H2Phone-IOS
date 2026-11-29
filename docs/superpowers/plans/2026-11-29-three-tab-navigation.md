# Three-tab Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace modal APP/Setting access with three persistent tabs and make the Change confirmation accurately represent native fake-profile activation.

**Architecture:** RootView owns a three-item TabView and only retains sheets for transactional Change and Rollback flows. Dashboard navigation owns profile history, while AppsView and ProfileSettingsView become independent tab roots.

**Tech Stack:** SwiftUI, Swift 5, existing H2Store/DeviceService

**Spec:** `docs/superpowers/specs/2026-11-29-three-tab-navigation-design.md`

## Global Constraints

- Keep Change activation non-destructive.
- Do not claim backup, cleanup, or restore operations ran when their native services are unavailable.
- Preserve installed-app discovery and profile history/rollback access.
- Do not commit or push without a new explicit `push` request.

## Review Focus

- Each tab must own exactly one NavigationStack and avoid nested navigation bars.
- APP discovery must still run when the tab first appears.
- Profile history and rollback must remain reachable from Điều khiển.
- Change must not dismiss into a silent failure or show stale “unavailable” copy.
- Small-screen tab labels and APP filters must remain usable.

---

### Task 1: Three-tab root navigation

**Files:**
- Modify: `H2PhoneSwiftUI/Features/DashboardAndProfilesViews.swift`
- Modify: `H2PhoneSwiftUI/Features/TargetAppsAndOperationsViews.swift`
- Modify: `Tests/SourceTests.ps1`

- [ ] Add failing source assertions for Điều khiển/APP/Setting tabs and removal of modal APP/gear navigation.
- [ ] Run tests and confirm the old hierarchy fails.
- [ ] Refactor RootView, DashboardView, and AppsView to the selected hierarchy.
- [ ] Run source tests.

### Task 2: Truthful real Change flow

**Files:**
- Modify: `H2PhoneSwiftUI/Features/TargetAppsAndOperationsViews.swift`
- Modify: `Tests/SourceTests.ps1`

- [ ] Add failing assertions that confirmation describes native fake activation and contains no stale unavailable claim.
- [ ] Run tests and confirm stale copy fails.
- [ ] Update ChangeSheet copy and disable execution when no Fake Info app is selected.
- [ ] Run all repository tests and `git diff --check`.
