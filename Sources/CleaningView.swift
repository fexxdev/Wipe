import SwiftUI

struct CleaningView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            appState.currentColor.color
                .ignoresSafeArea()
                .onTapGesture {
                    appState.cycleColor()
                }

            if appState.showInstructions {
                VStack(spacing: 12) {
                    Text("Cleaning Mode")
                        .font(.title2.weight(.semibold))
                    Text("Hold fn + \u{23CE} for 7 seconds to unlock")
                        .font(.headline.weight(.regular))
                    Text("Click anywhere to change color")
                        .font(.subheadline)
                }
                .foregroundStyle(textColor)
                .opacity(0.7)
                .transition(.opacity)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(formatCleaningTime(appState.elapsedTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(textColor)
                        .opacity(0.3)
                        .padding(12)
                }
            }

            if appState.unlockProgress > 0 {
                VStack {
                    Spacer()
                    ProgressView(value: appState.unlockProgress)
                        .progressViewStyle(.linear)
                        .tint(.green)
                        .frame(width: 200)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            NSCursor.hide()
            enterFullScreen()
        }
        .onDisappear {
            NSCursor.unhide()
            exitFullScreen()
        }
    }

    private var textColor: Color {
        appState.currentColor == .white ? .black : .white
    }

    private func enterFullScreen() {
        guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    private func exitFullScreen() {
        guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }
}
