import Foundation

// MARK: - Main Configuration

struct HUDConfig {
    var position: CGPoint = CGPoint(x: 50, y: 100)
    var font: String = "SF Mono"
    var fontSize: Double = 12
    var color: String = "#FFFFFF"
    var updateInterval: Double = 1.0
    var enablePublicIP: Bool = false
    var enableFileReading: Bool = false
    var widgets: [WidgetConfig] = []

    // Multi-monitor support
    var displayIndex: Int = 0       // 0 = main display, 1 = secondary, etc.
    var anchor: String = "topLeft"  // topLeft, topRight, bottomLeft, bottomRight

    // Custom date/time formats (strftime-style)
    var dateFormat: String?
    var timeFormat: String?
    var datetimeFormat: String?

    // Per-interface network stats
    var networkInterface: String?

    // Shell command execution (opt-in)
    var enableShellCommands: Bool = false
}

// MARK: - Widget Types

enum WidgetConfig {
    case text(TextWidgetConfig)
    case graph(GraphWidgetConfig)
    case bar(BarWidgetConfig)
    case hr(HRWidgetConfig)
    case gauge(GaugeWidgetConfig)
    case image(ImageWidgetConfig)
}

struct TextWidgetConfig {
    var text: String
    var position: CGPoint
    var color: String?
    var fontSize: Double?
    var fontName: String?
    var weight: String?
    var italic: Bool
    var opacity: Double?
    var shadow: ShadowConfig?
    var alignment: String?  // "left", "center", "right"
    var condition: String?  // JavaScript expression to evaluate for visibility
}

struct ShadowConfig {
    var color: String
    var offsetX: Double
    var offsetY: Double
    var blur: Double
}

struct GraphWidgetConfig {
    var source: String
    var position: CGPoint
    var size: CGSize
    var color: String?
    var condition: String?
}

struct BarWidgetConfig {
    var source: String
    var position: CGPoint
    var width: CGFloat
    var height: CGFloat
    var color: String?
    var backgroundColor: String?
    var condition: String?
}

struct HRWidgetConfig {
    var position: CGPoint
    var width: CGFloat
    var color: String?
    var condition: String?
}

struct GaugeWidgetConfig {
    var source: String
    var position: CGPoint
    var radius: CGFloat
    var thickness: CGFloat
    var color: String?
    var backgroundColor: String?
    var startAngle: Double
    var endAngle: Double
    var condition: String?
}

struct ImageWidgetConfig {
    var path: String
    var position: CGPoint
    var size: CGSize?
    var condition: String?
}
