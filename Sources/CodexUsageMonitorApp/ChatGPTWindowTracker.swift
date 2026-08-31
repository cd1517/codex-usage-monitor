import AppKit
import CoreGraphics

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

@MainActor
final class ChatGPTWindowTracker {
    private static let trackingInterval: TimeInterval = 1.0 / 60.0

    private let targetBundleID = "com.openai.codex"
    private var observer: NSObjectProtocol?
    private var timer: Timer?
    private var activePID: pid_t?
    private var trackedWindowID: CGWindowID?
    private var wasActive = false

    var onWindowFrame: ((CGRect?) -> Void)?
    var onActivation: (() -> Void)?

    func start() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateFrontmostApplication()
            }
        }
        updateFrontmostApplication()
    }

    func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
        stopTracking()
    }

    private func updateFrontmostApplication() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier == targetBundleID else {
            wasActive = false
            stopTracking()
            onWindowFrame?(nil)
            return
        }

        activePID = app.processIdentifier
        if !wasActive {
            wasActive = true
            onActivation?()
        }
        if timer == nil {
            let timer = Timer(timeInterval: Self.trackingInterval, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.refreshWindowFrame()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
        refreshWindowFrame()
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        activePID = nil
        trackedWindowID = nil
    }

    private func refreshWindowFrame() {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == targetBundleID,
              let activePID else {
            updateFrontmostApplication()
            return
        }

        guard let window = primaryWindowDescriptor(ownerPID: activePID),
              let appKitBounds = convertWindowBounds(window.bounds, displays: displayDescriptors()) else {
            onWindowFrame?(nil)
            return
        }
        onWindowFrame?(appKitBounds)
    }

    private func primaryWindowDescriptor(ownerPID: pid_t) -> WindowDescriptor? {
        if let trackedWindowID,
           let window = selectTrackedWindowDescriptor(
               from: windowDescriptors(windowID: trackedWindowID),
               ownerPID: ownerPID
           ) {
            return window
        }

        let window = selectPrimaryWindowDescriptor(from: windowDescriptors(), ownerPID: ownerPID)
        trackedWindowID = window?.windowID
        return window
    }

    private func windowDescriptors(windowID: CGWindowID? = nil) -> [WindowDescriptor] {
        let rawWindows: [[String: Any]]?
        if let windowID {
            rawWindows = CGWindowListCreateDescriptionFromArray(
                [windowID] as CFArray
            ) as? [[String: Any]]
        } else {
            rawWindows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]]
        }

        guard let rawWindows else {
            return []
        }

        return rawWindows.compactMap { window in
            guard let windowID = (window[kCGWindowNumber as String] as? NSNumber)?.uint32Value,
                  let ownerPID = (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                  let layer = (window[kCGWindowLayer as String] as? NSNumber)?.intValue,
                  let boundsDictionary = window[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary) else {
                return nil
            }
            return WindowDescriptor(
                windowID: windowID,
                ownerPID: ownerPID,
                layer: layer,
                isOnscreen: (window[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ?? false,
                alpha: (window[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1,
                bounds: bounds
            )
        }
    }

    private func displayDescriptors() -> [DisplayDescriptor] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            return DisplayDescriptor(
                cgBounds: CGDisplayBounds(CGDirectDisplayID(number.uint32Value)),
                appKitFrame: screen.frame
            )
        }
    }
}
