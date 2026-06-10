--!strict
-- RemoteFunction Example (Server)
-- Server responds to client invocations.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

Net.onInvoke("GetPlayerData", function(player: Player, field: string)
	local data = {
		coins = 100,
		level = 5,
		name = player.Name,
	}
	return data[field]
end, {
	Middleware.Validate({"string"}),
})
