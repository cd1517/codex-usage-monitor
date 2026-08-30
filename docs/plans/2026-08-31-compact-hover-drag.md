# Title Bar Usage Strip Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the large usage card with a fixed opaque strip immediately left of ChatGPT's Share button, with hover-only details.

**Architecture:** Anchor a nonactivating panel to a tested title-bar offset from the ChatGPT window's right edge. Render two remaining-percentage values and a right-side separator in the compact state, then resize the same panel downwards on hover to reveal dates and reset-credit expiry.

**Tech Stack:** Swift 6 toolchain in Swift 5 language mode, AppKit, SwiftUI, CoreGraphics, repository-local test runner.

---

### Task 1: Title-bar strip geometry

**Files:**
- Modify: `Tests/CodexUsageMonitorCoreTests/WindowGeometryTests.swift`
- Modify: `Sources/CodexUsageMonitorCore/WindowGeometry.swift`

1. Replace the old card-anchor test with a failing test for `220×30` title-bar placement left of the Share controls.
2. Add a failing test that clamps the strip inside a narrow ChatGPT window.
3. Run `./scripts/test.sh WindowGeometryTests` and confirm RED.
4. Implement the fixed right-control reservation and narrow-window clamp.
5. Run the focused test and the complete test suite; confirm GREEN.

### Task 2: Reset-credit expiry data

**Files:**
- Modify: `Tests/CodexUsageMonitorCoreTests/UsageSnapshotTests.swift`
- Modify: `Tests/CodexUsageMonitorCoreTests/AppServerProtocolTests.swift`
- Modify: `Sources/CodexUsageMonitorCore/UsageSnapshot.swift`

1. Add failing tests for decoding reset-credit details and exposing the earliest expiry date.
2. Run the focused and complete tests; confirm RED.
3. Add the smallest Codable reset-credit detail model and normalized expiry property.
4. Run the complete suite; confirm GREEN.

### Task 3: Compact opaque strip with hover details

**Files:**
- Modify: `Sources/CodexUsageMonitorApp/UsageView.swift`
- Modify: `Sources/CodexUsageMonitorApp/OverlayPanelController.swift`

1. Set the panel and view to `220×30`.
2. Render the Codex icon, `5小时` remaining percentage, divider, `7天` remaining percentage and a final Share-side separator in one row.
3. Use a solid window-background fill and keep `alphaValue=1`.
4. Accept hover events while preserving the nonactivating/key restrictions.
5. Expand the same panel below the strip to show reset dates, reset-credit count and earliest expiry.
6. Run tests and `./scripts/build.sh debug`.

### Task 4: Package and real UI verification

**Files:**
- Modify: `README.md`

1. Document the fixed opaque title-bar strip, right separator and hover details.
2. Run `./scripts/test.sh`, `./scripts/check-live.sh`, and `./scripts/package-app.sh`.
3. Replace the installed app, relaunch it and verify its signature.
4. Visually verify Share-left placement, right separator, opaque appearance, hover details and app-switch hiding.
5. Review the final diff and commit on `main`.
