import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var presentation: OverlayPresentation

    private var metrics: OverlayMetrics {
        presentation.metrics
    }

    var body: some View {
        compactStrip
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background {
            RoundedRectangle(
                cornerRadius: metrics.compactCornerRadius,
                style: .continuous
            )
            .fill(Color.primary.opacity(0.055))
            .opacity(
                presentation.isHovering || presentation.isFontMenuOpen
                    ? 1
                    : 0
            )
        }
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.1), value: presentation.isHovering)
        .animation(.easeInOut(duration: 0.16), value: presentation.fontSize)
    }

    private var compactStrip: some View {
        HStack(spacing: metrics.compactSpacing) {
            compactValue(
                label: presentation.localization.compactPrimaryLabel,
                value: windows[0].remainingPercent
            )

            Image(systemName: "bolt.fill")
                .font(.system(size: metrics.iconSize, weight: .regular))
                .foregroundStyle(Color(nsColor: .systemBlue))
                .frame(width: metrics.iconWidth, height: metrics.iconHeight)
                .padding(.horizontal, metrics.boltHorizontalPadding)

            compactValue(
                label: presentation.localization.compactSecondaryLabel,
                value: windows[1].remainingPercent
            )

            FontSizeMenuButton(
                selectedSize: presentation.fontSize,
                selectedLanguage: presentation.overlayLanguage,
                menuTitle: presentation.localization.fontSizeMenuTitle,
                languageMenuTitle: presentation.localization.languageMenuTitle,
                autoLanguageLabel: presentation.localization.autoLanguageLabel,
                symbolPointSize: metrics.iconSize,
                onSelect: presentation.selectFontSize,
                onSelectLanguage: presentation.selectLanguage,
                onTrackingChange: presentation.setFontMenuOpen
            )
            .frame(width: metrics.menuButtonSize, height: metrics.menuButtonSize)
        }
        .padding(.leading, metrics.compactLeadingPadding)
        .padding(.trailing, metrics.compactTrailingPadding)
    }

    private func compactValue(label: String, value: Int?) -> some View {
        HStack(spacing: metrics.compactValueSpacing) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value.map { "\($0)%" } ?? "--")
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(
                    isLowRemainingUsage(value)
                        ? Color(nsColor: .systemOrange)
                        : Color.primary
                )
        }
        .font(.system(size: metrics.fontSize, weight: .regular))
        .fixedSize()
    }

    private var windows: [UsageWindow] {
        viewModel.snapshot?.windows ?? [
            UsageWindow(label: "5 小时", remainingPercent: nil, resetsAt: nil),
            UsageWindow(label: "1 周", remainingPercent: nil, resetsAt: nil)
        ]
    }

}

private struct FontSizeMenuButton: NSViewRepresentable {
    let selectedSize: Int
    let selectedLanguage: String
    let menuTitle: String
    let languageMenuTitle: String
    let autoLanguageLabel: String
    let symbolPointSize: CGFloat
    let onSelect: (Int) -> Void
    let onSelectLanguage: (String) -> Void
    let onTrackingChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.setButtonType(.momentaryChange)
        button.isBordered = false
        button.bezelStyle = .inline
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.contentTintColor = .secondaryLabelColor
        button.setAccessibilityLabel(menuTitle)
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        updateButtonImage(button)
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.parent = self
        nsView.toolTip = menuTitle
        nsView.setAccessibilityLabel(menuTitle)
        updateButtonImage(nsView)
    }

    private func updateButtonImage(_ button: NSButton) {
        let configuration = NSImage.SymbolConfiguration(
            pointSize: symbolPointSize,
            weight: .regular
        )
        button.image = NSImage(
            systemSymbolName: "ellipsis",
            accessibilityDescription: menuTitle
        )?.withSymbolConfiguration(configuration)
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var parent: FontSizeMenuButton
        private let menu = NSMenu()

        init(parent: FontSizeMenuButton) {
            self.parent = parent
            super.init()
            menu.delegate = self
            menu.autoenablesItems = false
        }

        @objc func showMenu(_ sender: NSButton) {
            rebuildMenu()
            menu.popUp(
                positioning: nil,
                at: CGPoint(x: sender.bounds.maxX, y: sender.bounds.minY - 2),
                in: sender
            )
        }

        @objc private func selectFontSize(_ sender: NSMenuItem) {
            guard let size = sender.representedObject as? Int else {
                return
            }
            parent.onSelect(size)
        }

        @objc private func selectLanguage(_ sender: NSMenuItem) {
            guard let language = sender.representedObject as? String else {
                return
            }
            parent.onSelectLanguage(language)
        }

        func menuWillOpen(_ menu: NSMenu) {
            parent.onTrackingChange(true)
        }

        func menuDidClose(_ menu: NSMenu) {
            parent.onTrackingChange(false)
        }

        private func rebuildMenu() {
            menu.removeAllItems()
            menu.title = parent.menuTitle
            for size in supportedOverlayFontSizes {
                let item = NSMenuItem(
                    title: "\(size)pt",
                    action: #selector(selectFontSize(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = size
                item.state = size == parent.selectedSize ? .on : .off
                menu.addItem(item)
            }
            menu.addItem(.separator())
            menu.addItem(languageMenuItem())
        }

        private func languageMenuItem() -> NSMenuItem {
            let languageMenu = NSMenu(title: parent.languageMenuTitle)
            languageMenu.autoenablesItems = false
            let choices: [(value: String, title: String)] = [
                ("auto", parent.autoLanguageLabel),
                ("zh-Hans", "简体中文"),
                ("zh-Hant", "繁體中文"),
                ("en", "English"),
                ("ja", "日本語")
            ]
            for choice in choices {
                let item = NSMenuItem(
                    title: choice.title,
                    action: #selector(selectLanguage(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = choice.value
                item.state = choice.value == parent.selectedLanguage ? .on : .off
                languageMenu.addItem(item)
            }
            let languageItem = NSMenuItem(
                title: parent.languageMenuTitle,
                action: nil,
                keyEquivalent: ""
            )
            languageItem.submenu = languageMenu
            return languageItem
        }
    }
}

@MainActor
final class OverlayPresentation: ObservableObject {
    private static let fontSizeDefaultsKey = "usageOverlayFontSize"
    private static let languageDefaultsKey = "usageOverlayLanguage"

    @Published var isHovering = false
    @Published var isDetailVisible = false
    @Published private(set) var fontSize: Int
    @Published private(set) var isFontMenuOpen = false
    @Published private(set) var overlayLanguage: String
    @Published private(set) var localization: UsageLocalization

    var onFontSizeChange: (() -> Void)?
    var onMenuTrackingChange: ((Bool) -> Void)?

    private let userDefaults: UserDefaults

    init(
        userDefaults: UserDefaults = .standard,
        localeIdentifier: String? = ChatGPTLanguageDetector.detect()
    ) {
        self.userDefaults = userDefaults
        let storedSize = (userDefaults.object(forKey: Self.fontSizeDefaultsKey) as? NSNumber)?.intValue
        fontSize = normalizedOverlayFontSize(storedSize)
        let storedLanguage = normalizedOverlayLanguage(
            userDefaults.string(forKey: Self.languageDefaultsKey)
        )
        overlayLanguage = storedLanguage
        localization = UsageLocalization(
            localeIdentifier: storedLanguage == "auto"
                ? localeIdentifier ?? Locale.preferredLanguages.first ?? "en-US"
                : storedLanguage
        )
    }

    var metrics: OverlayMetrics {
        OverlayMetrics(fontSize: fontSize)
    }

    func selectFontSize(_ size: Int) {
        let normalizedSize = normalizedOverlayFontSize(size)
        guard normalizedSize != fontSize else {
            return
        }
        fontSize = normalizedSize
        userDefaults.set(normalizedSize, forKey: Self.fontSizeDefaultsKey)
        onFontSizeChange?()
    }

    func selectLanguage(_ language: String) {
        let normalizedLanguage = normalizedOverlayLanguage(language)
        guard normalizedLanguage != overlayLanguage else {
            return
        }
        overlayLanguage = normalizedLanguage
        userDefaults.set(normalizedLanguage, forKey: Self.languageDefaultsKey)
        refreshLanguage()
    }

    func setFontMenuOpen(_ isOpen: Bool) {
        guard isOpen != isFontMenuOpen else {
            return
        }
        isFontMenuOpen = isOpen
        onMenuTrackingChange?(isOpen)
    }

    func refreshLanguage() {
        let localeIdentifier = overlayLanguage == "auto"
            ? ChatGPTLanguageDetector.detect()
            : overlayLanguage
        guard let localeIdentifier else {
            return
        }
        let detected = UsageLocalization(localeIdentifier: localeIdentifier)
        guard detected != localization else {
            return
        }
        localization = detected
    }
}
