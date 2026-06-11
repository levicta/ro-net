# RoNet v1.1.0

**Adds reactive state synchronization helpers (Observables).**

## What's New

### Added (v1.1.0)
- **`Net.observable(name, initialValue)`** — Reactive state that auto-syncs to all clients (including new joiners)
  - `:set(value)` — Update and broadcast
  - `:get()` — Read cached value
  - `:onChange(callback)` — React to updates
  - `:destroy()` — Cleanup
- Namespace support: `Game:observable("RoundNumber", 0)`

### Added (v1.0.1)
- **`Net.Zone`** — Spatial zone utilities for interest management
  - `Net.Zone.fromPosition(origin, radius)`
  - `Net.Zone.fromCFrame(cframe, radius)`
  - `Net.Zone.fromPart(part, radius)`
  - `Net.Zone.isPlayerInZone(player, zoneData)`
  - `Net.Zone.getPlayersInZone(zoneData)`
- **`Net.fireInZone(name, zoneData, ...)`** — Fire only to players inside a zone
- **`Net.fireExceptInZone(name, zoneData, exceptPlayer, ...)`** — Fire to all in-zone except one
- Namespace support for zone methods (`Combat:fireInZone(...)`)

### Core Features (v1.0.0)
- **Auto-registration** — Define remotes in code, no manual Studio setup
- **Unified API** — Same `on()`/`fire()`/`invoke()` works on server and client
- **Middleware system** — Compose validation, rate limiting, logging, auth, debounce
- **Type validation** — Runtime schema checking for 18+ Luau/Roblox types
- **Promise-based async** — `invokeAsync()` with timeout, never hangs
- **Connection cleanup** — `.off()` and auto-disconnecting `.once()`
- **Strict mode** — Catch undefined remote typos at runtime

### Advanced Features (v1.0.0)
- **Namespaces** — Scoped remotes (`Combat.Damage`, `Economy.Purchase`) to prevent collisions
- **Bindable wrapper** — Same-context messaging without RemoteEvents
- **Serialization** — Send `Vector3`, `CFrame`, `ColorSequence`, `NumberSequence` over remotes
- **Network profiler** — Built-in metrics: latency, throughput, payload size, errors
- **Utilities** — `.wait()` for yielding event consumption

## Installation

**GitHub:**
```bash
git clone https://github.com/levicta/ro-net.git
```

**Wally:**
```toml
ro-net = "levicta/ro-net@1.1.0"
```

## Quick Start

```lua
local Net = require(ReplicatedStorage.RoNet)

-- Server
local Round = Net.observable("RoundNumber", 0)
Round:set(3)

-- Client
local Round = Net.observable("RoundNumber", 0)
Round:onChange(function(newRound)
    updateUI(newRound)
end)
```

## Full Changelog

See [README.md](README.md) for the complete API reference.
