import AppKit

final class OverlayWindow: NSWindow {
    let overlayView: OverlayView

    init() {
        // Get main screen size
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        // Create the view
        overlayView = OverlayView(frame: screenFrame)

        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Configure as desktop-level overlay
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.hasShadow = false

        self.contentView = overlayView
    }

    /// Position the window on a specific display with anchor-based positioning
    /// - Parameters:
    ///   - index: Display index (0 = main display)
    ///   - anchor: Position anchor (topLeft, topRight, bottomLeft, bottomRight)
    ///   - offset: Offset from the anchor point
    func positionOnDisplay(index: Int, anchor: String, offset: CGPoint) {
        let screens = NSScreen.screens

        // Fall back to main screen if index is out of range
        guard index < screens.count else {
            if index > 0 {
                print("Display \(index) not found, falling back to main display")
            }
            positionOnDisplay(index: 0, anchor: anchor, offset: offset)
            return
        }

        let screen = screens[index]
        let frame = screen.visibleFrame

        // Resize window to match the target screen
        self.setFrame(screen.frame, display: false)
        overlayView.frame = NSRect(origin: .zero, size: screen.frame.size)

        // Calculate origin based on anchor
        var origin: CGPoint

        switch anchor.lowercased() {
        case "topright":
            // Top-right: position content from right edge (handled in OverlayView)
            origin = CGPoint(
                x: frame.minX,
                y: frame.minY
            )
        case "bottomleft":
            // Bottom-left: position content from bottom (handled in OverlayView)
            origin = CGPoint(
                x: frame.minX,
                y: frame.minY
            )
        case "bottomright":
            // Bottom-right: position content from right edge (handled in OverlayView)
            origin = CGPoint(
                x: frame.minX,
                y: frame.minY
            )
        default: // topLeft
            // All anchors: position window at display origin, content positioning handled in OverlayView
            origin = CGPoint(
                x: frame.minX,
                y: frame.minY
            )
        }

        self.setFrameOrigin(origin)
    }
}
