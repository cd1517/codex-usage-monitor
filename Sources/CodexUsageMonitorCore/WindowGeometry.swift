import CoreGraphics

public struct WindowDescriptor: Equatable, Sendable {
    public let ownerPID: pid_t
    public let layer: Int
    public let isOnscreen: Bool
    public let alpha: Double
    public let bounds: CGRect

    public init(ownerPID: pid_t, layer: Int, isOnscreen: Bool, alpha: Double, bounds: CGRect) {
        self.ownerPID = ownerPID
        self.layer = layer
        self.isOnscreen = isOnscreen
        self.alpha = alpha
        self.bounds = bounds
    }
}

public struct DisplayDescriptor: Equatable, Sendable {
    public let cgBounds: CGRect
    public let appKitFrame: CGRect

    public init(cgBounds: CGRect, appKitFrame: CGRect) {
        self.cgBounds = cgBounds
        self.appKitFrame = appKitFrame
    }
}

public func selectPrimaryWindow(from windows: [WindowDescriptor], ownerPID: pid_t) -> CGRect? {
    windows
        .filter {
            $0.ownerPID == ownerPID
                && $0.layer == 0
                && $0.isOnscreen
                && $0.alpha > 0
                && $0.bounds.width >= 600
                && $0.bounds.height >= 400
        }
        .max { left, right in
            left.bounds.width * left.bounds.height < right.bounds.width * right.bounds.height
        }?
        .bounds
}

public func convertWindowBounds(_ bounds: CGRect, displays: [DisplayDescriptor]) -> CGRect? {
    guard let display = displays.max(by: {
        $0.cgBounds.intersection(bounds).area < $1.cgBounds.intersection(bounds).area
    }), display.cgBounds.intersects(bounds) else {
        return nil
    }

    let relativeX = bounds.minX - display.cgBounds.minX
    let relativeMaxY = bounds.maxY - display.cgBounds.minY
    return CGRect(
        x: display.appKitFrame.minX + relativeX,
        y: display.appKitFrame.maxY - relativeMaxY,
        width: bounds.width,
        height: bounds.height
    )
}

public func overlayFrame(chatGPTWindow: CGRect, panelSize: CGSize) -> CGRect {
    let windowInset: CGFloat = 12
    let titleBarTopInset: CGFloat = 16
    let trailingControlsWidth: CGFloat = 220
    let preferredX = chatGPTWindow.maxX - trailingControlsWidth - panelSize.width
    return CGRect(
        x: max(chatGPTWindow.minX + windowInset, preferredX),
        y: chatGPTWindow.maxY - titleBarTopInset - panelSize.height,
        width: panelSize.width,
        height: panelSize.height
    )
}

private extension CGRect {
    var area: CGFloat {
        isNull ? 0 : width * height
    }
}
