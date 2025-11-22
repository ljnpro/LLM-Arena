import SwiftUI
import AppKit

@main
struct LLMComparisonApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var keyManager = APIKeyManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 900, minHeight: 700)
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }.keyboardShortcut(",")
            }
        }

        Settings {
            PreferencesView(keyManager: keyManager)
                .frame(width: 500, height: 350)
        }
    }
}
