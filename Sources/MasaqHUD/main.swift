import Foundation
import AppKit
import MasaqHUDCore

enum Command: String {
    case start
    case stop
    case reload
    case `init`
    case enable
    case disable
    case status
    case help
    case version
}

struct CLI {
    static let version = "0.5.0"
    static let configDir = NSHomeDirectory() + "/.config/masaqhud"
    static let configPath = configDir + "/masaqhud.js"
    static let pidFile = configDir + "/masaqhud.pid"

    static func run() {
        let args = CommandLine.arguments.dropFirst()

        guard let firstArg = args.first else {
            startApplication()
            return
        }

        if firstArg == "--help" || firstArg == "-h" {
            printHelp()
            return
        }

        if firstArg == "--version" || firstArg == "-v" {
            printVersion()
            return
        }

        guard let command = Command(rawValue: firstArg) else {
            printError("Unknown command: \(firstArg)")
            printHelp()
            exit(1)
        }

        switch command {
        case .start:
            startApplication()
        case .stop:
            stopApplication()
        case .reload:
            reloadConfiguration()
        case .`init`:
            initializeConfig()
        case .enable:
            enableLaunchAtLogin()
        case .disable:
            disableLaunchAtLogin()
        case .status:
            showStatus()
        case .help:
            printHelp()
        case .version:
            printVersion()
        }
    }

    private static func printHelp() {
        print("""
        MasaqHUD - A lightweight, scriptable desktop HUD for macOS

        Usage: masaqhud [command]

        Commands:
            start       Start the HUD overlay (default)
            stop        Stop the running HUD
            reload      Reload the configuration
            init        Create default configuration
            enable      Enable launch at login
            disable     Disable launch at login
            status      Show running status and settings
            help        Show this help message
            version     Show version information

        Options:
            -h, --help      Show this help message
            -v, --version   Show version information

        Configuration:
            \(configPath)
        """)
    }

    private static func printVersion() {
        print("MasaqHUD \(version)")
    }

    private static func printError(_ message: String) {
        FileHandle.standardError.write("Error: \(message)\n".data(using: .utf8)!)
    }

    private static func startApplication() {
        // Check if already running
        if let existingPID = readPID(), isProcessRunning(pid: existingPID) {
            printError("MasaqHUD is already running (PID: \(existingPID))")
            exit(1)
        }

        // Write PID file
        writePID()

        // Start the application
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    private static func stopApplication() {
        guard let pid = readPID() else {
            printError("MasaqHUD is not running (no PID file found)")
            exit(1)
        }

        guard isProcessRunning(pid: pid) else {
            printError("MasaqHUD is not running (stale PID file)")
            removePIDFile()
            exit(1)
        }

        // Send SIGTERM
        kill(pid, SIGTERM)
        print("Stopping MasaqHUD (PID: \(pid))")

        // Wait briefly for graceful shutdown
        usleep(500_000)

        // Check if still running and force kill if necessary
        if isProcessRunning(pid: pid) {
            kill(pid, SIGKILL)
            usleep(100_000)
        }

        removePIDFile()
    }

    private static func reloadConfiguration() {
        guard let pid = readPID() else {
            printError("MasaqHUD is not running (no PID file found)")
            exit(1)
        }

        guard isProcessRunning(pid: pid) else {
            printError("MasaqHUD is not running (stale PID file)")
            removePIDFile()
            exit(1)
        }

        // Send SIGHUP to trigger reload
        kill(pid, SIGHUP)
        print("Configuration reload signal sent to MasaqHUD (PID: \(pid))")
    }

    private static func initializeConfig() {
        // Create config directory
        do {
            try FileManager.default.createDirectory(
                atPath: configDir,
                withIntermediateDirectories: true
            )
        } catch {
            printError("Failed to create config directory: \(error.localizedDescription)")
            exit(1)
        }

        // Check if config already exists
        if FileManager.default.fileExists(atPath: configPath) {
            print("Configuration already exists at \(configPath)")
            print("Remove it first if you want to regenerate the default config.")
            return
        }

        // Write default config
        do {
            try DefaultConfig.content.write(
                toFile: configPath,
                atomically: true,
                encoding: .utf8
            )
            print("Created default configuration at \(configPath)")
        } catch {
            printError("Failed to write config: \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func enableLaunchAtLogin() {
        do {
            try LaunchAtLogin.enable()
        } catch {
            printError("Failed to enable launch at login: \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func disableLaunchAtLogin() {
        do {
            try LaunchAtLogin.disable()
        } catch {
            printError("Failed to disable launch at login: \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func showStatus() {
        print("MasaqHUD \(version)")
        print("")

        // Running status
        if let pid = readPID(), isProcessRunning(pid: pid) {
            print("Status: running (PID: \(pid))")
        } else {
            print("Status: not running")
        }

        // Launch at login status
        LaunchAtLogin.status()

        // Config status
        if FileManager.default.fileExists(atPath: configPath) {
            print("Configuration: \(configPath)")
        } else {
            print("Configuration: not found (run 'masaqhud init' to create)")
        }
    }

    // MARK: - PID File Management

    private static func readPID() -> pid_t? {
        guard let content = try? String(contentsOfFile: pidFile, encoding: .utf8),
              let pid = pid_t(content.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return pid
    }

    private static func writePID() {
        let pid = getpid()
        try? String(pid).write(toFile: pidFile, atomically: true, encoding: .utf8)
    }

    private static func removePIDFile() {
        try? FileManager.default.removeItem(atPath: pidFile)
    }

    private static func isProcessRunning(pid: pid_t) -> Bool {
        return kill(pid, 0) == 0
    }
}

// Entry point
CLI.run()
