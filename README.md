<div align="center">

[简体中文](./README.zh.md) · **English**

</div>

<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Comoni: a macOS menu bar app that places Codex remaining usage in the ChatGPT title bar and opens details beneath it">
</p>

<p align="center">
  <a href="https://github.com/cd1517/comoni/releases/latest"><strong>Latest Release</strong></a>
  ·
  <a href="#terminal-install">Terminal Install</a>
  ·
  <a href="#local-development">Local Development</a>
</p>

Comoni is an independent macOS menu bar app. It places your remaining **5-hour** and **1-week** Codex usage in a compact strip integrated into the ChatGPT title bar. Hover over the strip to open a detail window directly beneath it—without opening settings or stealing keyboard focus.

## How it works

The ChatGPT title bar normally shows only the compact usage strip. Hovering over it opens a detail window below with reset times for both usage windows, available reset credits, and their expiration date, rendered in the selected language. The ··· menu on the right side of the strip offers two settings: Font Size (`14–20pt`) and Language (简体中文 / 繁體中文 / English / 日本語). Language changes apply immediately and are remembered across relaunches; the default Auto follows the macOS system language.

| ChatGPT state | Monitor behavior |
| --- | --- |
| Main window visible and frontmost | The strip stays in the title bar; details open directly beneath it |
| Another app is active | The monitor remains attached to ChatGPT but allows other windows to cover it naturally |
| Main window minimized or closed, or ChatGPT quits | The monitor hides automatically |

Usage refreshes every 60 seconds. You can also click the lightning icon in the menu bar to refresh manually or quit the app.

## Install

### Terminal install

Requires **macOS 14 or later**. Paste this command into Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/cd1517/comoni/main/scripts/install.sh | bash
```

Launch the app after installation:

```bash
open "/Applications/Comoni.app"
```

### Manual install

Download the DMG from [Releases](https://github.com/cd1517/comoni/releases/latest), then drag `Comoni.app` into Applications.

Launch ChatGPT and keep its main window visible. The usage strip will attach to the title bar automatically. If Codex usage data cannot be read, the app displays “Unavailable” instead of estimating a value.

## Read-only and privacy boundaries

- Calls only the read-only `account/rateLimits/read` method exposed by ChatGPT's built-in Codex App Server.
- Does not read, store, or print account credentials, and does not modify ChatGPT, Codex configuration, or account limits.
- Requires no Accessibility permission; window attachment uses macOS frontmost-app information and visible window bounds only.
- Uses non-activating panels, so it does not take keyboard focus away from ChatGPT.

This is an independent third-party utility, not a ChatGPT plugin. The current implementation recognizes the macOS desktop app with bundle ID `com.openai.codex`. Changes to ChatGPT's built-in App Server or bundle identifier may require a corresponding update.

## Local development

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
