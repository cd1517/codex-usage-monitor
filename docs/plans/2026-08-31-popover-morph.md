# Usage Strip Popover Morph Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将标题栏用量横条平滑变形成有圆角、描边和阴影的详情弹窗，并补齐低余量颜色和横条间距。

**Architecture:** 继续复用单个 `NSPanel`，由 AppKit 唯一控制展开状态和 frame 动画，SwiftUI 根据同一 presentation 状态切换紧凑/详情内容与弹窗装饰。颜色边界放入 Core 纯函数，便于无 AppKit 环境回归测试。

**Tech Stack:** Swift 5 language mode、AppKit、SwiftUI、CoreGraphics、仓库本地 Swift 测试脚本。

---

### Task 1: 低余量颜色边界

**Files:**
- Modify: `Tests/CodexUsageMonitorCoreTests/UsageSnapshotTests.swift`
- Modify: `Sources/CodexUsageMonitorCore/UsageSnapshot.swift`

1. 添加 `nil`、`0%`、`10%`、`11%` 的失败测试，期望仅 `0...10%` 返回警告状态。
2. 运行 `./scripts/test.sh UsageSnapshotTests`，确认因缺少函数失败。
3. 实现 `isLowRemainingUsage(_:)` 纯函数。
4. 重跑聚焦测试与完整测试，确认通过。

### Task 2: 横条布局与变形弹窗

**Files:**
- Modify: `Sources/CodexUsageMonitorApp/UsageView.swift`
- Modify: `Sources/CodexUsageMonitorApp/OverlayPanelController.swift`

1. 横条组内间距改为 `7pt`，两组之间保留 `1×18pt` 竖分隔线，最右侧继续保留分享分隔线。
2. 数值使用 `isLowRemainingUsage` 决定系统橙色，标签保持次要文字色。
3. 展开态增加 `14pt` 圆角、细描边、系统窗口背景和阴影；紧凑态保持无边框、无阴影、标题栏同色。
4. 面板以右上角为固定锚点，用 `0.22s easeInEaseOut` 动画改变 frame；SwiftUI 内容和装饰使用同节奏动画，收起反向执行。
5. 运行 `./scripts/build.sh debug`，确认无编译错误。

### Task 3: 安装与验收

**Files:**
- No source additions.

1. 运行 `./scripts/test.sh` 和 `./scripts/check-live.sh`。
2. 运行 `./scripts/package-app.sh`，验证签名。
3. 替换 `/Users/hey/Applications/Codex Usage Monitor.app` 并重启。
4. 验证紧凑态、变形动画、展开弹窗层次、悬停稳定、低余量橙色与应用切换隐藏。
5. 审查最终 Diff，只暂存任务文件并提交 `main`。
