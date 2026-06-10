--!strict
-- Client Admin Panel Demo
-- Only works if the player is in the ADMINS list on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- These will be silently blocked by auth middleware if not an admin
Net.fire("AdminTeleport", "SomePlayer", Vector3.new(0, 50, 0))
Net.fire("Broadcast", "Server maintenance in 5 minutes!")
