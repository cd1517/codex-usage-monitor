import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import ComoniCore
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
    private var hoverReconcileTimer: Timer?
    private var clickMonitors: [Any] = []

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

        // AppKit 的 mouseEntered/mouseExited 在面板带动画重排、快速进出时会
        // 丢失，悬停标志可能卡住导致详情窗不收起；定时用鼠标真实位置对账。
        let reconcileTimer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reconcileHoverState()
            }
        }
        RunLoop.main.add(reconcileTimer, forMode: .common)
        hoverReconcileTimer = reconcileTimer

        // 双保险：横条与详情窗以外的任何鼠标按下都必须收回详情窗。全局监听
        // 覆盖其他应用与桌面，本地监听覆盖状态栏图标；横条豁免（···菜单在其
        // 中），详情窗豁免（点击视为正在查看）。鼠标事件监听不需要辅助功能权限。
        let clickMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        clickMonitors = [
            NSEvent.addGlobalMonitorForEvents(matching: clickMask) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.forceCollapseDetail()
                }
            },
            NSEvent.addLocalMonitorForEvents(matching: clickMask) { [weak self] event in
                MainActor.assumeIsolated {
                    guard let self else {
                        return event
                    }
                    if event.window === self.compactPanel || event.window === self.detailPanel {
                        return event
                    }
                    self.forceCollapseDetail()
                    return event
                }
            }
        ]
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

    /// 以鼠标真实位置为准校正悬停标志，兜住丢失的 mouseEntered/mouseExited。
    private func reconcileHoverState() {
        guard compactPanel.isVisible, !presentation.isFontMenuOpen else {
            return
        }
        let mouseLocation = NSEvent.mouseLocation
        isCompactHovering = compactPanel.frame.contains(mouseLocation)
        isDetailHovering = isDetailVisible && detailPanel.isVisible
            && detailPanel.frame.contains(mouseLocation)
        updateHoverState()
    }

    /// 点击兜底：立即收回详情窗，不等 0.12s 收起延迟。
    private func forceCollapseDetail() {
        guard isDetailVisible, !presentation.isFontMenuOpen else {
            return
        }
        pendingCollapse?.cancel()
        pendingCollapse = nil
        isCompactHovering = compactPanel.frame.contains(NSEvent.mouseLocation)
        isDetailHovering = false
        presentation.isHovering = isCompactHovering || presentation.isFontMenuOpen
        hideDetail()
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
        // 层级在每个 tick 断言而非仅在前台切换时设置：若横条不可见期间错过
        // 前台切换，level 会停留旧值，ChatGPT 重排自身窗口后横条被压到底下，
        // 只能靠用户点击其他窗口触发 level 重设才能恢复。
        let level: NSWindow.Level = isChatGPTFrontmost ? .floating : .normal
        if compactPanel.level != level {
            compactPanel.level = level
        }
        if detailPanel.level != level {
            detailPanel.level = level
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
