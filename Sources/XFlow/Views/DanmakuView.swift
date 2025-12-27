import SwiftUI

struct DanmakuItem: Identifiable {
    let id: String
    let tweet: XFlowTweet
    var x: CGFloat
    var y: CGFloat
    var lane: Int
    var speedMultiplier: CGFloat // Individual variation
    var isPaused: Bool = false
    
    // Cached crypto addresses
    var cryptoAddresses: [CryptoAddress] = []
    
    var width: CGFloat = 0 // Will be set by the view
}

struct DanmakuView: View {
    @ObservedObject var service: TwitterService
    @ObservedObject var settings = SettingsStore.shared
    
    @State private var items: [DanmakuItem] = []
    @State private var processedTweetIds: Set<String> = []
    @State private var canvasSize: CGSize = .zero
    
    // Lane management to prevent simple overlaps
    @State private var laneLastX: [Int: CGFloat] = [:]
    private let laneHeight: CGFloat = 50
    private let lanePadding: CGFloat = 20
    private let verticalMargin: CGFloat = 50
    private let horizontalGap: CGFloat = 150
    
    var body: some View {
        ZStack {
            ForEach($items) { $item in
                DanmakuCellView(item: $item)
                    .position(x: item.x, y: item.y)
                    .opacity(settings.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { canvasSize = proxy.size }
                    .onChange(of: proxy.size) { _, newValue in canvasSize = newValue }
            }
            .allowsHitTesting(false)
        )
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if canvasSize != .zero {
                updateItems(in: canvasSize)
            }
        }
        .onReceive(service.$tweets) { newTweets in
            if newTweets.isEmpty {
                // Service was reset/cleared - clear view state
                items = []
                processedTweetIds = []
                laneLastX = [:]
                DanmakuPositionTracker.shared.clear()
            } else if canvasSize != .zero {
                addNewItems(from: newTweets, in: canvasSize)
            }
        }
    }
    
    private func updateItems(in size: CGSize) {
        let baseSpeed = settings.speed
        
        var newLaneLastX: [Int: CGFloat] = [:]
        
        for i in items.indices {
            if !items[i].isPaused {
                items[i].x -= (baseSpeed * items[i].speedMultiplier)
            }
            
            // Update lane occupancy based on actual item positions
            let rightEdge = items[i].x + items[i].width
            let currentMax = newLaneLastX[items[i].lane] ?? -1000
            newLaneLastX[items[i].lane] = max(currentMax, rightEdge)
        }
        
        self.laneLastX = newLaneLastX
        
        // Update position tracker with current positions
        for item in items {
            let frame = CGRect(
                x: item.x - item.width / 2,
                y: item.y - 25, // Approximate half height
                width: item.width,
                height: 50
            )
            DanmakuPositionTracker.shared.updatePosition(id: item.id, tweet: item.tweet, frame: frame)
        }
        
        // Remove items that are far off-screen
        let removedIds = items.filter { $0.x < -2000 }.map { $0.id }
        for id in removedIds {
            DanmakuPositionTracker.shared.removePosition(id: id)
        }
        items.removeAll { $0.x < -2000 } // Allow more space for long expanded tweets
    }
    
    private func addNewItems(from tweets: [XFlowTweet], in size: CGSize) {
        let usableHeight = size.height - (verticalMargin * 2)
        let availableLanes = Int(usableHeight / (laneHeight + lanePadding))
        
        for tweet in tweets {
            if !processedTweetIds.contains(tweet.id) {
                processedTweetIds.insert(tweet.id)
                
                // Determine valid zones
                let totalLanes = availableLanes
                let topLanes = 0..<Int(Double(totalLanes) * 0.33)
                let middleLanes = Int(Double(totalLanes) * 0.33)..<Int(Double(totalLanes) * 0.66)
                let bottomLanes = Int(Double(totalLanes) * 0.66)..<totalLanes
                
                var possibleLanes: [Int] = []
                if settings.showTop { possibleLanes.append(contentsOf: topLanes) }
                if settings.showMiddle { possibleLanes.append(contentsOf: middleLanes) }
                if settings.showBottom { possibleLanes.append(contentsOf: bottomLanes) }
                
                if possibleLanes.isEmpty { possibleLanes = Array(0..<totalLanes) }
                
                // Find a lane that is not occupied at the entry point
                // Add horizontalGap to push items further apart
                let entryX = size.width + 100
                
                if let bestLane = possibleLanes.shuffled().first(where: { (laneLastX[$0] ?? 0) < size.width - horizontalGap }) {
                    let y = CGFloat(bestLane) * (laneHeight + lanePadding) + laneHeight / 2 + verticalMargin
                    
                    let addresses = Web3Utils.shared.extractAddresses(from: tweet.text)
                    
                    // Estimate width (rough) for initial placement
                    let estimatedWidth: CGFloat = CGFloat(tweet.text.count) * (settings.fontSize * 0.7) + 150
                    
                    let item = DanmakuItem(
                        id: tweet.id,
                        tweet: tweet,
                        x: entryX,
                        y: y,
                        lane: bestLane,
                        speedMultiplier: CGFloat.random(in: 0.8...1.2),
                        cryptoAddresses: addresses,
                        width: estimatedWidth
                    )
                    
                    laneLastX[bestLane] = entryX + estimatedWidth
                    items.append(item)
                }
            }
        }
    }
}

struct DanmakuCellView: View {
    @Binding var item: DanmakuItem
    @ObservedObject var settings = SettingsStore.shared
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            if let url = item.tweet.authorProfileImageUrl {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .frame(width: settings.fontSize + 4, height: settings.fontSize + 4)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(item.tweet.authorUsername ?? "User")
                        .font(.system(size: settings.fontSize * 0.7, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(item.tweet.relativeTimestamp)
                        .font(.system(size: settings.fontSize * 0.5))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(item.tweet.text)
                    .font(.system(size: settings.fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(isHovering ? nil : 1)
                    .frame(maxWidth: isHovering ? 500 : settings.maxItemWidth, alignment: .leading)
                    .fixedSize(horizontal: !isHovering, vertical: isHovering)
            }
            
            // Web3 Logo Injection
            if settings.isCryptoEnabled && !item.cryptoAddresses.isEmpty {
                ForEach(item.cryptoAddresses) { address in
                    Button(action: {
                        if let url = Web3Utils.shared.getTradingUrl(for: address.address, type: address.type, dex: settings.selectedDex) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 2) {
                            Text(address.type == .solana ? "SOL" : "EVM")
                                .font(.system(size: 8, weight: .bold))
                            Image(systemName: "arrow.up.forward.square.fill")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(address.type == .solana ? Color.purple : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Open Tweet Button (Visible on Hover)
            if isHovering {
                Button(action: {
                    openInChrome(item.tweet)
                }) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(8)
        .background(
            Capsule()
                .fill(Color.black.opacity(isHovering ? 0.8 : 0.3))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                item.isPaused = hovering
            }
        }
        .onTapGesture {
            openInChrome(item.tweet)
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { item.width = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in item.width = newValue }
            }
        )
    }
    
    private func openInChrome(_ tweet: XFlowTweet) {
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
