# MasaqHUD

MasaqHUD is a lightweight, scriptable desktop heads-up display for macOS.

It provides a configurable overlay inspired by Conky, designed specifically for macOS users (power/casual users alike) with configuration expressed as code. MasaqHUD runs quietly in the background, stays out of the way, and presents information in a form that is precise, composable, and predictable.

MasaqHUD is a display layer. It observes and renders information; it does not manage or administer the system.

---

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1, M2, M3, or later)

---

## Why MasaqHUD

- macOS-native, by design
- Configuration as code (JavaScript)
- Hot-reloadable configuration
- Lightweight and resource-conscious
- CLI-first operation
- Free and open source

MasaqHUD favors clarity, stability, and long-term maintainability over novelty or abstraction.

---

## Non-Goals

MasaqHUD does **not** aim to be:

- A GUI-only application
- An enterprise monitoring solution
- A cross-platform dashboard framework
- A system administration or control tool
- A background agent that mutates system state

---

## Features

Current and planned capabilities include:

- System metrics (CPU, memory, disk, network, processes, uptime, etc.)
- CPU temperature
- Configurable widgets (text, bars, graphs, gauges, images)
- JavaScript-based configuration via JavaScriptCore
- Hot reload on configuration changes
- Per-widget refresh control
- Optional, opt-in network-backed data (planned)
- Zero-network-access operation supported

Feature parity with Conky is a goal where it makes sense on macOS, without inheriting Linux- or X11-specific assumptions.

---

## Installation

### Homebrew

```sh
brew tap iflavin/masaqhud
brew install masaqhud
```

Uninstall:

```sh
brew uninstall masaqhud
```

### Build from Source

```sh
git clone https://github.com/iflavin/MasaqHUD.git
cd MasaqHUD
swift build -c release
cp .build/release/MasaqHUD /usr/local/bin/masaqhud
```

---

## Getting Started

### Initialize a default configuration

```sh
masaqhud init
```

This will create a configuration directory at:

```
~/.config/masaqhud/
```

The default configuration:

- Displays a minimal, unobtrusive overlay
    
- Serves as inline documentation
    
- Is safe to modify and reload live
    

### Start MasaqHUD

```sh
masaqhud start
```

### Stop MasaqHUD

```sh
masaqhud stop
```

### Reload configuration

```sh
masaqhud reload
```

Configuration changes are applied live. Invalid configurations will not replace a running, valid setup.

---

## Configuration

MasaqHUD is configured using JavaScript at `~/.config/masaqhud/masaqhud.js`.

### Quick Example

```javascript
masaqhud.config({
    position: { x: 20, y: 40 },
    font: "SF Mono",
    fontSize: 11
});

masaqhud.widget({
    type: "text",
    text: "CPU: ${cpu.usage}% | RAM: ${memory.percent}% | ${time}",
    position: { x: 0, y: 0 }
});
```

### Documentation

- **[User Guide](docs/USER_GUIDE.md)** - Complete configuration reference
- **[Examples](docs/examples/)** - Ready-to-use configurations

Configuration features:
- Hot-reloaded on save
- JavaScript-based (via JavaScriptCore)
- Errors surfaced clearly
- Backward-compatible API

---

## Security and Privacy

MasaqHUD does not collect telemetry.

Any feature that requires:

- Network access
- External services
- Shell command execution

is explicitly opt-in, clearly documented, and easy to disable.

Running MasaqHUD with **zero network access** is a supported and documented mode of operation.

---

## Relationship to Conky

MasaqHUD is inspired by Conky, not a reimplementation.

There is no relationship between MasaqHUD and the Conky project, and MasaqHUD is not endorsed by them. The inspiration is conceptual: a scriptable, text-driven system monitor with deep configurability.

Where Conky assumptions do not translate cleanly to macOS, MasaqHUD favors native macOS approaches over strict behavioral compatibility.

---

## License

MasaqHUD is licensed under the **Apache License 2.0**.

See the `LICENSE` file for details.

---

## Contributing

Contributions are welcome. Open an issue to discuss before submitting large changes.

**Quick start:**
```sh
git clone https://github.com/iflavin/MasaqHUD.git
cd MasaqHUD
swift build
swift test  # Requires Xcode
```

Detailed contribution guidelines will be added in a future release. For now:
- Follow existing code style
- Test your changes
- Keep PRs focused

Architectural coherence and long-term maintainability matter more than rapid feature expansion.

---

## Project Status

MasaqHUD is under active development.

The API surface and configuration format may evolve, but stability and compatibility are treated as first-class concerns. Breaking changes will be deliberate and documented.

---

## Closing

MasaqHUD exists to give macOS users a clear, scriptable view of information on their desktop, with system monitoring as its core focus.

It displays information. It does not manage, control, or administer the system.

---
