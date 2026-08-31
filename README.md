<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Comoni：将 Codex 剩余用量横条贴在 ChatGPT 标题栏，并在横条下方展开详情窗口 | A macOS menu bar app that places Codex remaining usage in the ChatGPT title bar">
</p>

<p align="center">
  <a href="#简体中文">简体中文</a>
  ·
  <a href="#english">English</a>
</p>

## 简体中文

Comoni 是一个独立的 macOS 菜单栏应用。它把 Codex 的 **5 小时**与**1 周**剩余用量以横条形式无缝贴在 ChatGPT 标题栏上；悬停横条时，详情窗口从横条下方弹出。无需打开设置，也不会抢走输入焦点。

<p align="center">
  <a href="https://github.com/cd1517/comoni/releases/latest"><strong>下载最新版本</strong></a>
  ·
  <a href="#终端安装">终端安装</a>
  ·
  <a href="#本地开发">本地开发</a>
</p>

### 界面如何工作

ChatGPT 标题栏默认只显示一条紧凑的用量横条；悬停横条时，其下方弹出详情窗口，包括两个用量窗口的重置时间、可用限额重置次数和有效期，文案与日期格式跟随所选语言。横条右侧「···」菜单提供两组设置：「字号」（`14–20pt`）和「语言」（简体中文 / 繁體中文 / English / 日本語，选择立即生效并自动记住；默认「自动」跟随 macOS 系统语言）。

| ChatGPT 状态 | 浮窗行为 |
| --- | --- |
| 主窗口可见且位于前台 | 横条附着在标题栏，详情窗口在横条下方弹出 |
| 切换到其他应用 | 继续跟随 ChatGPT 窗口，但允许其他窗口自然遮挡 |
| 主窗口最小化、关闭或 ChatGPT 退出 | 自动隐藏 |

用量每 60 秒自动刷新。也可以点击菜单栏闪电图标，选择「刷新用量」或退出应用。

### 安装

#### 终端安装

要求 **macOS 14 或更高版本**。复制下面一行到终端：

```bash
curl -fsSL https://raw.githubusercontent.com/cd1517/comoni/main/scripts/install.sh | bash
```

安装完成后启动：

```bash
open "/Applications/Comoni.app"
```

#### 手动安装

从 [Releases](https://github.com/cd1517/comoni/releases/latest) 下载 DMG，将 `Comoni.app` 拖入「应用程序」。

启动 ChatGPT 并保持主窗口可见，用量横条会自动贴在标题栏上。Codex 数据暂时不可读取时，界面会明确显示「不可用」，不会估算剩余额度。

### 只读与隐私边界

- 仅调用 ChatGPT 内置 Codex App Server 的只读方法 `account/rateLimits/read`。
- 不读取、保存或输出账号凭据，也不修改 ChatGPT、Codex 配置或账户额度。
- 不需要辅助功能权限；窗口附着只使用 macOS 提供的前台应用信息与可见窗口边界。
- 浮窗使用非激活窗口，不会夺取 ChatGPT 的键盘焦点。

这是一个独立的第三方工具，不是 ChatGPT 插件。当前实现识别 Bundle ID 为 `com.openai.codex` 的 macOS 桌面应用；如果 ChatGPT 调整内置 App Server 接口或应用标识，读取功能可能需要同步更新。

### 本地开发

项目使用 Swift、AppKit 与 SwiftUI，无第三方运行时依赖。核心逻辑与 UI 分离：

```text
Sources/
├── ComoniCore/       # 用量模型、JSON-RPC、窗口与几何逻辑
├── ComoniApp/        # 菜单栏、浮窗和应用生命周期
└── ComoniCheck/      # 只读联调入口
Tests/
└── ComoniCoreTests/  # 无依赖测试运行器
```

运行最小验证：

```bash
./scripts/test.sh
./scripts/check-live.sh
./scripts/build.sh release
```

打包应用或 DMG：

```bash
./scripts/package-app.sh
./scripts/package-dmg.sh
```

产物写入 `dist/`。最终界面行为仍需在真实 ChatGPT 前台、后台、移动、最小化和关闭场景中检查。

## English

Comoni is an independent macOS menu bar app. It places your remaining **5-hour** and **1-week** Codex usage in a compact strip integrated into the ChatGPT title bar. Hover over the strip to open a detail window directly beneath it—without opening settings or stealing keyboard focus.

<p align="center">
  <a href="https://github.com/cd1517/comoni/releases/latest"><strong>Latest Release</strong></a>
  ·
  <a href="#terminal-install">Terminal Install</a>
  ·
  <a href="#local-development">Local Development</a>
</p>

### How it works

The ChatGPT title bar normally shows only the compact usage strip. Hovering over it opens a detail window below with reset times for both usage windows, available reset credits, and their expiration date, rendered in the selected language. The ··· menu on the right side of the strip offers two settings: Font Size (`14–20pt`) and Language (简体中文 / 繁體中文 / English / 日本語). Language changes apply immediately and are remembered across relaunches; the default Auto follows the macOS system language.

| ChatGPT state | Monitor behavior |
| --- | --- |
| Main window visible and frontmost | The strip stays in the title bar; details open directly beneath it |
| Another app is active | The monitor remains attached to ChatGPT but allows other windows to cover it naturally |
| Main window minimized or closed, or ChatGPT quits | The monitor hides automatically |

Usage refreshes every 60 seconds. You can also click the lightning icon in the menu bar to refresh manually or quit the app.

### Install

#### Terminal install

Requires **macOS 14 or later**. Paste this command into Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/cd1517/comoni/main/scripts/install.sh | bash
```

Launch the app after installation:

```bash
open "/Applications/Comoni.app"
```

#### Manual install

Download the DMG from [Releases](https://github.com/cd1517/comoni/releases/latest), then drag `Comoni.app` into Applications.

Launch ChatGPT and keep its main window visible. The usage strip will attach to the title bar automatically. If Codex usage data cannot be read, the app displays “Unavailable” instead of estimating a value.

### Read-only and privacy boundaries

- Calls only the read-only `account/rateLimits/read` method exposed by ChatGPT's built-in Codex App Server.
- Does not read, store, or print account credentials, and does not modify ChatGPT, Codex configuration, or account limits.
- Requires no Accessibility permission; window attachment uses macOS frontmost-app information and visible window bounds only.
- Uses non-activating panels, so it does not take keyboard focus away from ChatGPT.

This is an independent third-party utility, not a ChatGPT plugin. The current implementation recognizes the macOS desktop app with bundle ID `com.openai.codex`. Changes to ChatGPT's built-in App Server or bundle identifier may require a corresponding update.

### Local development

The project uses Swift, AppKit, and SwiftUI with no third-party runtime dependencies. Core logic is kept separate from the UI:

```text
Sources/
├── ComoniCore/       # Usage models, JSON-RPC, window and geometry logic
├── ComoniApp/        # Menu bar, overlay panels, and app lifecycle
└── ComoniCheck/      # Read-only live-check entry point
Tests/
└── ComoniCoreTests/  # Dependency-free test runner
```

Run the minimum verification set:

```bash
./scripts/test.sh
./scripts/check-live.sh
./scripts/build.sh release
```

Package the app or DMG:

```bash
./scripts/package-app.sh
./scripts/package-dmg.sh
```

Artifacts are written to `dist/`. Final UI behavior should still be checked with a real ChatGPT window while frontmost, backgrounded, moved, minimized, and closed.

## License

[MIT](LICENSE)
