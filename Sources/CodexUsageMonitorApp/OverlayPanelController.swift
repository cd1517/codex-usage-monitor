import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

@MainActor
final class OverlayPanelController {
    private static let slideDuration: TimeInterval = 0.20
    private static let collapseDelay: TimeInterval = 0.12

    private let compactPanel: NSPanel
    private let detailPanel: NSPanel
    private let presentation: OverlayPresentation
    private var chatGPTWindow: CGRect?
    private var chatGPTWindowNumber: Int?
    private var isChatGPTFrontmost = false
    private var isDetailVisible = false
    private var isCompactHovering = false
    private var isDetailHovering = false
    private var isDetailSliding = false
    private var pendingCollapse: DispatchWorkItem?

    init(viewModel: UsageViewModel) {
        let presentation = OverlayPresentation()
        self.presentation = presentation
        compactPanel = NonactivatingPanel(
            contentRect: CGRect(origin: .zero, size: presentation.metrics.compactSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        detailPanel = NonactivatingPanel(
            contentRect: CGRect(origin: .zero, size: presentation.metrics.detailPanelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let compactHostingView = HoverTrackingHostingView(
            rootView: UsageView(
                viewModel: viewModel,
                presentation: presentation
            )
        )
        let detailHostingView = HoverTrackingHostingView(
            rootView: UsageDetailView(
                viewModel: viewModel,
                presentation: presentation
            )
        )
        compactPanel.contentView = compactHostingView
        detailPanel.contentView = detailHostingView

        for panel in [compactPanel, detailPanel] {
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
        }

        compactHostingView.onHoverChange = { [weak self] isHovering in
            self?.handleCompactHoverChange(isHovering)
        }
        detailHostingView.onHoverChange = { [weak self] isHovering in
            self?.handleDetailHoverChange(isHovering)
        }
        presentation.onFontSizeChange = { [weak self] in
            self?.updatePanelFramesForCurrentMetrics()
        }
        presentation.onMenuTrackingChange = { [weak self] isOpen in
            self?.handleMenuTrackingChange(isOpen)
        }
    }

    func show(attachedTo chatGPTWindow: CGRect, relativeTo chatGPTWindowNumber: Int) {
        self.chatGPTWindow = chatGPTWindow
        self.chatGPTWindowNumber = chatGPTWindowNumber
        let compactFrame = compactFrame(attachedTo: chatGPTWindow)
        if compactPanel.frame != compactFrame {
            compactPanel.setFrame(compactFrame, display: compactPanel.isVisible)
        }
        if isDetailVisible && !isDetailSliding {
            let detailFrame = detailFrame(attachedTo: compactFrame)
            if detailPanel.frame != detailFrame {
                detailPanel.setFrame(detailFrame, display: detailPanel.isVisible)
            }
        }
        orderPanelsFront()
    }

    func setChatGPTFrontmost(_ isFrontmost: Bool) {
        isChatGPTFrontmost = isFrontmost
        let level: NSWindow.Level = isFrontmost ? .floating : .normal
        compactPanel.level = level
        detailPanel.level = level
        if compactPanel.isVisible {
            orderPanelsFront()
        }
    }

    func refreshLanguage() {
        presentation.refreshLanguage()
    }

    func hide() {
        pendingCollapse?.cancel()
        pendingCollapse = nil
        isDetailVisible = false
        isCompactHovering = false
        isDetailHovering = false
        presentation.isDetailVisible = false
        presentation.isHovering = false
        compactPanel.orderOut(nil)
        detailPanel.orderOut(nil)
        detailPanel.hasShadow = false
        detailPanel.alphaValue = 1
        chatGPTWindow = nil
        chatGPTWindowNumber = nil
    }

    private func showDetail() {
        guard !isDetailVisible, let chatGPTWindow else {
            return
        }
        isDetailVisible = true
        presentation.isDetailVisible = true
        isDetailSliding = true
        let compactFrame = compactFrame(attachedTo: chatGPTWindow)
        let collapsedFrame = collapsedDetailFrame(attachedTo: compactFrame)
        let finalFrame = detailFrame(attachedTo: compactFrame)
        detailPanel.setFrame(collapsedFrame, display: false)
        detailPanel.alphaValue = 0
        detailPanel.hasShadow = true
        detailPanel.invalidateShadow()
        orderPanelsFront()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.slideDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            detailPanel.animator().setFrame(finalFrame, display: true)
            detailPanel.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.isDetailSliding = false
            }
        }
    }

    private func hideDetail() {
        guard isDetailVisible, let chatGPTWindow else {
            return
        }
        isDetailVisible = false
        isDetailSliding = false
        let compactFrame = compactFrame(attachedTo: chatGPTWindow)
        let collapsedFrame = collapsedDetailFrame(attachedTo: compactFrame)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.slideDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            detailPanel.animator().setFrame(collapsedFrame, display: true)
            detailPanel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isDetailVisible else {
                    return
                }
                self.presentation.isDetailVisible = false
                self.detailPanel.orderOut(nil)
                self.detailPanel.hasShadow = false
            }
        }
    }

    private func handleCompactHoverChange(_ isHovering: Bool) {
        isCompactHovering = isHovering
        updateHoverState()
    }

    private func handleDetailHoverChange(_ isHovering: Bool) {
        isDetailHovering = isHovering
        updateHoverState()
    }

    private func updateHoverState() {
        pendingCollapse?.cancel()
        pendingCollapse = nil
        let isHovering = isCompactHovering || isDetailHovering
        presentation.isHovering = isHovering || presentation.isFontMenuOpen

        if isHovering || presentation.isFontMenuOpen {
            showDetail()
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
                panelFrames: self.visiblePanelFrames
            ) else {
                return
            }
            self.presentation.isHovering = false
            self.hideDetail()
        }
        pendingCollapse = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.collapseDelay, execute: workItem)
    }

    private func compactFrame(attachedTo chatGPTWindow: CGRect) -> CGRect {
        overlayFrame(
            chatGPTWindow: chatGPTWindow,
            panelSize: presentation.metrics.compactSize
        )
    }

    private func detailFrame(attachedTo compactFrame: CGRect) -> CGRect {
        detailOverlayFrame(
            compactFrame: compactFrame,
            detailSize: presentation.metrics.detailPanelSize,
            gap: presentation.metrics.detailGap
        )
    }

    private func collapsedDetailFrame(attachedTo compactFrame: CGRect) -> CGRect {
        collapsedDetailOverlayFrame(
            compactFrame: compactFrame,
            detailSize: presentation.metrics.detailPanelSize,
            gap: presentation.metrics.detailGap
        )
    }

    private var visiblePanelFrames: [CGRect] {
        if isDetailVisible {
            return [compactPanel.frame, detailPanel.frame]
        }
        return [compactPanel.frame]
    }

    private func updatePanelFramesForCurrentMetrics() {
        guard let chatGPTWindow else {
            return
        }
        let compactFrame = compactFrame(attachedTo: chatGPTWindow)
        let detailFrame = detailFrame(attachedTo: compactFrame)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            compactPanel.animator().setFrame(compactFrame, display: true)
            if isDetailVisible {
                detailPanel.animator().setFrame(detailFrame, display: true)
            }
        }
    }

    private func handleMenuTrackingChange(_ isOpen: Bool) {
        pendingCollapse?.cancel()
        pendingCollapse = nil
        if isOpen {
            presentation.isHovering = true
            showDetail()
            return
        }
        isCompactHovering = compactPanel.frame.contains(NSEvent.mouseLocation)
        isDetailHovering = isDetailVisible && detailPanel.frame.contains(NSEvent.mouseLocation)
        updateHoverState()
    }

    private func orderPanelsFront() {
        guard let chatGPTWindowNumber else {
            return
        }
        if isChatGPTFrontmost {
            if isDetailVisible {
                detailPanel.orderFrontRegardless()
            }
            compactPanel.orderFrontRegardless()
            return
        }
        if isDetailVisible {
            detailPanel.order(.above, relativeTo: chatGPTWindowNumber)
            compactPanel.order(.above, relativeTo: detailPanel.windowNumber)
        } else {
            compactPanel.order(.above, relativeTo: chatGPTWindowNumber)
        }
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
