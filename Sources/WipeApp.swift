import SwiftUI

@main
struct WipeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isCleaning {
                    CleaningView()
                } else {
                    HomeView()
                }
            }
            .environmentObject(appState)
            .frame(minWidth: 480, minHeight: 520)
        }
        .defaultSize(width: 480, height: 520)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
