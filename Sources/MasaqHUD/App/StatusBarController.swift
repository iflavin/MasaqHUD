import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use SF Symbol for menu bar icon
            button.image = NSImage(systemSymbolName: "gauge.medium", accessibilityDescription: "MasaqHUD")
        }

        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Config...", action: #selector(openConfig), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Open Config Folder", action: #selector(openConfigFolder), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MasaqHUD", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        return menu
    }

    @objc private func reloadConfig() {
        appDelegate?.reloadConfig()
    }

    @objc private func openConfig() {
        let configPath = NSHomeDirectory() + "/.config/masaqhud/masaqhud.js"
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc private func openConfigFolder() {
        let configDir = NSHomeDirectory() + "/.config/masaqhud"
        NSWorkspace.shared.open(URL(fileURLWithPath: configDir))
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
