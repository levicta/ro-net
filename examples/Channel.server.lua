--!strict
-- Example: Channel-based Subscription Rooms — Server

local Net = require(game.ReplicatedStorage.RoNet)

-- Create/get channels
local lobby = Net.channel("lobby")
local dungeon = Net.channel("dungeon-1")

-- Join players to channels
lobby:join(player)
dungeon:join(player)

-- Check membership
if lobby:has(player) then
    print("Player is in lobby")
end

-- Fire to all channel members
lobby:fire("ChatMessage", player.Name, "Hello lobby!")
dungeon:fire("DungeonEvent", "Boss spawned!")

-- Fire to all except one
lobby:fireExcept("PrivateMsg", excludedPlayer, "Secret message")

-- Get all members
local members = lobby:getPlayers()
for _, member in ipairs(members) do
    print(member.Name)
end

-- Cleanup
lobby:destroy()
