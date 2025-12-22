import Cocoa

class OverlayWindow: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        // We force .borderless and .nonactivatingPanel
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: backingStoreType, defer: flag)
        
        self.isFloatingPanel = true
        // Use Desktop level + 1 to ensure it's above wallpaper but strictly BEHIND all normal windows
        // This guarantees Dashboard (at .floating or .normal) is always above and interactive
        self.level = NSWindow.Level(Int(CGWindowLevelKey.desktopWindow.rawValue) + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        // CRITICAL: Always ignore mouse events so all clicks pass through
        self.ignoresMouseEvents = true
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
