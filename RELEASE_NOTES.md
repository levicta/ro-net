# RoNet v1.0.1

**Adds spatial/zone-based broadcasting for interest management.**

## What's New

### Added
- **`Net.Zone`** — Spatial zone utilities:
  - `Net.Zone.fromPosition(origin, radius)`
  - `Net.Zone.fromCFrame(cframe, radius)`
  - `Net.Zone.fromPart(part, radius)`
  - `Net.Zone.isPlayerInZone(player, zoneData)`
  - `Net.Zone.getPlayersInZone(zoneData)`
- **`Net.fireInZone(name, zoneData, ...)`** — Fire only to players inside a zone
- **`Net.fireExceptInZone(name, zoneData, exceptPlayer, ...)`** — Fire to all in-zone except one
- Namespace support for zone methods (`Combat:fireInZone(...)`)

## Installation

**GitHub:**
```bash
git clone https://github.com/levicta/ro-net.git
```

**Wally:**
```toml
ro-net = "levicta/ro-net@1.0.1"
```

## Quick Start

```lua
local Net = require(ReplicatedStorage.RoNet)

-- Server
local zone = Net.Zone.fromPosition(Vector3.new(0, 10, 0), 50)
Net.fireInZone("MinigameEffect", zone, "boost")
```

## Full Changelog

See [README.md](README.md) for the complete API reference.
