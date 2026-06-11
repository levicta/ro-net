--!strict
-- PlayerObservable
-- Per-player reactive state synchronization over RemoteEvent.

local Players = game:GetService("Players")
local Internal = require(script.Parent.Internal)

local PlayerObservable = {}
PlayerObservable.__index = PlayerObservable

export type PlayerObservable<T> = {
	name: string,
	initialValue: T,
	onChangeCallbacks: {(...any) -> ()},
	connection: RBXScriptConnection?,
	playerAddedConnection: RBXScriptConnection?,
	playerRemovingConnection: RBXScriptConnection?,
	_cache: {[number]: any}?,
}

local instances: {[string]: PlayerObservable<any>} = {}

local function getRemote(name: string): RemoteEvent
	return Internal.createRemote("__RoNetPlayerObs_" .. name, "Event") :: RemoteEvent
end

function PlayerObservable.new(name: string, initialValue: any): PlayerObservable<any>
	if instances[name] then
		return instances[name]
	end

	local self: PlayerObservable<any> = setmetatable({}, PlayerObservable) :: any
	self.name = name
	self.initialValue = initialValue
	self.onChangeCallbacks = {}
	self.connection = nil
	self.playerAddedConnection = nil
	self.playerRemovingConnection = nil

	if Internal.isServer then
		local remote = getRemote(name)
		local cache: {[number]: any} = {}

		self._cache = cache

		self.connection = remote.OnServerEvent:Connect(function(player, newValue)
			cache[player.UserId] = newValue
			remote:FireClient(player, newValue)
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, player, newValue)
			end
		end)

		self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
			local current = cache[player.UserId] or initialValue
			cache[player.UserId] = current
			task.spawn(function()
				remote:FireClient(player, current)
			end)
		end)

		self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
			cache[player.UserId] = nil
		end)
	else
		local remote = getRemote(name)

		self.connection = remote.OnClientEvent:Connect(function(newValue)
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, newValue)
			end
		end)
	end

	instances[name] = self
	return self :: PlayerObservable<any>
end

function PlayerObservable:set(player: Player, newValue: any)
	if Internal.isServer then
		self._cache[player.UserId] = newValue
		local remote = getRemote(self.name)
		remote:FireClient(player, newValue)
		for _, cb in ipairs(self.onChangeCallbacks) do
			task.spawn(cb, player, newValue)
		end
	else
		local remote = getRemote(self.name)
		remote:FireServer(newValue)
	end
end

function PlayerObservable:get(player: Player?): any
	if Internal.isServer then
		if not player then
			return self.initialValue
		end
		return self._cache[player.UserId] or self.initialValue
	else
		return self.initialValue
	end
end

function PlayerObservable:onChange(callback: (...any) -> ())
	table.insert(self.onChangeCallbacks, callback)
end

function PlayerObservable:destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.playerAddedConnection then
		self.playerAddedConnection:Disconnect()
		self.playerAddedConnection = nil
	end
	if self.playerRemovingConnection then
		self.playerRemovingConnection:Disconnect()
		self.playerRemovingConnection = nil
	end
	self.onChangeCallbacks = {}
	instances[self.name] = nil
end

return PlayerObservable
