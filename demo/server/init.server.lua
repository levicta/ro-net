--!strict
-- Server Demo Init
-- Bootstraps all server-side demo scripts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Pre-define all remotes so clients never wait
Net.defineMany({
	{name = "PlayerJoined", type = "Event"},
	{name = "PlayerLeft", type = "Event"},
	{name = "ChatMessage", type = "Event"},
	{name = "UpdateCoins", type = "Event"},
	{name = "DamageDealt", type = "Event"},
	{name = "EquipItem", type = "Event"},
	{name = "TeleportTo", type = "Event"},
	{name = "Purchase", type = "Event"},
	{name = "GetStats", type = "Function"},
	{name = "GetInventory", type = "Function"},
	{name = "GetClientSetting", type = "Function"},
})

-- Require all demo modules
require(script.PlayerLifecycle)
require(script.CombatSystem)
require(script.EconomySystem)
require(script.AdminTools)

print("[RoNet Demo] Server initialized with", #game.Players:GetPlayers(), "players")
