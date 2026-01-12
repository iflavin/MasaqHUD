## What MasaqHUD Is

MasaqHUD is a lightweight, scriptable desktop heads-up display for macOS.

It provides a configurable system overlay inspired by Conky, designed specifically for macOS users (power/casual users alike) with configuration expressed as code. It runs quietly in the background, stays out of the way, and presents information in a form that is precise, composable, and predictable.
 
MasaqHUD is not a general-purpose system administration tool. It is a display layer.

---

## Core Principles

### macOS-only, by design

MasaqHUD is intentionally focused on macOS.

It embraces macOS APIs, behaviors, and constraints rather than abstracting them away. There is no goal of cross-platform parity, and no roadmap promise to support other operating systems.

This focus allows the project to remain lightweight, coherent, and maintainable.

---

### Configuration by code

MasaqHUD is configured through code, not through a graphical editor.

Configuration is:

- Explicit
- Versionable
- Hot-reloadable
- Readable in a plain text editor

This approach favors clarity, composability, and long-term maintainability over ease of initial discovery. Casual users are supported through good defaults and clear examples, not through a GUI abstraction layer.

---

### Lightweight and respectful

MasaqHUD should never become the most expensive process on the screen.

It is designed to:

- Use minimal CPU and memory
- Update only as often as necessary
- Cache responsibly
- Degrade gracefully when data is unavailable
  
A system monitor should not meaningfully affect the system it is monitoring.

---

### Transparency and trust

MasaqHUD does not collect telemetry.

Any feature that requires:

- Network access
- External services
- Shell command execution

must be explicitly opt-in, clearly documented, and easy to disable.

Running MasaqHUD with zero network access must always be a supported and documented mode of operation.

---

### Stability over novelty

MasaqHUD prioritizes configuration stability and API consistency.

Breaking changes are deliberate, documented, and avoided whenever possible. Existing configurations should continue to work across updates whenever feasible. Compatibility and predictability matter more than rapid feature expansion.

---

## What MasaqHUD Is Not

MasaqHUD explicitly does not aim to be:

- A GUI-only application
- An enterprise monitoring solution
- A cross-platform dashboard framework
- A system administration or control tool
- A background agent that mutates system state

MasaqHUD observes and displays. It does not manage.

---

## Relationship to Conky

MasaqHUD is inspired by Conky, not a reimplementation of it.

There is no relationship between MasaqHUD and the Conky project, and MasaqHUD is not endorsed by them. The inspiration is conceptual: a scriptable, text-driven system monitor with deep configurability.

The goal is to provide:

- A familiar conceptual model
- A similar configuration experience
- Feature parity where it makes sense on macOS
    

Where Conky assumptions do not translate cleanly to macOS, MasaqHUD favors native macOS approaches over strict behavioral compatibility.

Conky compatibility is a tool for migration and familiarity, not a constraint on design.
