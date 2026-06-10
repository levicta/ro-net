--!strict
-- Serialization Example
-- Send complex Roblox types over remotes automatically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Server
if game:GetService("RunService"):IsServer() then
	Net.define("UpdateTrail", "Event")
	Net.define("SetPartColor", "Event")
	Net.define("UpdateUI", "Event")

	Net.on("RequestTrail", function(player: Player)
		local trailData = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255)),
			}),
			width = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2),
				NumberSequenceKeypoint.new(1, 0.5),
			}),
			position = CFrame.new(10, 5, 20),
			rect = Rect.new(0, 0, 100, 100),
		}

		-- Serialize before sending
		local serialized = Net.serialize(trailData)
		Net.fire("UpdateTrail", player, serialized)
	end)
else
	-- Client
	Net.on("UpdateTrail", function(data)
		-- Deserialize back to native types
		local trailData = Net.deserialize({data})[1]

		print("ColorSequence:", trailData.color)
		print("NumberSequence:", trailData.width)
		print("CFrame:", trailData.position)
		print("Rect:", trailData.rect)

		-- All types are fully reconstructed
		assert(typeof(trailData.color) == "ColorSequence")
		assert(typeof(trailData.width) == "NumberSequence")
		assert(typeof(trailData.position) == "CFrame")
		assert(typeof(trailData.rect) == "Rect")
	end)

	Net.fire("RequestTrail")
end
