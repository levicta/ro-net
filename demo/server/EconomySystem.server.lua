--!strict
-- Economy System Demo

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

local inventories: {[number]: {string}} = {}

Net.on("Purchase", function(player: Player, itemId: string, cost: number)
	-- In a real game, check DataStore for funds
	print(player.Name .. " purchased " .. itemId .. " for " .. cost .. " coins")

	if not inventories[player.UserId] then
		inventories[player.UserId] = {}
	end

	table.insert(inventories[player.UserId], itemId)
	Net.fire("PurchaseSuccess", player, itemId)
end, {
	Middleware.Validate({"string", "number"}),
	Middleware.RateLimit(2, 3),
	Middleware.Logger(),
})

Net.onInvoke("GetInventory", function(player: Player)
	return inventories[player.UserId] or {}
end)
