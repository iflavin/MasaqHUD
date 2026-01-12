import Foundation
import JavaScriptCore

final class ConfigEngine {
    private var context: JSContext
    private var configData: HUDConfig = HUDConfig()

    // Cached regex for variable expansion (avoids repeated compilation)
    private static let variableRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\$\{([^}]+)\}"#)
    }()

    // Cached regex for file variable expansion
    private static let fileVariableRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\$\{file\s+path="([^"]+)"\}"#)
    }()

    // Cached regex for shell command execution
    private static let execVariableRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\$\{exec\s+command="([^"]+)"\}"#)
    }()

    // Cached static system info (doesn't change during runtime)
    private lazy var cachedSystemInfo: (kernel: String, machine: String, sysname: String, osVersion: String) = {
        var uts = utsname()
        uname(&uts)
        let kernel = withUnsafePointer(to: &uts.release) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        let machine = withUnsafePointer(to: &uts.machine) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        let sysname = withUnsafePointer(to: &uts.sysname) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        return (kernel, machine, sysname, getOSVersion())
    }()

    init() {
        context = JSContext()!

        context.exceptionHandler = { _, exception in
            if let error = exception?.toString() {
                print("JS Error: \(error)")
            }
        }

        setupMasaqHUDAPI()
    }

    func loadConfig(from path: String) -> HUDConfig? {
        guard let script = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to read config file: \(path)")
            return nil
        }

        // Reset config for fresh load
        configData = HUDConfig()

        // Create fresh JSContext to prevent memory accumulation from repeated hot-reloads
        context = JSContext()!
        context.exceptionHandler = { _, exception in
            if let error = exception?.toString() {
                print("JS Error: \(error)")
            }
        }
        setupMasaqHUDAPI()

        // Execute the config script
        context.evaluateScript(script)

        // Check for errors
        if context.exception != nil {
            print("Config execution error: \(context.exception?.toString() ?? "unknown")")
            return nil
        }

        return configData
    }

    private func setupMasaqHUDAPI() {
        // Create masaqhud object
        let masaqhud = JSValue(newObjectIn: context)!

        // masaqhud.config(options)
        let configFunc: @convention(block) (JSValue) -> Void = { [weak self] options in
            self?.parseGlobalConfig(options)
        }
        masaqhud.setObject(configFunc, forKeyedSubscript: "config" as NSString)

        // masaqhud.widget(options)
        let widgetFunc: @convention(block) (JSValue) -> Void = { [weak self] options in
            self?.parseWidget(options)
        }
        masaqhud.setObject(widgetFunc, forKeyedSubscript: "widget" as NSString)

        context.setObject(masaqhud, forKeyedSubscript: "masaqhud" as NSString)
    }

    private func parseGlobalConfig(_ options: JSValue) {
        if let position = options.forProperty("position"), !position.isUndefined {
            let x = position.forProperty("x")?.toDouble() ?? 50
            let y = position.forProperty("y")?.toDouble() ?? 100
            configData.position = CGPoint(x: x, y: y)
        }

        if let font = options.forProperty("font"), font.isString {
            configData.font = font.toString()
        }

        if let fontSize = options.forProperty("fontSize"), fontSize.isNumber {
            configData.fontSize = fontSize.toDouble()
        }

        if let color = options.forProperty("color"), color.isString {
            configData.color = color.toString()
        }

        if let interval = options.forProperty("updateInterval"), interval.isNumber {
            configData.updateInterval = interval.toDouble()
        }

        if let enablePublicIP = options.forProperty("enablePublicIP"), enablePublicIP.isBoolean {
            configData.enablePublicIP = enablePublicIP.toBool()
        }

        if let enableFileReading = options.forProperty("enableFileReading"), enableFileReading.isBoolean {
            configData.enableFileReading = enableFileReading.toBool()
        }

        // Multi-monitor support
        if let displayIndex = options.forProperty("display"), displayIndex.isNumber {
            configData.displayIndex = Int(displayIndex.toInt32())
        }

        if let anchor = options.forProperty("anchor"), anchor.isString {
            configData.anchor = anchor.toString()
        }

        // Custom date/time formats (strftime-style)
        if let dateFormat = options.forProperty("dateFormat"), dateFormat.isString {
            configData.dateFormat = dateFormat.toString()
        }

        if let timeFormat = options.forProperty("timeFormat"), timeFormat.isString {
            configData.timeFormat = timeFormat.toString()
        }

        if let datetimeFormat = options.forProperty("datetimeFormat"), datetimeFormat.isString {
            configData.datetimeFormat = datetimeFormat.toString()
        }

        // Per-interface network stats
        if let networkInterface = options.forProperty("networkInterface"), networkInterface.isString {
            configData.networkInterface = networkInterface.toString()
        }

        // Shell command execution (opt-in)
        if let enableShellCommands = options.forProperty("enableShellCommands"), enableShellCommands.isBoolean {
            configData.enableShellCommands = enableShellCommands.toBool()
        }
    }

    private func parseWidget(_ options: JSValue) {
        guard let typeValue = options.forProperty("type"), typeValue.isString else { return }
        let type = typeValue.toString()

        let position = parsePoint(options.forProperty("position"))
        let color = optionalString(options.forProperty("color"))
        let fontSize = options.forProperty("fontSize")?.toDouble()

        switch type {
        case "text":
            let text = options.forProperty("text")?.toString() ?? ""
            let fontName = optionalString(options.forProperty("font"))
            let italic = options.forProperty("italic")?.toBool() ?? false
            var weight = optionalString(options.forProperty("weight"))
            if weight == nil && (options.forProperty("bold")?.toBool() ?? false) {
                weight = "bold"
            }
            let opacity = options.forProperty("opacity")?.toDouble()
            let shadow = parseShadow(options.forProperty("shadow"))
            let alignment = optionalString(options.forProperty("align"))
            let condition = optionalString(options.forProperty("condition"))
            configData.widgets.append(.text(TextWidgetConfig(
                text: text,
                position: position,
                color: color,
                fontSize: fontSize,
                fontName: fontName,
                weight: weight,
                italic: italic,
                opacity: opacity,
                shadow: shadow,
                alignment: alignment,
                condition: condition
            )))

        case "graph":
            let source = options.forProperty("source")?.toString() ?? ""
            let size = parseSize(options.forProperty("size")) ?? CGSize(width: 200, height: 50)
            let condition = optionalString(options.forProperty("condition"))
            configData.widgets.append(.graph(GraphWidgetConfig(
                source: source,
                position: position,
                size: size,
                color: color,
                condition: condition
            )))

        case "bar":
            let source = options.forProperty("source")?.toString() ?? ""
            let width = options.forProperty("width")?.toDouble() ?? 100
            let height = options.forProperty("height")?.toDouble() ?? 10
            let bgColor = optionalString(options.forProperty("backgroundColor"))
            let condition = optionalString(options.forProperty("condition"))
            configData.widgets.append(.bar(BarWidgetConfig(
                source: source,
                position: position,
                width: CGFloat(width),
                height: CGFloat(height),
                color: color,
                backgroundColor: bgColor,
                condition: condition
            )))

        case "hr":
            let width = options.forProperty("width")?.toDouble() ?? 200
            let condition = optionalString(options.forProperty("condition"))
            configData.widgets.append(.hr(HRWidgetConfig(
                position: position,
                width: CGFloat(width),
                color: color,
                condition: condition
            )))

        case "gauge":
            let source = options.forProperty("source")?.toString() ?? ""
            let radius = options.forProperty("radius")?.toDouble() ?? 40
            let thickness = options.forProperty("thickness")?.toDouble() ?? 8
            let bgColor = optionalString(options.forProperty("backgroundColor"))
            let startAngle = options.forProperty("startAngle")?.toDouble() ?? 135
            let endAngle = options.forProperty("endAngle")?.toDouble() ?? 405
            let condition = optionalString(options.forProperty("condition"))
            configData.widgets.append(.gauge(GaugeWidgetConfig(
                source: source,
                position: position,
                radius: CGFloat(radius),
                thickness: CGFloat(thickness),
                color: color,
                backgroundColor: bgColor,
                startAngle: startAngle,
                endAngle: endAngle,
                condition: condition
            )))

        case "image":
            let path = options.forProperty("path")?.toString() ?? ""
            let size = parseSize(options.forProperty("size"))
            let condition = optionalString(options.forProperty("condition"))
            configData.widgets.append(.image(ImageWidgetConfig(
                path: path,
                position: position,
                size: size,
                condition: condition
            )))

        default:
            print("Unknown widget type: \(type ?? "nil")")
        }
    }

    private func parsePoint(_ value: JSValue?) -> CGPoint {
        guard let value = value, !value.isUndefined, !value.isNull else {
            return .zero
        }
        let x = value.forProperty("x")?.toDouble() ?? 0
        let y = value.forProperty("y")?.toDouble() ?? 0
        return CGPoint(x: x, y: y)
    }

    private func parseSize(_ value: JSValue?) -> CGSize? {
        guard let value = value, !value.isUndefined, !value.isNull else {
            return nil
        }
        let width = value.forProperty("width")?.toDouble() ?? 0
        let height = value.forProperty("height")?.toDouble() ?? 0
        return CGSize(width: width, height: height)
    }

    private func parseShadow(_ value: JSValue?) -> ShadowConfig? {
        guard let value = value, !value.isUndefined, !value.isNull else {
            return nil
        }
        let color = value.forProperty("color")?.toString() ?? "#000000"
        let offsetX = value.forProperty("offsetX")?.toDouble() ?? 1
        let offsetY = value.forProperty("offsetY")?.toDouble() ?? 1
        let blur = value.forProperty("blur")?.toDouble() ?? 2
        return ShadowConfig(color: color, offsetX: offsetX, offsetY: offsetY, blur: blur)
    }

    /// Safely extract an optional String from a JSValue, returning nil for undefined/null
    private func optionalString(_ value: JSValue?) -> String? {
        guard let value = value,
              !value.isUndefined,
              !value.isNull,
              value.isString else {
            return nil
        }
        return value.toString()
    }

    /// Expand variable placeholders like ${cpu.usage} with actual values
    /// Uses single-pass replacement to minimize string allocations
    func expandVariables(in text: String, metrics: DisplayMetrics) -> String {
        // Early exit if no variables present
        guard text.contains("${") else { return text }

        // Build variable lookup dictionary
        let variables = buildVariableDictionary(metrics: metrics)

        // Handle file variables separately (opt-in feature)
        if configData.enableFileReading {
            return expandAllVariables(in: text, variables: variables, expandFiles: true)
        }

        return expandAllVariables(in: text, variables: variables, expandFiles: false)
    }

    /// Evaluate a condition expression using current metrics values
    /// Returns true if condition passes or is nil/empty, false otherwise
    func evaluateCondition(_ condition: String?, metrics: DisplayMetrics) -> Bool {
        guard let condition = condition, !condition.isEmpty else { return true }

        // Build variable dictionary for JavaScript evaluation
        let variables = buildVariableDictionary(metrics: metrics)

        // Build JavaScript object with all variables as properties
        // Transform flat keys like "cpu.usage" into nested object cpu.usage
        var jsSetup = "var __vars = {};\n"

        for (key, value) in variables {
            let parts = key.split(separator: ".")
            if parts.count == 2 {
                let objName = String(parts[0])
                let propName = String(parts[1])
                jsSetup += "__vars.\(objName) = __vars.\(objName) || {};\n"
                // Try to parse as number, otherwise quote as string
                if let numValue = Double(value) {
                    jsSetup += "__vars.\(objName).\(propName) = \(numValue);\n"
                } else {
                    let escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
                                       .replacingOccurrences(of: "\"", with: "\\\"")
                                       .replacingOccurrences(of: "\n", with: "\\n")
                    jsSetup += "__vars.\(objName).\(propName) = \"\(escaped)\";\n"
                }
            } else {
                // Single-part key (like "time", "hostname")
                if let numValue = Double(value) {
                    jsSetup += "__vars.\(key) = \(numValue);\n"
                } else {
                    let escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
                                       .replacingOccurrences(of: "\"", with: "\\\"")
                                       .replacingOccurrences(of: "\n", with: "\\n")
                    jsSetup += "__vars.\(key) = \"\(escaped)\";\n"
                }
            }
        }

        // Destructure to top-level for easy access in conditions
        jsSetup += "var { cpu, memory, battery, disk, network, gpu, wifi, load, swap, top, processes, audio, bluetooth } = __vars;\n"

        let script = jsSetup + "Boolean(\(condition))"

        guard let result = context.evaluateScript(script), result.isBoolean else {
            // On error, default to rendering the widget
            return true
        }
        return result.toBool()
    }

    /// Build dictionary of all variable names to their values
    private func buildVariableDictionary(metrics: DisplayMetrics) -> [String: String] {
        var variables: [String: String] = [:]

        // CPU
        variables["cpu.usage"] = String(format: "%.1f", metrics.cpuUsage)
        variables["cpu.temp"] = metrics.cpuTemp > 0 ? String(format: "%.0f", metrics.cpuTemp) : "N/A"
        variables["cpu.cores"] = String(metrics.perCoreUsage.count)
        variables["cpu.freq"] = metrics.cpuFreqMHz > 0 ? String(metrics.cpuFreqMHz) : "N/A"
        variables["cpu.freq_ghz"] = metrics.cpuFreqMHz > 0 ? String(format: "%.2f", Double(metrics.cpuFreqMHz) / 1000.0) : "N/A"

        // Load averages
        variables["load.1"] = String(format: "%.2f", metrics.loadAverages.load1)
        variables["load.5"] = String(format: "%.2f", metrics.loadAverages.load5)
        variables["load.15"] = String(format: "%.2f", metrics.loadAverages.load15)

        // Per-core CPU
        for core in metrics.perCoreUsage {
            variables["cpu.core\(core.core)"] = String(format: "%.0f", core.usage)
        }

        // Memory
        variables["memory.used"] = String(format: "%.1f GB", metrics.memoryUsage.used)
        variables["memory.total"] = String(format: "%.1f GB", metrics.memoryUsage.total)
        variables["memory.percent"] = String(format: "%.0f", metrics.memoryUsage.percentage)

        // Swap
        variables["swap.used"] = String(format: "%.1f GB", metrics.memoryUsage.swapUsed)
        variables["swap.total"] = String(format: "%.1f GB", metrics.memoryUsage.swapTotal)
        variables["swap.percent"] = String(format: "%.0f", metrics.memoryUsage.swapPercentage)

        // GPU
        variables["gpu.name"] = metrics.gpuUsage.name
        variables["gpu.usage"] = String(format: "%.0f", metrics.gpuUsage.utilizationPercent)
        // GPU temperature not available on Apple Silicon (GPU shares die with CPU)
        variables["gpu.temp"] = ""

        // Disk
        variables["disk.used"] = String(format: "%.0f GB", metrics.diskUsage.usedGB)
        variables["disk.total"] = String(format: "%.0f GB", metrics.diskUsage.totalGB)
        variables["disk.free"] = String(format: "%.0f GB", metrics.diskUsage.freeGB)
        variables["disk.percent"] = String(format: "%.0f", metrics.diskUsage.percentage)
        variables["disk.read"] = formatBytes(metrics.diskUsage.readBytesPerSec)
        variables["disk.write"] = formatBytes(metrics.diskUsage.writeBytesPerSec)
        variables["disk.type"] = metrics.diskUsage.fsType

        // Network
        variables["network.local_ip"] = metrics.networkUsage.localIP
        variables["network.public_ip"] = metrics.networkUsage.publicIP
        variables["network.down"] = formatBytes(metrics.networkUsage.bytesInPerSec)
        variables["network.up"] = formatBytes(metrics.networkUsage.bytesOutPerSec)
        variables["network.total_down"] = formatBytes(Double(metrics.networkUsage.bytesIn))
        variables["network.total_up"] = formatBytes(Double(metrics.networkUsage.bytesOut))

        // WiFi
        variables["wifi.ssid"] = metrics.wifiInfo.ssid
        variables["wifi.signal"] = String(metrics.wifiInfo.signalStrength)
        variables["wifi.bssid"] = metrics.wifiInfo.bssid

        // Date/Time
        variables["time"] = metrics.dateTime.time
        variables["date"] = metrics.dateTime.date
        variables["datetime"] = metrics.dateTime.formatted
        variables["weekday"] = metrics.dateTime.weekday

        // System (hostname and uptime are dynamic, cached info is static)
        variables["hostname"] = ProcessInfo.processInfo.hostName
        variables["uptime"] = formatUptime(ProcessInfo.processInfo.systemUptime)
        variables["os"] = cachedSystemInfo.osVersion
        variables["kernel"] = cachedSystemInfo.kernel
        variables["machine"] = cachedSystemInfo.machine
        variables["sysname"] = cachedSystemInfo.sysname

        // Top CPU processes
        for (index, proc) in metrics.topCPUProcesses.enumerated() {
            let num = index + 1
            variables["top.cpu\(num).name"] = proc.name
            variables["top.cpu\(num).percent"] = String(format: "%.1f", proc.cpuPercent)
            variables["top.cpu\(num).pid"] = String(proc.pid)
        }

        // Top Memory processes
        for (index, proc) in metrics.topMemoryProcesses.enumerated() {
            let num = index + 1
            variables["top.mem\(num).name"] = proc.name
            variables["top.mem\(num).mb"] = String(format: "%.0f", proc.memoryMB)
            variables["top.mem\(num).pid"] = String(proc.pid)
        }

        // Process counts
        variables["processes.total"] = String(metrics.processTotal)
        variables["processes.running"] = String(metrics.processRunning)

        // Battery
        variables["battery.percent"] = String(metrics.batteryInfo.percent)
        variables["battery.status"] = metrics.batteryInfo.status
        variables["battery.time"] = metrics.batteryInfo.timeRemaining
        variables["battery.power"] = String(format: "%.1f W", abs(metrics.batteryInfo.powerDraw))
        variables["battery.cycles"] = String(metrics.batteryInfo.cycleCount)
        variables["battery.health"] = String(metrics.batteryInfo.health)

        // Audio
        variables["audio.device"] = metrics.audioInfo.deviceName
        variables["audio.volume"] = String(metrics.audioInfo.volume)
        variables["audio.muted"] = metrics.audioInfo.isMuted ? "true" : "false"

        // Bluetooth
        variables["bluetooth.connected"] = String(metrics.bluetoothInfo.connectedCount)
        variables["bluetooth.powered"] = metrics.bluetoothInfo.isPoweredOn ? "On" : "Off"

        // Individual Bluetooth devices (up to 5)
        for (index, device) in metrics.bluetoothInfo.devices.prefix(5).enumerated() {
            let num = index + 1
            variables["bluetooth.device\(num).name"] = device.name
            variables["bluetooth.device\(num).address"] = device.address
        }

        return variables
    }

    /// Single-pass variable expansion using regex
    private func expandAllVariables(in text: String, variables: [String: String], expandFiles: Bool) -> String {
        guard let regex = Self.variableRegex else { return text }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: fullRange)

        guard !matches.isEmpty else { return text }

        // Build result by replacing matches
        var result = ""
        var lastEnd = 0

        for match in matches {
            // Append text before this match
            let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
            result += nsText.substring(with: beforeRange)

            // Get the variable name (capture group 1)
            let varNameRange = match.range(at: 1)
            let varName = nsText.substring(with: varNameRange)

            // Handle exec variables (opt-in feature)
            if configData.enableShellCommands && varName.hasPrefix("exec ") {
                let replacement = expandExecVariable(varName)
                result += replacement
            } else if expandFiles && varName.hasPrefix("file ") {
                // Handle file variables specially
                let replacement = expandFileVariable(varName)
                result += replacement
            } else if let value = variables[varName] {
                result += value
            } else {
                // Unknown variable - keep original
                result += nsText.substring(with: match.range)
            }

            lastEnd = match.range.location + match.range.length
        }

        // Append remaining text after last match
        if lastEnd < nsText.length {
            result += nsText.substring(from: lastEnd)
        }

        return result
    }

    /// Expand a single file variable like 'file path="/path/to/file"'
    private func expandFileVariable(_ varContent: String) -> String {
        // Parse path from 'file path="..."' format
        guard let regex = Self.fileVariableRegex else { return "[error]" }

        let fullVar = "${\(varContent)}"
        let range = NSRange(location: 0, length: fullVar.utf16.count)
        guard let match = regex.firstMatch(in: fullVar, range: range),
              let pathRange = Range(match.range(at: 1), in: fullVar) else {
            return "[error]"
        }

        let filePath = String(fullVar[pathRange])
        let expandedPath = (filePath as NSString).expandingTildeInPath

        // Security: only allow reading from home directory or /tmp
        let homeDir = NSHomeDirectory()
        guard expandedPath.hasPrefix(homeDir) || expandedPath.hasPrefix("/tmp/") else {
            return "[access denied]"
        }

        // Read file with size limit (1KB)
        guard let data = FileManager.default.contents(atPath: expandedPath),
              data.count <= 1024,
              let content = String(data: data, encoding: .utf8) else {
            return "[error]"
        }

        // Return first line only, trimmed
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        return firstLine.trimmingCharacters(in: .whitespaces)
    }

    /// Expand a shell exec variable like 'exec command="..."'
    private func expandExecVariable(_ varContent: String) -> String {
        guard let regex = Self.execVariableRegex else { return "[error]" }

        let fullVar = "${\(varContent)}"
        let range = NSRange(location: 0, length: fullVar.utf16.count)
        guard let match = regex.firstMatch(in: fullVar, range: range),
              let commandRange = Range(match.range(at: 1), in: fullVar) else {
            return "[error]"
        }

        let command = String(fullVar[commandRange])
        return executeShellCommand(command)
    }

    /// Execute a shell command with security constraints
    /// - 5 second timeout
    /// - 1KB output limit
    /// - First line only
    private func executeShellCommand(_ command: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Set up timeout
        let timeoutSeconds: Double = 5.0
        var timedOut = false

        let timeoutWorkItem = DispatchWorkItem {
            timedOut = true
            process.terminate()
        }

        DispatchQueue.global().asyncAfter(
            deadline: .now() + timeoutSeconds,
            execute: timeoutWorkItem
        )

        do {
            try process.run()
            process.waitUntilExit()
            timeoutWorkItem.cancel()

            if timedOut {
                return "[timeout]"
            }

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()

            // Enforce 1KB limit
            let limitedData = data.prefix(1024)

            guard let output = String(data: limitedData, encoding: .utf8) else {
                return "[error]"
            }

            // Return first line only, trimmed
            let firstLine = output.components(separatedBy: .newlines).first ?? ""
            return firstLine.trimmingCharacters(in: .whitespaces)

        } catch {
            timeoutWorkItem.cancel()
            return "[error]"
        }
    }

    func formatBytes(_ bytes: Double) -> String {
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

    func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func getOSVersion() -> String {
        let plistPath = "/System/Library/CoreServices/SystemVersion.plist"
        var osName = "macOS"
        var versionString = ""

        if let plistData = FileManager.default.contents(atPath: plistPath),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            if let productName = plist["ProductName"] as? String {
                osName = productName
            }
            if let productVersion = plist["ProductUserVisibleVersion"] as? String {
                versionString = productVersion
            }
        }

        return "\(osName) \(versionString)"
    }
}
