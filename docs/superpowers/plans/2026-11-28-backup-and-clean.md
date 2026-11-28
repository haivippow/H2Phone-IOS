# Backup & Clean Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the separate backup/reset configuration with one safe `Backup & Làm sạch` choice.

**Architecture:** Keep `backupData` as the persisted UI selection and remove `resetOnChange`. The future device service must interpret the selection as backup, verify, then clear; the current unavailable service remains non-destructive.

**Tech Stack:** SwiftUI, Swift 5, iOS 16+, PowerShell source tests.

**Spec:** User-approved conversation design on 2026-11-28.

## Global Constraints

- Never clear app data unless its backup has been verified successfully.
- Do not report success while the backend operation is unavailable.
- Keep Fake Info independent from Backup & Làm sạch.

## Review Focus

- Apps selected only for Fake Info remain selected without being cleaned.
- Apps selected for Backup & Làm sạch are counted once in Change confirmation.
- No reset-without-backup configuration remains reachable.
- Existing installed-app discovery initializes the new option off.
- Preview data continues to compile after the model field removal.

### Task 1: Simplify the target-app model

**Files:** `H2PhoneSwiftUI/Models/H2Models.swift`, `H2PhoneSwiftUI/Services/DeviceService.swift`, `H2PhoneSwiftUI/Preview/PreviewData.swift`, `Tests/SourceTests.ps1`

- [ ] Add failing source assertions that `resetOnChange` is absent and selection uses only `fakeInfo || backupData`.
- [ ] Remove the field and update every initializer.
- [ ] Run `Tests/SourceTests.ps1` and confirm it passes.

### Task 2: Update application and Change UI copy

**Files:** `H2PhoneSwiftUI/Features/TargetAppsAndOperationsViews.swift`, `Tests/SourceTests.ps1`

- [ ] Add failing assertions for `Backup & Làm sạch`, the verified-backup explanation, and absence of Reset UI.
- [ ] Update row, detail, filters, and Change confirmation; retain the unavailable backend notice.
- [ ] Run the complete repository verification suite.

