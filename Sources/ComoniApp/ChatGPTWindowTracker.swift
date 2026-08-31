import AppKit
import CoreGraphics

#if SWIFT_PACKAGE
import ComoniCore
#endif

struct TrackedChatGPTWindow {
    let frame: CGRect
    let windowNumber: Int
}

@MainActor
final class ChatGPTWindowTracker {
    private static let foregroundTrackingInterval: TimeInterval = 1.0 / 60.0
    private static let backgroundTrackingInterval: TimeInterval = 0.25

    private let targetBundleID = "com.openai.codex"
    private var observers: [NSObjectProtocol] = []
    private var timer: Timer?
    private var timerInterval: TimeInterval?
    private var activePID: pid_t?
    private var trackedWindowID: CGWindowID?
    private var wasFrontmost = false

    var onWindowChange: ((TrackedChatGPTWindow?) -> Void)?
    var onActivation: (() -> Void)?
    var onFrontmostChange: ((Bool) -> Void)?

    func start() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let notificationNames: [Notification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification
        ]
        observers = notificationNames.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.updateTrackedApplication()
                }
            }
        }
        updateTrackedApplication()
    }

    func stop() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
        updateFrontmostState(false)
        stopTracking()
    }

    private func updateTrackedApplication() {
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: targetBundleID
        ).first(where: { !$0.isTerminated }) else {
            updateFrontmostState(false)
            stopTracking()
            onWindowChange?(nil)
            return
        }

        if activePID != app.processIdentifier {
            activePID = app.processIdentifier
            trackedWindowID = nil
        }
        let isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
        updateFrontmostState(isFrontmost)
        configureTrackingTimer(isFrontmost: isFrontmost)
        refreshWindowFrame()
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        timerInterval = nil
        activePID = nil
        trackedWindowID = nil
    }

    private func configureTrackingTimer(isFrontmost: Bool) {
        let interval = isFrontmost
            ? Self.foregroundTrackingInterval
            : Self.backgroundTrackingInterval
        guard timer == nil || timerInterval != interval else {
            return
        }

        timer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.trackingTimerFired()
            }
        }
        timer.tolerance = isFrontmost ? 0.001 : 0.05
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        timerInterval = interval
    }

    private func trackingTimerFired() {
        guard let activePID,
              let app = NSRunningApplication(processIdentifier: activePID),
              !app.isTerminated else {
            updateTrackedApplication()
            return
        }

        let isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == activePID
        guard isFrontmost == wasFrontmost else {
            updateTrackedApplication()
            return
        }
        refreshWindowFrame()
    }

    private func updateFrontmostState(_ isFrontmost: Bool) {
        guard isFrontmost != wasFrontmost else {
            return
        }
        wasFrontmost = isFrontmost
        onFrontmostChange?(isFrontmost)
        if isFrontmost {
            onActivation?()
        }
    }

    private func refreshWindowFrame() {
        guard let activePID,
              let app = NSRunningApplication(processIdentifier: activePID),
              !app.isTerminated else {
            updateTrackedApplication()
            return
        }

        guard let window = primaryWindowDescriptor(ownerPID: activePID),
              let appKitBounds = convertWindowBounds(window.bounds, displays: displayDescriptors()) else {
            onWindowChange?(nil)
            return
        }
        onWindowChange?(
            TrackedChatGPTWindow(
                frame: appKitBounds,
                windowNumber: Int(window.windowID)
            )
        )
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
