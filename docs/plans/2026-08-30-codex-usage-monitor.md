# Codex Usage Monitor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build and install a native macOS companion app that automatically shows Codex remaining usage only while ChatGPT.app is frontmost.

**Architecture:** A testable core library normalizes Codex App Server responses and computes ChatGPT window selection and overlay geometry. A menu-bar AppKit executable observes frontmost-application changes, polls usage, and presents a nonactivating SwiftUI-backed `NSPanel` anchored to the ChatGPT window.

**Tech Stack:** Swift 6 toolchain, repository-local `swiftc` scripts, AppKit, SwiftUI, CoreGraphics, dependency-free Swift tests, shell packaging. SwiftPM is not the verification path because the installed Command Line Tools has a mismatched `PackageDescription` module and library.

---

### Task 1: Usage data contract

**Files:**
- Create: `Package.swift` (metadata for a repaired SwiftPM installation)
- Create: `scripts/test.sh`
- Create: `Tests/CodexUsageMonitorCoreTests/UsageSnapshotTests.swift`
- Create: `Sources/CodexUsageMonitorCore/UsageSnapshot.swift`

1. Add failing tests for remaining-percent calculation, clamping, missing windows and reset timestamps.
2. Run `./scripts/test.sh UsageSnapshotTests` and confirm RED.
3. Implement the smallest Codable transport structs and normalized display model.
4. Run the focused tests and confirm GREEN.

### Task 2: Window selection and overlay geometry

**Files:**
- Create: `Tests/CodexUsageMonitorCoreTests/WindowGeometryTests.swift`
- Create: `Sources/CodexUsageMonitorCore/WindowGeometry.swift`

1. Add failing tests that select the largest visible layer-zero window and reject tiny/helper windows.
2. Add failing tests for per-display CoreGraphics-to-AppKit conversion and top-right anchoring.
3. Implement pure selection and geometry functions.
4. Run focused tests and confirm GREEN.

### Task 3: Codex App Server client

**Files:**
- Create: `Tests/CodexUsageMonitorCoreTests/AppServerProtocolTests.swift`
- Create: `Sources/CodexUsageMonitorCore/AppServerProtocol.swift`
- Create: `Sources/CodexUsageMonitorCore/CodexExecutableResolver.swift`

1. Add failing protocol tests for initialize, rate-limit request, response matching and error redaction.
2. Implement a line-oriented JSON-RPC session with a 12-second timeout and guaranteed process cleanup.
3. Resolve the bundled ChatGPT `codex` binary before PATH fallbacks.
4. Run focused tests and real read-only smoke verification.

### Task 4: Foreground tracker and nonactivating overlay

**Files:**
- Create: `Sources/CodexUsageMonitorApp/AppDelegate.swift`
- Create: `Sources/CodexUsageMonitorApp/ChatGPTWindowTracker.swift`
- Create: `Sources/CodexUsageMonitorApp/OverlayPanelController.swift`
- Create: `Sources/CodexUsageMonitorApp/UsageView.swift`
- Create: `Sources/CodexUsageMonitorApp/main.swift`

1. Observe `NSWorkspace.didActivateApplicationNotification` and hide unless the frontmost Bundle ID is `com.openai.codex`.
2. Track the selected ChatGPT window while active and update the panel frame without activation.
3. Refresh usage on activation, every 60 seconds and from the card button.
4. Build and run against the real ChatGPT window.

### Task 5: Package, install and verify

**Files:**
- Create: `Resources/Info.plist`
- Create: `scripts/package-app.sh`
- Create: `scripts/check-live.sh`
- Create: `README.md`

1. Package the release binary into `dist/Codex Usage Monitor.app` with `LSUIElement=true` and ad-hoc signing.
2. Run tests, release build, packaging, signature inspection and live read-only verification.
3. Install the verified app to `~/Applications`, launch it, and visually verify show/follow/hide against ChatGPT.
4. Review the final Diff and commit all source changes on `main`.
