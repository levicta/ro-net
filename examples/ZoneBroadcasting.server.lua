--!strict
-- Example: Spatial/Zone-Based Broadcasting (Server)

local Net = require(game.ReplicatedStorage.RoNet)

-- Define zones for your minigame or world area
local lobbyZone = Net.Zone.fromPosition(Vector3.new(0, 5, 0), 30)
local arenaZone = Net.Zone.fromCFrame(CFrame.new(100, 10, 100), 75)
local capturePoint = Net.Zone.fromPart(workspace.CapturePoint.PrimaryPart :: BasePart, 20)

-- Fire an event only to players inside the lobby
Net.fireInZone("LobbyWelcome", lobbyZone, "Welcome to the lobby!")

-- Fire an event to all players in a zone except one
Net.fireExceptInZone("ArenaEffect", arenaZone, excludedPlayer, "shield")

-- Query membership manually for custom logic
local nearby = Net.Zone.getPlayersInZone(capturePoint)
for _, player in ipairs(nearby) do
    print(player.Name .. " is near the capture point")
end

-- Check a single player
if Net.Zone.isPlayerInZone(player, capturePoint) then
    -- player is inside
end

-- Works with namespaces too
local Combat = Net.namespace("Combat")
Combat:fireInZone(arenaZone, "AreaDamage", attacker.UserId, 25)
