--!strict
-- Client-to-Server Invoke Example (Client)
-- Client responds to server invocations.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.onInvoke("GetClientSetting", function(settingName: string)
	local settings = {
		volume = 0.8,
		fov = 70,
		vsync = true,
	}
	return settings[settingName]
end)
