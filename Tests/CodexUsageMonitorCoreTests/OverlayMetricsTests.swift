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
            metrics.compactSize.width > previous.compactSize.width
                && metrics.compactSize.height > previous.compactSize.height,
            "compact dimensions should grow with the selected font size"
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
        defaultMetrics.compactSize == CGSize(width: 278, height: 32),
        "18pt should add only enough compact width for the native ellipsis control"
    )
    try expect(
        defaultMetrics.expandedSize == CGSize(width: 278, height: 186),
        "18pt should include the fixed strip and four detail rows"
    )
    try expect(
        defaultMetrics.detailPanelSize == CGSize(width: 278, height: 154),
        "the detail window should exclude the 32pt compact strip"
    )
    try expect(
        defaultMetrics.compactCornerRadius == 16,
        "the compact strip should use a pill radius matching the native Share control"
    )
    try expect(defaultMetrics.detailGap == 12, "the detail window should align with the native title-bar bottom")
    let compactFrame = CGRect(x: 802, y: 860, width: 278, height: 32)
    let expandedFrame = overlayFrame(
        preservingTopRightOf: compactFrame,
        panelSize: defaultMetrics.expandedSize
    )
    try expect(
        expandedFrame == CGRect(x: 802, y: 706, width: 278, height: 186),
        "the expanded panel should grow left and down from the compact top-right anchor"
    )
    try expect(
        expandedFrame.maxX == compactFrame.maxX && expandedFrame.maxY == compactFrame.maxY,
        "the compact strip world-space top-right anchor must remain fixed"
    )
}
