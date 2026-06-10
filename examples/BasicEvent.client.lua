--!strict
-- Basic Event Example (Client)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Listen for server events
Net.on("UpdateCoins", function(coins: number)
	print("Coins updated:", coins)
end)

-- Fire to server
Net.fire("RequestCoins", "get")
