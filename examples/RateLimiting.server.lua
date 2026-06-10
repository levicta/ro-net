--!strict
-- Rate Limiting Example (Server)
-- Prevents players from spamming a remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

Net.on("Attack", function(player: Player, targetId: number)
	print(player.Name, "attacked player", targetId)
end, {
	-- Max 5 attacks per second with burst of 8
	Middleware.RateLimit(5, 8),
	Middleware.Logger(),
})
