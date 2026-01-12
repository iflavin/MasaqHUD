# MasaqHUD User Guide

A comprehensive reference for creating custom overlay configurations.

---

## Table of Contents

1. [Overview](#overview)
2. [Installation and CLI](#installation-and-cli)
3. [Configuration Basics](#configuration-basics)
4. [Global Configuration Options](#global-configuration-options)
5. [Widget Types](#widget-types)
6. [Template Variables](#template-variables)
7. [Advanced Features](#advanced-features)
8. [Date/Time Formatting](#datetime-formatting)
9. [Examples](#examples)
10. [Tips for LLMs](#tips-for-llms)

---

## Overview

MasaqHUD is a native macOS desktop overlay that displays system metrics as a transparent window. Configuration is done via JavaScript files that are hot-reloaded when saved.

**Key characteristics:**
- macOS 13.0+ (Ventura) on Apple Silicon
- Zero external dependencies
- Hot-reloading configuration
- Fully scriptable via JavaScript

---

## Installation and CLI

### CLI Commands

```bash
masaqhud start      # Start the HUD overlay (default)
masaqhud stop       # Stop the running HUD
masaqhud reload     # Reload the configuration
masaqhud init       # Create default configuration
masaqhud enable     # Enable launch at login
masaqhud disable    # Disable launch at login
masaqhud status     # Show running status and settings
masaqhud help       # Show help message
masaqhud version    # Show version information
```

### Configuration Location

```
~/.config/masaqhud/masaqhud.js
```

---

## Configuration Basics

The configuration file is JavaScript. Use two main functions:

```javascript
// Set global options
masaqhud.config({
    // options...
});

// Add widgets
masaqhud.widget({
    type: "text",
    // widget properties...
});
```

Changes are automatically detected and applied (hot reload).

---

## Global Configuration Options

Set via `masaqhud.config({...})`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `position` | `{x, y}` | `{x: 50, y: 100}` | Base position for widgets |
| `font` | String | `"SF Mono"` | Default font family |
| `fontSize` | Number | `12` | Default font size in points |
| `color` | String | `"#FFFFFF"` | Default text color |
| `updateInterval` | Number | `1.0` | Refresh rate in seconds |
| `display` | Number | `0` | Display index (0 = main) |
| `anchor` | String | `"topLeft"` | Position anchor point |
| `dateFormat` | String | null | Custom date format (strftime) |
| `timeFormat` | String | null | Custom time format (strftime) |
| `datetimeFormat` | String | null | Custom datetime format (strftime) |
| `networkInterface` | String | null | Specific interface (e.g., `"en0"`) |
| `enablePublicIP` | Boolean | `false` | Enable public IP lookup |
| `enableFileReading` | Boolean | `false` | Enable `${file}` variables |
| `enableShellCommands` | Boolean | `false` | Enable `${exec}` variables |

### Anchor Values

- `"topLeft"` - Position from top-left corner
- `"topRight"` - Position from top-right corner
- `"bottomLeft"` - Position from bottom-left corner
- `"bottomRight"` - Position from bottom-right corner

### Color Formats

All color properties accept:
- Hex: `"#FFFFFF"` or `"#FFFFFFFF"` (with alpha)
- RGB: `"rgb(255, 255, 255)"`
- RGBA: `"rgba(255, 255, 255, 0.8)"`

---

## Widget Types

All widgets share these common properties:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | String | Yes | Widget type name |
| `position` | `{x, y}` | Yes | Position relative to anchor |
| `color` | String | No | Override default color |
| `condition` | String | No | JS expression for conditional display |

---

### Text Widget

Displays text with variable substitution.

```javascript
masaqhud.widget({
    type: "text",
    text: "CPU: ${cpu.usage}%",
    position: { x: 0, y: 0 },
    // Optional properties:
    color: "#FFFFFF",
    fontSize: 12,
    font: "SF Mono",
    weight: "bold",        // or use bold: true
    italic: false,
    opacity: 1.0,          // 0.0 - 1.0
    align: "left",         // "left", "center", "right"
    shadow: {
        color: "#000000",
        offsetX: 1,
        offsetY: 1,
        blur: 2
    },
    condition: "cpu.usage > 50"
});
```

---

### Graph Widget

Displays a rolling line graph (60 data points).

```javascript
masaqhud.widget({
    type: "graph",
    source: "cpu.usage",
    position: { x: 0, y: 50 },
    size: { width: 200, height: 40 },
    color: "#99CCFF",
    condition: null
});
```

**Available sources:** `cpu.usage`, `memory.percent`, `gpu.usage`, `network.down`, `network.up`, `swap.percent`, `disk.percent`

---

### Bar Widget

Displays a horizontal progress bar.

```javascript
masaqhud.widget({
    type: "bar",
    source: "memory.percent",
    position: { x: 0, y: 100 },
    width: 150,
    height: 10,
    color: "#00FF00",
    backgroundColor: "rgba(255,255,255,0.2)",
    condition: null
});
```

**Available sources:** `cpu.usage`, `memory.percent`, `gpu.usage`, `swap.percent`, `disk.percent`, `cpu.core0`, `cpu.core1`, etc.

---

### Gauge Widget

Displays a circular arc gauge.

```javascript
masaqhud.widget({
    type: "gauge",
    source: "cpu.usage",
    position: { x: 0, y: 150 },
    radius: 40,
    thickness: 8,
    color: "#FF6600",
    backgroundColor: "rgba(255,255,255,0.2)",
    startAngle: 135,       // degrees
    endAngle: 405,         // degrees
    condition: null
});
```

---

### Horizontal Rule Widget

Displays a horizontal line separator.

```javascript
masaqhud.widget({
    type: "hr",
    position: { x: 0, y: 200 },
    width: 200,
    color: "#666666",
    condition: null
});
```

---

### Image Widget

Displays an image file or SF Symbol.

```javascript
masaqhud.widget({
    type: "image",
    path: "~/Pictures/icon.png",  // or SF Symbol name: "cpu"
    position: { x: 0, y: 220 },
    size: { width: 32, height: 32 },  // optional, uses native size if omitted
    condition: null
});
```

---

## Template Variables

Use `${variable.name}` syntax in text widgets.

### CPU

| Variable | Description |
|----------|-------------|
| `${cpu.usage}` | CPU usage percentage (0-100) |
| `${cpu.temp}` | CPU temperature in Celsius |
| `${cpu.cores}` | Number of CPU cores |
| `${cpu.freq}` | CPU frequency in MHz |
| `${cpu.freq_ghz}` | CPU frequency in GHz |
| `${cpu.core0}`, `${cpu.core1}`, ... | Per-core usage percentage |

### Load Averages

| Variable | Description |
|----------|-------------|
| `${load.1}` | 1-minute load average |
| `${load.5}` | 5-minute load average |
| `${load.15}` | 15-minute load average |

### Memory

| Variable | Description |
|----------|-------------|
| `${memory.used}` | Used memory (e.g., "8.2 GB") |
| `${memory.total}` | Total memory (e.g., "16.0 GB") |
| `${memory.percent}` | Memory usage percentage |

### Swap

| Variable | Description |
|----------|-------------|
| `${swap.used}` | Used swap (e.g., "1.0 GB") |
| `${swap.total}` | Total swap (e.g., "4.0 GB") |
| `${swap.percent}` | Swap usage percentage |

### GPU

| Variable | Description |
|----------|-------------|
| `${gpu.name}` | GPU model name |
| `${gpu.usage}` | GPU utilization percentage |

### Disk

| Variable | Description |
|----------|-------------|
| `${disk.used}` | Used disk space (e.g., "250 GB") |
| `${disk.total}` | Total disk space (e.g., "500 GB") |
| `${disk.free}` | Free disk space |
| `${disk.percent}` | Disk usage percentage |
| `${disk.read}` | Read speed (e.g., "10.5 MB") |
| `${disk.write}` | Write speed (e.g., "5.2 MB") |
| `${disk.type}` | Filesystem type (e.g., "apfs") |

### Network

| Variable | Description |
|----------|-------------|
| `${network.local_ip}` | Local IP address |
| `${network.public_ip}` | Public IP (requires `enablePublicIP`) |
| `${network.down}` | Download speed (e.g., "1.2 MB") |
| `${network.up}` | Upload speed |
| `${network.total_down}` | Total downloaded |
| `${network.total_up}` | Total uploaded |

### WiFi

| Variable | Description |
|----------|-------------|
| `${wifi.ssid}` | WiFi network name |
| `${wifi.signal}` | Signal strength (0-100) |
| `${wifi.bssid}` | Access point MAC address |

### Date/Time

| Variable | Description |
|----------|-------------|
| `${time}` | Current time |
| `${date}` | Current date |
| `${datetime}` | Full date and time |
| `${weekday}` | Day of week name |

### System

| Variable | Description |
|----------|-------------|
| `${hostname}` | Computer hostname |
| `${uptime}` | System uptime (e.g., "2d 5h 30m") |
| `${os}` | OS name and version |
| `${kernel}` | Kernel version |
| `${machine}` | Architecture (e.g., "arm64") |
| `${sysname}` | System name (e.g., "Darwin") |

### Processes

| Variable | Description |
|----------|-------------|
| `${processes.total}` | Total process count |
| `${processes.running}` | Running process count |
| `${top.cpu1.name}` | Top CPU process name |
| `${top.cpu1.percent}` | Top CPU process usage |
| `${top.cpu1.pid}` | Top CPU process ID |
| `${top.cpu2.name}`, etc. | 2nd, 3rd, etc. |
| `${top.mem1.name}` | Top memory process name |
| `${top.mem1.mb}` | Top memory process MB |
| `${top.mem1.pid}` | Top memory process ID |

### Battery

| Variable | Description |
|----------|-------------|
| `${battery.percent}` | Battery percentage |
| `${battery.status}` | Status: "Charging", "Discharging", "Full" |
| `${battery.time}` | Time remaining |
| `${battery.power}` | Power draw in Watts |
| `${battery.cycles}` | Charge cycle count |
| `${battery.health}` | Battery health percentage |

### Audio

| Variable | Description |
|----------|-------------|
| `${audio.device}` | Output device name |
| `${audio.volume}` | Volume level (0-100) |
| `${audio.muted}` | "true" or "false" |

### Bluetooth

| Variable | Description |
|----------|-------------|
| `${bluetooth.powered}` | "On" or "Off" |
| `${bluetooth.connected}` | Number of connected devices |
| `${bluetooth.device1.name}` | First connected device name |
| `${bluetooth.device1.address}` | First device address |
| `${bluetooth.device2.name}`, etc. | Up to 5 devices |

---

## Advanced Features

### Conditional Rendering

Show/hide widgets based on JavaScript expressions:

```javascript
// Show only when battery is low
masaqhud.widget({
    type: "text",
    text: "LOW BATTERY: ${battery.percent}%",
    position: { x: 0, y: 0 },
    color: "#FF0000",
    condition: "battery.percent < 20 && battery.status !== 'Charging'"
});

// Show only when CPU is high
masaqhud.widget({
    type: "text",
    text: "CPU HIGH: ${cpu.usage}%",
    position: { x: 0, y: 20 },
    condition: "cpu.usage > 80"
});
```

**Available in conditions:** All variables from the template variables section, accessed as JavaScript objects (e.g., `cpu.usage`, `battery.status`, `audio.muted`).

---

### File Reading (Opt-in)

Read content from files:

```javascript
masaqhud.config({
    enableFileReading: true
});

masaqhud.widget({
    type: "text",
    text: "Status: ${file path=\"~/.config/mystatus.txt\"}",
    position: { x: 0, y: 0 }
});
```

**Restrictions:**
- Files must be in home directory (`~`) or `/tmp/`
- Maximum 1KB file size
- Returns first line only

---

### Shell Command Execution (Opt-in)

Execute shell commands and display output:

```javascript
masaqhud.config({
    enableShellCommands: true  // WARNING: Security risk
});

masaqhud.widget({
    type: "text",
    text: "Branch: ${exec command=\"git -C ~/project rev-parse --abbrev-ref HEAD\"}",
    position: { x: 0, y: 0 }
});
```

**Restrictions:**
- 5-second timeout
- 1KB output limit
- Returns first line only
- Runs as your user

---

## Date/Time Formatting

Use strftime-style patterns:

```javascript
masaqhud.config({
    dateFormat: "%Y-%m-%d",           // "2026-01-10"
    timeFormat: "%I:%M %p",           // "02:30 PM"
    datetimeFormat: "%A, %B %d %Y"    // "Friday, January 10 2026"
});
```

### Supported Format Codes

| Code | Description | Example |
|------|-------------|---------|
| `%Y` | 4-digit year | 2026 |
| `%y` | 2-digit year | 26 |
| `%m` | Month (01-12) | 01 |
| `%d` | Day (01-31) | 10 |
| `%e` | Day (1-31) | 10 |
| `%H` | Hour 24h (00-23) | 14 |
| `%I` | Hour 12h (01-12) | 02 |
| `%M` | Minute (00-59) | 30 |
| `%S` | Second (00-59) | 45 |
| `%p` | AM/PM | PM |
| `%A` | Full weekday | Friday |
| `%a` | Abbrev weekday | Fri |
| `%B` | Full month | January |
| `%b` | Abbrev month | Jan |
| `%j` | Day of year | 010 |
| `%W` | Week of year | 02 |
| `%Z` | Timezone name | PST |
| `%z` | Timezone offset | -0800 |
| `%%` | Literal % | % |

---

## Examples

### Minimal CPU/Memory Monitor

```javascript
masaqhud.config({
    position: { x: 20, y: 40 },
    font: "SF Mono",
    fontSize: 11,
    color: "#FFFFFF"
});

masaqhud.widget({
    type: "text",
    text: "CPU: ${cpu.usage}% | RAM: ${memory.percent}%",
    position: { x: 0, y: 0 }
});
```

### Full System Dashboard

```javascript
masaqhud.config({
    position: { x: 50, y: 80 },
    font: "SF Mono",
    fontSize: 11,
    color: "#FFFFFF",
    anchor: "topLeft"
});

// Header
masaqhud.widget({
    type: "text",
    text: "${datetime}",
    position: { x: 0, y: 0 },
    color: "#888888"
});

// CPU Section
masaqhud.widget({
    type: "text",
    text: "CPU",
    position: { x: 0, y: 30 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "${cpu.usage}% @ ${cpu.temp}C",
    position: { x: 0, y: 48 }
});

masaqhud.widget({
    type: "graph",
    source: "cpu.usage",
    position: { x: 0, y: 66 },
    size: { width: 200, height: 30 },
    color: "#99CCFF"
});

// Memory Section
masaqhud.widget({
    type: "text",
    text: "MEMORY",
    position: { x: 0, y: 110 },
    fontSize: 13,
    bold: true,
    color: "#99CCFF"
});

masaqhud.widget({
    type: "text",
    text: "${memory.used} / ${memory.total}",
    position: { x: 0, y: 128 }
});

masaqhud.widget({
    type: "bar",
    source: "memory.percent",
    position: { x: 0, y: 146 },
    width: 200,
    height: 8,
    color: "#99CCFF"
});
```

### Battery Warning Overlay

```javascript
masaqhud.config({
    position: { x: 20, y: 20 },
    anchor: "topRight"
});

masaqhud.widget({
    type: "text",
    text: "BATTERY LOW: ${battery.percent}%",
    position: { x: 0, y: 0 },
    fontSize: 14,
    bold: true,
    color: "#FF3333",
    condition: "battery.percent < 15 && battery.status !== 'Charging'"
});
```

### Developer Status Bar

```javascript
masaqhud.config({
    position: { x: 10, y: 10 },
    anchor: "bottomLeft",
    enableShellCommands: true
});

masaqhud.widget({
    type: "text",
    text: "${exec command=\"git -C ~/project rev-parse --abbrev-ref HEAD\"} | ${exec command=\"git -C ~/project rev-parse --short HEAD\"}",
    position: { x: 0, y: 0 },
    font: "SF Mono",
    fontSize: 10,
    color: "#88FF88"
});
```

---

## Tips for LLMs

When generating MasaqHUD configurations:

1. **Always start with `masaqhud.config()`** to set global options before adding widgets.

2. **Position is relative to anchor.** With `anchor: "topLeft"`, position `{x: 50, y: 100}` means 50px from left, 100px from top.

3. **Use consistent spacing.** A typical line height is 16-20px for fontSize 11-12.

4. **Variables use `${}` syntax** in text widgets only. Conditions use plain JavaScript syntax without `${}`.

5. **Opt-in features require explicit config:**
   - `enablePublicIP: true` for `${network.public_ip}`
   - `enableFileReading: true` for `${file path="..."}`
   - `enableShellCommands: true` for `${exec command="..."}`

6. **Graph/bar/gauge `source` values** are different from text variables:
   - Use: `"cpu.usage"` (no `${}`)
   - Not: `"${cpu.usage}"`

7. **Conditions are JavaScript expressions:**
   ```javascript
   condition: "cpu.usage > 80"                    // Correct
   condition: "${cpu.usage} > 80"                 // Wrong
   condition: "battery.status === 'Charging'"    // Use === for comparison
   ```

8. **Color with transparency:** Use `"rgba(255,255,255,0.5)"` or 8-digit hex `"#FFFFFF80"`.

9. **Section headers pattern:**
   ```javascript
   masaqhud.widget({ type: "text", text: "SECTION", bold: true, color: "#99CCFF" });
   ```

10. **Common widget heights:**
    - Text line: 16-20px
    - Graph: 30-50px
    - Bar: 8-12px
    - Gauge: 2 * radius
    - Section gap: 10-20px
