--!strict
-- Observable
-- Reactive state synchronization over RemoteEvent.

local Players = game:GetService("Players")
local Internal = require(script.Parent.Internal)

local Observable = {}
Observable.__index = Observable

export type Observable<T> = {
	name: string,
	initialValue: T,
	value: T,
	onChangeCallbacks: {(...any) -> ()},
	connection: RBXScriptConnection?,
	playerAddedConnection: RBXScriptConnection?,
}

local instances: {[string]: Observable<any>} = {}

local function getRemote(name: string): RemoteEvent
	return Internal.createRemote(name, "Event") :: RemoteEvent
end

function Observable.new(name: string, initialValue: any): Observable<any>
	if instances[name] then
		return instances[name]
	end

	local self: Observable<any> = setmetatable({}, Observable) :: any
	self.name = name
	self.initialValue = initialValue
	self.value = initialValue
	self.onChangeCallbacks = {}
	self.connection = nil
	self.playerAddedConnection = nil

	if Internal.isServer then
		local remote = getRemote(name)

		remote:FireAllClients(initialValue)

		self.connection = remote.OnServerEvent:Connect(function(player, newValue)
			self.value = newValue
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, newValue)
			end
		end)

		self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
			task.spawn(function()
				remote:FireClient(player, self.value)
			end)
		end)
	else
		local remote = getRemote(name)

		self.connection = remote.OnClientEvent:Connect(function(newValue)
			self.value = newValue
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, newValue)
			end
		end)
	end

	instances[name] = self
	return self :: Observable<any>
end

function Observable:set(newValue: any)
	self.value = newValue
	local remote = getRemote(self.name)
	if Internal.isServer then
		remote:FireAllClients(newValue)
	end
end

function Observable:get(): any
	return self.value
end

function Observable:onChange(callback: (...any) -> ())
	table.insert(self.onChangeCallbacks, callback)
end

function Observable:destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.playerAddedConnection then
		self.playerAddedConnection:Disconnect()
		self.playerAddedConnection = nil
	end
	self.onChangeCallbacks = {}
	instances[self.name] = nil
end

return Observable
