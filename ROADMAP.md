# MasaqHUD Roadmap

This document outlines the direction and planned evolution of MasaqHUD.

---

## How to Read This Roadmap

MasaqHUD prioritizes **stability over novelty**. This roadmap is organized by theme, not by date. Features are listed in rough priority order within each milestone, but no timeline commitments are made.

Items may be:
- Reordered based on community feedback
- Deferred if they conflict with core principles
- Implemented ahead of schedule if contributed

This is a living document. See [Contributing](#contributing-to-the-roadmap) for how to propose changes.

---

## Current Release: v0.5.0

MasaqHUD v0.5.0 is a feature-complete beta providing a scriptable desktop overlay for macOS.

### Implemented

**Core**
- Desktop-level transparent overlay window
- JavaScript-based configuration via JavaScriptCore
- Hot-reload on configuration file changes
- CLI commands: `init`, `start`, `stop`, `reload`, `enable`, `disable`, `status`
- Menu bar status icon with quick access
- Launch at login via launchd

**Metrics**
- CPU usage, temperature, frequency, per-core usage
- Load averages (1, 5, 15 minute)
- Memory and swap usage
- GPU name and usage
- Disk usage, I/O rates, filesystem type
- Network local IP, bandwidth (up/down), cumulative totals, per-interface filtering
- WiFi SSID, signal strength, BSSID
- Public IP lookup (opt-in, disabled by default)
- Battery level, status, time remaining, power draw, cycles, health
- Audio output device, volume level, mute status
- Bluetooth power state, connected device count and names
- Top processes by CPU and memory
- Process counts (total, running)
- Date, time, uptime, hostname, OS version, kernel, architecture

**Widgets**
- `text` - Variable-substituted text with styling (font, color, weight, shadow, alignment)
- `bar` - Horizontal progress bar
- `graph` - Rolling line graph (60 data points)
- `gauge` - Arc/ring gauge
- `hr` - Horizontal rule
- `image` - PNG files and SF Symbols

**Advanced Features (Opt-in)**
- File content reading via `${file path="..."}`
- Shell command execution via `${exec command="..."}`
- Conditional widget rendering via `condition` property

**Performance**
- Double-buffered rendering
- Font caching
- LRU-bounded image caching

**Multi-Monitor**
- Display index selection (`display: 0`, `display: 1`, etc.)
- Anchor-based positioning (topLeft, topRight, bottomLeft, bottomRight)
- Automatic repositioning on display changes

**Configuration**
- Config validation with error/warning severity levels
- Graceful degradation for unavailable metrics
- Custom date/time formats (strftime-style patterns)

---

## Milestone: Foundation

Establish the infrastructure for a sustainable open-source project.

- [x] **Homebrew formula** - `brew tap iflavin/masaqhud && brew install masaqhud`
- [x] **Documentation** - User guide, widget examples, variable reference in `docs/`
- [x] **Automated tests** - Unit tests for formatting, validation, variable expansion, metrics (requires Xcode)
- [ ] **CI pipeline** - Build verification on PRs
- [ ] **Release automation** - Tagged releases with changelogs

---

## Milestone: Conky Parity (Complete)

Achieve feature parity with commonly-used Conky variables for macOS.

**Core Metrics**
- [x] **CPU frequency** - `${cpu.freq}`, `${cpu.freq_ghz}`
- [x] **Load averages** - `${load.1}`, `${load.5}`, `${load.15}`
- [x] **Process counts** - `${processes.total}`, `${processes.running}`
- [x] **Kernel info** - `${kernel}`, `${machine}`, `${sysname}`

**Network Enhancements**
- [x] **WiFi information** - `${wifi.ssid}`, `${wifi.signal}`, `${wifi.bssid}`
- [x] **Cumulative network totals** - `${network.total_down}`, `${network.total_up}`
- [x] **Per-interface stats** - `networkInterface: "en0"` config option

**Disk Enhancements**
- [x] **Filesystem type** - `${disk.type}`

**Configuration**
- [x] **Text alignment** - `align: "left" | "center" | "right"`
- [x] **File content reading** - `${file path="..."}` (opt-in via `enableFileReading`)

---

## Milestone: Polish (Complete)

Refine the user experience for everyday use.

- [x] **Menu bar status icon** - Quick access to start/stop/reload
- [x] **Launch at login** - launchd integration with `masaqhud enable`/`disable`
- [x] **Multi-monitor support** - Configure overlay position per display with `display` and `anchor`
- [x] **Config validation** - Clear error messages for invalid configurations
- [x] **Graceful degradation** - Handle unavailable metrics without errors

---

## Milestone: Extensibility (Complete)

Expand capabilities while maintaining simplicity.

- [x] **Custom date/time formats** - `dateFormat`, `timeFormat`, `datetimeFormat` with strftime-style patterns
- [x] **Battery metrics** - `${battery.percent}`, `${battery.status}`, `${battery.time}`, `${battery.power}`, `${battery.cycles}`, `${battery.health}`
- [x] **Audio metrics** - `${audio.device}`, `${audio.volume}`, `${audio.muted}`
- [x] **Bluetooth metrics** - `${bluetooth.connected}`, `${bluetooth.powered}`, `${bluetooth.device1.name}`, etc.
- [x] **Conditional rendering** - `condition` property on widgets with JavaScript expressions
- [x] **Shell command execution** - `${exec command="..."}` (opt-in via `enableShellCommands`)
- [x] **Widget positioning modes** - Anchor to screen edges (`anchor: "topRight"`, etc.)

---

## Milestone: Advanced (Under Consideration)

These items are being evaluated but are not committed.

- [ ] **Theme presets** - Bundled configuration examples
- [ ] **Plugin architecture** - Load custom metrics from external modules

---

## Non-Goals

The following are explicitly **out of scope** for MasaqHUD. See the [MANIFESTO](MANIFESTO.md) for rationale.

- **Cross-platform support** - MasaqHUD is macOS-only by design
- **GUI configuration editor** - Configuration is code, not clicks
- **System administration features** - MasaqHUD displays; it does not manage
- **Telemetry or analytics** - No data collection, ever
- **Enterprise features** - Not a monitoring solution for fleets
- **Mandatory network access** - Zero-network operation is always supported
- **Conky Linux-specific features** - ACPI variables, /proc filesystem, X11/XRandR, Linux music players (MPD, Audacious, XMMS2, CMUS), iwconfig, i8k sensors

---

## Contributing to the Roadmap

Feature requests and feedback are welcome.

**To propose a feature:**
1. Check this roadmap and existing issues first
2. Open a GitHub issue with the `enhancement` label
3. Describe the use case, not just the solution
4. Explain how it aligns with the [MANIFESTO](MANIFESTO.md)

**Pull requests for roadmap items are welcome**, but please open an issue first for anything not already listed.

Features that add complexity, require network access, or execute external commands will be held to a higher bar and must be opt-in.

---

## Versioning

MasaqHUD follows [Semantic Versioning](https://semver.org/):

- **MAJOR** - Breaking changes to configuration API
- **MINOR** - New features, backward compatible
- **PATCH** - Bug fixes, backward compatible

The configuration API is treated as a public interface. Breaking changes are avoided and, when necessary, documented with migration guides.
