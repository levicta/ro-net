--!strict
-- Client Economy Demo

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

Net.on("PurchaseSuccess", function(itemId: string)
	print("[Economy] Successfully purchased:", itemId)
end)

-- Buy an item
Net.fire("Purchase", "sword_01", 50)

-- Check inventory
local inventory = Net.invoke("GetInventory")
print("[Economy] Inventory:", inventory)
