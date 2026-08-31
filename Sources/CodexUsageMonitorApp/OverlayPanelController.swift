import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

@MainActor
final class OverlayPanelController {
    private static let morphDuration: TimeInterval = 0.22

    private let panel: NSPanel
    private let presentation: OverlayPresentation
    private var chatGPTWindow: CGRect?
    private var chatGPTWindowNumber: Int?
    private var isChatGPTFrontmost = false
    private var isExpanded = false
    private var pendingCollapse: DispatchWorkItem?
    private var pendingActivationOrdering: DispatchWorkItem?

    init(viewModel: UsageViewModel) {
        let presentation = OverlayPresentation()
        self.presentation = presentation
        panel = NonactivatingPanel(
            contentRect: CGRect(origin: .zero, size: presentation.metrics.compactSize),
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
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .normal
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
        presentation.onFontSizeChange = { [weak self] in
            self?.updatePanelFrameForCurrentMetrics()
        }
        presentation.onMenuTrackingChange = { [weak self] isOpen in
            self?.handleMenuTrackingChange(isOpen)
        }
    }

    func show(attachedTo chatGPTWindow: CGRect, relativeTo chatGPTWindowNumber: Int) {
        let targetChanged = self.chatGPTWindowNumber != chatGPTWindowNumber
        self.chatGPTWindow = chatGPTWindow
        self.chatGPTWindowNumber = chatGPTWindowNumber
        let frame = targetFrame(attachedTo: chatGPTWindow)
        if panel.frame != frame {
            panel.setFrame(frame, display: panel.isVisible)
        }
        if !panel.isVisible || targetChanged {
            if isChatGPTFrontmost {
                panel.orderFrontRegardless()
            } else {
                panel.order(.above, relativeTo: chatGPTWindowNumber)
            }
        }
    }

    func setChatGPTFrontmost(_ isFrontmost: Bool) {
        isChatGPTFrontmost = isFrontmost
        pendingActivationOrdering?.cancel()
        pendingActivationOrdering = nil
        guard isFrontmost else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.panel.isVisible, self.chatGPTWindowNumber != nil else {
                return
            }
            self.pendingActivationOrdering = nil
            self.panel.orderFrontRegardless()
        }
        pendingActivationOrdering = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    func hide() {
        pendingCollapse?.cancel()
        pendingCollapse = nil
        pendingActivationOrdering?.cancel()
        pendingActivationOrdering = nil
        isExpanded = false
        presentation.isExpanded = false
        panel.hasShadow = false
        panel.orderOut(nil)
        chatGPTWindowNumber = nil
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded, let chatGPTWindow else {
            return
        }
        isExpanded = expanded
        let frame = targetFrame(attachedTo: chatGPTWindow)

        if expanded {
            panel.hasShadow = true
            panel.invalidateShadow()
        }

        withAnimation(.easeInOut(duration: Self.morphDuration)) {
            presentation.isExpanded = expanded
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.morphDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self] in
            guard let self else {
                return
            }
            if !expanded {
                self.panel.hasShadow = false
            }
            self.panel.invalidateShadow()
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
            guard !self.presentation.isFontMenuOpen else {
                return
            }
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

    private func targetFrame(attachedTo chatGPTWindow: CGRect) -> CGRect {
        let compactFrame = overlayFrame(
            chatGPTWindow: chatGPTWindow,
            panelSize: presentation.metrics.compactSize
        )
        guard isExpanded else {
            return compactFrame
        }
        return overlayFrame(
            preservingTopRightOf: compactFrame,
            panelSize: presentation.metrics.expandedSize
        )
    }

    private func updatePanelFrameForCurrentMetrics() {
        guard let chatGPTWindow else {
            return
        }
        let frame = targetFrame(attachedTo: chatGPTWindow)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func handleMenuTrackingChange(_ isOpen: Bool) {
        pendingCollapse?.cancel()
        pendingCollapse = nil
        guard !isOpen else {
            return
        }
        handleHoverChange(panel.frame.contains(NSEvent.mouseLocation))
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
