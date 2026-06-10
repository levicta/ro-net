--!strict
-- Custom Middleware Example (Server)
-- Shows how to write and compose your own middleware.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Middleware = Net.Middleware

-- Custom middleware: only allow players above level 10
local function RequireLevel(minLevel: number)
	return function(context, next)
		local player = context.player
		if not player then return next() end

		-- Imagine we have a DataStore system here
		local level = 15 -- player:GetAttribute("Level") or 1

		if level >= minLevel then
			return next()
		else
			warn(player.Name .. " tried to use a level-locked remote (needs level " .. minLevel .. ")")
			return nil
		end
	end
end

Net.on("OpenVIPShop", function(player: Player)
	print("Opening VIP shop for", player.Name)
end, {
	RequireLevel(10),
	Middleware.Debounce(2), -- 2 second cooldown
	Middleware.Logger(),
})
