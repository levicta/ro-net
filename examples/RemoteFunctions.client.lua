--!strict
-- RemoteFunction Example (Client)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)

local coins = Net.invoke("GetPlayerData", "coins")
print("You have", coins, "coins")

local level = Net.invoke("GetPlayerData", "level")
print("You are level", level)
