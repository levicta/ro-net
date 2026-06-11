--!strict
-- TeamObservable
-- Per-team reactive state synchronization over RemoteEvent.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Internal = require(script.Parent.Internal)

local TeamObservable = {}
TeamObservable.__index = TeamObservable

export type TeamObservable<T> = {
	name: string,
	initialValue: T,
	onChangeCallbacks: {(...any) -> ()},
	connection: RBXScriptConnection?,
	teamAddedConnection: RBXScriptConnection?,
	teamRemovedConnection: RBXScriptConnection?,
	playerAddedConnection: RBXScriptConnection?,
	playerRemovingConnection: RBXScriptConnection?,
	_teamValues: {[string]: any}?,
	_teamMembers: {[string]: {Player}}?,
	_playerTeams: {[Player]: Team}?,
	_teamConnections: {[Player]: RBXScriptConnection}?,
}

local instances: {[string]: TeamObservable<any>} = {}

local function getRemote(name: string): RemoteEvent
	return Internal.createRemote("__RoNetTeamObs_" .. name, "Event") :: RemoteEvent
end

function TeamObservable.new(name: string, initialValue: any): TeamObservable<any>
	if instances[name] then
		return instances[name]
	end

	local self: TeamObservable<any> = setmetatable({}, TeamObservable) :: any
	self.name = name
	self.initialValue = initialValue
	self.onChangeCallbacks = {}
	self.connection = nil
	self.teamAddedConnection = nil
	self.teamRemovedConnection = nil
	self.playerAddedConnection = nil
	self.playerRemovingConnection = nil

	if Internal.isServer then
		local remote = getRemote(name)
		local teamValues: {[string]: any} = {}
		local teamMembers: {[string]: {Player}} = {}
		local playerTeams: {[Player]: Team} = {}
		local teamConnections: {[Player]: RBXScriptConnection} = {}

		self._teamValues = teamValues
		self._teamMembers = teamMembers
		self._playerTeams = playerTeams
		self._teamConnections = teamConnections

		local function broadcast(team: Team, newValue: any)
			for _, player in ipairs(teamMembers[team.Name] or {}) do
				task.spawn(function()
					remote:FireClient(player, newValue)
				end)
			end
			for _, cb in ipairs(self.onChangeCallbacks) do
				task.spawn(cb, team, newValue)
			end
		end

		local function syncPlayer(player: Player)
			local team = player.Team
			if not team then return end

			local oldTeam = playerTeams[player]
			if oldTeam and oldTeam ~= team then
				local oldMembers = teamMembers[oldTeam.Name]
				if oldMembers then
					for i, member in ipairs(oldMembers) do
						if member == player then
							table.remove(oldMembers, i)
							break
						end
					end
				end
			end

			playerTeams[player] = team

			if not teamMembers[team.Name] then
				teamMembers[team.Name] = {}
			end

			local alreadyMember = false
			for _, member in ipairs(teamMembers[team.Name]) do
				if member == player then
					alreadyMember = true
					break
				end
			end

			if not alreadyMember then
				table.insert(teamMembers[team.Name], player)
			end

			broadcast(team, teamValues[team.Name] or initialValue)
		end

		for _, team in ipairs(Teams:GetTeams()) do
			teamValues[team.Name] = initialValue
			teamMembers[team.Name] = {}
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Team then
				playerTeams[player] = player.Team
				if not teamMembers[player.Team.Name] then
					teamMembers[player.Team.Name] = {}
				end
				table.insert(teamMembers[player.Team.Name], player)
				broadcast(player.Team, initialValue)
			end
		end

		self.connection = remote.OnServerEvent:Connect(function(player, newValue)
			local team = player.Team
			if not team then return end

			teamValues[team.Name] = newValue
			broadcast(team, newValue)
		end)

		self.teamAddedConnection = Teams.ChildAdded:Connect(function(team)
			teamValues[team.Name] = initialValue
			teamMembers[team.Name] = {}
		end)

		self.teamRemovedConnection = Teams.ChildRemoved:Connect(function(team)
			teamValues[team.Name] = nil
			teamMembers[team.Name] = nil
		end)

		self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
			local conn = player:GetPropertyChangedSignal("Team"):Connect(function()
				syncPlayer(player)
			end)
			teamConnections[player] = conn
			syncPlayer(player)
		end)

		self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
			local conn = teamConnections[player]
			if conn then
				conn:Disconnect()
				teamConnections[player] = nil
			end

			local team = playerTeams[player]
			if team then
				local members = teamMembers[team.Name]
				if members then
					for i, member in ipairs(members) do
						if member == player then
							table.remove(members, i)
							break
						end
					end
				end
				playerTeams[player] = nil
			end
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
	return self :: TeamObservable<any>
end

function TeamObservable:set(team: Team, newValue: any)
	if Internal.isServer then
		self._teamValues[team.Name] = newValue
		local remote = getRemote(self.name)
		for _, player in ipairs(self._teamMembers[team.Name] or {}) do
			task.spawn(function()
				remote:FireClient(player, newValue)
			end)
		end
		for _, cb in ipairs(self.onChangeCallbacks) do
			task.spawn(cb, team, newValue)
		end
	else
		local remote = getRemote(self.name)
		remote:FireServer(newValue)
	end
end

function TeamObservable:get(team: Team?): any
	if Internal.isServer then
		if not team then
			return self.initialValue
		end
		return self._teamValues[team.Name] or self.initialValue
	else
		return self.initialValue
	end
end

function TeamObservable:onChange(callback: (...any) -> ())
	table.insert(self.onChangeCallbacks, callback)
end

function TeamObservable:destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.teamAddedConnection then
		self.teamAddedConnection:Disconnect()
		self.teamAddedConnection = nil
	end
	if self.teamRemovedConnection then
		self.teamRemovedConnection:Disconnect()
		self.teamRemovedConnection = nil
	end
	if self.playerAddedConnection then
		self.playerAddedConnection:Disconnect()
		self.playerAddedConnection = nil
	end
	if self.playerRemovingConnection then
		self.playerRemovingConnection:Disconnect()
		self.playerRemovingConnection = nil
	end
	if self._teamConnections then
		for _, conn in pairs(self._teamConnections) do
			conn:Disconnect()
		end
		self._teamConnections = nil
	end
	self.onChangeCallbacks = {}
	instances[self.name] = nil
end

return TeamObservable
