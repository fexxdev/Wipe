import SwiftUI
import ApplicationServices

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var hasAccessibility = AXIsProcessTrusted()
    @State private var isCheckingAccess = false
    @State private var pollTimer: Timer?
    @State private var showStats = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button { showStats = true } label: {
                    Image(systemName: "chart.bar")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Stats")
            }
            .padding(.bottom, -16)

            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Wipe")
                .font(.system(size: 40, weight: .bold, design: .rounded))

            Text("Screen & Keyboard Cleaner")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Screen goes fullscreen at max brightness", systemImage: "sun.max")
                Label("Keyboard is locked while cleaning", systemImage: "keyboard")
                Label("Click anywhere to cycle colors", systemImage: "paintpalette")
                Label("Hold fn + \u{23CE} for 7s to unlock", systemImage: "lock.open")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if !hasAccessibility {
                VStack(spacing: 8) {
                    if isCheckingAccess {
                        ProgressView()
                            .controlSize(.small)
                        Text("Waiting for Accessibility access...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("If Wipe is already enabled, toggle it off and on")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.7))
                    }

                    Button("Open Accessibility Settings") {
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
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            hasAccessibility = AXIsProcessTrusted()
            if !hasAccessibility {
                isCheckingAccess = true
                startPolling()
            }
        }
        .onDisappear {
            stopPolling()
        }
        .sheet(isPresented: $showStats) {
            StatsView()
        }
    }

    private func promptAccessibility() {
        resetStaleEntry()
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        isCheckingAccess = true
        startPolling()
    }

    private func resetStaleEntry() {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.fexxdev.wipe"
        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", bundleId]
        try? task.run()
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if AXIsProcessTrusted() {
                hasAccessibility = true
                isCheckingAccess = false
                stopPolling()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
