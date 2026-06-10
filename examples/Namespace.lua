--!strict
-- Namespace Example
-- Organize remotes by domain to prevent naming collisions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Define scoped remotes
local PlayerNet = Net.namespace("Player")
local CombatNet = Net.namespace("Combat")
local EconomyNet = Net.namespace("Economy")

-- Server
if game:GetService("RunService"):IsServer() then
	-- Define remotes in each namespace
	PlayerNet:defineMany({
		{name = "Joined", type = "Event"},
		{name = "Left", type = "Event"},
		{name = "GetData", type = "Function"},
	})

	CombatNet:defineMany({
		{name = "Damage", type = "Event"},
		{name = "Heal", type = "Event"},
		{name = "GetStats", type = "Function"},
	})

	EconomyNet:defineMany({
		{name = "Purchase", type = "Event"},
		{name = "Sell", type = "Event"},
	})

	-- Listen on namespaced remotes
	CombatNet:on("Damage", function(player: Player, targetId: number, amount: number)
		print(player.Name .. " dealt " .. amount .. " damage to " .. targetId)
	end)

	EconomyNet:on("Purchase", function(player: Player, itemId: string)
		print(player.Name .. " bought " .. itemId)
		EconomyNet:fire("PurchaseSuccess", player, itemId)
	end)

	-- Namespaced invoke
	CombatNet:onInvoke("GetStats", function(player: Player)
		return {health = 100, damage = 25}
	end)
else
	-- Client
	CombatNet:on("Damage", function(targetId: number, amount: number)
		print("You took " .. amount .. " damage!")
	end)

	EconomyNet:on("PurchaseSuccess", function(itemId: string)
		print("Successfully purchased: " .. itemId)
	end)

	-- Fire namespaced events
	CombatNet:fire("Damage", 12345, 25)
	EconomyNet:fire("Purchase", "sword_01")

	-- Invoke namespaced function
	local stats = CombatNet:invoke("GetStats")
	print("My combat stats:", stats)
end
