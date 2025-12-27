import Foundation
import SwiftUI

/// Shared tracker for danmaku item positions to enable manual hit testing
/// when the overlay window has ignoresMouseEvents = true
@MainActor
class DanmakuPositionTracker: ObservableObject {
    static let shared = DanmakuPositionTracker()
    
    struct ItemPosition {
        let id: String
        let tweet: XFlowTweet
        var frame: CGRect
    }
    
    @Published var positions: [ItemPosition] = []
    
    private init() {}
    
    func updatePosition(id: String, tweet: XFlowTweet, frame: CGRect) {
        if let index = positions.firstIndex(where: { $0.id == id }) {
            positions[index].frame = frame
        } else {
            positions.append(ItemPosition(id: id, tweet: tweet, frame: frame))
        }
    }
    
    func removePosition(id: String) {
        positions.removeAll { $0.id == id }
    }
    
    func clear() {
        positions = []
    }
    
    /// Check if a point (in screen coordinates) is over any danmaku item
    func itemAt(screenPoint: NSPoint, in window: NSWindow) -> ItemPosition? {
        // Convert screen point to window coordinates
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        
        // The window origin is at bottom-left in AppKit, but SwiftUI uses top-left
        // So we need to flip the y coordinate
        let flippedPoint = NSPoint(x: windowPoint.x, y: window.frame.height - windowPoint.y)
        
        // Check each position
        for position in positions {
            if position.frame.contains(flippedPoint) {
                return position
            }
        }
        return nil
    }
    
    /// Open the tweet in Chrome
    func openTweetInChrome(_ tweet: XFlowTweet) {
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
