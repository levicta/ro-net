--!strict
-- Client-to-Server Invoke Example (Server)
-- Server asks the client for data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.define("GetClientSetting", "Function")

Net.on("RequestSetting", function(player: Player, settingName: string)
	local value = Net.invoke("GetClientSetting", player, settingName)
	print(player.Name .. "'s " .. settingName .. " = " .. tostring(value))
	return value
end)
