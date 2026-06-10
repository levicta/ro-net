--!strict
-- Bindable Example
-- Same-context messaging (server→server or client→client).
-- Perfect for decoupled module communication without RemoteEvents.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

-- Module A: listens for currency changes
Net.Bindable.on("CurrencyChanged", function(playerId: number, newAmount: number)
	print("[Module A] Player", playerId, "now has", newAmount, "coins")
end)

-- Module B: listens for the same event
Net.Bindable.on("CurrencyChanged", function(playerId: number, newAmount: number)
	print("[Module B] Updating leaderboard for player", playerId)
end)

-- Module C: fires the event (no network, instant)
Net.Bindable.fire("CurrencyChanged", 12345, 500)

-- Bindable Functions (request/response within same context)
Net.Bindable.onInvoke("GetPlayerRank", function(playerId: number)
	return "Gold" -- lookup from local cache
end)

local rank = Net.Bindable.invoke("GetPlayerRank", 12345)
print("Rank:", rank)

-- Disconnect a specific listener when done
-- Net.Bindable.off("CurrencyChanged", myHandler)
