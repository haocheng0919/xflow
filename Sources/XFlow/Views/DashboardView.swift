import SwiftUI

struct DashboardView: View {
    @ObservedObject var service = TwitterService.shared
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Column (Status & Settings)
            VStack(spacing: 16) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        LanguageCard()
                        StatusCard()
                        VisualsCard()
                        FilterCard()
                        Web3Card()
                    }
                }
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
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: settings.language) { oldValue, newValue in
            updateWindowManager()
        }
    }
    
    @MainActor
    private func updateWindowManager() {
        if let window = NSApp.windows.first(where: { $0.title.contains("Dashboard") || $0.title.contains("仪表盘") || $0.title.contains("XFlow") }) {
            window.title = "XFlow Dashboard".localized()
        }
    }
}

// MARK: - Components

struct LanguageCard: View {
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Language".localized())
                    .font(.headline)
                Spacer()
                Picker("", selection: $settings.language) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatusCard: View {
    @ObservedObject var service = TwitterService.shared
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(service.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text((service.isRunning ? "Running" : "Paused").localized())
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
                Text("API Connection".localized())
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                if service.errorMessage != nil {
                    Text("Error".localized())
                        .foregroundColor(.red)
                        .font(.system(size: 10))
                } else if settings.bearerToken.isEmpty {
                    Text("Not Configured".localized())
                        .foregroundColor(.orange)
                        .font(.system(size: 10))
                } else {
                    Text("Connected".localized())
                        .foregroundColor(.green)
                        .font(.system(size: 10))
                }
            }
            
            Divider()
            
            // Connection Status
            VStack(alignment: .leading, spacing: 4) {
                Text("Connection Status".localized())
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                HStack {
                    Circle()
                        .fill(service.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(service.isRunning ? ("Running".localized() + (service.errorMessage != nil ? " (With Errors)" : "")) : "Stopped".localized())
                        .font(.headline)
                }
                
                if let error = service.errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                } else if service.isRunning {
                    Text("All systems nominal".localized())
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Divider().padding(.vertical, 4)
                
                // Update Frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text("Update Frequency".localized())
                        .font(.system(size: 11))
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
            Text("Visuals".localized())
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 8) {
                alignedSlider(label: "Speed", value: $settings.speed, in: 1...10)
                alignedSlider(label: "Opacity", value: $settings.opacity, in: 0.1...1.0)
                alignedSlider(label: "Size", value: $settings.fontSize, in: 12...36)
                alignedSlider(label: "Max Width", value: $settings.maxItemWidth, in: 100...800)
                
                HStack {
                    Text("Initial Count".localized())
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .leading)
                    Slider(value: Binding(
                        get: { Double(settings.initialCount) },
                        set: { settings.initialCount = Int($0) }
                    ), in: 0...50, step: 1)
                    Text("\(settings.initialCount)")
                        .font(.system(size: 10))
                        .frame(width: 20)
                }
                
                Divider().padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Zones".localized())
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    HStack {
                        Toggle("Top".localized(), isOn: $settings.showTop)
                        Toggle("Mid".localized(), isOn: $settings.showMiddle)
                        Toggle("Bot".localized(), isOn: $settings.showBottom)
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
    
    private func alignedSlider(label: String, value: Binding<Double>, in range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label.localized())
                .font(.system(size: 11))
                .frame(width: 80, alignment: .leading)
            Slider(value: value, in: range)
        }
    }
}

struct Web3Card: View {
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Memecoin CA".localized())
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $settings.isCryptoEnabled)
                    .toggleStyle(.switch)
            }
            
            if settings.isCryptoEnabled {
                Divider()
                
                Picker("DEX".localized(), selection: $settings.selectedDex) {
                    Text("GMGN").tag("GMGN")
                }
                .pickerStyle(.segmented)
                
                Text("Auto-detects CAs".localized())
                    .font(.system(size: 10))
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
            Text("Data Sources".localized())
                .font(.headline)
            
            Picker("API Service Provider".localized(), selection: $settings.apiType) {
                ForEach(APIServiceType.allCases) { type in
                    Text(Strings.localized(type.displayName, lang: settings.language)).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // API Key Configuration
                    if settings.apiType == .rapid {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("RapidAPI Keys".localized())
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                Spacer()
                                Button(action: {
                                    settings.rapidAPIKeys.append("")
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(.plain)
                                .help("Add Key".localized())
                            }
                            
                            ForEach(settings.rapidAPIKeys.indices, id: \.self) { index in
                                HStack(spacing: 4) {
                                    // Active indicator
                                    if settings.currentKeyIndex == index && !settings.rapidAPIKeys[index].isEmpty {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 6, height: 6)
                                    }
                                    
                                    AppKitSecureField(placeholder: "Key \(index + 1)", text: Binding(
                                        get: { settings.rapidAPIKeys[index] },
                                        set: { settings.rapidAPIKeys[index] = $0 }
                                    )) {}
                                    .frame(height: 22)
                                    
                                    // Remove button (only if more than one key)
                                    if settings.rapidAPIKeys.count > 1 {
                                        Button(action: {
                                            settings.rapidAPIKeys.remove(at: index)
                                            if settings.currentKeyIndex >= settings.rapidAPIKeys.count {
                                                settings.currentKeyIndex = 0
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            // Status text
                            let validKeys = settings.rapidAPIKeys.filter { !$0.isEmpty }.count
                            if validKeys > 1 {
                                Text(String(format: "MultiKeyStatus".localized(), validKeys))
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Official API Key".localized())
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                                AppKitSecureField(placeholder: "bvQy...", text: $settings.officialApiKey) {
                                }
                                .frame(height: 20)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Official API Secret".localized())
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                                AppKitSecureField(placeholder: "tMBg...", text: $settings.officialApiSecret) {
                                }
                                .frame(height: 20)
                            }
                            
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 4) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Access Token".localized())
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                        AppKitSecureField(placeholder: "Optional for timeline", text: $settings.officialAccessToken) {}
                                            .frame(height: 18)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Access Token Secret".localized())
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                        AppKitSecureField(placeholder: "Optional for timeline", text: $settings.officialAccessTokenSecret) {}
                                            .frame(height: 18)
                                    }
                                }
                                .padding(.top, 4)
                            } label: {
                                Text("Timeline Auth (OAuth 1.0a)".localized())
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("OfficialTokenInfo".localized())
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    // User Handles
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Toggle("User Handles".localized(), isOn: $settings.useUserHandles)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .controlSize(.small)
                            Spacer()
                            Text("Token Warning".localized())
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                        AppKitTextField(placeholder: "@user1, @user2, @user3", text: $settings.userHandles)
                            .frame(height: 22)
                            .disabled(!settings.useUserHandles)
                            .opacity(settings.useUserHandles ? 1.0 : 0.5)
                        
                        if settings.useUserHandles && settings.userHandles.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Please enter handles".localized())
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        } else {
                            Text("Handle Info".localized())
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Twitter Lists
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Toggle("Twitter Lists".localized(), isOn: $settings.useTwitterLists)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .controlSize(.small)
                            Spacer()
                            Text("List Token Warning".localized())
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                        AppKitTextField(placeholder: "list_id1, list_id2", text: $settings.twitterLists)
                            .frame(height: 22)
                            .disabled(!settings.useTwitterLists)
                            .opacity(settings.useTwitterLists ? 1.0 : 0.5)
                        
                        if settings.useTwitterLists && settings.twitterLists.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Please enter List IDs".localized())
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        } else {
                            Text("List Info".localized())
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Communities
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Toggle("Communities".localized(), isOn: $settings.useCommunities)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .controlSize(.small)
                            Spacer()
                            Text("Comm Token Warning".localized())
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                        AppKitTextField(placeholder: "comm_id1, comm_id2", text: $settings.communities)
                            .frame(height: 22)
                            .disabled(!settings.useCommunities)
                            .opacity(settings.useCommunities ? 1.0 : 0.5)
                        
                        if settings.useCommunities && settings.communities.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Please enter Community IDs".localized())
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        } else {
                            Text("Comm Info".localized())
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Search Query
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Search Query".localized(), isOn: $settings.useSearchQuery)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .controlSize(.small)
                        AppKitTextField(placeholder: "#crypto, bitcoin, etc.", text: $settings.searchQuery)
                            .frame(height: 22)
                            .disabled(!settings.useSearchQuery)
                            .opacity(settings.useSearchQuery ? 1.0 : 0.5)
                        
                        if settings.useSearchQuery && settings.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Please enter search query".localized())
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Home Timeline (Official Only)
                    if settings.apiType == .official {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Toggle("Home Timeline".localized(), isOn: $settings.useHomeTimeline)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .controlSize(.small)
                                Spacer()
                                Text("Official Only".localized())
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                            AppKitTextField(placeholder: "@your_handle", text: $settings.timelineHandle)
                                .frame(height: 22)
                                .disabled(!settings.useHomeTimeline || settings.apiType != .official)
                                .opacity((settings.useHomeTimeline && settings.apiType == .official) ? 1.0 : 0.5)
                            
                            if settings.useHomeTimeline && settings.apiType == .official && settings.timelineHandle.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("Please enter handles".localized())
                                    .font(.system(size: 8))
                                    .foregroundColor(.red)
                            } else {
                                Text("Timeline Info".localized())
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
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

struct FilterCard: View {
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Advanced Filters".localized())
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $settings.isFiltersEnabled)
                    .toggleStyle(.switch)
            }
            
            if settings.isFiltersEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Toggle("Only Verified".localized(), isOn: $settings.filterVerified)
                        .controlSize(.small)
                    
                    Toggle("Force Verified Mock".localized(), isOn: $settings.forceVerified)
                        .controlSize(.small)
                    
                    Text("Follower Filter".localized())
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Toggle("", isOn: $settings.filterMinFollowersEnabled)
                                .toggleStyle(.checkbox)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Min".localized())
                                    .font(.system(size: 8))
                                AppKitTextField(placeholder: "0", text: Binding(
                                    get: { String(settings.filterMinFollowers) },
                                    set: { if let v = Int($0) { settings.filterMinFollowers = v } }
                                ))
                                .frame(width: 70, height: 20)
                                .disabled(!settings.filterMinFollowersEnabled)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Toggle("", isOn: $settings.filterMaxFollowersEnabled)
                                .toggleStyle(.checkbox)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Max".localized())
                                    .font(.system(size: 8))
                                AppKitTextField(placeholder: "Inf", text: Binding(
                                    get: { String(settings.filterMaxFollowers) },
                                    set: { if let v = Int($0) { settings.filterMaxFollowers = v } }
                                ))
                                .frame(width: 70, height: 20)
                                .disabled(!settings.filterMaxFollowersEnabled)
                            }
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
    @ObservedObject var settings = SettingsStore.shared
    
    var sortedTweets: [XFlowTweet] {
        if settings.historySortNewest {
            return service.tweets.reversed() // Tweets are appended oldest to newest in service
        } else {
            return service.tweets
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History".localized())
                    .font(.headline)
                Spacer()
                Button(action: {
                    settings.historySortNewest.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text((settings.historySortNewest ? "Newest First" : "Oldest First").localized())
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Text("\(service.tweets.count) \("tweets".localized())")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Text("Click Info".localized())
                .font(.system(size: 10))
                .foregroundColor(.blue)
            
            Divider()
            
            List(sortedTweets.prefix(50)) { tweet in
                Button(action: {
                    openTweetInChrome(tweet)
                }) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 2) {
                                Text(tweet.authorName ?? (tweet.authorUsername ?? "Anon"))
                                    .font(.system(size: 11))
                                    .bold()
                                    .lineLimit(1)
                                
                                if tweet.isVerified == true || settings.forceVerified {
                                    if let nsImage = AppAssets.verifiedBadge {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, height: 10)
                                    } else {
                                        Image(systemName: "checkmark.seal.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            Text(tweet.relativeTimestamp)
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 100, alignment: .leading)
                        
                        Text(tweet.text)
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        // Web3 Buttons for History
                        if settings.isCryptoEnabled {
                            let addresses = Web3Utils.shared.extractAddresses(from: tweet.text)
                            if !addresses.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(addresses) { address in
                                        if address.type == .solana {
                                            Button(action: {
                                                if let url = Web3Utils.shared.getTradingUrl(for: address.address, type: .solana, dex: "GMGN") {
                                                    NSWorkspace.shared.open(url)
                                                }
                                            }) {
                                                if let nsImage = AppAssets.gmgnLogo {
                                                    Image(nsImage: nsImage)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 14, height: 14)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        }
                                    }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func openTweetInChrome(_ tweet: XFlowTweet) {
        let username = tweet.authorUsername ?? "i"
        guard let url = URL(string: "https://x.com/\(username)/status/\(tweet.id)") else { return }
        
        // Try to find Google Chrome
        if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: configuration, completionHandler: nil)
        } else {
            // Fallback to default browser
            NSWorkspace.shared.open(url)
        }
    }
}
