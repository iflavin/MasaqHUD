import AppKit

enum Application {
    static func start() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
