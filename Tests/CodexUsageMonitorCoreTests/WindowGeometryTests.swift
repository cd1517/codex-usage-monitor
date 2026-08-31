import CoreGraphics

func runWindowGeometryTests() throws {
    let windows = [
        WindowDescriptor(ownerPID: 42, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 300, height: 200)),
        WindowDescriptor(ownerPID: 42, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 50, y: 60, width: 1200, height: 800)),
        WindowDescriptor(ownerPID: 99, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 1500, height: 1000)),
        WindowDescriptor(ownerPID: 42, layer: 2, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 1400, height: 900))
    ]
    try expect(
        selectPrimaryWindow(from: windows, ownerPID: 42) == CGRect(x: 50, y: 60, width: 1200, height: 800),
        "largest visible normal window should be selected"
    )

    let invalidWindows = [
        WindowDescriptor(ownerPID: 42, layer: 0, isOnscreen: false, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 1200, height: 800)),
        WindowDescriptor(ownerPID: 42, layer: 0, isOnscreen: true, alpha: 0, bounds: CGRect(x: 0, y: 0, width: 1200, height: 800)),
        WindowDescriptor(ownerPID: 42, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 400, height: 300))
    ]
    try expect(selectPrimaryWindow(from: invalidWindows, ownerPID: 42) == nil, "hidden, transparent and helper windows should be rejected")

    let display = DisplayDescriptor(
        cgBounds: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
        appKitFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1080)
    )
    let converted = convertWindowBounds(
        CGRect(x: 1600, y: 100, width: 1000, height: 800),
        displays: [display]
    )
    try expect(converted == CGRect(x: 1600, y: 180, width: 1000, height: 800), "CoreGraphics coordinates should convert on the owning display")

    let frame = overlayFrame(
        chatGPTWindow: CGRect(x: 100, y: 100, width: 1200, height: 800),
        panelSize: CGSize(width: 220, height: 30)
    )
    try expect(frame == CGRect(x: 860, y: 854, width: 220, height: 30), "strip should sit immediately left of the Share controls")

    let narrowFrame = overlayFrame(
        chatGPTWindow: CGRect(x: 100, y: 100, width: 400, height: 600),
        panelSize: CGSize(width: 220, height: 30)
    )
    try expect(narrowFrame.minX == 112, "strip should stay inside a narrow ChatGPT window")

    let expandedFrame = overlayFrame(
        chatGPTWindow: CGRect(x: 100, y: 100, width: 1200, height: 800),
        panelSize: CGSize(width: 310, height: 136)
    )
    try expect(
        !shouldCollapseOverlay(pointerLocation: CGPoint(x: frame.midX, y: frame.midY), panelFrame: expandedFrame),
        "a transient tracking exit must not collapse while the pointer is still inside the expanded panel"
    )
    try expect(
        shouldCollapseOverlay(pointerLocation: CGPoint(x: expandedFrame.maxX + 1, y: expandedFrame.midY), panelFrame: expandedFrame),
        "the panel should collapse after the pointer actually leaves its frame"
    )
}
