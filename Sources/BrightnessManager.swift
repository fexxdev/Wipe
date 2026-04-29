import Foundation
import CoreGraphics

class BrightnessManager {
    private var savedBrightness: Float = 1.0
    private static let recoveryKey = "com.fexxdev.wipe.savedBrightness"
    private static let recoveryFlagKey = "com.fexxdev.wipe.brightnessNeedsRecovery"

    private typealias SetBrightnessFn = @convention(c) (UInt32, Float) -> Int32
    private typealias GetBrightnessFn = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32

    private let handle: UnsafeMutableRawPointer?
    private let setBrightness: SetBrightnessFn?
    private let getBrightness: GetBrightnessFn?

    init() {
        handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
        if let h = handle {
            setBrightness = unsafeBitCast(dlsym(h, "DisplayServicesSetBrightness"), to: SetBrightnessFn?.self)
            getBrightness = unsafeBitCast(dlsym(h, "DisplayServicesGetBrightness"), to: GetBrightnessFn?.self)
        } else {
            setBrightness = nil
            getBrightness = nil
        }
    }

    deinit {
        if let h = handle { dlclose(h) }
    }

    func setMaxBrightness() {
        var current: Float = 1.0
        if let get = getBrightness {
            _ = get(CGMainDisplayID(), &current)
        }
        savedBrightness = current
        UserDefaults.standard.set(current, forKey: Self.recoveryKey)
        UserDefaults.standard.set(true, forKey: Self.recoveryFlagKey)
        _ = setBrightness?(CGMainDisplayID(), 1.0)
    }

    func restoreBrightness() {
        _ = setBrightness?(CGMainDisplayID(), savedBrightness)
        UserDefaults.standard.removeObject(forKey: Self.recoveryKey)
        UserDefaults.standard.removeObject(forKey: Self.recoveryFlagKey)
    }

    func recoverIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Self.recoveryFlagKey) else { return }
        let saved = UserDefaults.standard.float(forKey: Self.recoveryKey)
        _ = setBrightness?(CGMainDisplayID(), saved)
        UserDefaults.standard.removeObject(forKey: Self.recoveryKey)
        UserDefaults.standard.removeObject(forKey: Self.recoveryFlagKey)
    }
}
