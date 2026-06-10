--!strict
-- Strict Mode Example
-- Catches typos and undefined remotes at runtime.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Enable strict mode BEFORE any other calls
Net.configure({
	strictMode = true,
})

-- Define all remotes upfront
Net.defineMany({
	{name = "ValidEvent", type = "Event"},
	{name = "ValidFunc", type = "Function"},
})

-- This works — remote was defined
Net.on("ValidEvent", function(player, data)
	print(data)
end)

-- This will ERROR in strict mode — typo!
-- Net.fire("ValidEvet", player, "hello")  -- ERROR: remote not defined

-- This will ERROR — never defined
-- Net.on("UndefinedRemote", function() end)  -- ERROR: remote not defined

-- Check if a remote is defined before using it
if Net.isDefined("ValidEvent") then
	print("ValidEvent is ready")
end
