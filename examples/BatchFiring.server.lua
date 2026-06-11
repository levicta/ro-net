--!strict
-- Example: Batch Firing — Server

local Net = require(game.ReplicatedStorage.RoNet)

-- Define some stateful remotes
Net.on("HealthChanged", function(player, newHealth)
    print(player.Name .. " health: " .. newHealth)
end)

Net.on("PositionChanged", function(player, pos)
    -- handle position update
end)

Net.on("StatusEffect", function(player, effect)
    -- handle status effect
end)

-- Instead of three separate FireClient calls:
-- Net.fire("HealthChanged", player, 75)
-- Net.fire("PositionChanged", player, Vector3.new(10, 5, 20))
-- Net.fire("StatusEffect", player, "poison")

-- Coalesce them into a single network packet:
Net.fireBatch(player, {
    {"HealthChanged", 75},
    {"PositionChanged", Vector3.new(10, 5, 20)},
    {"StatusEffect", "poison"},
})

-- Broadcast to all players at once
Net.fireBatchAll({
    {"Announcement", "Round starting!"},
    {"TimerUpdate", 60},
})

-- Broadcast except one player
Net.fireBatchExcept(excludedPlayer, {
    {"ChatMessage", sender.Name, message},
})

-- With namespaces
local Combat = Net.namespace("Combat")
Combat:fireBatch(player, {
    {"Damage", targetId, 25},
    {"Heal", targetId, 10},
})
