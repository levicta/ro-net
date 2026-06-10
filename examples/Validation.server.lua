--!strict
-- Validation Example (Server)
-- Shows how to enforce type safety on incoming data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

Net.on("TeleportTo", function(player: Player, position: Vector3, targetName: string?)
	print(player.Name, "teleporting to", position)
	-- Safe to use position as Vector3 — validation already passed
end, {
	-- Schema: arg1 must be Vector3, arg2 is optional string
	Middleware.Validate({"Vector3", {type = "string", optional = true}}),
	Middleware.Logger(),
})
