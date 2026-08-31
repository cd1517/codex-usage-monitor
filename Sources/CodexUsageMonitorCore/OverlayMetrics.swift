import CoreGraphics

public let supportedOverlayFontSizes = Array(14...20)

public func normalizedOverlayFontSize(_ storedValue: Int?) -> Int {
    guard let storedValue, supportedOverlayFontSizes.contains(storedValue) else {
        return 18
    }
    return storedValue
}

public let supportedOverlayLanguages = ["auto", "zh-Hans", "zh-Hant", "en", "ja"]

public func normalizedOverlayLanguage(_ storedValue: String?) -> String {
    guard let storedValue, supportedOverlayLanguages.contains(storedValue) else {
        return "auto"
    }
    return storedValue
}

/// 非 CJK 语言的标签与日期明显更宽，固定面板宽度会把标签与数值之间的
/// Spacer 压到最小值，需要加宽详情面板留出间距。
public func usesWideScriptDetailLayout(localeIdentifier: String) -> Bool {
    let language = localeIdentifier.lowercased()
    return !(language.hasPrefix("zh") || language.hasPrefix("ja") || language.hasPrefix("ko"))
}

public struct OverlayMetrics: Equatable, Sendable {
    public let fontSize: CGFloat
    public let scale: CGFloat
    public let wideScriptDetail: Bool

    public init(fontSize: Int, wideScriptDetail: Bool = false) {
        let normalizedSize = normalizedOverlayFontSize(fontSize)
        self.fontSize = CGFloat(normalizedSize)
        scale = CGFloat(normalizedSize) / 18
        self.wideScriptDetail = wideScriptDetail
    }

    public var compactSize: CGSize {
        // 高度 35pt = 原生分享按钮灰底实测高度
        CGSize(width: scaled(278), height: 35)
    }

    public var expandedSize: CGSize {
        CGSize(width: compactSize.width, height: compactSize.height + scaled(154))
    }

    public var detailPanelSize: CGSize {
        // 高度收紧 9pt：文字行框自带上下 slack，使底部留白与顶部对齐
        CGSize(
            width: expandedSize.width + (wideScriptDetail ? scaled(28) : 0),
            height: expandedSize.height - compactSize.height - scaled(9)
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
    public var detailSpacing: CGFloat { scaled(12) }
    public var detailValueSpacing: CGFloat { scaled(8) }
    public var detailHorizontalPadding: CGFloat { scaled(14) }
    public var detailTopPadding: CGFloat { scaled(12) }
    public var detailBottomPadding: CGFloat { scaled(13) }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}
