import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AccountsSettingsView()
                .tabItem {
                    Label("Accounts", systemImage: "at")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Text("General Settings Placeholder")
        }
        .padding()
    }
}

struct AccountsSettingsView: View {
    var body: some View {
        Form {
            Text("Twitter API Key Configuration")
        }
        .padding()
    }
}
