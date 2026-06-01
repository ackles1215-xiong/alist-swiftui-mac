# AList SwiftUI Mac Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the MVP into a stronger desktop shell with binary discovery, release metadata parsing, service health checks, and an embedded AList admin view.

**Architecture:** Keep platform-neutral logic in `AListCore` and test it with XCTest. Keep SwiftUI/AppKit/WebKit integration thin in `AListSwiftUIMac`, driven by `AppModel`.

**Tech Stack:** Swift 6.3, Swift Package Manager, SwiftUI, WebKit, AppKit, Foundation, XCTest.

---

## File Structure

- `Sources/AListCore/BinaryDiscovery.swift`: finds the best local `alist` binary path from candidate URLs.
- `Sources/AListCore/DesktopRelease.swift`: decodes GitHub release JSON and selects macOS assets.
- `Sources/AListCore/HealthChecker.swift`: testable HTTP health check abstraction.
- `Sources/AListSwiftUIMac/WebAdminView.swift`: `WKWebView` wrapper for the admin UI.
- `Sources/AListSwiftUIMac/AppModel.swift`: adds binary auto-detect, health state, release state, and admin display mode.
- `Sources/AListSwiftUIMac/ContentView.swift`: adds segmented control for Control/Admin/Logs and status metadata.
- `Tests/AListCoreTests/AListCoreTests.swift`: tests for discovery, release asset selection, and health result mapping.

## Tasks

### Task 1: Binary Discovery

**Files:**
- Create: `Sources/AListCore/BinaryDiscovery.swift`
- Modify: `Tests/AListCoreTests/AListCoreTests.swift`

- [ ] Add a failing test that candidate binary paths choose the first existing executable.
- [ ] Implement `BinaryDiscovery` with injected `FileChecking`.
- [ ] Run `swift test --filter AListCoreTests/testBinaryDiscoveryChoosesFirstExistingExecutable`.

### Task 2: Release Metadata Parsing

**Files:**
- Create: `Sources/AListCore/DesktopRelease.swift`
- Modify: `Tests/AListCoreTests/AListCoreTests.swift`

- [ ] Add a failing test that GitHub release JSON decodes `tag_name`, `name`, and macOS `.app.tar.gz` assets.
- [ ] Implement `DesktopRelease`, `DesktopReleaseAsset`, and `preferredMacAppAsset(architecture:)`.
- [ ] Run `swift test --filter AListCoreTests/testDesktopReleaseSelectsPreferredMacAsset`.

### Task 3: Health Checking

**Files:**
- Create: `Sources/AListCore/HealthChecker.swift`
- Modify: `Tests/AListCoreTests/AListCoreTests.swift`

- [ ] Add failing tests for healthy 2xx/3xx HTTP responses and unhealthy failures.
- [ ] Implement `HealthStatus`, `HealthChecking`, and a URLSession-backed checker.
- [ ] Run `swift test --filter AListCoreTests/testHealthStatusMapsHTTPResponses`.

### Task 4: Embedded Admin View

**Files:**
- Create: `Sources/AListSwiftUIMac/WebAdminView.swift`
- Modify: `Sources/AListSwiftUIMac/AppModel.swift`
- Modify: `Sources/AListSwiftUIMac/ContentView.swift`

- [ ] Add an admin display mode to `AppModel`.
- [ ] Add a `WKWebView` SwiftUI wrapper.
- [ ] Replace the single detail view with Control/Admin/Logs sections.
- [ ] Run `swift build`.

### Task 5: Documentation, Verification, Push

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-06-01-alist-swiftui-mac-design.md`

- [ ] Document phase 1 features and limitations.
- [ ] Run `swift test`.
- [ ] Run `swift build`.
- [ ] Commit and push to `origin/main`.
