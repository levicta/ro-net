--!strict
-- Batch
-- Batch multiple events into a single network call to reduce per-RemoteEvent overhead.

local Players = game:GetService("Players")
local Internal = require(script.Parent.Internal)
local Client = require(script.Parent.Client)

local Batch = {}
local BATCH_REMOTE_NAME = "__RoNetBatch"

export type BatchEvent = {
	name: string,
	args: {any},
}

local remote: RemoteEvent? = nil

local function getRemote(): RemoteEvent
	if remote then
		return remote
	end
	remote = Internal.createRemote(BATCH_REMOTE_NAME, "Event") :: RemoteEvent
	return remote
end

local function dispatch(player: Player, events: {BatchEvent})
	for _, event in ipairs(events) do
		task.spawn(function()
			Client.dispatch(event.name, player, table.unpack(event.args))
		end)
	end
end

function Batch.send(player: Player, events: {BatchEvent})
	local r = getRemote()
	task.spawn(function()
		r:FireClient(player, events)
	end)
end

function Batch.sendAll(events: {BatchEvent})
	local r = getRemote()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			r:FireClient(player, events)
		end)
	end
end

function Batch.sendExcept(exceptPlayer: Player, events: {BatchEvent})
	local r = getRemote()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= exceptPlayer then
			task.spawn(function()
				r:FireClient(player, events)
			end)
		end
	end
end

local function onClientEvent(events: {BatchEvent})
	for _, event in ipairs(events) do
		task.spawn(function()
			Client.dispatch(event.name, nil, table.unpack(event.args))
		end)
	end
end

function Batch.init()
	local r = getRemote()
	r.OnClientEvent:Connect(onClientEvent)
end

return Batch
