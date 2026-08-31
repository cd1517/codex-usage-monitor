import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = UsageViewModel()
    private lazy var panelController = OverlayPanelController(viewModel: viewModel)
    private let windowTracker = ChatGPTWindowTracker()
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()

        windowTracker.onWindowChange = { [weak self] window in
            guard let self else {
                return
            }
            if let window {
                self.panelController.show(
                    attachedTo: window.frame,
                    relativeTo: window.windowNumber
                )
            } else {
                self.panelController.hide()
            }
        }
        windowTracker.onFrontmostChange = { [weak self] isFrontmost in
            self?.panelController.setChatGPTFrontmost(isFrontmost)
        }
        windowTracker.onActivation = { [weak self] in
            self?.panelController.refreshLanguage()
            self?.viewModel.refresh()
        }
        windowTracker.start()
        viewModel.refresh()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.panelController.refreshLanguage()
                self?.viewModel.refresh()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        windowTracker.stop()
    }

    @objc private func refreshUsage() {
        viewModel.refresh()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: "Codex 用量")

        let menu = NSMenu()
        let refreshItem = NSMenuItem(title: "刷新用量", action: #selector(refreshUsage), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 Codex 用量浮窗", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        item.menu = menu
        statusItem = item
    }
}
