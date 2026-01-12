// Full System Dashboard
// Comprehensive system monitoring overlay

masaqhud.config({
    position: { x: 50, y: 80 },
    font: "SF Mono",
    fontSize: 11,
    color: "#FFFFFF",
    anchor: "topLeft",
    updateInterval: 1.0
});

// Header
masaqhud.widget({
    type: "text",
    text: "${datetime}",
    position: { x: 0, y: 0 },
    color: "#888888",
    fontSize: 10
});

masaqhud.widget({
    type: "hr",
    position: { x: 0, y: 18 },
    width: 220,
    color: "#444444"
});

// CPU Section
masaqhud.widget({
    type: "text",
    text: "CPU",
    position: { x: 0, y: 35 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "Usage: ${cpu.usage}%",
    position: { x: 0, y: 53 }
});

masaqhud.widget({
    type: "text",
    text: "Temp: ${cpu.temp}C",
    position: { x: 0, y: 69 }
});

masaqhud.widget({
    type: "text",
    text: "Load: ${load.1} ${load.5} ${load.15}",
    position: { x: 0, y: 85 },
    color: "#AAAAAA",
    fontSize: 10
});

masaqhud.widget({
    type: "graph",
    source: "cpu.usage",
    position: { x: 0, y: 100 },
    size: { width: 220, height: 35 },
    color: "#99CCFF"
});

// Memory Section
masaqhud.widget({
    type: "text",
    text: "MEMORY",
    position: { x: 0, y: 150 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "${memory.used} / ${memory.total}",
    position: { x: 0, y: 168 }
});

masaqhud.widget({
    type: "bar",
    source: "memory.percent",
    position: { x: 0, y: 186 },
    width: 220,
    height: 8,
    color: "#99CCFF",
    backgroundColor: "rgba(255,255,255,0.1)"
});

masaqhud.widget({
    type: "text",
    text: "Swap: ${swap.used} / ${swap.total}",
    position: { x: 0, y: 200 },
    fontSize: 10,
    color: "#AAAAAA"
});

// GPU Section
masaqhud.widget({
    type: "text",
    text: "GPU",
    position: { x: 0, y: 225 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "${gpu.name}",
    position: { x: 0, y: 243 },
    fontSize: 10,
    color: "#AAAAAA"
});

masaqhud.widget({
    type: "text",
    text: "Usage: ${gpu.usage}%",
    position: { x: 0, y: 257 }
});

// Disk Section
masaqhud.widget({
    type: "text",
    text: "DISK",
    position: { x: 0, y: 285 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "${disk.used} / ${disk.total} (${disk.percent}%)",
    position: { x: 0, y: 303 }
});

masaqhud.widget({
    type: "text",
    text: "R: ${disk.read}/s  W: ${disk.write}/s",
    position: { x: 0, y: 319 },
    fontSize: 10,
    color: "#AAAAAA"
});

// Network Section
masaqhud.widget({
    type: "text",
    text: "NETWORK",
    position: { x: 0, y: 345 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "IP: ${network.local_ip}",
    position: { x: 0, y: 363 }
});

masaqhud.widget({
    type: "text",
    text: "Down: ${network.down}/s  Up: ${network.up}/s",
    position: { x: 0, y: 379 }
});

masaqhud.widget({
    type: "text",
    text: "WiFi: ${wifi.ssid} (${wifi.signal}%)",
    position: { x: 0, y: 395 },
    fontSize: 10,
    color: "#AAAAAA"
});

// Battery Section (only shows when present)
masaqhud.widget({
    type: "text",
    text: "BATTERY",
    position: { x: 0, y: 420 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF",
    condition: "battery.percent > 0"
});

masaqhud.widget({
    type: "text",
    text: "${battery.percent}% - ${battery.status}",
    position: { x: 0, y: 438 },
    condition: "battery.percent > 0"
});

masaqhud.widget({
    type: "text",
    text: "${battery.time} remaining",
    position: { x: 0, y: 454 },
    fontSize: 10,
    color: "#AAAAAA",
    condition: "battery.status === 'Discharging'"
});

// System Info
masaqhud.widget({
    type: "hr",
    position: { x: 0, y: 475 },
    width: 220,
    color: "#444444"
});

masaqhud.widget({
    type: "text",
    text: "${hostname} | ${os}",
    position: { x: 0, y: 485 },
    fontSize: 9,
    color: "#666666"
});

masaqhud.widget({
    type: "text",
    text: "Uptime: ${uptime}",
    position: { x: 0, y: 497 },
    fontSize: 9,
    color: "#666666"
});
