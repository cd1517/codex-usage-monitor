<div align="center">

**简体中文** · [English](./README.md)

</div>

<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Comoni：将 Codex 剩余用量横条贴在 ChatGPT 标题栏，并在横条下方展开详情窗口">
</p>

<p align="center">
  <a href="https://github.com/cd1517/comoni/releases/latest"><strong>下载最新版本</strong></a>
  ·
  <a href="#终端安装">终端安装</a>
  ·
  <a href="#本地开发">本地开发</a>
</p>

Comoni 是一个独立的 macOS 菜单栏应用。它把 Codex 的 **5 小时**与**1 周**剩余用量以横条形式无缝贴在 ChatGPT 标题栏上；悬停横条时，详情窗口从横条下方弹出。无需打开设置，也不会抢走输入焦点。

## 界面如何工作

ChatGPT 标题栏默认只显示一条紧凑的用量横条；悬停横条时，其下方弹出详情窗口，包括两个用量窗口的重置时间、可用限额重置次数和有效期，文案与日期格式跟随所选语言。横条右侧「···」菜单提供两组设置：「字号」（`14–20pt`）和「语言」（简体中文 / 繁體中文 / English / 日本語，选择立即生效并自动记住；默认「自动」跟随 macOS 系统语言）。

| ChatGPT 状态 | 浮窗行为 |
| --- | --- |
| 主窗口可见且位于前台 | 横条附着在标题栏，详情窗口在横条下方弹出 |
| 切换到其他应用 | 继续跟随 ChatGPT 窗口，但允许其他窗口自然遮挡 |
| 主窗口最小化、关闭或 ChatGPT 退出 | 自动隐藏 |

用量每 60 秒自动刷新。也可以点击菜单栏闪电图标，选择「刷新用量」或退出应用。

## 安装

### 终端安装

要求 **macOS 14 或更高版本**。复制下面一行到终端：

```bash
curl -fsSL https://raw.githubusercontent.com/cd1517/comoni/main/scripts/install.sh | bash
```

安装完成后启动：

```bash
open "/Applications/Comoni.app"
```

### 手动安装

从 [Releases](https://github.com/cd1517/comoni/releases/latest) 下载 DMG，将 `Comoni.app` 拖入「应用程序」。

启动 ChatGPT 并保持主窗口可见，用量横条会自动贴在标题栏上。Codex 数据暂时不可读取时，界面会明确显示「不可用」，不会估算剩余额度。

## 只读与隐私边界

- 仅调用 ChatGPT 内置 Codex App Server 的只读方法 `account/rateLimits/read`。
- 不读取、保存或输出账号凭据，也不修改 ChatGPT、Codex 配置或账户额度。
- 不需要辅助功能权限；窗口附着只使用 macOS 提供的前台应用信息与可见窗口边界。
- 浮窗使用非激活窗口，不会夺取 ChatGPT 的键盘焦点。

这是一个独立的第三方工具，不是 ChatGPT 插件。当前实现识别 Bundle ID 为 `com.openai.codex` 的 macOS 桌面应用；如果 ChatGPT 调整内置 App Server 接口或应用标识，读取功能可能需要同步更新。

## 本地开发

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

## License

[MIT](LICENSE)
