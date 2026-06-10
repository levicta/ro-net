--!strict
-- Broadcasting Example (Client)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.on("ChatMessage", function(senderName: string, message: string)
	print(string.format("[%s]: %s", senderName, message))
end)

-- Send a chat message to the server
Net.fire("SendChat", "Hello everyone!")
