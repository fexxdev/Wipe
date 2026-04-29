import SwiftUI
import ApplicationServices

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var hasAccessibility = AXIsProcessTrusted()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)

            Text("Wipe")
                .font(.system(size: 44, weight: .bold, design: .rounded))

            Text("Screen & Keyboard Cleaner")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Screen goes fullscreen at max brightness", systemImage: "sun.max")
                Label("Keyboard is locked while cleaning", systemImage: "keyboard")
                Label("Click anywhere to cycle colors", systemImage: "paintpalette")
                Label("Hold fn + \u{23CE} for 7s to unlock", systemImage: "lock.open")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if !hasAccessibility {
                VStack(spacing: 8) {
                    Text("Accessibility access required to lock keyboard")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.orange)

                    Button("Grant Access") {
                        promptAccessibility()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button(action: { appState.startCleaning() }) {
                Label("Start Cleaning", systemImage: "play.fill")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!hasAccessibility)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            hasAccessibility = AXIsProcessTrusted()
        }
    }

    private func promptAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            hasAccessibility = AXIsProcessTrusted()
        }
    }
}
