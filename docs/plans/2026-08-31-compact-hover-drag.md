# Compact Hover and Drag Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the usage overlay smaller, translucent until hovered, and draggable with remembered ChatGPT-relative placement.

**Architecture:** Add pure placement conversion and clamping functions to the core geometry module. The AppKit panel receives mouse tracking and drag events without becoming key, persists normalized placement in `UserDefaults`, and renders a compact SwiftUI card.

**Tech Stack:** Swift 6 toolchain in Swift 5 language mode, AppKit, SwiftUI, CoreGraphics, repository-local test runner.

---

### Task 1: Relative placement geometry

**Files:**
- Modify: `Tests/CodexUsageMonitorCoreTests/WindowGeometryTests.swift`
- Modify: `Sources/CodexUsageMonitorCore/WindowGeometry.swift`

1. Add failing tests for converting top-right/bottom-left frames into normalized placement.
2. Add failing tests for restoring a placement and clamping an off-window frame to a `12pt` inset.
3. Run `./scripts/test.sh WindowGeometryTests` and confirm RED.
4. Implement `OverlayPlacement`, placement restoration, capture and clamping functions.
5. Run the focused test and the complete test suite; confirm GREEN.

### Task 2: Compact interactive panel

**Files:**
- Modify: `Sources/CodexUsageMonitorApp/UsageView.swift`
- Modify: `Sources/CodexUsageMonitorApp/OverlayPanelController.swift`

1. Set the panel and card to `280×170` with compact typography and spacing.
2. Add an `NSHostingView` subclass with `.activeAlways` tracking and drag callbacks.
3. Keep the nonactivating/key restrictions, but accept pointer events.
4. Animate panel opacity between `0.65` and `1.0` on pointer exit/entry.
5. Clamp drag frames and save normalized placement at mouse-up.
6. Restore saved placement whenever the ChatGPT window frame changes.
7. Run tests and `./scripts/build.sh debug`.

### Task 3: Package and real UI verification

**Files:**
- Modify: `README.md`

1. Document hover opacity, compact size and drag-position memory.
2. Run `./scripts/test.sh`, `./scripts/check-live.sh`, and `./scripts/package-app.sh`.
3. Replace the installed app, relaunch it and verify its signature.
4. Visually verify default translucency, hover opacity, drag persistence and app-switch hiding.
5. Review the final diff and commit on `main`.
