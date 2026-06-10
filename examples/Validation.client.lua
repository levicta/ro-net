--!strict
-- Validation Example (Client)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.fire("TeleportTo", Vector3.new(10, 5, 20), "SpawnPoint")
-- This will pass validation and be logged on the server.
-- Net.fire("TeleportTo", "not a vector") -- This would be blocked with a warning.
