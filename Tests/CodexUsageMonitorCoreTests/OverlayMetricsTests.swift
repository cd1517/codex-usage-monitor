import CoreGraphics

func runOverlayMetricsTests() throws {
    try expect(
        normalizedOverlayFontSize(nil) == 18,
        "a missing saved font size should use 18pt"
    )
    try expect(
        normalizedOverlayFontSize(13) == 18 && normalizedOverlayFontSize(21) == 18,
        "an unsupported saved font size should use 18pt"
    )
    try expect(
        supportedOverlayFontSizes == Array(14...20),
        "the native menu should expose every integer size from 14pt through 20pt"
    )
    try expect(
        normalizedOverlayLanguage(nil) == "auto",
        "a missing saved language should follow automatic detection"
    )
    try expect(
        normalizedOverlayLanguage("fr") == "auto",
        "an unsupported saved language should follow automatic detection"
    )
    try expect(
        normalizedOverlayLanguage("zh-Hant") == "zh-Hant",
        "a supported saved language should be kept as the override"
    )
    try expect(
        supportedOverlayLanguages == ["auto", "zh-Hans", "zh-Hant", "en", "ja"],
        "the native menu should expose automatic detection and the four manual languages"
    )

    var previous = OverlayMetrics(fontSize: 14)
    for size in 15...20 {
        let metrics = OverlayMetrics(fontSize: size)
        try expect(
            metrics.compactSize.width > previous.compactSize.width,
            "compact width should grow with the selected font size"
        )
        try expect(
            metrics.compactSize.height == 35,
            "compact background height must stay equal to the native Share background"
        )
        try expect(
            metrics.compactCornerRadius == 12,
            "compact background radius must stay equal to the native Share background"
        )
        try expect(
            metrics.expandedSize.width > previous.expandedSize.width
                && metrics.expandedSize.height > previous.expandedSize.height,
            "detail dimensions should grow with the selected font size"
        )
        previous = metrics
    }

    let defaultMetrics = OverlayMetrics(fontSize: 18)
    try expect(
        defaultMetrics.compactSize == CGSize(width: 278, height: 35),
        "18pt should use the native Share background height"
    )
    try expect(
        defaultMetrics.expandedSize == CGSize(width: 278, height: 189),
        "18pt should include the fixed strip and four detail rows"
    )
    try expect(
        defaultMetrics.detailPanelSize == CGSize(width: 278, height: 145),
        "the detail window should exclude the compact strip and align bottom inset with the top"
    )
    try expect(
        defaultMetrics.compactCornerRadius == 12,
        "the compact strip should use the same rounded-rectangle radius as Share"
    )
    try expect(defaultMetrics.detailGap == 12, "the detail window should align with the native title-bar bottom")
    try expect(
        defaultMetrics.detailHorizontalPadding == 14,
        "detail rows must keep equal text insets on both panel edges"
    )
    let compactFrame = CGRect(x: 802, y: 857, width: 278, height: 35)
    let expandedFrame = overlayFrame(
        preservingTopRightOf: compactFrame,
        panelSize: defaultMetrics.expandedSize
    )
    try expect(
        expandedFrame == CGRect(x: 802, y: 703, width: 278, height: 189),
        "the expanded panel should grow left and down from the compact top-right anchor"
    )
    try expect(
        expandedFrame.maxX == compactFrame.maxX && expandedFrame.maxY == compactFrame.maxY,
        "the compact strip world-space top-right anchor must remain fixed"
    )
}
