# RoNet v1.0.0

**A clean, intuitive networking framework for Roblox.**

## What's New

### Core Features
- **Auto-registration** — Define remotes in code, no manual Studio setup
- **Unified API** — Same `on()`/`fire()`/`invoke()` works on server and client
- **Middleware system** — Compose validation, rate limiting, logging, auth, debounce
- **Type validation** — Runtime schema checking for 18+ Luau/Roblox types
- **Promise-based async** — `invokeAsync()` with timeout, never hangs
- **Connection cleanup** — `.off()` and auto-disconnecting `.once()`
- **Strict mode** — Catch undefined remote typos at runtime

### Advanced Features
- **Namespaces** — Scoped remotes (`Combat.Damage`, `Economy.Purchase`) to prevent collisions
- **Bindable wrapper** — Same-context messaging without RemoteEvents
- **Serialization** — Send `Vector3`, `CFrame`, `ColorSequence`, `NumberSequence` over remotes
- **Network profiler** — Built-in metrics: latency, throughput, payload size, errors
- **Utilities** — `.wait()` for yielding event consumption

### Developer Experience
- Full TypeScript declarations (`index.d.ts`) for roblox-ts
- Rojo project file included
- Wally package manifest included
- GitHub Actions CI (type check + lint + structure verification)
- 24 working examples
- 25 automated tests
- Complete API reference in README

## Installation

**GitHub (recommended):**
```bash
git clone https://github.com/YOUR_USERNAME/ro-net.git
```

**Wally:**
```toml
ro-net = "YOUR_USERNAME/ro-net@1.0.0"
```

**roblox-ts:**
```ts
import Net from "@rbxts/ro-net";
```

## Quick Start

```lua
local Net = require(ReplicatedStorage.RoNet)

-- Server
Net.on("Hello", function(player, message)
    print(player.Name .. " says: " .. message)
    Net.fire("Response", player, "Hello back!")
end)

-- Client
Net.on("Response", function(msg)
    print("Server says:", msg)
end)

Net.fire("Hello", "world")
```

## Breaking Changes

None — this is the initial release.

## Known Issues

- `invokeAsync` timeout uses `task.delay` which may not interrupt an in-progress `InvokeClient`/`InvokeServer` call on the Roblox side. The Promise will reject after timeout, but the underlying RemoteFunction call may still complete internally.
- Studio plugin for remote visualization is planned but not yet implemented.

## Contributors

- [levicta](https://github.com/levicta)

## Full Documentation

See [README.md](README.md) for complete API reference, examples, and contribution guidelines.
