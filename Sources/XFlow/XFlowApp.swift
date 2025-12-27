import SwiftUI
import KeyboardShortcuts
import SwiftDotenv

@main
struct XFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var twitterService = TwitterService.shared
    
    init() {
        // Load .env manually to avoid SwiftUI.Environment conflict
        do {
            let env = try Dotenv.load(path: ".env")
            if let tokenVal = env.values["BEARER_TOKEN"] {
                // swift-dotenv Value enum: .string, .boolean, etc.
                if case .string(let token) = tokenVal {
                    if SettingsStore.shared.bearerToken.isEmpty {
                        SettingsStore.shared.bearerToken = token
                    }
                }
            }
            if let rapidKeyVal = env.values["RAPIDAPI_KEY"] {
                if case .string(let key) = rapidKeyVal {
                    if SettingsStore.shared.rapidAPIKeys.isEmpty || SettingsStore.shared.rapidAPIKeys.first?.isEmpty == true {
                        SettingsStore.shared.rapidAPIKeys = [key]
                    }
                }
            }
        } catch {
            // Error loading .env
        }
    }
    
    var body: some Scene {
        // 1. The Menu Bar Extra with X-shaped icon
        MenuBarExtra("XFlow", systemImage: "xmark") {
            MenuBarContent()
        }
    }
}

struct MenuBarContent: View {
    @ObservedObject var twitterService = TwitterService.shared
    
    var body: some View {
        Button((twitterService.isRunning ? "Stop Flow" : "Start Flow").localized()) {
            if twitterService.isRunning {
                twitterService.stopPolling()
            } else {
                twitterService.startPolling()
            }
        }
        
        Divider()
        
        // ============================================================
        // IMPORTANT: Dashboard Button - Brings Dashboard Window to Front
        // DO NOT MODIFY THIS LOGIC - It ensures proper window activation
        // ============================================================
        Button("Dashboard".localized()) {
            // Use async dispatch to ensure menu closes before window activation
            // This is required because MenuBarExtra steals focus when closing
            DispatchQueue.main.async {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.showDashboard()
                }
            }
        }
        .keyboardShortcut(",")
        
        Divider()
        
        Button("Quit".localized()) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
