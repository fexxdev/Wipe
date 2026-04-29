import SwiftUI

enum CleaningColor: CaseIterable {
    case black, white, red, green, blue

    var color: Color {
        switch self {
        case .black: return .black
        case .white: return .white
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        }
    }

    var label: String {
        switch self {
        case .black: return "Black"
        case .white: return "White"
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        }
    }
}

func formatCleaningTime(_ t: TimeInterval) -> String {
    let m = Int(t) / 60
    let s = Int(t) % 60
    return String(format: "%d:%02d", m, s)
}

@MainActor
class AppState: ObservableObject {
    @Published var isCleaning = false
    @Published var currentColor: CleaningColor = .black
    @Published var elapsedTime: TimeInterval = 0
    @Published var showInstructions = true
    @Published var unlockProgress: Double = 0

    let keyboardManager = KeyboardManager()
    let brightnessManager = BrightnessManager()

    private var timer: Timer?
    private var fadeTask: Task<Void, Never>?

    init() {
        brightnessManager.recoverIfNeeded()
    }

    func startCleaning() {
        isCleaning = true
        currentColor = .black
        elapsedTime = 0
        unlockProgress = 0
        showInstructions = true

        let start = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
        }

        brightnessManager.setMaxBrightness()

        keyboardManager.start(
            onUnlockProgress: { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.unlockProgress = progress
                }
            },
            onUnlock: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.stopCleaning()
                }
            }
        )

        fadeTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1)) {
                showInstructions = false
            }
        }
    }

    func stopCleaning() {
        isCleaning = false
        timer?.invalidate()
        timer = nil
        fadeTask?.cancel()
        fadeTask = nil
        unlockProgress = 0
        keyboardManager.stop()
        brightnessManager.restoreBrightness()
        NSSound(named: "Glass")?.play()
    }

    func cycleColor() {
        let all = CleaningColor.allCases
        let idx = all.firstIndex(of: currentColor) ?? 0
        currentColor = all[(idx + 1) % all.count]
    }
}
