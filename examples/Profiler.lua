--!strict
-- Profiler Example
-- Monitor remote performance in real-time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Enable profiling on specific remotes
Net.profile("DamageDealt")
Net.profile("Purchase")
Net.profile("GetInventory")

-- Or enable globally (profiles ALL remotes)
-- Net.profile()

-- Server
if game:GetService("RunService"):IsServer() then
	Net.defineMany({
		{name = "DamageDealt", type = "Event"},
		{name = "Purchase", type = "Event"},
		{name = "GetInventory", type = "Function"},
	})

	Net.on("DamageDealt", function(player, targetId, damage)
		-- Simulate some work
		task.wait(0.001)
	end)

	Net.on("Purchase", function(player, itemId)
		-- Simulate DB lookup
		task.wait(0.005)
	end)

	Net.onInvoke("GetInventory", function(player)
		-- Simulate large data fetch
		task.wait(0.01)
		return {"sword", "shield", "potion"}
	end)

	-- Print metrics every 10 seconds
	task.spawn(function()
		while true do
			task.wait(10)
			print("\n" .. Net.profilerReport())
		end
	end)
else
	-- Client — spam some remotes to generate metrics
	task.spawn(function()
		for i = 1, 50 do
			Net.fire("DamageDealt", i, 25)
			task.wait(0.05)
		end
	end)

	task.spawn(function()
		for i = 1, 20 do
			Net.fire("Purchase", "item_" .. i)
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		for i = 1, 10 do
			local inv = Net.invoke("GetInventory")
			task.wait(0.2)
		end
	end)

	-- Check metrics after 5 seconds
	task.delay(5, function()
		local damageMetrics = Net.getMetrics("DamageDealt")
		if damageMetrics then
			print("DamageDealt metrics:")
			print("  Calls:", damageMetrics.callCount)
			print("  Avg latency:", damageMetrics.avgLatency * 1000, "ms")
			print("  Calls/sec:", damageMetrics.callsPerSecond)
			print("  Errors:", damageMetrics.errors)
		end
	end)
end
