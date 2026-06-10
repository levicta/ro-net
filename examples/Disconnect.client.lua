--!strict
-- Disconnect Example
-- Clean up temporary listeners to prevent memory leaks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Temporary listener for a minigame
local conn = Net.on("MinigameScore", function(score: number)
	print("Score update:", score)
end)

-- Later, when the minigame ends:
conn:Disconnect()
-- OR use the off() helper:
-- Net.off("MinigameScore")

-- Reconnect when needed
Net.on("MinigameScore", function(score: number)
	print("Reconnected! Score:", score)
end)
