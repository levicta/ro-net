--!strict
-- Admin Tools Demo

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

local ADMINS = {
	[123456789] = true, -- Replace with actual admin UserIds
}

Net.on("AdminTeleport", function(player: Player, targetName: string, position: Vector3)
	print(player.Name .. " teleported " .. targetName .. " to " .. tostring(position))
end, {
	Middleware.Validate({"string", "Vector3"}),
	Middleware.Auth(function(p)
		return ADMINS[p.UserId] == true
	end),
	Middleware.Logger(),
})

Net.on("Broadcast", function(player: Player, message: string)
	Net.fireAll("Announcement", message)
end, {
	Middleware.Auth(function(p)
		return ADMINS[p.UserId] == true
	end),
	Middleware.Debounce(5),
})
