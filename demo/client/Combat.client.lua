--!strict
-- Client Combat Demo

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local UserInputService = game:GetService("UserInputService")

Net.on("UpdateHealth", function(health: number)
	print("[Combat] Health:", health)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
		-- In a real game, you'd raycast to find the target
		local targetId = 12345 -- placeholder
		Net.fire("DamageDealt", targetId, 25)
	end
end)
