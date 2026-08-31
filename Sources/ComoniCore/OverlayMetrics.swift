import CoreGraphics

public let supportedOverlayFontSizes = Array(14...20)

public func normalizedOverlayFontSize(_ storedValue: Int?) -> Int {
    guard let storedValue, supportedOverlayFontSizes.contains(storedValue) else {
        return 18
    }
    return storedValue
}

public struct OverlayMetrics: Equatable, Sendable {
    public let fontSize: CGFloat
    public let scale: CGFloat

    public init(fontSize: Int) {
        let normalizedSize = normalizedOverlayFontSize(fontSize)
        self.fontSize = CGFloat(normalizedSize)
        scale = CGFloat(normalizedSize) / 18
    }

    public var compactSize: CGSize {
        CGSize(width: scaled(278), height: 36)
    }

    public var expandedSize: CGSize {
        CGSize(width: compactSize.width, height: compactSize.height + scaled(154))
    }

    public var detailPanelSize: CGSize {
        // 高度收紧 11pt：文字行框自带上下 slack，使底部留白与顶部对齐
        CGSize(
            width: expandedSize.width,
            height: expandedSize.height - compactSize.height - scaled(11)
        )
    }

    public var detailGap: CGFloat { scaled(12) }

    public var compactSpacing: CGFloat { scaled(7) }
    public var boltHorizontalPadding: CGFloat { scaled(4) }
    public var compactValueSpacing: CGFloat { scaled(8) }
    public var compactLeadingPadding: CGFloat { scaled(9) }
    public var compactTrailingPadding: CGFloat { scaled(5) }
    public var compactSeparatorHeight: CGFloat { scaled(18) }
    public var iconSize: CGFloat { scaled(13) }
    public var iconWidth: CGFloat { scaled(15) }
    public var iconHeight: CGFloat { scaled(17) }
    public var menuButtonSize: CGFloat { max(22, scaled(22)) }
    public var compactCornerRadius: CGFloat { 12 }
    public var cornerRadius: CGFloat { scaled(14) }
    public var detailSpacing: CGFloat { scaled(10) }
    public var detailSectionExtra: CGFloat { scaled(4) }
    public var detailValueSpacing: CGFloat { scaled(8) }
    public var detailHorizontalPadding: CGFloat { scaled(14) }
    public var detailTopPadding: CGFloat { scaled(12) }
    public var detailBottomPadding: CGFloat { scaled(13) }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}
