--!strict
-- Example: Batch Firing — Client

local Net = require(game.ReplicatedStorage.RoNet)

-- Clients still define remotes normally; the batch system just
-- dispatches the events automatically on receipt.
Net.on("HealthChanged", function(newHealth)
    healthBar.Value = newHealth
end)

Net.on("PositionChanged", function(pos)
    local hrp = character.HumanoidRootPart
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end)

Net.on("StatusEffect", function(effect)
    statusEffects:Add(effect)
end)

-- No client-side changes needed; batch events arrive and are
-- routed to the correct handlers automatically.

-- Client-side batch firing (manual RemoteEvents) is a v2 addition.
