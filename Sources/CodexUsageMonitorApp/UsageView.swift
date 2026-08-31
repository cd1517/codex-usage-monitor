import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var presentation: OverlayPresentation

    private let morphAnimation = Animation.easeInOut(duration: 0.22)

    private var metrics: OverlayMetrics {
        presentation.metrics
    }

    private var currentSize: CGSize {
        presentation.isExpanded ? metrics.expandedSize : metrics.compactSize
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            surface

            VStack(alignment: .trailing, spacing: 0) {
                compactStrip
                    .frame(
                        width: metrics.compactSize.width,
                        height: metrics.compactSize.height
                    )

                if presentation.isExpanded {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: metrics.detailGap)
                        detailBody
                    }
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.94, anchor: .topTrailing)
                        )
                    )
                }
            }
            .frame(
                width: currentSize.width,
                height: currentSize.height,
                alignment: .topTrailing
            )
        }
        .frame(width: currentSize.width, height: currentSize.height, alignment: .topTrailing)
        .contentShape(Rectangle())
        .animation(morphAnimation, value: presentation.isExpanded)
        .animation(.easeInOut(duration: 0.16), value: presentation.fontSize)
    }

    private var surface: some View {
        ZStack(alignment: .topTrailing) {
            if presentation.isExpanded {
                RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                            .stroke(
                                Color(nsColor: .separatorColor).opacity(0.55),
                                lineWidth: 1
                            )
                    }
                    .frame(
                        width: metrics.detailPanelSize.width,
                        height: metrics.detailPanelSize.height
                    )
                    .frame(
                        width: currentSize.width,
                        height: currentSize.height,
                        alignment: .bottom
                    )
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.94, anchor: .topTrailing)
                        )
                    )
            }

            Rectangle()
                .fill(Color(nsColor: .windowBackgroundColor))
                .frame(width: metrics.compactSize.width, height: metrics.compactSize.height)
        }
        .frame(width: currentSize.width, height: currentSize.height, alignment: .topTrailing)
    }

    private var compactStrip: some View {
        HStack(spacing: metrics.compactSpacing) {
            Image(systemName: "bolt.fill")
                .font(.system(size: metrics.iconSize, weight: .regular))
                .foregroundStyle(Color(nsColor: .systemBlue))
                .frame(width: metrics.iconWidth, height: metrics.iconHeight)

            compactValue(label: "5小时", value: windows[0].remainingPercent)

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.72))
                .frame(width: 1, height: metrics.compactSeparatorHeight)

            compactValue(label: "7天", value: windows[1].remainingPercent)

            Spacer(minLength: metrics.compactSpacing)

            FontSizeMenuButton(
                selectedSize: presentation.fontSize,
                symbolPointSize: metrics.iconSize,
                onSelect: presentation.selectFontSize,
                onTrackingChange: presentation.setFontMenuOpen
            )
            .frame(width: metrics.menuButtonSize, height: metrics.menuButtonSize)
            .background {
                Circle()
                    .fill(Color.primary.opacity(0.045))
            }

            Rectangle()
                .fill(.secondary.opacity(0.45))
                .frame(width: 1, height: metrics.iconHeight)
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

    private var detailBody: some View {
        detailRows
        .frame(
            width: metrics.detailPanelSize.width,
            height: metrics.detailPanelSize.height,
            alignment: .top
        )
    }

    private var detailRows: some View {
        VStack(spacing: metrics.detailSpacing) {
            detailRow(label: "5 小时重置", value: dateText(windows[0].resetsAt))
            detailRow(label: "7 天重置", value: dateText(windows[1].resetsAt))

            Divider()

            HStack(spacing: metrics.compactSpacing) {
                Text("重置额度")
                    .foregroundStyle(.secondary)
                Text(viewModel.snapshot?.resetCreditsAvailable.map(String.init) ?? "--")
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Spacer()
                Text(expiryText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.system(size: metrics.fontSize))
        }
        .padding(.horizontal, metrics.detailHorizontalPadding)
        .padding(.top, metrics.detailTopPadding)
        .padding(.bottom, metrics.detailBottomPadding)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.system(size: metrics.fontSize))
    }

    private var windows: [UsageWindow] {
        viewModel.snapshot?.windows ?? [
            UsageWindow(label: "5 小时", remainingPercent: nil, resetsAt: nil),
            UsageWindow(label: "7 天", remainingPercent: nil, resetsAt: nil)
        ]
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else {
            return "不可用"
        }
        return date.formatted(.dateTime.month().day().hour().minute())
    }

    private var expiryText: String {
        guard let date = viewModel.snapshot?.resetCreditExpiresAt else {
            return "有效期未知"
        }
        return "有效期至 \(date.formatted(.dateTime.month().day().hour().minute()))"
    }
}

private struct FontSizeMenuButton: NSViewRepresentable {
    let selectedSize: Int
    let symbolPointSize: CGFloat
    let onSelect: (Int) -> Void
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
        button.toolTip = "设置字号"
        button.setAccessibilityLabel("设置字号")
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        updateButtonImage(button)
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.parent = self
        updateButtonImage(nsView)
    }

    private func updateButtonImage(_ button: NSButton) {
        let configuration = NSImage.SymbolConfiguration(
            pointSize: symbolPointSize,
            weight: .regular
        )
        button.image = NSImage(
            systemSymbolName: "ellipsis",
            accessibilityDescription: "设置字号"
        )?.withSymbolConfiguration(configuration)
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var parent: FontSizeMenuButton
        private let menu = NSMenu(title: "字号")

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

        func menuWillOpen(_ menu: NSMenu) {
            parent.onTrackingChange(true)
        }

        func menuDidClose(_ menu: NSMenu) {
            parent.onTrackingChange(false)
        }

        private func rebuildMenu() {
            menu.removeAllItems()
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
        }
    }
}

@MainActor
final class OverlayPresentation: ObservableObject {
    private static let fontSizeDefaultsKey = "usageOverlayFontSize"

    @Published var isExpanded = false
    @Published private(set) var fontSize: Int
    @Published private(set) var isFontMenuOpen = false

    var onFontSizeChange: (() -> Void)?
    var onMenuTrackingChange: ((Bool) -> Void)?

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedSize = (userDefaults.object(forKey: Self.fontSizeDefaultsKey) as? NSNumber)?.intValue
        fontSize = normalizedOverlayFontSize(storedSize)
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

    func setFontMenuOpen(_ isOpen: Bool) {
        guard isOpen != isFontMenuOpen else {
            return
        }
        isFontMenuOpen = isOpen
        onMenuTrackingChange?(isOpen)
    }
}
