// Minimal MasaqHUD Configuration
// A single-line status bar in the corner of your screen

masaqhud.config({
    position: { x: 20, y: 30 },
    font: "SF Mono",
    fontSize: 11,
    color: "#FFFFFF",
    anchor: "topLeft"
});

masaqhud.widget({
    type: "text",
    text: "CPU: ${cpu.usage}% | RAM: ${memory.percent}% | ${time}",
    position: { x: 0, y: 0 }
});
