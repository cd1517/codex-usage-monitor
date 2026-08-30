import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

@MainActor
final class OverlayPanelController {
    static let compactSize = CGSize(width: 220, height: 30)
    static let expandedSize = CGSize(width: 300, height: 132)

    private let panel: NSPanel
    private let hoverRelay: HoverRelay
    private var chatGPTWindow: CGRect?
    private var isExpanded = false

    init(viewModel: UsageViewModel) {
        let hoverRelay = HoverRelay()
        self.hoverRelay = hoverRelay
        panel = NonactivatingPanel(
            contentRect: CGRect(origin: .zero, size: Self.compactSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(
            rootView: UsageView(
                viewModel: viewModel,
                onHoverChange: { isHovering in
                    hoverRelay.handler?(isHovering)
                }
            )
        )
        panel.isOpaque = true
        panel.backgroundColor = .windowBackgroundColor
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.alphaValue = 1
        panel.isMovable = false
        panel.isReleasedWhenClosed = false

        hoverRelay.handler = { [weak self] isHovering in
            self?.setExpanded(isHovering)
        }
    }

    func show(attachedTo chatGPTWindow: CGRect) {
        self.chatGPTWindow = chatGPTWindow
        let frame = overlayFrame(chatGPTWindow: chatGPTWindow, panelSize: currentSize)
        panel.setFrame(frame, display: panel.isVisible)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        isExpanded = false
        panel.orderOut(nil)
    }

    private var currentSize: CGSize {
        isExpanded ? Self.expandedSize : Self.compactSize
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded, let chatGPTWindow else {
            return
        }
        isExpanded = expanded
        let frame = overlayFrame(chatGPTWindow: chatGPTWindow, panelSize: currentSize)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }
}

private final class HoverRelay {
    var handler: ((Bool) -> Void)?
}

private final class NonactivatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
