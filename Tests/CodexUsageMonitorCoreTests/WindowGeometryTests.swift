import CoreGraphics

func runWindowGeometryTests() throws {
    let windows = [
        WindowDescriptor(windowID: 101, ownerPID: 42, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 300, height: 200)),
        WindowDescriptor(windowID: 102, ownerPID: 42, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 50, y: 60, width: 1200, height: 800)),
        WindowDescriptor(ownerPID: 99, layer: 0, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 1500, height: 1000)),
        WindowDescriptor(ownerPID: 42, layer: 2, isOnscreen: true, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 1400, height: 900))
    ]
    try expect(
        selectPrimaryWindow(from: windows, ownerPID: 42) == CGRect(x: 50, y: 60, width: 1200, height: 800),
        "largest visible normal window should be selected"
    )
    try expect(
        selectPrimaryWindowDescriptor(from: windows, ownerPID: 42)?.windowID == 102,
        "primary-window discovery should preserve the window ID for low-latency frame tracking"
    )
    let backgroundVisibleWindow = WindowDescriptor(
        windowID: 102,
        ownerPID: 42,
        layer: 0,
        isOnscreen: true,
        alpha: 1,
        bounds: CGRect(x: 50, y: 60, width: 1200, height: 800)
    )
    try expect(
        selectTrackedWindowDescriptor(from: [backgroundVisibleWindow], ownerPID: 42)?.windowID == 102,
        "a visible background main window should remain trackable"
    )
    let minimizedWindow = WindowDescriptor(
        windowID: 102,
        ownerPID: 42,
        layer: 0,
        isOnscreen: false,
        alpha: 1,
        bounds: CGRect(x: 50, y: 60, width: 1200, height: 800)
    )
    try expect(
        selectTrackedWindowDescriptor(from: [minimizedWindow], ownerPID: 42) == nil,
        "a minimized cached window should no longer keep the overlay visible"
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
        panelSize: CGSize(width: 250, height: 32)
    )
    try expect(frame == CGRect(x: 830, y: 852, width: 250, height: 32), "strip should sit immediately left of the Share controls")

    let narrowFrame = overlayFrame(
        chatGPTWindow: CGRect(x: 100, y: 100, width: 400, height: 600),
        panelSize: CGSize(width: 250, height: 32)
    )
    try expect(narrowFrame.minX == 112, "strip should stay inside a narrow ChatGPT window")

    let expandedFrame = overlayFrame(
        chatGPTWindow: CGRect(x: 100, y: 100, width: 1200, height: 800),
        panelSize: CGSize(width: 360, height: 170)
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
