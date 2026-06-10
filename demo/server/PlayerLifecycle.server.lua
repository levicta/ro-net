--!strict
-- Player Lifecycle Demo

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

local playerData: {[number]: {coins: number, level: number, joined: number}} = {}

Players.PlayerAdded:Connect(function(player: Player)
	playerData[player.UserId] = {
		coins = 100,
		level = 1,
		joined = tick(),
	}

	Net.fireAll("PlayerJoined", player.Name, player.UserId)

	-- Give them their starting coins
	Net.fire("UpdateCoins", player, 100)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerData[player.UserId] = nil
	Net.fireAll("PlayerLeft", player.Name)
end)

Net.onInvoke("GetStats", function(player: Player)
	return playerData[player.UserId] or {coins = 0, level = 0, joined = 0}
end)
