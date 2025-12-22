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
                    if SettingsStore.shared.rapidApiKey.isEmpty {
                        SettingsStore.shared.rapidApiKey = key
                    }
                }
            }
        } catch {
            print("Failed to load .env: \(error)")
        }
    }
    
    var body: some Scene {
        // 1. The Dashboard Window
        Window("XFlow Dashboard", id: "dashboard") {
            DashboardView()
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 650, height: 500)
        
        // 2. The Menu Bar Extra
        MenuBarExtra("XFlow", systemImage: "wind") {
            MenuBarContent()
        }
        
        // 3. Settings (Preferences)
        Settings {
            DashboardView()
        }
    }
}

struct MenuBarContent: View {
    @SwiftUI.Environment(\.openWindow) var openWindow
    @ObservedObject var twitterService = TwitterService.shared
    
    var body: some View {
        Button(twitterService.isRunning ? "Stop Flow" : "Start Flow") {
            if twitterService.isRunning {
                twitterService.stopPolling()
            } else {
                twitterService.startPolling()
            }
        }
        
        Divider()
        
        Button("Dashboard") {
            openWindow(id: "dashboard")
            
            // Activate and bring Dashboard to front
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                
                for window in NSApplication.shared.windows {
                    if window.title == "XFlow Dashboard" || window.identifier?.rawValue == "dashboard" {
                        window.level = .floating
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                        break
                    }
                }
            }
        }
        .keyboardShortcut(",")
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
