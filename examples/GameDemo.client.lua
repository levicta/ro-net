--!strict
-- Full Game Demo (Client)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.on("PlayerJoined", function(name: string, userId: number)
	print(name .. " joined the game!")
end)

Net.on("PlayerLeft", function(name: string)
	print(name .. " left the game.")
end)

-- Request stats on spawn
local stats = Net.invoke("GetStats")
print("My stats:", stats)

-- Simulate dealing damage
local function attack(targetId: number, damage: number)
	Net.fire("DamageDealt", targetId, damage)
end

-- Equip an item
Net.fire("EquipItem", "sword_01")
