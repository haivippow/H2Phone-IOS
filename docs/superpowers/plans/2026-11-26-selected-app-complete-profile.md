# Selected App Complete Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans and superpowers:test-driven-development.

**Goal:** Use one coherent profile for supported native and WebKit information in every selected app.

**Architecture:** Extend `H2ConfigManager` profiles with typed values, consume them from native hooks, and serialize browser values into the existing document-start script. Preserve the central `H2FakeEnabled` guard.

**Tech Stack:** Objective-C, Logos, Theos, WebKit JavaScript, PowerShell and Node tests

**Spec:** `docs/superpowers/specs/2026-11-26-selected-app-complete-profile-design.md`

## Tasks

1. Add failing tests for required profile fields and browser surfaces.
2. Extend profile dictionaries and native hooks for device/display/memory/CPU/carrier/location/battery consistency.
3. Extend WebKit script configuration for screen, DPR, CPU/touch, vendor and WebGL consistency.
4. Expand DeviceTest probes and coverage documentation.
5. Run source/JavaScript/structure verification; defer package build, commit, and push until requested.
