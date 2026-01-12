// Developer Status Bar
// Git info, system resources, and dev-focused metrics
// NOTE: Requires enableShellCommands: true for git integration

masaqhud.config({
    position: { x: 15, y: 15 },
    font: "SF Mono",
    fontSize: 10,
    color: "#E0E0E0",
    anchor: "bottomLeft",
    updateInterval: 2.0,
    enableShellCommands: true  // Required for git commands
});

// Git Status Line (update path to your project)
masaqhud.widget({
    type: "text",
    text: "git: ${exec command=\"git -C ~/Projects/myproject rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A'\"}",
    position: { x: 0, y: 0 },
    color: "#88FF88"
});

masaqhud.widget({
    type: "text",
    text: "@ ${exec command=\"git -C ~/Projects/myproject rev-parse --short HEAD 2>/dev/null || echo '-------'\"}",
    position: { x: 120, y: 0 },
    color: "#888888"
});

// Resource Bar
masaqhud.widget({
    type: "text",
    text: "CPU ${cpu.usage}%",
    position: { x: 0, y: 18 },
    color: "#99CCFF"
});

masaqhud.widget({
    type: "bar",
    source: "cpu.usage",
    position: { x: 60, y: 20 },
    width: 50,
    height: 6,
    color: "#99CCFF",
    backgroundColor: "rgba(255,255,255,0.1)"
});

masaqhud.widget({
    type: "text",
    text: "RAM ${memory.percent}%",
    position: { x: 120, y: 18 },
    color: "#FFCC66"
});

masaqhud.widget({
    type: "bar",
    source: "memory.percent",
    position: { x: 185, y: 20 },
    width: 50,
    height: 6,
    color: "#FFCC66",
    backgroundColor: "rgba(255,255,255,0.1)"
});

// Process Info
masaqhud.widget({
    type: "text",
    text: "Procs: ${processes.total} (${processes.running} running)",
    position: { x: 0, y: 36 },
    color: "#AAAAAA",
    fontSize: 9
});

// Top CPU Consumer
masaqhud.widget({
    type: "text",
    text: "Top: ${top.cpu1.name} (${top.cpu1.percent}%)",
    position: { x: 0, y: 48 },
    color: "#FF9999",
    fontSize: 9,
    condition: "cpu.usage > 30"
});

// Time
masaqhud.widget({
    type: "text",
    text: "${time}",
    position: { x: 200, y: 36 },
    color: "#666666",
    fontSize: 9
});

// Battery Warning (laptop users)
masaqhud.widget({
    type: "text",
    text: "LOW BATTERY: ${battery.percent}%",
    position: { x: 0, y: 65 },
    color: "#FF4444",
    bold: true,
    condition: "battery.percent < 20 && battery.status !== 'Charging'"
});
