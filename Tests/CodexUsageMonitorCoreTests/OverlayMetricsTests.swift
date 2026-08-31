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
        defaultMetrics.expandedSize == CGSize(width: 360, height: 170),
        "18pt should preserve the current detail dimensions"
    )
    let compactFrame = CGRect(x: 802, y: 852, width: 278, height: 32)
    let expandedFrame = overlayFrame(
        preservingTopRightOf: compactFrame,
        panelSize: defaultMetrics.expandedSize
    )
    try expect(
        expandedFrame == CGRect(x: 720, y: 714, width: 360, height: 170),
        "the expanded panel should grow left and down from the compact top-right anchor"
    )
    try expect(
        expandedFrame.maxX == compactFrame.maxX && expandedFrame.maxY == compactFrame.maxY,
        "the compact strip world-space top-right anchor must remain fixed"
    )
}
