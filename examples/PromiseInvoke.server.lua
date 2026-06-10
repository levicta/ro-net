--!strict
-- Promise Invoke Example (Server)
-- Shows async invoke with timeout — no hanging calls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.define("GetClientSetting", "Function")

-- Fire-and-forget with timeout
Net.on("RequestClientData", function(player: Player)
	-- Ask client for their FOV setting, timeout after 3 seconds
	local promise = Net.invokeAsync("GetClientSetting", player, 3, "fov")

	promise:andThen(function(value)
		print(player.Name .. " FOV:", value)
	end):catch(function(err)
		warn("Failed to get FOV from " .. player.Name .. ": " .. err)
	end)
end)

-- Or await synchronously if you need the value now
Net.on("SyncSettings", function(player: Player)
	local success, value = Net.invokeAsync("GetClientSetting", player, 5, "volume"):await()
	if success then
		print("Volume:", value)
	else
		print("Timed out or errored")
	end
end)
