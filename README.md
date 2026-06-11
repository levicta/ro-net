# RoNet

A clean, intuitive networking framework for Roblox that eliminates boilerplate and makes client-server communication feel effortless.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## The Problem

Roblox's native networking works, but it's verbose and error-prone:

```lua
-- Vanilla Roblox (server)
local remote = Instance.new("RemoteEvent")
remote.Name = "MyEvent"
remote.Parent = ReplicatedStorage

remote.OnServerEvent:Connect(function(player, data)
    -- No validation, no logging, no rate limiting
    -- Just raw data you have to manually check
end)

-- Vanilla Roblox (client)
ReplicatedStorage:WaitForChild("MyEvent"):FireServer(data)
```

**RoNet replaces all of that with a unified, type-safe, middleware-driven API.**

## Quick Start

### Installation

**Option A: GitHub (recommended)**
1. Download the latest release from the [Releases](https://github.com/levicta/ro-net/releases) page
2. Place the `src` folder into `ReplicatedStorage` as a ModuleScript named `RoNet`

**Option B: Rojo**
```bash
git clone https://github.com/levicta/ro-net.git
cd ro-net
rojo serve
```

**Option C: Wally**
Add to your `wally.toml`:
```toml
ro-net = "levicta/ro-net@0.1.0"
```

**Option D: roblox-ts (TypeScript)**
```ts
import Net from "@rbxts/ro-net";
```

### 10-Second Setup

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

No manually creating RemoteEvents. No `:WaitForChild` on the client. No boilerplate.

## API Reference

### Unified API (Context-Aware)

RoNet automatically detects whether it's running on the server or client, so the same API works everywhere.

#### `Net.on(name, handler, middleware?)`
Listen for an event. Returns an `RBXScriptConnection` you can disconnect later.

**Server:**
```lua
Net.on("UpdateCoins", function(player, coins)
    -- player is automatically passed as first argument
end)
```

**Client:**
```lua
Net.on("UpdateCoins", function(coins)
    -- no player argument on client
end)
```

#### `Net.off(name)`
Disconnect the listener for a remote. Use this to clean up temporary listeners.

```lua
Net.on("MinigameScore", function(score) ... end)
-- Later:
Net.off("MinigameScore")
```

#### `Net.fire(name, ...)`
Fire an event.

**Server:**
```lua
Net.fire("EventName", targetPlayer, data1, data2)
```

**Client:**
```lua
Net.fire("EventName", data1, data2)
```

#### `Net.fireAll(name, ...)` *(Server only)*
Fire to all connected players.

```lua
Net.fireAll("Announcement", "Server restarting in 5 minutes")
```

#### `Net.fireExcept(name, exceptPlayer, ...)` *(Server only)*
Fire to all players except one.

```lua
Net.fireExcept("ChatMessage", sender, sender.Name, message)
```

#### `Net.fireInZone(name, zoneData, ...)` *(Server only)*
Fire only to players within a spatial zone (interest management).

```lua
local zone = Net.Zone.fromPosition(Vector3.new(0, 10, 0), 50)
Net.fireInZone("MinigameEffect", zone, "boost")
```

#### `Net.fireExceptInZone(name, zoneData, exceptPlayer, ...)` *(Server only)*
Fire to all players in a zone except one.

```lua
local zone = Net.Zone.fromPart(workspace.Arena.PrimaryPart, 100)
Net.fireExceptInZone("AreaDamage", zone, attacker, damageType)
```

#### `Net.Zone`
```lua
local zone = Net.Zone.fromPosition(Vector3.new(0, 10, 0), 50)
local zone = Net.Zone.fromCFrame(CFrame.new(0, 10, 0), 50)
local zone = Net.Zone.fromPart(workspace.Minigame.PrimaryPart, 30)

-- Query membership
local players = Net.Zone.getPlayersInZone(zone)
local inZone = Net.Zone.isPlayerInZone(player, zone)
```

#### `Net.observable(name, initialValue)`
Create a reactive state variable that auto-syncs to all clients (including new joiners).

**Server:**
```lua
local Round = Net.observable("RoundNumber", 0)
Round:set(3)
Round:onChange(function(newVal)
    print("Round is now", newVal)
end)
```

**Client:**
```lua
local Round = Net.observable("RoundNumber", 0)
print(Round:get()) -- 0 (initial value until first sync)
Round:onChange(function(newVal)
    updateUI(newVal)
end)
```

With namespaces:
```lua
local Game = Net.namespace("Game")
local Round = Game:observable("RoundNumber", 0)
```

#### `Net.playerObservable(name, initialValue)`
Create a reactive state variable that stores a separate value per-player and auto-syncs only to that player (including on join).

**Server:**
```lua
local Health = Net.playerObservable("PlayerHealth", 100)
Health:set(player, 75)
Health:get(player) -- 75
Health:onChange(function(player, newVal)
    print(player.Name .. " health: " .. newVal)
end)
```

**Client:**
```lua
local Health = Net.playerObservable("PlayerHealth", 100)
print(Health:get()) -- 100 (initial value until first sync)
Health:onChange(function(newVal)
    healthBar.Value = newVal
end)
```

With namespaces:
```lua
local Game = Net.namespace("Game")
local Score = Game:playerObservable("TeamScore", 0)
```

#### `Net.teamObservable(name, initialValue)`
Create a reactive state variable that stores a separate value per-team and auto-syncs only to members of that team (including on join/switch).

**Server:**
```lua
local TeamScore = Net.teamObservable("TeamScore", 0)
TeamScore:set(team, 150)
TeamScore:get(team) -- 150
TeamScore:onChange(function(team, newVal)
    print(team.Name .. " score: " .. newVal)
end)
```

**Client:**
```lua
local TeamScore = Net.teamObservable("TeamScore", 0)
print(TeamScore:get()) -- 0 (initial value until first sync)
TeamScore:onChange(function(newVal)
    updateTeamUI(newVal)
end)
```

With namespaces:
```lua
local Game = Net.namespace("Game")
local TeamScore = Game:teamObservable("TeamScore", 0)
```

#### `Net.computed(name, fn, dependencies)` / `Net.playerComputed(name, fn, dependencies)` / `Net.teamComputed(name, fn, dependencies)`
Create a read-only observable that automatically recalculates when its source observables change.

**Global computed:**
```lua
local RedScore = Net.observable("RedScore", 0)
local BlueScore = Net.observable("BlueScore", 0)
local TotalScore = Net.computed("TotalScore", function(red, blue)
    return red + blue
end, {RedScore, BlueScore})

TotalScore:get() -- 0
TotalScore:onChange(function(total)
    print("Total score:", total)
end)

RedScore:set(10) -- TotalScore auto-recalculates to 10
```

**Player computed:**
```lua
local PlayerLevel = Net.playerObservable("PlayerLevel", 1)
local PlayerMultiplier = Net.playerObservable("PlayerMultiplier", 1)
local PlayerPower = Net.playerComputed("PlayerPower", function(player, level, multiplier)
    return level * multiplier
end, {PlayerLevel, PlayerMultiplier})

PlayerPower:get(player)
```

**Team computed:**
```lua
local TeamAttack = Net.teamObservable("TeamAttack", 10)
local TeamDefense = Net.teamObservable("TeamDefense", 5)
local TeamPower = Net.teamComputed("TeamPower", function(team, attack, defense)
    return attack + defense
end, {TeamAttack, TeamDefense})

TeamPower:get(team)
```

#### `Net.channel(name)`
Create or get a named channel for arbitrary player grouping. Channels are not tied to Roblox Teams or spatial zones.

```lua
local lobby = Net.channel("lobby")
local dungeon = Net.channel("dungeon-1")

lobby:join(player)
lobby:leave(player)
lobby:has(player)          -- boolean
lobby:getPlayers()         -- {Player}

lobby:fire("ChatMessage", player.Name, message)
lobby:fireExcept("PrivateMsg", excludedPlayer, data)
```

#### `Net.fireBatch(player, events)` / `Net.fireBatchAll(events)` / `Net.fireBatchExcept(exceptPlayer, events)` *(Server only)*
Send multiple different events in a single network call to reduce per-RemoteEvent overhead.

```lua
Net.fireBatch(player, {
    {"HealthChanged", 75},
    {"PositionChanged", Vector3.new(10, 5, 20)},
    {"StatusEffect", "poison"},
})

Net.fireBatchAll({
    {"Announcement", "Round starting!"},
    {"TimerUpdate", 60},
})

Net.fireBatchExcept(excludedPlayer, {
    {"ChatMessage", sender.Name, message},
})
```

With namespaces:
```lua
local Combat = Net.namespace("Combat")
Combat:fireBatch(player, {
    {"Damage", targetId, 25},
    {"Heal", targetId, 10},
})
```

#### `Net.onInvoke(name, handler, middleware?)`
Handle a RemoteFunction invocation.

**Server:**
```lua
Net.onInvoke("GetData", function(player, key)
    return dataStore[key]
end)
```

**Client:**
```lua
Net.onInvoke("GetData", function(key)
    return localData[key]
end)
```

#### `Net.invoke(name, ...)`
Invoke a RemoteFunction and wait for a response. **Warning:** This blocks the thread and can hang indefinitely if the other side errors or disconnects.

**Server → Client:**
```lua
local setting = Net.invoke("GetClientSetting", player, "volume")
```

**Client → Server:**
```lua
local coins = Net.invoke("GetCoins")
```

#### `Net.invokeAsync(name, timeout?, ...)`
Invoke a RemoteFunction with a **timeout** and receive a **Promise**. Never hangs.

**Server → Client:**
```lua
Net.invokeAsync("GetClientSetting", player, 3, "fov")
    :andThen(function(value)
        print("FOV:", value)
    end)
    :catch(function(err)
        warn("Timed out:", err)
    end)
```

**Client → Server:**
```lua
Net.invokeAsync("GetCoins", 5)
    :andThen(function(coins)
        print("You have", coins)
    end)
```

You can also `await` synchronously:
```lua
local success, value = Net.invokeAsync("GetData", 5, "key"):await()
```

#### `Net.define(name, type)` *(Server only)*
Pre-register a remote so it's ready before any client connects.

```lua
Net.define("MyEvent", "Event")      -- Creates RemoteEvent
Net.define("MyFunc", "Function")    -- Creates RemoteFunction
```

#### `Net.defineMany(definitions)` *(Server only)*
Bulk-define remotes.

```lua
Net.defineMany({
    {name = "Event1", type = "Event"},
    {name = "Func1", type = "Function"},
    {name = "Event2", type = "Event"},
})
```

#### `Net.isDefined(name)` *(Server only)*
Check if a remote has been defined. Useful for conditional logic.

```lua
if Net.isDefined("MyEvent") then
    Net.fire("MyEvent", player, data)
end
```

#### `Net.configure(config)`
Adjust framework behavior.

```lua
Net.configure({
    strictMode = true,  -- Error on undefined remotes
})
```

---

### Namespaces

Organize remotes by domain to prevent naming collisions in large projects.

```lua
local PlayerNet = Net.namespace("Player")
local CombatNet = Net.namespace("Combat")

-- Server
CombatNet:defineMany({
    {name = "Damage", type = "Event"},
    {name = "GetStats", type = "Function"},
})

CombatNet:on("Damage", function(player, targetId, amount)
    -- remote name is automatically "Combat.Damage"
end)

CombatNet:fire("Damage", player, targetId, amount)

-- Client
CombatNet:on("Damage", function(targetId, amount)
    print("You took", amount, "damage!")
end)

CombatNet:fire("Damage", targetId, amount)

-- Namespaced invoke
CombatNet:onInvoke("GetStats", function(player)
    return {health = 100, damage = 25}
end)

local stats = CombatNet:invoke("GetStats")
```

All namespace methods mirror the top-level API: `on`, `off`, `fire`, `fireAll`, `fireExcept`, `onInvoke`, `invoke`, `invokeAsync`, `define`, `defineMany`, `isDefined`.

---

### Utilities

#### `Net.once(name, handler)`
Listen for an event exactly once, then auto-disconnect.

```lua
Net.once("RoundStart", function(roundNumber)
    print("Round started! (prints once)")
end)
```

#### `Net.wait(name, timeout?)`
Yield the current thread until an event fires. Returns the event arguments or `nil` on timeout.

```lua
local winner = Net.wait("RoundEnd", 30)
if winner then
    print("Winner:", winner)
else
    print("Timed out")
end
```

---

### Serialization

Send complex Roblox types (`Vector3`, `CFrame`, `ColorSequence`, etc.) over remotes by serializing them to plain tables.

```lua
-- Server
local trailData = {
    color = ColorSequence.new({...}),
    width = NumberSequence.new({...}),
    position = CFrame.new(10, 5, 20),
}

local serialized = Net.serialize(trailData)
Net.fire("UpdateTrail", player, serialized)

-- Client
Net.on("UpdateTrail", function(data)
    local trailData = Net.deserialize({data})[1]
    -- trailData.color is a real ColorSequence again
    -- trailData.position is a real CFrame again
end)
```

**Supported types:** `Vector3`, `Vector2`, `CFrame`, `Color3`, `BrickColor`, `UDim`, `UDim2`, `Rect`, `NumberRange`, `NumberSequence`, `ColorSequence`

---

### Network Profiler

Track performance metrics for every remote call: latency, frequency, payload size, and errors.

```lua
-- Enable profiling on specific remotes
Net.profile("DamageDealt")
Net.profile("Purchase")

-- Or enable globally (profiles ALL remotes)
Net.profile()

-- Later, inspect metrics
local m = Net.getMetrics("DamageDealt")
print(m.callCount)        -- total calls
print(m.avgLatency * 1000) -- average latency in ms
print(m.callsPerSecond)    -- current throughput
print(m.peakCallsPerSec)   -- highest burst
print(m.avgPayloadSize)    -- average bytes per call
print(m.errors)            -- error count

-- Get all metrics at once
for name, metrics in pairs(Net.getAllMetrics()) do
    print(name, metrics.avgLatency)
end

-- Print a formatted report
print(Net.profilerReport())
-- Output:
-- === RoNet Profiler Report ===
-- DamageDealt: 1523 calls | 0.523ms avg | 45.2/sec | 0 errors | 12 bytes avg
-- Purchase: 89 calls | 2.341ms avg | 1.2/sec | 2 errors | 45 bytes avg

-- Reset when done
Net.resetMetrics("DamageDealt")
-- Or reset all: Net.resetMetrics()
```

Profiling is zero-overhead when disabled. When enabled, it adds ~0.01ms per call.

---

### Middleware System

Middleware runs *before* your handler on every incoming call. Chain multiple middleware for powerful behavior.

#### Built-in Middleware

##### `Middleware.Validate(schema)`
Enforce type safety on incoming arguments.

```lua
local Middleware = Net.Middleware

Net.on("Teleport", function(player, position, targetName)
    -- Safe to use — validation already passed
end, {
    Middleware.Validate({"Vector3", {type = "string", optional = true}}),
})
```

**Supported types:** `string`, `number`, `boolean`, `table`, `function`, `nil`, `any`, `Instance`, `Player`, `Vector3`, `Vector2`, `CFrame`, `Color3`, `BrickColor`, `UDim`, `UDim2`, `Rect`, `NumberRange`, `NumberSequence`, `ColorSequence`

##### `Middleware.RateLimit(maxPerSecond, burstSize?)`
Token-bucket rate limiter per player.

```lua
Net.on("Attack", function(player, targetId)
    -- Max 5 per second, burst up to 8
end, {
    Middleware.RateLimit(5, 8),
})
```

##### `Middleware.Logger()`
Log every incoming call with direction, remote name, player, and arg count.

```lua
Net.on("BuyItem", function(player, itemId)
    -- [RoNet] incoming | BuyItem | PlayerName | args: 1
end, {
    Middleware.Logger(),
})
```

##### `Middleware.Auth(checkFn)`
Block calls that fail an auth check.

```lua
Net.on("AdminCommand", function(player, command)
    -- Only admins get here
end, {
    Middleware.Auth(function(player)
        return player:GetRankInGroup(12345) >= 255
    end),
})
```

##### `Middleware.Debounce(cooldown)`
Prevent a player from calling a remote more than once within a cooldown period (seconds).

```lua
Net.on("EquipItem", function(player, itemId)
    -- Can only be called once per second
end, {
    Middleware.Debounce(1),
})
```

#### Custom Middleware

Write your own middleware in 5 lines:

```lua
local function MyMiddleware(context, next)
    -- context.remote: string — remote name
    -- context.player: Player? — the player who sent it
    -- context.payload: {any} — all arguments
    -- context.direction: "incoming" | "outgoing"

    print("Before handler")
    local result = next()  -- Call the next middleware or handler
    print("After handler")
    return result
end

Net.on("MyEvent", handler, {MyMiddleware})
```

**Important:** Always call `next()` to continue the chain. Return `nil` to block the call.

---

### Promise API

RoNet includes a lightweight Promise implementation for `invokeAsync`.

```lua
local Promise = Net.Promise

-- Create a promise
local p = Promise.new(function(resolve, reject)
    task.delay(1, function()
        resolve("done")
    end)
end)

-- Chain handlers
p:andThen(function(value)
    print(value)  -- "done"
end):catch(function(err)
    warn("Failed:", err)
end)

-- Await synchronously
local success, result = p:await()
```

---

### Bindable (Same-Context Messaging)

For server→server or client→client communication without RemoteEvents.

```lua
-- Module A listens
Net.Bindable.on("CurrencyChanged", function(playerId, newAmount)
    print("Currency updated:", playerId, newAmount)
end)

-- Module B fires (instant, no network)
Net.Bindable.fire("CurrencyChanged", 12345, 500)

-- Functions work too
Net.Bindable.onInvoke("GetRank", function(playerId)
    return "Gold"
end)

local rank = Net.Bindable.invoke("GetRank", 12345)
```

Disconnect when done:
```lua
Net.Bindable.off("CurrencyChanged", myHandler)
```

---

### Strict Mode

Catch typos and undefined remotes at runtime.

```lua
-- Enable BEFORE any other calls
Net.configure({ strictMode = true })

Net.defineMany({
    {name = "ValidEvent", type = "Event"},
})

-- This works
Net.on("ValidEvent", handler)

-- This ERRORS — typo!
Net.fire("ValidEvet", player, data)
-- [RoNet] Strict mode: remote 'ValidEvet' was not defined. Use Net.define() first.
```

---

### Advanced: Direct Server/Client APIs

For cases where you need explicit control, access the raw modules:

```lua
local Net = require(ReplicatedStorage.RoNet)

-- Always use server API regardless of context
Net.Server.on("Event", handler)
Net.Server.fire("Event", player, data)
Net.Server.invokeAsync("Func", player, 5, arg)

-- Always use client API regardless of context
Net.Client.on("Event", handler)
Net.Client.fire("Event", data)
Net.Client.invokeAsync("Func", 5, arg)
```

---

### Validator (Standalone)

Validate data outside of middleware:

```lua
local Validator = Net.Validator

local valid, err = Validator.validate({"hello", 42}, {"string", "number"})
-- valid = true

local valid, err = Validator.validate({"hello", true}, {"string", "number"})
-- valid = false, err = "Argument #2: Expected number, got boolean"
```

## Examples

### Basic Event
```lua
-- Server
Net.on("Chat", function(player, message)
    Net.fireAll("ChatMessage", player.Name, message)
end)

-- Client
Net.on("ChatMessage", function(name, msg)
    print(string.format("[%s]: %s", name, msg))
end)

Net.fire("Chat", "Hello world!")
```

### Namespace Organization
```lua
local Combat = Net.namespace("Combat")
local Economy = Net.namespace("Economy")

Combat:on("Damage", function(player, target, amount) ... end)
Economy:on("Purchase", function(player, itemId) ... end)
```

### With Validation & Rate Limiting
```lua
Net.on("Purchase", function(player, itemId, quantity)
    -- Process purchase
end, {
    Middleware.Validate({"string", "number"}),
    Middleware.RateLimit(2, 4),  -- 2 purchases/sec
    Middleware.Logger(),
})
```

### RemoteFunction with Timeout
```lua
-- Server
Net.onInvoke("GetInventory", function(player)
    return inventoryService:Get(player)
end)

-- Client — safe from hanging
Net.invokeAsync("GetInventory", 5)
    :andThen(function(inventory)
        for _, item in ipairs(inventory) do
            print(item.name)
        end
    end)
    :catch(function(err)
        warn("Failed to load inventory:", err)
    end)
```

### Once / Wait Patterns
```lua
-- Fire exactly once
Net.once("BossSpawned", function(bossName)
    print("Boss appeared:", bossName)
end)

-- Wait for event with timeout
local winner = Net.wait("MatchEnd", 60)
```

### Serialization
```lua
local data = {
    color = ColorSequence.new({...}),
    pos = CFrame.new(10, 5, 20),
}
Net.fire("UpdateEffect", Net.serialize(data))
```

### Disconnect Temporary Listeners
```lua
local conn = Net.on("MinigameScore", function(score)
    updateUI(score)
end)

-- When minigame ends:
conn:Disconnect()
-- Or: Net.off("MinigameScore")
```

### Bindable (Decoupled Modules)
```lua
-- LeaderboardModule.lua
Net.Bindable.on("ScoreUpdated", function(playerId, score)
    leaderboard:Update(playerId, score)
end)

-- GameLogicModule.lua
Net.Bindable.fire("ScoreUpdated", player.UserId, newScore)
```

## Project Structure

```
ro-net/
├── src/
│   ├── init.lua          -- Main entry point, unified API
│   ├── Internal.lua      -- Remote instance lifecycle & registry
│   ├── Server.lua        -- Server-side event/function handlers
│   ├── Client.lua        -- Client-side event/function handlers
│   ├── Middleware.lua    -- Built-in middleware + execution pipeline
│   ├── Validator.lua     -- Runtime payload validation
│   ├── Promise.lua       -- Lightweight async primitive
│   ├── Bindable.lua      -- Same-context messaging
│   ├── Namespace.lua     -- Scoped remote registry
│   ├── Utilities.lua     -- once() and wait() helpers
│   ├── Serializer.lua    -- Roblox type serialization
│   ├── Profiler.lua      -- Network performance metrics
│   ├── Types.lua         -- Luau type definitions
│   ├── Zone.lua          -- Spatial zone filtering for interest management
│   ├── Observable.lua    -- Reactive state synchronization helpers
│   ├── PlayerObservable.lua -- Per-player reactive state synchronization
│   ├── TeamObservable.lua -- Per-team reactive state synchronization
│   ├── Computed.lua      -- Derived/computed observable helpers
│   ├── Channel.lua       -- Scoped subscription rooms for arbitrary grouping
│   └── Batch.lua         -- Batch multiple events into a single network call
├── examples/             -- Working examples for every feature
├── tests/                -- Studio test runner
├── demo/                 -- Full working game demo
├── default.project.json  -- Rojo project file
├── wally.toml           -- Wally package manifest
├── index.d.ts           -- TypeScript declarations (roblox-ts)
├── .github/workflows/    -- CI pipeline
├── LICENSE              -- MIT License
├── CONTRIBUTING.md      -- Contribution guidelines
└── README.md            -- This file
```

## Why RoNet?

| Feature | Vanilla Roblox | RoNet |
|---|---|---|
| Create remotes | Manual in Studio | Auto-created in code |
| Listen to events | `:OnServerEvent:Connect()` | `.on()` |
| Fire events | `:FireClient()` / `:FireServer()` | `.fire()` |
| Type safety | None | Built-in validation |
| Rate limiting | Manual | One-line middleware |
| Logging | Manual | One-line middleware |
| Auth checks | Manual | One-line middleware |
| Async invoke timeout | None | Built-in with Promise |
| Same-context messaging | BindableEvents manually | `.Bindable` API |
| Strict mode | None | Catch typos at runtime |
| Namespaces | None | Scoped remote organization |
| Auto-disconnect | Manual | `.once()` |
| Event waiting | Manual | `.wait()` |
| Complex type sending | Manual conversion | `.serialize()` / `.deserialize()` |
| Network profiling | Manual | Built-in metrics |
| Lines for basic remote | ~15-20 | ~3-5 |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, style guide, and PR process.

Quick start:
```bash
git clone https://github.com/levicta/ro-net.git
cd ro-net
# Install luau-lsp and selene for type checking and linting
```

## License

MIT — see [LICENSE](LICENSE) for details.

## Roadmap

- [x] Promise-based async invoke with timeout
- [x] BindableEvent wrapper for same-context communication
- [x] Strict mode (error on unvalidated remotes)
- [x] Connection cleanup / `.off()`
- [x] TypeScript type definitions (`.d.ts`)
- [x] GitHub Actions CI
- [x] Namespaces for scoped remotes
- [x] `.once()` and `.wait()` utilities
- [x] Serialization for complex Roblox types
- [ ] Automatic compression for large payloads
- [ ] Plugin for Studio remote visualization
- [ ] Built-in analytics middleware
- [x] Network profiler (latency, frequency, payload size)
