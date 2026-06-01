# AList SwiftUI Mac MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a testable SwiftUI macOS MVP that starts, stops, logs, and opens a local AList service.

**Architecture:** Create a Swift Package with a testable `AListCore` library and a thin `AListSwiftUIMac` SwiftUI executable. Keep process, settings, and log behavior outside views so the MVP can be verified with unit tests.

**Tech Stack:** Swift 6.3, Swift Package Manager, SwiftUI, AppKit, Foundation `Process`, XCTest.

---

## File Structure

- `Package.swift`: package, product, target, and platform declaration.
- `Sources/AListCore/AListConfiguration.swift`: configuration values and validation.
- `Sources/AListCore/AListLaunchConfiguration.swift`: command arguments derived from settings.
- `Sources/AListCore/LogStore.swift`: bounded in-memory log buffer.
- `Sources/AListCore/AListServiceController.swift`: process lifecycle state machine.
- `Sources/AListCore/SettingsStore.swift`: `UserDefaults` persistence.
- `Sources/AListSwiftUIMac/AListSwiftUIMacApp.swift`: SwiftUI app entry point and shared state.
- `Sources/AListSwiftUIMac/AppModel.swift`: UI-facing app model.
- `Sources/AListSwiftUIMac/ContentView.swift`: main MVP window.
- `Sources/AListSwiftUIMac/StatusBadge.swift`: small reusable status view.
- `Tests/AListCoreTests/AListCoreTests.swift`: core unit tests.

## Tasks

### Task 1: Package And Failing Core Tests

**Files:**
- Create: `Package.swift`
- Create: `Tests/AListCoreTests/AListCoreTests.swift`

- [ ] Create the package manifest with `AListCore`, `AListSwiftUIMac`, and `AListCoreTests`.
- [ ] Write tests that reference the desired core API before implementation exists.
- [ ] Run `swift test` and verify it fails because `AListCore` types are missing.

### Task 2: Core Configuration And Logs

**Files:**
- Create: `Sources/AListCore/AListConfiguration.swift`
- Create: `Sources/AListCore/AListLaunchConfiguration.swift`
- Create: `Sources/AListCore/LogStore.swift`

- [ ] Implement configuration validation and admin URL creation.
- [ ] Implement launch command construction for `alist server --data <dir>` with `ALIST_ADDR` and `ALIST_HTTP_PORT`.
- [ ] Implement bounded log storage.
- [ ] Run `swift test` and verify configuration/log tests pass.

### Task 3: Service Controller

**Files:**
- Create: `Sources/AListCore/AListServiceController.swift`

- [ ] Write the fake-process based lifecycle test.
- [ ] Run it and verify the expected failure.
- [ ] Implement `AListServiceController`, `ProcessLaunching`, and `RunningProcess`.
- [ ] Run `swift test` and verify lifecycle tests pass.

### Task 4: Settings Persistence

**Files:**
- Create: `Sources/AListCore/SettingsStore.swift`
- Modify: `Tests/AListCoreTests/AListCoreTests.swift`

- [ ] Add tests for saving and loading configuration in isolated `UserDefaults`.
- [ ] Run the new test and verify it fails.
- [ ] Implement `SettingsStore`.
- [ ] Run `swift test` and verify all core tests pass.

### Task 5: SwiftUI MVP Shell

**Files:**
- Create: `Sources/AListSwiftUIMac/AListSwiftUIMacApp.swift`
- Create: `Sources/AListSwiftUIMac/AppModel.swift`
- Create: `Sources/AListSwiftUIMac/ContentView.swift`
- Create: `Sources/AListSwiftUIMac/StatusBadge.swift`

- [ ] Implement shared app state with `@StateObject`.
- [ ] Implement main window controls for start, stop, open admin, settings, and logs.
- [ ] Implement menu bar extra commands.
- [ ] Run `swift build` and fix compiler errors.

### Task 6: Repository Finish

**Files:**
- Create: `README.md`
- Create: `.gitignore`

- [ ] Document how to build and run the MVP.
- [ ] Run `swift test`.
- [ ] Run `swift build`.
- [ ] Commit the working MVP.
- [ ] Create the GitHub repository `ackles1215-xiong/alist-swiftui-mac` and push `main`.
