--!strict
-- Broadcasting Example (Server)
-- Fire to all players or all except one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.define("ChatMessage", "Event")

Net.on("SendChat", function(sender: Player, message: string)
	-- Broadcast to everyone EXCEPT the sender
	Net.fireExcept("ChatMessage", sender, sender.Name, message)

	-- Alternatively, send to everyone:
	-- Net.fireAll("ChatMessage", sender.Name, message)
end)
