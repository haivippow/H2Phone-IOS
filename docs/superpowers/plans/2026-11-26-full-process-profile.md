# Full Process Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans and superpowers:test-driven-development.

**Goal:** Cover additional OS and User-Agent discovery paths across the entire selected process.

**Architecture:** Extend immutable profiles with Darwin/build metadata, add process-wide hooks guarded only by `H2FakeEnabled`, and reuse the existing profile UA builder. Keep native screen geometry unhooked.

**Tech Stack:** Objective-C, Logos, Foundation, UIKit, WebKit

**Spec:** `docs/superpowers/specs/2026-11-26-full-process-profile-design.md`

## Tasks

1. Add failing source checks for build/Darwin profile fields and new hook surfaces.
2. Add kernel, uname, SystemVersion dictionary/bundle hooks.
3. Add legacy UIWebView, User-Agent cache, and request-header hooks.
4. Extend H2DEV and documentation, run all host verification, review, then push `develop` without a release tag.
