--!strict
-- Utilities Example (Once / Wait)
-- Auto-disconnecting listeners and yielding event waits.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- ONCE: Listen exactly once, then auto-disconnect
Net.once("RoundStart", function(roundNumber: number)
	print("Round " .. roundNumber .. " started! (this prints once)")
end)

-- WAIT: Yield until an event fires (or timeout)
task.spawn(function()
	print("Waiting for RoundEnd...")
	local winner = Net.wait("RoundEnd", 30) -- wait up to 30 seconds
	if winner then
		print("Winner:", winner)
	else
		print("Timed out waiting for round end")
	end
end)

-- Server-side demo
if game:GetService("RunService"):IsServer() then
	Net.define("RoundStart", "Event")
	Net.define("RoundEnd", "Event")

	task.delay(2, function()
		Net.fireAll("RoundStart", 1)
	end)

	task.delay(5, function()
		Net.fireAll("RoundEnd", "TeamA")
	end)
end
