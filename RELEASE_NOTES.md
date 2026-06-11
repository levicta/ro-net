# RoNet v1.3.0

**Adds per-player observable state synchronization.**

## What's New

### Added (v1.3.0)
- **`Net.playerObservable(name, initialValue)`** — Reactive state that stores a separate value per-player and auto-syncs only to that player
  - `:set(player, value)` — Update and send only to that player
  - `:get(player)` — Read cached value for a specific player
  - `:onChange(callback)` — React to updates (server: `callback(player, newValue)`, client: `callback(newValue)`)
  - `:destroy()` — Cleanup
- Auto-sync on join: new players immediately receive their own cached value
- Auto-evict on leave: player state is garbage-collected when they disconnect
- Client-side `.set()` support: clients can request their own value update via `FireServer`
- Namespace support: `Game:playerObservable("TeamScore", 0)`

### Added (v1.2.0)
- **`Net.fireBatch(player, events)`** — Send multiple different events to one player in a single network call
- **`Net.fireBatchAll(events)`** — Broadcast a batch to all players
- **`Net.fireBatchExcept(exceptPlayer, events)`** — Broadcast a batch to all except one
- Namespace support: `Combat:fireBatch(player, {...})`

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
ro-net = "levicta/ro-net@1.3.0"
```

## Quick Start

```lua
local Net = require(ReplicatedStorage.RoNet)

-- Server
local Health = Net.playerObservable("PlayerHealth", 100)
Health:set(player, 75)

-- Client
local Health = Net.playerObservable("PlayerHealth", 100)
Health:onChange(function(newVal)
    healthBar.Value = newVal
end)
```

## Full Changelog

See [README.md](README.md) for the complete API reference.
