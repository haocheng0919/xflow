import Cocoa
import SwiftUI

// ============================================================
// DashboardPanel - Custom NSPanel for Dashboard Window
// ============================================================
// This panel is designed to:
// 1. Accept keyboard input in TextFields (canBecomeKey = true)
// 2. Behave like a normal window (not always on top)
// 3. Come to front when activated from menu bar
// ============================================================
// DO NOT MODIFY canBecomeKey or canBecomeMain - TextField input will break!
// ============================================================

class DashboardPanel: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: backingStoreType, defer: flag)
        
        self.level = .normal
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.fullScreenAuxiliary]
        self.title = "XFlow Dashboard"
    }
    
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

// ============================================================
// DashboardWindowController - Controls the Dashboard Window
// ============================================================

class DashboardWindowController: NSWindowController {
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        let panel = DashboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "XFlow Dashboard"
        panel.center()
        
        let hostingView = NSHostingView(rootView: DashboardView())
        panel.contentView = hostingView
        
        self.init(window: panel)
    }
    
    // ============================================================
    // showWindow - Brings Dashboard Window to Front
    // ============================================================
    // This method is called from:
    // 1. Menu bar "Dashboard" button
    // 2. App launch (delayed)
    // 3. Keyboard shortcut (Cmd+,)
    // ============================================================
    // DO NOT MODIFY THE ORDER OF THESE CALLS - Window may not appear!
    // ============================================================
    override func showWindow(_ sender: Any?) {
        guard let window = self.window else { return }
        
        // Step 1: Ensure the app is active and has focus
        NSApp.activate(ignoringOtherApps: true)
        
        // Step 2: Make window visible and key (accepts keyboard input)
        window.makeKeyAndOrderFront(nil)
        
        // Step 3: Order front regardless of other apps
        window.orderFrontRegardless()
        
        // Step 4: Ensure first responder is set to the content view or first field
        if let contentView = window.contentView {
            window.makeFirstResponder(contentView)
        }
    }
}
