import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow!
    var hostingView: NSHostingView<ContentView>!
    var updateTimer: Timer?
    var dashboardController: DashboardWindowController?

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
        
        // ALWAYS ignore mouse events - this ensures Dashboard and everything else is interactive
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
        
        // Setup global mouse monitoring for danmaku interaction
        setupMouseMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
    }
    
    private func setupMouseMonitoring() {
        // Use a timer to periodically check mouse position
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkMousePosition()
            }
        }
    }
    
    @MainActor
    private func checkMousePosition() {
        // Check if Dashboard is currently the key window OR visible
        if let dashboardWindow = dashboardController?.window {
            if dashboardWindow.isKeyWindow || dashboardWindow.isVisible {
                // Dashboard is active or visible, ensure overlay doesn't interfere
                overlayWindow.ignoresMouseEvents = true
                return
            }
        }
        
        // If Dashboard is visible, we generally want to be careful, but since Dashboard is .floating (Level 3)
        // and Overlay is Desktop (Level 1), Dashboard will capture clicks if mouse is over it.
        // So we just need to check if mouse is over a danmaku item.
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Convert to overlay window coordinates
        let windowLocation = overlayWindow.convertPoint(fromScreen: mouseLocation)
        
        // Check if there's a danmaku item at this position
        if let contentView = overlayWindow.contentView {
            let hitView = contentView.hitTest(windowLocation)
            
            if let view = hitView, shouldViewBeInteractive(view, in: contentView) {
                // Mouse is over a danmaku - enable interaction
                overlayWindow.ignoresMouseEvents = false
            } else {
                // Mouse is not over anything interactive - pass through
                overlayWindow.ignoresMouseEvents = true
            }
        }
    }
    
    @MainActor
    private func shouldViewBeInteractive(_ view: NSView, in containerView: NSView) -> Bool {
        // If the view is the container, not interactive
        if view == containerView { return false }
        
        let containerSize = containerView.frame.size
        let viewSize = view.frame.size
        
        // Large views are containers, not interactive
        if viewSize.width > containerSize.width * 0.5 && viewSize.height > containerSize.height * 0.5 {
            return false
        }
        
        // Small views are likely danmaku items - interactive
        return true
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
}
