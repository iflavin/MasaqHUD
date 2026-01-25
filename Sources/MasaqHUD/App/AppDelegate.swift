import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: OverlayWindow?
    private var metricsProvider: MetricsProvider?
    private var configEngine: ConfigEngine?
    private var updateTimer: Timer?
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var configReloadWorkItem: DispatchWorkItem?
    private var config: HUDConfig?
    private var signalSources: [DispatchSourceSignal] = []
    private var statusBarController: StatusBarController?

    private let configDir = NSHomeDirectory() + "/.config/masaqhud"
    private let configPath = NSHomeDirectory() + "/.config/masaqhud/masaqhud.js"

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a background utility
        NSApp.setActivationPolicy(.accessory)

        // Set up signal handlers for reload
        setupSignalHandlers()

        // Initialize metrics
        metricsProvider = MetricsProvider()

        // Initialize configuration engine
        configEngine = ConfigEngine()

        // Create overlay window
        overlayWindow = OverlayWindow()
        overlayWindow?.makeKeyAndOrderFront(nil)

        // Load config (or use defaults)
        loadConfig()

        // Start file watcher for hot reload
        startFileWatcher()

        // Start update loop
        startUpdateLoop()

        // Initialize menu bar status icon
        statusBarController = StatusBarController(appDelegate: self)

        // Listen for display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func displayConfigurationChanged() {
        // Reposition window based on current config
        guard let cfg = config else { return }
        overlayWindow?.positionOnDisplay(
            index: cfg.displayIndex,
            anchor: cfg.anchor,
            offset: cfg.position
        )
    }

    public func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
        fileWatcher?.cancel()
        signalSources.forEach { $0.cancel() }

        // Remove notification observer to prevent leak
        NotificationCenter.default.removeObserver(self)

        // Clean up PID file
        try? FileManager.default.removeItem(atPath: NSHomeDirectory() + "/.config/masaqhud/masaqhud.pid")
    }

    private func setupSignalHandlers() {
        // Handle SIGHUP for config reload
        signal(SIGHUP, SIG_IGN)
        let hupSource = DispatchSource.makeSignalSource(signal: SIGHUP, queue: .main)
        hupSource.setEventHandler { [weak self] in
            print("Received SIGHUP, reloading configuration...")
            self?.loadConfig()
        }
        hupSource.resume()
        signalSources.append(hupSource)

        // Handle SIGTERM for graceful shutdown
        signal(SIGTERM, SIG_IGN)
        let termSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        termSource.setEventHandler { [weak self] in
            _ = self  // Prevent unused capture warning
            print("Received SIGTERM, shutting down...")
            NSApp.terminate(nil)
        }
        termSource.resume()
        signalSources.append(termSource)
    }

    /// Public method for reloading configuration (called by StatusBarController)
    func reloadConfig() {
        loadConfig()
    }

    private func loadConfig() {
        // Ensure config directory exists
        try? FileManager.default.createDirectory(
            atPath: configDir,
            withIntermediateDirectories: true
        )

        // Create default config if it doesn't exist
        if !FileManager.default.fileExists(atPath: configPath) {
            createDefaultConfig()
        }

        // Load config from JavaScript
        if let engine = configEngine, let loadedConfig = engine.loadConfig(from: configPath) {
            // Validate the configuration
            let validator = ConfigValidator()
            let validationErrors = validator.validate(loadedConfig)

            // Check for fatal errors
            let fatalErrors = validationErrors.filter { $0.severity == .error }
            if !fatalErrors.isEmpty {
                print("Configuration errors:")
                for error in fatalErrors {
                    print("  [\(error.path)] \(error.message)")
                }
                if config != nil {
                    print("Using previous configuration")
                    return
                }
                // If no previous config, continue with the invalid one (best effort)
            }

            // Log warnings
            let warnings = validationErrors.filter { $0.severity == .warning }
            for warning in warnings {
                print("Warning [\(warning.path)]: \(warning.message)")
            }

            config = loadedConfig
            overlayWindow?.overlayView.setConfig(loadedConfig, configEngine: engine)
            print("Config loaded: \(loadedConfig.widgets.count) widgets")

            // Position window on configured display
            overlayWindow?.positionOnDisplay(
                index: loadedConfig.displayIndex,
                anchor: loadedConfig.anchor,
                offset: loadedConfig.position
            )

            // Update metrics provider with network settings
            metricsProvider?.networkMetrics.enablePublicIP = loadedConfig.enablePublicIP
            metricsProvider?.networkMetrics.filterInterface = loadedConfig.networkInterface

            // Update date/time formats
            metricsProvider?.dateTimeMetrics.setFormats(
                date: loadedConfig.dateFormat,
                time: loadedConfig.timeFormat,
                datetime: loadedConfig.datetimeFormat
            )

            // Update timer interval if changed
            updateTimer?.invalidate()
            startUpdateLoop()
        } else {
            print("Failed to load config, using hardcoded fallback")
            config = nil
        }
    }

    private func createDefaultConfig() {
        try? DefaultConfig.content.write(
            toFile: configPath,
            atomically: true,
            encoding: .utf8
        )
        print("Created default config at \(configPath)")
    }

    private func startFileWatcher() {
        let fd = open(configPath, O_EVTONLY)
        guard fd >= 0 else {
            print("Could not open config file for watching")
            return
        }

        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        fileWatcher?.setEventHandler { [weak self] in
            guard let self = self else { return }
            // Debounce config reloads - wait 0.5s after last change
            self.configReloadWorkItem?.cancel()
            self.configReloadWorkItem = nil  // Explicitly release cancelled work item

            let workItem = DispatchWorkItem { [weak self] in
                self?.configReloadWorkItem = nil  // Clear after execution
                print("Config file changed, reloading...")
                self?.loadConfig()
            }
            self.configReloadWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }

        fileWatcher?.setCancelHandler {
            close(fd)
        }

        fileWatcher?.resume()
    }

    private func startUpdateLoop() {
        guard let metrics = metricsProvider else { return }

        // Do a few warm-up updates to initialize metrics (without displaying)
        // This ensures we have previous values for delta calculations
        for _ in 0..<3 {
            _ = metrics.cpuMetrics.getUsage()
            _ = metrics.cpuMetrics.getPerCoreUsage()
            _ = metrics.processMetrics.getTopProcesses()
            Thread.sleep(forTimeInterval: 0.1)
        }

        // Initial update
        updateDisplay()

        // Schedule periodic updates
        let interval = config?.updateInterval ?? 1.0
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }

    private func updateDisplay() {
        guard let metrics = metricsProvider, let window = overlayWindow else { return }

        let temps = metrics.smcReader.getTemperatures()
        let topProcesses = metrics.processMetrics.getTopProcesses(byCPU: 5, byMemory: 5)

        let processCounts = metrics.processMetrics.getProcessCounts()

        var displayMetrics = DisplayMetrics()
        displayMetrics.cpuUsage = metrics.cpuMetrics.getUsage()
        displayMetrics.cpuTemp = temps.cpuTemp
        displayMetrics.cpuFreqMHz = metrics.cpuMetrics.getFrequencyMHz()
        displayMetrics.loadAverages = metrics.cpuMetrics.getLoadAverages()
        displayMetrics.perCoreUsage = metrics.cpuMetrics.getPerCoreUsage()
        displayMetrics.memoryUsage = metrics.memoryMetrics.getUsage()
        displayMetrics.networkUsage = metrics.networkMetrics.getUsage()
        displayMetrics.wifiInfo = metrics.networkMetrics.getWiFiInfo()
        displayMetrics.diskUsage = metrics.diskMetrics.getUsage()
        displayMetrics.dateTime = metrics.dateTimeMetrics.getInfo()
        displayMetrics.gpuUsage = metrics.gpuMetrics.getUsage()
        displayMetrics.topCPUProcesses = topProcesses.cpu
        displayMetrics.topMemoryProcesses = topProcesses.memory
        displayMetrics.processTotal = processCounts.total
        displayMetrics.processRunning = processCounts.running
        displayMetrics.batteryInfo = metrics.batteryMetrics.getInfo()
        displayMetrics.audioInfo = metrics.audioMetrics.getInfo()
        displayMetrics.bluetoothInfo = metrics.bluetoothMetrics.getInfo()

        window.overlayView.update(metrics: displayMetrics)
    }
}
