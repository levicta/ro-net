--!strict
-- Full Game Demo (Server)
-- A complete mini-system showing RoNet in a real game context.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

-- Define all remotes upfront
Net.defineMany({
	{name = "PlayerJoined", type = "Event"},
	{name = "PlayerLeft", type = "Event"},
	{name = "DamageDealt", type = "Event"},
	{name = "GetStats", type = "Function"},
	{name = "EquipItem", type = "Event"},
})

local playerStats: {[number]: {health: number, kills: number, deaths: number}} = {}

Players.PlayerAdded:Connect(function(player: Player)
	playerStats[player.UserId] = {health = 100, kills = 0, deaths = 0}
	Net.fireAll("PlayerJoined", player.Name, player.UserId)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerStats[player.UserId] = nil
	Net.fireAll("PlayerLeft", player.Name)
end)

Net.on("DamageDealt", function(attacker: Player, targetId: number, damage: number)
	targetId = tonumber(targetId) :: number
	damage = math.clamp(damage, 0, 100)

	local target = Players:GetPlayerByUserId(targetId)
	if target and playerStats[target.UserId] then
		playerStats[target.UserId].health -= damage
		if playerStats[target.UserId].health <= 0 then
			playerStats[target.UserId].deaths += 1
			playerStats[attacker.UserId].kills += 1
			playerStats[target.UserId].health = 100
		end
	end
end, {
	Middleware.Validate({"number", "number"}),
	Middleware.RateLimit(10, 15),
	Middleware.Logger(),
})

Net.onInvoke("GetStats", function(player: Player)
	return playerStats[player.UserId] or {health = 100, kills = 0, deaths = 0}
end)

Net.on("EquipItem", function(player: Player, itemId: string)
	print(player.Name .. " equipped item: " .. itemId)
end, {
	Middleware.Validate({"string"}),
	Middleware.Debounce(1),
})

print("[RoNet] Game demo server initialized.")
