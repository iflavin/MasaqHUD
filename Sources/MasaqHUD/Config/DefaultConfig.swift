import Foundation

public enum DefaultConfig {
    public static let content = """
// MasaqHUD Configuration
// ~/.config/masaqhud/masaqhud.js
//
// This file is executed as JavaScript. Use masaqhud.config() to set global
// options and masaqhud.widget() to add display widgets.
//
// Changes to this file are automatically detected and applied (hot reload).

masaqhud.config({
    position: { x: 50, y: 80 },
    font: "SF Mono",
    fontSize: 11,
    color: "#FFFFFF",
    updateInterval: 1.0,

    // Network access is disabled by default for privacy.
    // Set to true to enable public IP lookup (requires internet).
    enablePublicIP: false,

    // File reading allows ${file path="..."} to read file contents.
    // Restricted to home directory and /tmp.
    enableFileReading: false,

    // WARNING: enableShellCommands allows ARBITRARY COMMAND EXECUTION.
    // When enabled, ${exec command="..."} runs shell commands as your user.
    // Only enable if you understand the security implications.
    enableShellCommands: false
});

// Date/Time
masaqhud.widget({
    type: "text",
    text: "${datetime}",
    position: { x: 0, y: 0 },
    color: "#B0B0B0"
});

// CPU Section
masaqhud.widget({
    type: "text",
    text: "CPU",
    position: { x: 0, y: 30 },
    fontSize: 13,
    color: "#99CCFF",
    bold: true
});

masaqhud.widget({
    type: "text",
    text: "Usage: ${cpu.usage}%",
    position: { x: 0, y: 48 }
});

masaqhud.widget({
    type: "text",
    text: "Temp: ${cpu.temp} C",
    position: { x: 0, y: 66 }
});

masaqhud.widget({
    type: "graph",
    source: "cpu.usage",
    position: { x: 0, y: 84 },
    size: { width: 200, height: 40 },
    color: "#99CCFF"
});

// Memory Section
masaqhud.widget({
    type: "text",
    text: "MEMORY",
    position: { x: 0, y: 140 },
    fontSize: 13,
    color: "#99CCFF",
    bold: true
});

masaqhud.widget({
    type: "text",
    text: "${memory.used} / ${memory.total} (${memory.percent}%)",
    position: { x: 0, y: 158 }
});

// GPU Section
masaqhud.widget({
    type: "text",
    text: "GPU",
    position: { x: 0, y: 188 },
    fontSize: 13,
    color: "#99CCFF",
    bold: true
});

masaqhud.widget({
    type: "text",
    text: "${gpu.name}",
    position: { x: 0, y: 206 }
});

masaqhud.widget({
    type: "text",
    text: "Usage: ${gpu.usage}%",
    position: { x: 0, y: 224 }
});

// Disk Section
masaqhud.widget({
    type: "text",
    text: "DISK",
    position: { x: 0, y: 254 },
    fontSize: 13,
    color: "#99CCFF",
    bold: true
});

masaqhud.widget({
    type: "text",
    text: "${disk.used} / ${disk.total} (${disk.percent}%)",
    position: { x: 0, y: 272 }
});

masaqhud.widget({
    type: "text",
    text: "Free: ${disk.free}",
    position: { x: 0, y: 290 }
});

// Network Section
masaqhud.widget({
    type: "text",
    text: "NETWORK",
    position: { x: 0, y: 320 },
    fontSize: 13,
    color: "#99CCFF",
    bold: true
});

masaqhud.widget({
    type: "text",
    text: "Local: ${network.local_ip}",
    position: { x: 0, y: 338 }
});

// Public IP is disabled by default. Enable it in the config above
// by setting enablePublicIP: true, then uncomment this widget:
// masaqhud.widget({
//     type: "text",
//     text: "Public: ${network.public_ip}",
//     position: { x: 0, y: 356 }
// });

masaqhud.widget({
    type: "text",
    text: "Down: ${network.down}/s  Up: ${network.up}/s",
    position: { x: 0, y: 356 }
});
"""
}
