--!strict
-- Combat System Demo

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

local playerHealth: {[number]: number} = {}

Net.on("DamageDealt", function(attacker: Player, targetId: number, damage: number)
	targetId = tonumber(targetId) :: number
	damage = math.clamp(damage, 0, 100)

	local target = Players:GetPlayerByUserId(targetId)
	if not target then return end

	if not playerHealth[target.UserId] then
		playerHealth[target.UserId] = 100
	end

	playerHealth[target.UserId] -= damage

	if playerHealth[target.UserId] <= 0 then
		playerHealth[target.UserId] = 100
		Net.fireAll("KillFeed", attacker.Name, target.Name)
	end

	Net.fire("UpdateHealth", target, playerHealth[target.UserId])
end, {
	Middleware.Validate({"number", "number"}),
	Middleware.RateLimit(8, 12),
	Middleware.Logger(),
})

Net.on("EquipItem", function(player: Player, itemId: string)
	print(player.Name .. " equipped: " .. itemId)
end, {
	Middleware.Validate({"string"}),
	Middleware.Debounce(0.5),
})
