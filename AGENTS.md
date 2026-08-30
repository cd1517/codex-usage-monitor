# Comoni 工作规范

## 目标

构建一个独立的 macOS 菜单栏应用：仅当 `ChatGPT.app` 位于前台时，在其主窗口对话区右上方显示 Codex 剩余用量浮窗；切换到其他应用后立即隐藏。

## 技术栈

- Swift 6 工具链，仓库内 `swiftc` 构建脚本
- AppKit + SwiftUI
- CoreGraphics 窗口列表
- 无依赖 Swift 测试运行器

## 目录边界

- `Sources/ComoniCore/`：用量模型、JSON-RPC、窗口选择与几何计算，必须可测试且不依赖 UI。
- `Sources/ComoniApp/`：应用生命周期、菜单栏、浮窗与系统事件。
- `Tests/ComoniCoreTests/`：核心行为测试。
- `Resources/`：应用清单和图标等打包资源。
- `scripts/`：构建、打包和只读联调脚本。
- `dist/`：生成的 `.app`，不纳入 Git。

## 行为约束

- ChatGPT Bundle ID 固定使用当前已验证值 `com.openai.codex`。
- 只调用 Codex App Server 的 `account/rateLimits/read`；禁止兑换重置额度或修改账户。
- 不读取、保存或输出账号凭据及 App Server stderr。
- 不修改 `ChatGPT.app`、`app.asar`、系统配置或 Codex 配置。
- 不申请辅助功能权限；窗口位置只使用前台应用信息和 CoreGraphics 可见窗口边界。
- 浮窗不得抢走 ChatGPT 输入焦点。
- 缺少数据时显示“不可用”，不得估算或伪造剩余量。

## 验证

- 单元测试：`./scripts/test.sh`
- Release 构建：`./scripts/build.sh release`
- 打包：`./scripts/package-app.sh`
- 只读联调：`./scripts/check-live.sh`
- 最终必须在真实 ChatGPT 前台/后台切换中检查显示、跟随和隐藏行为。

## Git

- 使用 `main` 分支。
- 提交前检查 `git status`、最终 Diff 和完整验证结果。
- 只提交本应用文件，不推送、不 rebase、不重写历史。
