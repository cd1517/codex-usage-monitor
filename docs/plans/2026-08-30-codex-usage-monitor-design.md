# Codex Usage Monitor 设计

应用采用原生 AppKit 菜单栏进程，不显示 Dock 图标。`NSWorkspace` 负责监听前台应用变化：当前 Bundle ID 为 `com.openai.codex` 时，应用从 `CGWindowListCopyWindowInfo` 中选择该进程面积最大的可见普通窗口；切换到其他应用时立即隐藏浮窗。窗口跟踪仅读取进程 ID 和窗口边界，不申请辅助功能或屏幕录制权限。浮窗使用不激活的无边框 `NSPanel`，固定在 ChatGPT 主窗口对话区右上方并随窗口移动，不抢输入焦点。

用量读取通过本机 ChatGPT.app 内置的 `codex app-server --stdio` 完成。客户端先发送 `initialize`，再调用只读方法 `account/rateLimits/read`，只保留五小时窗口、七天窗口、重置时间、套餐、Credits 和可用重置次数。启动、ChatGPT 再次进入前台及每 60 秒刷新一次；菜单栏提供手动刷新。读取失败时不暴露 stderr 或凭据：已有成功快照则保留并显示过期提示，没有快照则显示明确错误。

核心逻辑与 UI 分离。用量归一化、窗口筛选、多显示器坐标转换和浮窗锚点计算均为纯函数，用测试覆盖；App Server 使用可替换传输层做协议测试，并以真实只读联调补足进程边界。应用打包为 ad-hoc 签名的 `.app`，安装到用户级 `~/Applications`，不修改 ChatGPT.app。旧插件仅保持未安装状态，源码不删除。
