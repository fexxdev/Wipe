import Cocoa

class KeyboardManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var holdTimer: Timer?

    private var fnPressed = false
    private var returnPressed = false
    private var holdStartTime: Date?

    private var onUnlockProgress: ((Double) -> Void)?
    private var onUnlock: (() -> Void)?

    func start(onUnlockProgress: @escaping (Double) -> Void, onUnlock: @escaping () -> Void) {
        self.onUnlockProgress = onUnlockProgress
        self.onUnlock = onUnlock

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let mgr = Unmanaged<KeyboardManager>.fromOpaque(refcon).takeUnretainedValue()
                return mgr.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[Wipe] Cannot create event tap – grant Accessibility access")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStartTime = nil
        fnPressed = false
        returnPressed = false

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Event handling

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if !AXIsProcessTrusted() {
                onUnlock?()
                return Unmanaged.passUnretained(event)
            }
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        switch type {
        case .flagsChanged:
            fnPressed = event.flags.contains(.maskSecondaryFn)
            updateHold()
        case .keyDown where keyCode == 0x24 || keyCode == 0x4C:
            returnPressed = true
            updateHold()
        case .keyUp where keyCode == 0x24 || keyCode == 0x4C:
            returnPressed = false
            updateHold()
        default:
            break
        }

        return nil
    }

    // MARK: - Hold-to-unlock logic

    private func updateHold() {
        if fnPressed && returnPressed {
            if holdStartTime == nil {
                holdStartTime = Date()
                startHoldTimer()
            }
        } else {
            holdStartTime = nil
            holdTimer?.invalidate()
            holdTimer = nil
            onUnlockProgress?(0)
        }
    }

    private func startHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let start = self.holdStartTime else { return }
            let progress = min(Date().timeIntervalSince(start) / 7.0, 1.0)
            self.onUnlockProgress?(progress)
            if progress >= 1.0 { self.performUnlock() }
        }
    }

    private func performUnlock() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStartTime = nil
        fnPressed = false
        returnPressed = false
        onUnlock?()
    }
}
