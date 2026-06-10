--!strict
-- Client UI Demo

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Player joined/left notifications
Net.on("PlayerJoined", function(name: string, userId: number)
	print("[Chat] " .. name .. " joined the server!")
end)

Net.on("PlayerLeft", function(name: string)
	print("[Chat] " .. name .. " left the server.")
end)

-- Update coins display
Net.on("UpdateCoins", function(coins: number)
	print("[UI] Coins:", coins)
end)

-- Announcements
Net.on("Announcement", function(message: string)
	print("[ANNOUNCEMENT] " .. message)
end)

-- Kill feed
Net.on("KillFeed", function(killer: string, victim: string)
	print(string.format("[Kill Feed] %s eliminated %s!", killer, victim))
end)

-- Request stats on spawn
local stats = Net.invoke("GetStats")
print("[UI] My stats:", stats)
