--!strict
-- Basic Event Example (Server)
-- Demonstrates the simplest possible server-to-client event.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Define the remote (creates RemoteEvent in ReplicatedStorage)
Net.define("UpdateCoins", "Event")

-- Listen for client events
Net.on("RequestCoins", function(player: Player, action: string)
	print(player.Name .. " requested coins with action: " .. action)
	Net.fire("UpdateCoins", player, 100)
end)
