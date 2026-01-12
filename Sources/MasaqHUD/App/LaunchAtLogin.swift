import Foundation

public struct LaunchAtLogin {
    private static let plistName = "com.masaqhud.app.plist"

    private static var launchAgentsDir: String {
        NSHomeDirectory() + "/Library/LaunchAgents"
    }

    private static var plistPath: String {
        launchAgentsDir + "/" + plistName
    }

    public static func enable() throws {
        // Ensure LaunchAgents directory exists
        try FileManager.default.createDirectory(
            atPath: launchAgentsDir,
            withIntermediateDirectories: true
        )

        // Determine the executable path
        // In development, use the build location; in production, use installed path
        let executablePath: String
        if let bundlePath = Bundle.main.executablePath {
            executablePath = bundlePath
        } else {
            // Fallback to standard install location
            executablePath = "/usr/local/bin/masaqhud"
        }

        let plist: [String: Any] = [
            "Label": "com.masaqhud.app",
            "ProgramArguments": [executablePath, "start"],
            "RunAtLoad": true,
            "KeepAlive": false,
            "StandardOutPath": NSHomeDirectory() + "/Library/Logs/masaqhud.log",
            "StandardErrorPath": NSHomeDirectory() + "/Library/Logs/masaqhud.log"
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )

        try data.write(to: URL(fileURLWithPath: plistPath))
        print("Launch at login enabled")
        print("Plist created at: \(plistPath)")
        print("Executable: \(executablePath)")
    }

    public static func disable() throws {
        if FileManager.default.fileExists(atPath: plistPath) {
            try FileManager.default.removeItem(atPath: plistPath)
            print("Launch at login disabled")
        } else {
            print("Launch at login was not enabled")
        }
    }

    static func isEnabled() -> Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    public static func status() {
        if isEnabled() {
            print("Launch at login: enabled")
            print("Plist path: \(plistPath)")
        } else {
            print("Launch at login: disabled")
        }
    }
}
