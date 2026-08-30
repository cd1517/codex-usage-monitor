import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import ComoniCore
#endif

@MainActor
final class OverlayPanelController {
    static let panelSize = CGSize(width: 352, height: 232)

    private let panel: NSPanel

    init(viewModel: UsageViewModel) {
        panel = NonactivatingPanel(
            contentRect: CGRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: UsageView(viewModel: viewModel))
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
    }

    func show(attachedTo chatGPTWindow: CGRect) {
        let frame = overlayFrame(chatGPTWindow: chatGPTWindow, panelSize: Self.panelSize)
        panel.setFrame(frame, display: panel.isVisible)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }
}

private final class NonactivatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
