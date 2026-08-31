import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import ComoniCore
#endif

@MainActor
final class OverlayPanelController {
    static let compactSize = CGSize(width: 220, height: 30)
    static let expandedSize = CGSize(width: 310, height: 136)

    private let panel: NSPanel
    private let presentation: OverlayPresentation
    private var chatGPTWindow: CGRect?
    private var isExpanded = false
    private var pendingCollapse: DispatchWorkItem?

    init(viewModel: UsageViewModel) {
        let presentation = OverlayPresentation()
        self.presentation = presentation
        panel = NonactivatingPanel(
            contentRect: CGRect(origin: .zero, size: Self.compactSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let hostingView = HoverTrackingHostingView(
            rootView: UsageView(
                viewModel: viewModel,
                presentation: presentation
            )
        )
        panel.contentView = hostingView
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

        hostingView.onHoverChange = { [weak self] isHovering in
            self?.handleHoverChange(isHovering)
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
        pendingCollapse?.cancel()
        pendingCollapse = nil
        isExpanded = false
        presentation.isExpanded = false
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
        if expanded {
            panel.setFrame(frame, display: true)
            presentation.isExpanded = true
        } else {
            presentation.isExpanded = false
            panel.setFrame(frame, display: true)
        }
    }

    private func handleHoverChange(_ isHovering: Bool) {
        pendingCollapse?.cancel()
        pendingCollapse = nil

        if isHovering {
            setExpanded(true)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            self.pendingCollapse = nil
            guard shouldCollapseOverlay(
                pointerLocation: NSEvent.mouseLocation,
                panelFrame: self.panel.frame
            ) else {
                return
            }
            self.setExpanded(false)
        }
        pendingCollapse = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }
}

private final class NonactivatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class HoverTrackingHostingView<Content: View>: NSHostingView<Content> {
    var onHoverChange: ((Bool) -> Void)?

    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        hoverTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChange?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChange?(false)
    }
}
