--!strict
-- Promise Invoke Example (Client)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.onInvoke("GetClientSetting", function(settingName: string)
	local settings = {
		fov = 70,
		volume = 0.8,
		vsync = true,
	}
	-- Simulate network delay
	task.wait(0.1)
	return settings[settingName]
end)
