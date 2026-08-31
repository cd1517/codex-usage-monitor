# Codex 用量浮窗

这是一个独立的 macOS 菜单栏应用，不是插件，也不需要在 Codex 输入任何指令。

应用运行后：

- ChatGPT.app 存在可见主窗口时，用量横条自动显示在“分享”按钮左侧。
- 悬停横条时平滑变形成圆角阴影弹窗，显示重置日期、重置额度和截止有效期。
- ChatGPT 切换到后台时，横条仍保持附着，但会降至普通窗口层级，允许其他应用窗口自然遮挡。
- ChatGPT 主窗口最小化、关闭或应用退出后，横条自动隐藏。
- 横条不会激活应用或抢走键盘焦点，不影响 Codex 输入。
- 用量每 60 秒刷新；也可点击菜单栏的闪电图标，选择“刷新用量”。
- 退出时点击菜单栏闪电图标，选择“退出 Codex 用量浮窗”。

## 本地验证

```bash
./scripts/test.sh
./scripts/check-live.sh
./scripts/package-app.sh
```

打包产物位于 `dist/Comoni.app`。应用只调用 ChatGPT 内置 Codex 的只读 `account/rateLimits/read`，不会修改 ChatGPT、账户、额度或 Codex 配置。
