import AppKit

struct DisplayMetrics {
    var cpuUsage: Double = 0.0
    var cpuTemp: Double = 0.0
    var cpuFreqMHz: Int = 0
    var loadAverages: LoadAverages = LoadAverages(load1: 0, load5: 0, load15: 0)
    var perCoreUsage: [PerCoreUsage] = []
    var memoryUsage: MemoryUsage = MemoryUsage(
        used: 0, total: 0, percentage: 0,
        swapUsed: 0, swapTotal: 0, swapPercentage: 0
    )
    var networkUsage: NetworkUsage = NetworkUsage(
        localIP: "N/A", publicIP: "Disabled",
        bytesIn: 0, bytesOut: 0,
        bytesInPerSec: 0, bytesOutPerSec: 0
    )
    var wifiInfo: WiFiInfo = WiFiInfo(ssid: "N/A", signalStrength: 0, bssid: "N/A")
    var diskUsage: DiskUsage = DiskUsage(
        totalGB: 0, usedGB: 0, freeGB: 0, percentage: 0,
        readBytesPerSec: 0, writeBytesPerSec: 0, fsType: "N/A"
    )
    var dateTime: DateTimeInfo = DateTimeInfo(formatted: "", date: "", time: "", weekday: "")
    var gpuUsage: GPUUsage = GPUUsage(name: "Unknown", utilizationPercent: 0, temperature: 0)
    var topCPUProcesses: [ProcessInfoData] = []
    var topMemoryProcesses: [ProcessInfoData] = []
    var processTotal: Int = 0
    var processRunning: Int = 0
    var batteryInfo: BatteryInfo = BatteryInfo(
        percent: 0, status: "N/A", timeRemaining: "N/A",
        powerDraw: 0, isPresent: false, cycleCount: 0, health: 0
    )
    var audioInfo: AudioInfo = AudioInfo(deviceName: "Unknown", volume: 0, isMuted: false)
    var bluetoothInfo: BluetoothInfo = BluetoothInfo(connectedCount: 0, devices: [], isPoweredOn: false)
}

final class OverlayView: NSView {
    private var metrics = DisplayMetrics()
    private var config: HUDConfig?
    private var configEngine: ConfigEngine?
    private let renderer = TextRenderer()

    // Graph history storage
    private var graphHistory: [String: [Double]] = [:]
    private let maxHistoryPoints = 60

    // Double-buffering
    private var backBuffer: NSImage?

    // Image cache with LRU eviction
    private var imageCache: [String: NSImage] = [:]
    private var imageCacheOrder: [String] = []  // Tracks access order for LRU
    private let maxImageCacheSize = 50

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setConfig(_ config: HUDConfig, configEngine: ConfigEngine) {
        self.config = config
        self.configEngine = configEngine
        self.imageCache.removeAll()
        self.imageCacheOrder.removeAll()
        self.graphHistory.removeAll()
        self.needsDisplay = true
    }

    func update(metrics: DisplayMetrics) {
        self.metrics = metrics
        updateGraphHistory()
        self.needsDisplay = true
    }

    private func updateGraphHistory() {
        updateHistory(key: "cpu.usage", value: metrics.cpuUsage)
        updateHistory(key: "memory.percent", value: metrics.memoryUsage.percentage)
        updateHistory(key: "gpu.usage", value: metrics.gpuUsage.utilizationPercent)
        updateHistory(key: "network.down", value: min(metrics.networkUsage.bytesInPerSec / 1024 / 1024, 100))
        updateHistory(key: "network.up", value: min(metrics.networkUsage.bytesOutPerSec / 1024 / 1024, 100))
    }

    private func updateHistory(key: String, value: Double) {
        var history = graphHistory[key] ?? []
        history.append(value)
        if history.count > maxHistoryPoints {
            history.removeFirst()
        }
        graphHistory[key] = history
    }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        // Create or reuse back buffer
        if backBuffer == nil || backBuffer?.size != bounds.size {
            backBuffer = NSImage(size: bounds.size)
        }

        guard let buffer = backBuffer else { return }

        // Draw to back buffer
        buffer.lockFocus()
        if let bufferContext = NSGraphicsContext.current?.cgContext {
            bufferContext.clear(bounds)

            if let config = config, let engine = configEngine {
                renderFromConfig(context: bufferContext, config: config, engine: engine)
            } else {
                renderHardcoded(context: bufferContext)
            }
        }
        buffer.unlockFocus()

        // Composite back buffer to screen
        buffer.draw(in: bounds)
    }

    private func renderFromConfig(context: CGContext, config: HUDConfig, engine: ConfigEngine) {
        // Calculate base position based on anchor
        let baseX: CGFloat
        let baseY: CGFloat

        switch config.anchor.lowercased() {
        case "topright":
            baseX = bounds.width - config.position.x
            baseY = bounds.height - config.position.y
        case "bottomleft":
            baseX = config.position.x
            baseY = config.position.y
        case "bottomright":
            baseX = bounds.width - config.position.x
            baseY = config.position.y
        default: // topLeft
            baseX = config.position.x
            baseY = bounds.height - config.position.y
        }

        let defaultColor = parseColor(config.color) ?? .white
        let defaultFontSize = config.fontSize

        for (_, widget) in config.widgets.enumerated() {
            // Extract condition from widget and check if it should render
            let condition: String?
            switch widget {
            case .text(let c): condition = c.condition
            case .graph(let c): condition = c.condition
            case .bar(let c): condition = c.condition
            case .hr(let c): condition = c.condition
            case .gauge(let c): condition = c.condition
            case .image(let c): condition = c.condition
            }

            // Skip rendering if condition evaluates to false
            if !engine.evaluateCondition(condition, metrics: metrics) {
                continue
            }

            switch widget {
            case .text(let textConfig):
                let x = baseX + textConfig.position.x
                let y = baseY - textConfig.position.y

                let expandedText = engine.expandVariables(in: textConfig.text, metrics: metrics)
                let color = textConfig.color.flatMap { parseColor($0) } ?? defaultColor
                let fontSize = textConfig.fontSize ?? defaultFontSize
                let fontWeight = textConfig.weight.flatMap { FontWeight(rawValue: $0) } ?? .regular
                let opacity = CGFloat(textConfig.opacity ?? 1.0)

                var shadow: NSShadow?
                if let shadowConfig = textConfig.shadow {
                    let nsShadow = NSShadow()
                    nsShadow.shadowColor = parseColor(shadowConfig.color) ?? NSColor.black
                    nsShadow.shadowOffset = NSSize(width: shadowConfig.offsetX, height: -shadowConfig.offsetY)
                    nsShadow.shadowBlurRadius = CGFloat(shadowConfig.blur)
                    shadow = nsShadow
                }

                renderer.drawText(
                    context: context,
                    text: expandedText,
                    x: x,
                    y: y,
                    fontSize: fontSize,
                    color: color,
                    fontName: textConfig.fontName,
                    weight: fontWeight,
                    italic: textConfig.italic,
                    opacity: opacity,
                    shadow: shadow,
                    alignment: textConfig.alignment ?? "left"
                )

            case .graph(let graphConfig):
                let x = baseX + graphConfig.position.x
                let y = baseY - graphConfig.position.y
                let color = graphConfig.color.flatMap { parseColor($0) } ?? defaultColor
                let history = graphHistory[graphConfig.source] ?? []

                drawGraph(
                    context: context,
                    x: x,
                    y: y,
                    width: graphConfig.size.width,
                    height: graphConfig.size.height,
                    values: history,
                    color: color
                )

            case .bar(let barConfig):
                let x = baseX + barConfig.position.x
                let y = baseY - barConfig.position.y
                let color = barConfig.color.flatMap { parseColor($0) } ?? defaultColor
                let bgColor = barConfig.backgroundColor.flatMap { parseColor($0) } ?? NSColor(white: 0.2, alpha: 0.5)
                let value = getMetricValue(source: barConfig.source)

                drawBar(
                    context: context,
                    x: x,
                    y: y,
                    width: barConfig.width,
                    height: barConfig.height,
                    value: value,
                    color: color,
                    backgroundColor: bgColor
                )

            case .hr(let hrConfig):
                let x = baseX + hrConfig.position.x
                let y = baseY - hrConfig.position.y
                let color = hrConfig.color.flatMap { parseColor($0) } ?? defaultColor

                drawHorizontalRule(
                    context: context,
                    x: x,
                    y: y,
                    width: hrConfig.width,
                    color: color
                )

            case .gauge(let gaugeConfig):
                let x = baseX + gaugeConfig.position.x
                let y = baseY - gaugeConfig.position.y
                let color = gaugeConfig.color.flatMap { parseColor($0) } ?? defaultColor
                let bgColor = gaugeConfig.backgroundColor.flatMap { parseColor($0) } ?? NSColor(white: 0.2, alpha: 0.5)
                let value = getMetricValue(source: gaugeConfig.source)

                drawGauge(
                    context: context,
                    centerX: x + gaugeConfig.radius,
                    centerY: y - gaugeConfig.radius,
                    radius: gaugeConfig.radius,
                    thickness: gaugeConfig.thickness,
                    value: value,
                    color: color,
                    backgroundColor: bgColor,
                    startAngle: gaugeConfig.startAngle,
                    endAngle: gaugeConfig.endAngle
                )

            case .image(let imageConfig):
                let x = baseX + imageConfig.position.x
                let y = baseY - imageConfig.position.y

                drawImage(
                    context: context,
                    path: imageConfig.path,
                    x: x,
                    y: y,
                    size: imageConfig.size
                )
            }
        }
    }

    private func getMetricValue(source: String) -> Double {
        switch source {
        case "cpu.usage": return metrics.cpuUsage
        case "memory.percent": return metrics.memoryUsage.percentage
        case "swap.percent": return metrics.memoryUsage.swapPercentage
        case "gpu.usage": return metrics.gpuUsage.utilizationPercent
        case "disk.percent": return metrics.diskUsage.percentage
        default:
            if source.hasPrefix("cpu.core") {
                let coreStr = source.dropFirst("cpu.core".count)
                if let coreNum = Int(coreStr), coreNum < metrics.perCoreUsage.count {
                    return metrics.perCoreUsage[coreNum].usage
                }
            }
            return 0
        }
    }

    private func drawBar(
        context: CGContext,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        value: Double,
        color: NSColor,
        backgroundColor: NSColor
    ) {
        context.saveGState()

        // Draw background
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(x: x, y: y - height, width: width, height: height))

        // Draw filled portion
        let fillWidth = width * CGFloat(min(value, 100) / 100.0)
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: x, y: y - height, width: fillWidth, height: height))

        // Draw border
        context.setStrokeColor(NSColor(white: 0.4, alpha: 1.0).cgColor)
        context.setLineWidth(0.5)
        context.stroke(CGRect(x: x, y: y - height, width: width, height: height))

        context.restoreGState()
    }

    private func drawHorizontalRule(
        context: CGContext,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        color: NSColor
    ) {
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.0)
        context.setLineCap(.butt)
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x + width, y: y))
        context.strokePath()
        context.restoreGState()
    }

    private func drawGauge(
        context: CGContext,
        centerX: CGFloat,
        centerY: CGFloat,
        radius: CGFloat,
        thickness: CGFloat,
        value: Double,
        color: NSColor,
        backgroundColor: NSColor,
        startAngle: Double,
        endAngle: Double
    ) {
        context.saveGState()

        let startRad = CGFloat(startAngle) * .pi / 180
        let endRad = CGFloat(endAngle) * .pi / 180
        let arcRadius = radius - thickness / 2

        // Draw background arc
        context.setStrokeColor(backgroundColor.cgColor)
        context.setLineWidth(thickness)
        context.setLineCap(.round)
        context.beginPath()
        context.addArc(
            center: CGPoint(x: centerX, y: centerY),
            radius: arcRadius,
            startAngle: startRad,
            endAngle: endRad,
            clockwise: false
        )
        context.strokePath()

        // Calculate the fill angle based on value (0-100)
        let clampedValue = min(max(value, 0), 100)
        let totalAngle = endAngle - startAngle
        let fillAngle = startAngle + (totalAngle * clampedValue / 100.0)
        let fillRad = CGFloat(fillAngle) * .pi / 180

        // Draw filled arc
        if clampedValue > 0 {
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(thickness)
            context.setLineCap(.round)
            context.beginPath()
            context.addArc(
                center: CGPoint(x: centerX, y: centerY),
                radius: arcRadius,
                startAngle: startRad,
                endAngle: fillRad,
                clockwise: false
            )
            context.strokePath()
        }

        context.restoreGState()
    }

    private func drawImage(
        context: CGContext,
        path: String,
        x: CGFloat,
        y: CGFloat,
        size: CGSize?
    ) {
        let expandedPath = (path as NSString).expandingTildeInPath

        let image: NSImage?
        let cacheKey: String

        if let cached = imageCache[expandedPath] {
            image = cached
            cacheKey = expandedPath
            // Update LRU order - move to end (most recently used)
            if let index = imageCacheOrder.firstIndex(of: cacheKey) {
                imageCacheOrder.remove(at: index)
                imageCacheOrder.append(cacheKey)
            }
        } else if let loaded = NSImage(contentsOfFile: expandedPath) {
            cacheKey = expandedPath
            addToImageCache(key: cacheKey, image: loaded)
            image = loaded
        } else {
            if let symbol = NSImage(systemSymbolName: path, accessibilityDescription: nil) {
                cacheKey = path
                addToImageCache(key: cacheKey, image: symbol)
                image = symbol
            } else {
                print("Failed to load image: \(path)")
                return
            }
        }

        guard let img = image else { return }

        let drawSize = size ?? img.size
        let drawRect = CGRect(
            x: x,
            y: y - drawSize.height,
            width: drawSize.width,
            height: drawSize.height
        )

        NSGraphicsContext.saveGraphicsState()
        if let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgImage, in: drawRect)
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Add image to cache with LRU eviction when limit exceeded
    private func addToImageCache(key: String, image: NSImage) {
        // Evict oldest entries if at capacity
        while imageCache.count >= maxImageCacheSize && !imageCacheOrder.isEmpty {
            let oldestKey = imageCacheOrder.removeFirst()
            imageCache.removeValue(forKey: oldestKey)
        }

        imageCache[key] = image
        imageCacheOrder.append(key)
    }

    private func drawGraph(
        context: CGContext,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        values: [Double],
        color: NSColor
    ) {
        guard !values.isEmpty else { return }

        context.saveGState()

        // Draw background
        context.setFillColor(NSColor(white: 0.1, alpha: 0.5).cgColor)
        context.fill(CGRect(x: x, y: y - height, width: width, height: height))

        // Draw graph line
        let maxValue = max(values.max() ?? 100, 100)
        let pointSpacing = width / CGFloat(maxHistoryPoints - 1)

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.0)
        context.setLineCap(.butt)
        context.beginPath()

        for (index, value) in values.enumerated() {
            let px = x + CGFloat(index + (maxHistoryPoints - values.count)) * pointSpacing
            let py = y - height + (CGFloat(value) / CGFloat(maxValue)) * height

            if index == 0 {
                context.move(to: CGPoint(x: px, y: py))
            } else {
                context.addLine(to: CGPoint(x: px, y: py))
            }
        }

        context.strokePath()

        // Draw border
        context.setStrokeColor(NSColor(white: 0.3, alpha: 1.0).cgColor)
        context.stroke(CGRect(x: x, y: y - height, width: width, height: height))

        context.restoreGState()
    }

    private func renderHardcoded(context: CGContext) {
        let startX: CGFloat = 50
        var y: CGFloat = bounds.height - 80
        let lineHeight: CGFloat = 18
        let sectionGap: CGFloat = 12

        let headerColor = NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        let labelColor = NSColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        let valueColor = NSColor.white

        // Date/Time
        renderer.drawText(context: context, text: metrics.dateTime.formatted, x: startX, y: y, fontSize: 11, color: labelColor)
        y -= lineHeight + sectionGap

        // CPU Section
        renderer.drawText(context: context, text: "CPU", x: startX, y: y, fontSize: 13, color: headerColor, weight: .bold)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "Usage: %.1f%%", metrics.cpuUsage), x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        let cpuTempText = metrics.cpuTemp > 0 ? String(format: "Temp: %.0f C", metrics.cpuTemp) : "Temp: N/A"
        renderer.drawText(context: context, text: cpuTempText, x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight + sectionGap

        // Memory Section
        renderer.drawText(context: context, text: "MEMORY", x: startX, y: y, fontSize: 13, color: headerColor, weight: .bold)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "%.1f GB / %.1f GB (%.0f%%)", metrics.memoryUsage.used, metrics.memoryUsage.total, metrics.memoryUsage.percentage), x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight + sectionGap

        // GPU Section
        renderer.drawText(context: context, text: "GPU", x: startX, y: y, fontSize: 13, color: headerColor, weight: .bold)
        y -= lineHeight
        renderer.drawText(context: context, text: metrics.gpuUsage.name, x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "Usage: %.0f%%", metrics.gpuUsage.utilizationPercent), x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        let gpuTempText = metrics.gpuUsage.temperature > 0 ? String(format: "Temp: %.0f C", metrics.gpuUsage.temperature) : "Temp: N/A"
        renderer.drawText(context: context, text: gpuTempText, x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight + sectionGap

        // Disk Section
        renderer.drawText(context: context, text: "DISK", x: startX, y: y, fontSize: 13, color: headerColor, weight: .bold)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "%.0f GB / %.0f GB (%.0f%%)", metrics.diskUsage.usedGB, metrics.diskUsage.totalGB, metrics.diskUsage.percentage), x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "Free: %.0f GB", metrics.diskUsage.freeGB), x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight + sectionGap

        // Network Section
        renderer.drawText(context: context, text: "NETWORK", x: startX, y: y, fontSize: 13, color: headerColor, weight: .bold)
        y -= lineHeight
        renderer.drawText(context: context, text: "Local: \(metrics.networkUsage.localIP)", x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        renderer.drawText(context: context, text: "Public: \(metrics.networkUsage.publicIP)", x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "Down: %@/s", formatBytes(metrics.networkUsage.bytesInPerSec)), x: startX, y: y, fontSize: 11, color: valueColor)
        y -= lineHeight
        renderer.drawText(context: context, text: String(format: "Up: %@/s", formatBytes(metrics.networkUsage.bytesOutPerSec)), x: startX, y: y, fontSize: 11, color: valueColor)
    }

    private func parseColor(_ hex: String) -> NSColor? {
        var colorString = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle rgba(r,g,b,a) format
        if colorString.hasPrefix("rgba(") && colorString.hasSuffix(")") {
            let inner = colorString.dropFirst(5).dropLast(1)
            let components = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if components.count == 4,
               let r = Double(components[0]),
               let g = Double(components[1]),
               let b = Double(components[2]),
               let a = Double(components[3]) {
                return NSColor(
                    red: CGFloat(r / 255.0),
                    green: CGFloat(g / 255.0),
                    blue: CGFloat(b / 255.0),
                    alpha: CGFloat(a)
                )
            }
            return nil
        }

        // Handle rgb(r,g,b) format
        if colorString.hasPrefix("rgb(") && colorString.hasSuffix(")") {
            let inner = colorString.dropFirst(4).dropLast(1)
            let components = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if components.count == 3,
               let r = Double(components[0]),
               let g = Double(components[1]),
               let b = Double(components[2]) {
                return NSColor(
                    red: CGFloat(r / 255.0),
                    green: CGFloat(g / 255.0),
                    blue: CGFloat(b / 255.0),
                    alpha: 1.0
                )
            }
            return nil
        }

        // Handle hex format
        if colorString.hasPrefix("#") {
            colorString.removeFirst()
        }

        if colorString.count == 6 {
            var rgbValue: UInt64 = 0
            Scanner(string: colorString).scanHexInt64(&rgbValue)
            return NSColor(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else if colorString.count == 8 {
            var rgbaValue: UInt64 = 0
            Scanner(string: colorString).scanHexInt64(&rgbaValue)
            return NSColor(
                red: CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgbaValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgbaValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbaValue & 0x000000FF) / 255.0
            )
        }

        return nil
    }

    private func formatBytes(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        } else {
            return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
        }
    }
}
