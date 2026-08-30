import AppKit
import CoreGraphics

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

@MainActor
final class ChatGPTWindowTracker {
    private let targetBundleID = "com.openai.codex"
    private var observer: NSObjectProtocol?
    private var timer: Timer?
    private var activePID: pid_t?
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
            timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.refreshWindowFrame()
                }
            }
        }
        refreshWindowFrame()
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        activePID = nil
    }

    private func refreshWindowFrame() {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == targetBundleID,
              let activePID else {
            updateFrontmostApplication()
            return
        }

        guard let cgBounds = selectPrimaryWindow(from: windowDescriptors(), ownerPID: activePID),
              let appKitBounds = convertWindowBounds(cgBounds, displays: displayDescriptors()) else {
            onWindowFrame?(nil)
            return
        }
        onWindowFrame?(appKitBounds)
    }

    private func windowDescriptors() -> [WindowDescriptor] {
        guard let rawWindows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return rawWindows.compactMap { window in
            guard let ownerPID = (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                  let layer = (window[kCGWindowLayer as String] as? NSNumber)?.intValue,
                  let boundsDictionary = window[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary) else {
                return nil
            }
            return WindowDescriptor(
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
