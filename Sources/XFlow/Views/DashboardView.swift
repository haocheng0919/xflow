import SwiftUI

struct DashboardView: View {
    @ObservedObject var service = TwitterService.shared
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Column (Status & Settings)
            VStack(spacing: 16) {
                // Status Card
                StatusCard()
                
                // Visuals Card
                VisualsCard()
                
                // Web3 Card
                Web3Card()
            }
            .frame(width: 280)
            
            // Right Column (History & Sources)
            VStack(spacing: 16) {
                // Sources Card
                SourcesCard()
                
                // History Card
                HistoryCard()
            }
            .frame(minWidth: 300)
        }
        .padding()
        .frame(width: 650, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Components

struct StatusCard: View {
    @ObservedObject var service = TwitterService.shared
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(service.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(service.isRunning ? "Running" : "Paused")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { service.isRunning },
                    set: { val in
                        if val { service.startPolling() }
                        else { service.stopPolling() }
                    }
                ))
                .toggleStyle(.switch)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("API Connection")
                    .font(.caption)
                    .foregroundColor(.gray)
                if service.errorMessage != nil {
                    Text("Error")
                        .foregroundColor(.red)
                        .font(.caption2)
                } else if settings.bearerToken.isEmpty {
                    Text("Not Configured")
                        .foregroundColor(.orange)
                        .font(.caption2)
                } else {
                    Text("Connected")
                        .foregroundColor(.green)
                        .font(.caption2)
                }
            }
            
            Divider()
            
            // Update Frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text("Update Frequency")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        AppKitTextField(placeholder: "Interval", text: Binding(
                            get: { String(settings.updateInterval) },
                            set: { 
                                if let value = Double($0) {
                                    settings.updateInterval = value
                                }
                            }
                        ))
                            .frame(width: 60, height: 22)
                        Picker("", selection: $settings.updateUnit) {
                            Text("s").tag("s")
                            Text("m").tag("m")
                            Text("h").tag("h")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct VisualsCard: View {
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visuals")
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 12) {
                HStack {
                    Text("Speed")
                        .font(.caption)
                    Slider(value: $settings.speed, in: 1...10)
                }
                
                HStack {
                    Text("Opacity")
                        .font(.caption)
                    Slider(value: $settings.opacity, in: 0.1...1.0)
                }
                
                HStack {
                    Text("Size")
                        .font(.caption)
                    Slider(value: $settings.fontSize, in: 12...36)
                }
                
                HStack {
                    Text("Max Width")
                        .font(.caption)
                    Slider(value: $settings.maxItemWidth, in: 100...800)
                }
                
                HStack {
                    Text("Initial Count")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { Double(settings.initialCount) },
                        set: { settings.initialCount = Int($0) }
                    ), in: 0...50, step: 1)
                    Text("\(settings.initialCount)")
                        .font(.caption2)
                        .frame(width: 20)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Zones")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Toggle("Top", isOn: $settings.showTop)
                        Toggle("Mid", isOn: $settings.showMiddle)
                        Toggle("Bot", isOn: $settings.showBottom)
                    }
                    .toggleStyle(.button)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct Web3Card: View {
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Web3")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $settings.isCryptoEnabled)
                    .toggleStyle(.switch)
            }
            
            if settings.isCryptoEnabled {
                Divider()
                
                Picker("DEX", selection: $settings.selectedDex) {
                    Text("GMGN").tag("GMGN")
                    Text("Axiom").tag("Axiom")
                    Text("Photon").tag("Photon")
                }
                .pickerStyle(.segmented)
                
                Text("Auto-detects Solana & EVM CAs")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SourcesCard: View {
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Sources")
                .font(.headline)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // API Key
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RapidAPI Key")
                            .font(.caption)
                            .foregroundColor(.gray)
                        AppKitSecureField(placeholder: "API Key", text: $settings.rapidApiKey) {
                        }
                        .frame(height: 22)
                        .onChange(of: settings.rapidApiKey) { oldValue, newValue in
                        }
                    }
                    
                    // User Handles
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("User Handles")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("⚠️ 1 token per handle")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        AppKitTextField(placeholder: "@user1, @user2, @user3", text: $settings.userHandles)
                            .frame(height: 22)
                            .onChange(of: settings.userHandles) { oldValue, newValue in
                            }
                        Text("Comma-separated user handles")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Twitter Lists
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Twitter Lists (IDs)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("⚠️ 1 token per list")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        AppKitTextField(placeholder: "list_id1, list_id2", text: $settings.twitterLists)
                            .frame(height: 22)
                        Text("Not yet supported by API")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Communities
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Communities (IDs)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("⚠️ 1 token per community")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        AppKitTextField(placeholder: "comm_id1, comm_id2", text: $settings.communities)
                            .frame(height: 22)
                        Text("Not yet supported by API")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Search Query
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Query")
                            .font(.caption)
                            .foregroundColor(.gray)
                        AppKitTextField(placeholder: "#crypto, bitcoin, etc.", text: $settings.searchQuery)
                            .frame(height: 22)
                            .onChange(of: settings.searchQuery) { oldValue, newValue in
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct HistoryCard: View {
    @ObservedObject var service = TwitterService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                Text("\(service.tweets.count) tweets")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            List(service.tweets.prefix(20)) { tweet in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(tweet.authorUsername ?? "Anon")
                            .font(.caption)
                            .bold()
                        Text(tweet.relativeTimestamp)
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 80, alignment: .leading)
                    
                    Text(tweet.text)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
            .listStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
