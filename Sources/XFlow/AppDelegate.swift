import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow!
    var hostingView: NSHostingView<ContentView>!
    var updateTimer: Timer?
    var dashboardController: DashboardWindowController?
    var globalClickMonitor: Any?
    var localClickMonitor: Any?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Change to .regular to ensure it behaves like a normal Mac app with focus
        NSApp.setActivationPolicy(.regular)
        
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        overlayWindow = OverlayWindow(
            contentRect: screenRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        // Always ignore mouse events - we handle clicks via global monitor
        overlayWindow.ignoresMouseEvents = true
        
        hostingView = NSHostingView(rootView: ContentView())
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        overlayWindow.contentView = hostingView
        overlayWindow.orderFront(nil)
        
        // Create dashboard controller immediately
        dashboardController = DashboardWindowController()
        
        // Show Dashboard on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showDashboard()
        }
        
        // Setup global click monitoring for danmaku clicks
        setupGlobalClickMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupGlobalClickMonitoring() {
        // Monitor global clicks (when app is not focused)
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            // Event monitors already run on main thread
            self?.processClickNow()
        }
        
        // Monitor local clicks (when app is focused)
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            // Event monitors already run on main thread
            self?.processClickNow()
            return event
        }
    }
    
    private func processClickNow() {
        // If Dashboard is focused, don't handle danmaku clicks
        if let dashboardWindow = dashboardController?.window, dashboardWindow.isKeyWindow {
            return
        }
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Check if click is on a danmaku item using the position tracker
        if let item = DanmakuPositionTracker.shared.itemAt(screenPoint: mouseLocation, in: overlayWindow) {
            // Smart redirect: GMGN for CA tweets, Twitter for others
            DanmakuPositionTracker.shared.openTweetOrGMGN(item.tweet)
        }
    }
    
    // ============================================================
    // showDashboard - Entry Point for Showing Dashboard
    // ============================================================
    // Called from: MenuBarContent "Dashboard" button
    // DO NOT MODIFY - This ensures Dashboard can be activated from menu bar
    // ============================================================
    @MainActor
    func showDashboard() {
        guard let dashboardController = dashboardController else { return }
        
        // Ensure overlay doesn't interfere with dashboard input
        overlayWindow.ignoresMouseEvents = true
        
        // Show the dashboard window (handles activation and focus)
        dashboardController.showWindow(nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }
}
