--!strict
-- Channel
-- Scoped subscription rooms for arbitrary player grouping.

local Players = game:GetService("Players")
local Internal = require(script.Parent.Internal)
local Server = require(script.Parent.Server)

local Channel = {}
Channel.__index = Channel

export type Channel = {
	name: string,
	members: {[Player]: boolean},
	memberCount: number,
}

local instances: {[string]: Channel} = {}

local function getChannel(name: string): Channel
	if instances[name] then
		return instances[name]
	end

	local self: Channel = setmetatable({}, Channel) :: any
	self.name = name
	self.members = {}
	self.memberCount = 0
	instances[name] = self
	return self :: Channel
end

function Channel.new(name: string): Channel
	return getChannel(name)
end

function Channel:join(player: Player)
	if not self.members[player] then
		self.members[player] = true
		self.memberCount += 1
	end
end

function Channel:leave(player: Player)
	if self.members[player] then
		self.members[player] = nil
		self.memberCount -= 1
	end
end

function Channel:has(player: Player): boolean
	return self.members[player] == true
end

function Channel:getPlayers(): {Player}
	local result: {Player} = {}
	for player in pairs(self.members) do
		table.insert(result, player)
	end
	return result
end

function Channel:fire(name: string, ...)
	for player in pairs(self.members) do
		Server.fire(name, player, ...)
	end
end

function Channel:fireExcept(name: string, exceptPlayer: Player, ...)
	for player in pairs(self.members) do
		if player ~= exceptPlayer then
			Server.fire(name, player, ...)
		end
	end
end

function Channel:destroy()
	self.members = {}
	self.memberCount = 0
	instances[self.name] = nil
end

Players.PlayerRemoving:Connect(function(player)
	for _, channel in pairs(instances) do
		channel:leave(player)
	end
end)

return Channel
