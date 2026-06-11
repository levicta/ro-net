--!strict
-- Computed
-- Derived / computed observables that recalculate when dependencies change.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Internal = require(script.Parent.Internal)

local Computed = {}
Computed.__index = Computed

export type Computed<T> = {
	name: string,
	fn: (...any) -> any,
	dependencies: {any},
	value: T?,
	onChangeCallbacks: {(...any) -> ()},
	connections: {RBXScriptConnection},
	connection: RBXScriptConnection?,
}

local instances: {[string]: Computed<any>} = {}
local playerInstances: {[string]: Computed<any>} = {}
local teamInstances: {[string]: Computed<any>} = {}

local function getRemote(name: string, prefix: string): RemoteEvent
	return Internal.createRemote(prefix .. name, "Event") :: RemoteEvent
end

local function getScope(dependencies: {any}): string?
	if #dependencies == 0 then
		return nil
	end
	local firstScope = dependencies[1].scope
	for _, dep in ipairs(dependencies) do
		if dep.scope ~= firstScope then
			return nil
		end
	end
	return firstScope
end

function Computed.new(name: string, fn: (...any) -> any, dependencies: {any}): Computed<any>
	if instances[name] then
		return instances[name]
	end

	local self: Computed<any> = setmetatable({}, Computed) :: any
	self.name = name
	self.fn = fn
	self.dependencies = dependencies
	self.value = nil
	self.onChangeCallbacks = {}
	self.connections = {}
	self.connection = nil

	if Internal.isServer then
		local remote = getRemote(name, "__RoNetComputed_")

		local function recalculate()
			local values = {}
			for i, dep in ipairs(dependencies) do
				values[i] = dep:get()
			end
			local newValue = fn(table.unpack(values))

			if newValue ~= self.value then
				self.value = newValue
				remote:FireAllClients(newValue)
				for _, cb in ipairs(self.onChangeCallbacks) do
					task.spawn(cb, newValue)
				end
			end
		end

		for _, dep in ipairs(dependencies) do
			local conn = dep:onChange(function()
				recalculate()
			end)
			table.insert(self.connections, conn)
		end

		recalculate()
	else
		local remote = getRemote(name, "__RoNetComputed_")

		self.connection = remote.OnClientEvent:Connect(function(newValue)
			self.value = newValue
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, newValue)
			end
		end)
	end

	instances[name] = self
	return self :: Computed<any>
end

function Computed.player(name: string, fn: (Player, ...any) -> any, dependencies: {any}): Computed<any>
	if playerInstances[name] then
		return playerInstances[name]
	end

	local self: Computed<any> = setmetatable({}, Computed) :: any
	self.name = name
	self.fn = fn
	self.dependencies = dependencies
	self.value = nil
	self.onChangeCallbacks = {}
	self.connections = {}
	self.connection = nil

	if Internal.isServer then
		local remote = getRemote(name, "__RoNetPlayerComputed_")
		local playerValues: {[number]: any} = {}

		local function recalculate(player: Player)
			local values = {}
			for i, dep in ipairs(dependencies) do
				values[i] = dep:get(player)
			end
			local newValue = fn(player, table.unpack(values))

			if newValue ~= playerValues[player.UserId] then
				playerValues[player.UserId] = newValue
				remote:FireClient(player, newValue)
				for _, cb in ipairs(self.onChangeCallbacks) do
					task.spawn(cb, player, newValue)
				end
			end
		end

		for _, dep in ipairs(dependencies) do
			local conn = dep:onChange(function(player)
				recalculate(player)
			end)
			table.insert(self.connections, conn)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			recalculate(player)
		end
	else
		local remote = getRemote(name, "__RoNetPlayerComputed_")

		self.connection = remote.OnClientEvent:Connect(function(newValue)
			self.value = newValue
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, newValue)
			end
		end)
	end

	playerInstances[name] = self
	return self :: Computed<any>
end

function Computed.team(name: string, fn: (Team, ...any) -> any, dependencies: {any}): Computed<any>
	if teamInstances[name] then
		return teamInstances[name]
	end

	local self: Computed<any> = setmetatable({}, Computed) :: any
	self.name = name
	self.fn = fn
	self.dependencies = dependencies
	self.value = nil
	self.onChangeCallbacks = {}
	self.connections = {}
	self.connection = nil

	if Internal.isServer then
		local remote = getRemote(name, "__RoNetTeamComputed_")
		local teamValues: {[string]: any} = {}

		local function recalculate(team: Team)
			local values = {}
			for i, dep in ipairs(dependencies) do
				values[i] = dep:get(team)
			end
			local newValue = fn(team, table.unpack(values))

			if newValue ~= teamValues[team.Name] then
				teamValues[team.Name] = newValue
				local firstDep = dependencies[1]
				local members = firstDep._teamMembers and firstDep._teamMembers[team.Name] or {}
				for _, player in ipairs(members) do
					task.spawn(function()
						remote:FireClient(player, newValue)
					end)
				end
				for _, cb in ipairs(self.onChangeCallbacks) do
					task.spawn(cb, team, newValue)
				end
			end
		end

		for _, dep in ipairs(dependencies) do
			local conn = dep:onChange(function(team)
				recalculate(team)
			end)
			table.insert(self.connections, conn)
		end

		for _, team in ipairs(Teams:GetTeams()) do
			recalculate(team)
		end
	else
		local remote = getRemote(name, "__RoNetTeamComputed_")

		self.connection = remote.OnClientEvent:Connect(function(newValue)
			self.value = newValue
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, newValue)
			end
		end)
	end

	teamInstances[name] = self
	return self :: Computed<any>
end

function Computed:get(): any
	return self.value
end

function Computed:onChange(callback: (...any) -> ())
	table.insert(self.onChangeCallbacks, callback)
end

function Computed:destroy()
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	self.connections = {}
	self.onChangeCallbacks = {}
	instances[self.name] = nil
	playerInstances[self.name] = nil
	teamInstances[self.name] = nil
end

return Computed
