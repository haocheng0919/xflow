import SwiftUI

struct ContentView: View {
    @ObservedObject var twitterService = TwitterService.shared
    
    var body: some View {
        ZStack {
            // Danmaku Layer
            DanmakuView(service: twitterService)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
