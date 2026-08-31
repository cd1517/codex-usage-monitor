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

    var previous = OverlayMetrics(fontSize: 14)
    for size in 15...20 {
        let metrics = OverlayMetrics(fontSize: size)
        try expect(
            metrics.compactSize.width > previous.compactSize.width,
            "compact width should grow with the selected font size"
        )
        try expect(
            metrics.compactSize.height == 36,
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
        defaultMetrics.compactSize == CGSize(width: 278, height: 36),
        "18pt should use the native Share background height"
    )
    try expect(
        defaultMetrics.expandedSize == CGSize(width: 278, height: 190),
        "18pt should include the fixed strip and four detail rows"
    )
    try expect(
        defaultMetrics.detailPanelSize == CGSize(width: 278, height: 154),
        "the detail window should exclude the 36pt compact strip"
    )
    try expect(
        defaultMetrics.compactCornerRadius == 12,
        "the compact strip should use the same rounded-rectangle radius as Share"
    )
    try expect(defaultMetrics.detailGap == 12, "the detail window should align with the native title-bar bottom")
    try expect(
        defaultMetrics.detailHorizontalPadding == 10 && defaultMetrics.detailValueSpacing == 8,
        "detail chrome must leave the label and value columns wide enough for full-size text"
    )
    let compactFrame = CGRect(x: 802, y: 856, width: 278, height: 36)
    let expandedFrame = overlayFrame(
        preservingTopRightOf: compactFrame,
        panelSize: defaultMetrics.expandedSize
    )
    try expect(
        expandedFrame == CGRect(x: 802, y: 702, width: 278, height: 190),
        "the expanded panel should grow left and down from the compact top-right anchor"
    )
    try expect(
        expandedFrame.maxX == compactFrame.maxX && expandedFrame.maxY == compactFrame.maxY,
        "the compact strip world-space top-right anchor must remain fixed"
    )
}
