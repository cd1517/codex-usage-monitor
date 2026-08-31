# Native Attachment and Font Menu Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a native 14–20pt font menu, scale the complete overlay with the selected size, keep the compact strip fixed while its details grow as one extension, and preserve the overlay on ChatGPT while other apps can cover it.

**Architecture:** Put font normalization and overlay geometry in the testable core target. Keep one nonactivating normal-level `NSPanel`; its world-space top-right anchor stays constant while an AppKit-backed font menu and a stepped SwiftUI surface extend left and downward. Track ChatGPT whenever it has a visible main window, using a fast foreground cadence and a low-cost background cadence.

**Tech Stack:** Swift 5 language mode, AppKit, SwiftUI, CoreGraphics, repository test runner, shell build/package scripts.

---

### Task 1: Lock font and geometry behavior with core tests

**Files:**
- Create: `Sources/CodexUsageMonitorCore/OverlayMetrics.swift`
- Create: `Tests/CodexUsageMonitorCoreTests/OverlayMetricsTests.swift`
- Modify: `Tests/CodexUsageMonitorCoreTests/TestMain.swift`

**Step 1: Write failing tests**

Cover the default `18pt`, clamping to the supported `14...20` range, integer menu values, monotonic compact/detail growth, and preservation of the compact strip's top-right world frame when the full panel expands.

**Step 2: Run the focused suite and confirm failure**

Run: `./scripts/test.sh OverlayMetrics`

Expected: compilation fails because the metrics API does not exist.

**Step 3: Implement the minimum core API**

Add `OverlayMetrics`, `normalizedOverlayFontSize(_:)`, and an expanded-frame helper derived from a compact top-right anchor. Keep the constants proportional to the selected font and preserve the current `18pt` visual dimensions.

**Step 4: Run the focused suite and confirm pass**

Run: `./scripts/test.sh OverlayMetrics`

Expected: `PASS OverlayMetricsTests`.

**Step 5: Commit**

Commit message: `test: 定义字号与浮窗几何行为`

### Task 2: Add the native font menu and unified extension

**Files:**
- Modify: `Sources/CodexUsageMonitorApp/UsageView.swift`
- Modify: `Sources/CodexUsageMonitorApp/OverlayPanelController.swift`
- Modify: `Sources/CodexUsageMonitorApp/AppDelegate.swift`

**Step 1: Add persistent presentation state**

Read and write the selected integer size through `UserDefaults`, defaulting invalid or absent values to `18pt`. Expose menu-tracking state so hover collapse pauses while the native menu is open.

**Step 2: Build the native ellipsis control**

Wrap an AppKit pull-down control with `NSViewRepresentable`. Populate `14pt` through `20pt`, check the current item, update immediately on selection, and report menu open/close through `NSMenuDelegate`.

**Step 3: Rebuild the overlay layout**

Use `OverlayMetrics` for all fonts, dimensions, padding, and spacing. Place the compact strip at the root view's top-right. Draw one stepped surface behind the fixed compact strip and the growing detail body. Keep the lightning symbol blue and retain orange usage values at or below 10%.

**Step 4: Keep the compact anchor fixed during animation**

Resize the panel left/down from a shared top-right anchor. Animate the stepped view and panel frame together; do not change the compact strip's screen position or size during hover expansion.

**Step 5: Build and inspect compiler output**

Run: `./scripts/build.sh release`

Expected: release binary builds without warnings or errors.

**Step 6: Commit**

Commit message: `feat: 添加原生字号菜单与一体延伸`

### Task 3: Preserve native-like attachment in the background

**Files:**
- Modify: `AGENTS.md`
- Modify: `Sources/CodexUsageMonitorApp/ChatGPTWindowTracker.swift`
- Modify: `Sources/CodexUsageMonitorApp/AppDelegate.swift`
- Modify: `Sources/CodexUsageMonitorApp/OverlayPanelController.swift`
- Modify: `Sources/CodexUsageMonitorCore/WindowGeometry.swift`
- Modify: `Tests/CodexUsageMonitorCoreTests/WindowGeometryTests.swift`

**Step 1: Update the project behavior contract**

Replace the obsolete foreground-only rule with the new native-attachment rule: visible over ChatGPT even in the background, naturally covered by other apps, hidden only without a visible ChatGPT main window.

**Step 2: Add a failing window-selection regression test**

Verify that a cached window is rejected once it is offscreen or minimized, while a visible background main window remains selectable.

**Step 3: Tighten cached-window selection**

Require the tracked descriptor to remain a visible, normal, nontransparent usable window so minimization and closure hide the overlay.

**Step 4: Track running ChatGPT independently of frontmost state**

Keep the target PID and main window while another app is active. Use approximately 60Hz while ChatGPT is frontmost and a low-frequency timer while backgrounded. Emit frontmost changes separately from frame availability.

**Step 5: Adopt normal window ordering**

Use `.normal` panel level. Bring the panel forward when ChatGPT activates; when another app activates, leave it visible without reordering so that app's normal windows cover it.

**Step 6: Run focused and full verification**

Run: `./scripts/test.sh WindowGeometry`

Run: `./scripts/test.sh`

Run: `./scripts/build.sh release`

Expected: all suites pass and the release build succeeds.

**Step 7: Commit**

Commit message: `feat: 让浮窗原生附着于 ChatGPT`

### Task 4: Package, install, and verify the real UI

**Files:**
- Generated only: `dist/Codex Usage Monitor.app`
- Installed copy: `/Users/hey/Applications/Codex Usage Monitor.app`

**Step 1: Package and verify signing**

Run: `./scripts/package-app.sh`

Expected: `plutil` and `codesign --verify --deep --strict` pass.

**Step 2: Install the tested build**

Replace the existing installed application with the newly packaged application, then launch it.

**Step 3: Perform live acceptance**

Check all seven font choices and persistence after relaunch; confirm metrics grow with font size; confirm the compact strip does not move during hover; confirm the detail surface grows as one extension; confirm the lightning is blue; confirm another app covers the panel while returning to ChatGPT restores it; confirm minimizing/closing ChatGPT hides it.

**Step 4: Review repository state**

Run: `git status --short --branch`

Run: `git log -4 --oneline`

Expected: `main` is clean and all implementation commits are present.
