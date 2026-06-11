--!strict
-- Namespace
-- Scoped remote registry to prevent naming collisions in large projects.
--
-- Usage:
--   local PlayerNet = Net.namespace("Player")
--   PlayerNet.on("Damage", handler)      -- remote name: "Player.Damage"
--   PlayerNet.fire("Damage", player, 10) -- fires "Player.Damage"

local Internal = require(script.Parent.Internal)
local Server = require(script.Parent.Server)
local Client = require(script.Parent.Client)
local Types = require(script.Parent.Types)
local Observable = require(script.Parent.Observable)
local PlayerObservable = require(script.Parent.PlayerObservable)
local TeamObservable = require(script.Parent.TeamObservable)
local Computed = require(script.Parent.Computed)
local Channel = require(script.Parent.Channel)

local Namespace = {}
Namespace.__index = Namespace

export type Namespace = {
	name: string,
	on: (self: Namespace, remote: string, handler: (...any) -> (), middleware: Types.Middleware?) -> RBXScriptConnection?,
	off: (self: Namespace, remote: string) -> (),
	fire: (self: Namespace, remote: string, ...any) -> (),
	fireAll: (self: Namespace, remote: string, ...any) -> (),
	fireExcept: (self: Namespace, remote: string, exceptPlayer: Player, ...any) -> (),
	fireInZone: (self: Namespace, remote: string, zoneData: Types.Zone, ...any) -> (),
	fireExceptInZone: (self: Namespace, remote: string, zoneData: Types.Zone, exceptPlayer: Player, ...any) -> (),
	onInvoke: (self: Namespace, remote: string, handler: (...any) -> any, middleware: Types.Middleware?) -> (),
	invoke: (self: Namespace, remote: string, ...any) -> any,
	invokeAsync: (self: Namespace, remote: string, timeout: number?, ...any) -> any,
	define: (self: Namespace, remote: string, remoteType: Types.RemoteType) -> (RemoteEvent | RemoteFunction)?,
	defineMany: (self: Namespace, definitions: {{name: string, type: Types.RemoteType}}) -> (),
	isDefined: (self: Namespace, remote: string) -> boolean,
	observable: (self: Namespace, remote: string, initialValue: any) -> Observable.Observable<any>,
	fireBatch: (self: Namespace, player: Player, events: {Types.BatchEvent}) -> (),
	fireBatchAll: (self: Namespace, events: {Types.BatchEvent}) -> (),
	fireBatchExcept: (self: Namespace, exceptPlayer: Player, events: {Types.BatchEvent}) -> (),
	playerObservable: (self: Namespace, remote: string, initialValue: any) -> PlayerObservable.PlayerObservable<any>,
	teamObservable: (self: Namespace, remote: string, initialValue: any) -> TeamObservable.TeamObservable<any>,
	computed: (self: Namespace, remote: string, fn: (...any) -> any, dependencies: {any}) -> Computed.Computed<any>,
	playerComputed: (self: Namespace, remote: string, fn: (...any) -> any, dependencies: {any}) -> Computed.Computed<any>,
	teamComputed: (self: Namespace, remote: string, fn: (...any) -> any, dependencies: {any}) -> Computed.Computed<any>,
	channel: (self: Namespace, name: string) -> Channel.Channel,
}

local function qualify(ns: string, name: string): string
	return ns .. "." .. name
end

function Namespace.new(name: string): Namespace
	local self = setmetatable({}, Namespace) :: any
	self.name = name
	return self :: Namespace
end

function Namespace:on(remote: string, handler: (...any) -> (), middleware: Types.Middleware?): RBXScriptConnection?
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		return Server.on(fullName, handler :: any, middleware)
	else
		return Client.on(fullName, handler, middleware)
	end
end

function Namespace:off(remote: string)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.off(fullName)
	else
		Client.off(fullName)
	end
end

function Namespace:fire(remote: string, ...)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.fire(fullName, ...)
	else
		Client.fire(fullName, ...)
	end
end

function Namespace:fireAll(remote: string, ...)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.fireAll(fullName, ...)
	else
		warn(string.format("[RoNet] fireAll is server-only (namespace '%s')", self.name))
	end
end

function Namespace:fireExcept(remote: string, exceptPlayer: Player, ...)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.fireExcept(fullName, exceptPlayer, ...)
	else
		warn(string.format("[RoNet] fireExcept is server-only (namespace '%s')", self.name))
	end
end

function Namespace:fireInZone(remote: string, zoneData: Types.Zone, ...)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.fireInZone(fullName, zoneData, ...)
	else
		warn(string.format("[RoNet] fireInZone is server-only (namespace '%s')", self.name))
	end
end

function Namespace:fireExceptInZone(remote: string, zoneData: Types.Zone, exceptPlayer: Player, ...)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.fireExceptInZone(fullName, zoneData, exceptPlayer, ...)
	else
		warn(string.format("[RoNet] fireExceptInZone is server-only (namespace '%s')", self.name))
	end
end

function Namespace:onInvoke(remote: string, handler: (...any) -> any, middleware: Types.Middleware?)
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		Server.onInvoke(fullName, handler :: any, middleware)
	else
		Client.onInvoke(fullName, handler)
	end
end

function Namespace:invoke(remote: string, ...): any
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		return Server.invoke(fullName, ...)
	else
		return Client.invoke(fullName, ...)
	end
end

function Namespace:invokeAsync(remote: string, timeout: number?, ...): any
	local fullName = qualify(self.name, remote)
	if Internal.isServer then
		return Server.invokeAsync(fullName, timeout, ...)
	else
		return Client.invokeAsync(fullName, timeout, ...)
	end
end

function Namespace:define(remote: string, remoteType: Types.RemoteType): (RemoteEvent | RemoteFunction)?
	if not Internal.isServer then
		warn(string.format("[RoNet] define is server-only (namespace '%s')", self.name))
		return nil
	end
	local fullName = qualify(self.name, remote)
	return Internal.createRemote(fullName, remoteType)
end

function Namespace:defineMany(definitions: {{name: string, type: Types.RemoteType}})
	if not Internal.isServer then return end
	for _, def in ipairs(definitions) do
		Internal.createRemote(qualify(self.name, def.name), def.type)
	end
end

function Namespace:isDefined(remote: string): boolean
	return Internal.isDefined(qualify(self.name, remote))
end

function Namespace:observable(remote: string, initialValue: any): Observable.Observable<any>
	local fullName = qualify(self.name, remote)
	return Observable.new(fullName, initialValue)
end

function Namespace:fireBatch(player: Player, events: {Types.BatchEvent})
	local fullNameEvents: {Types.BatchEvent} = {}
	for _, event in ipairs(events) do
		table.insert(fullNameEvents, {
			name = qualify(self.name, event.name),
			args = event.args,
		})
	end
	Server.fireBatch(player, fullNameEvents)
end

function Namespace:fireBatchAll(events: {Types.BatchEvent})
	local fullNameEvents: {Types.BatchEvent} = {}
	for _, event in ipairs(events) do
		table.insert(fullNameEvents, {
			name = qualify(self.name, event.name),
			args = event.args,
		})
	end
	Server.fireBatchAll(fullNameEvents)
end

function Namespace:fireBatchExcept(exceptPlayer: Player, events: {Types.BatchEvent})
	local fullNameEvents: {Types.BatchEvent} = {}
	for _, event in ipairs(events) do
		table.insert(fullNameEvents, {
			name = qualify(self.name, event.name),
			args = event.args,
		})
	end
	Server.fireBatchExcept(exceptPlayer, fullNameEvents)
end

function Namespace:playerObservable(remote: string, initialValue: any): PlayerObservable.PlayerObservable<any>
	local fullName = qualify(self.name, remote)
	return PlayerObservable.new(fullName, initialValue)
end

function Namespace:teamObservable(remote: string, initialValue: any): TeamObservable.TeamObservable<any>
	local fullName = qualify(self.name, remote)
	return TeamObservable.new(fullName, initialValue)
end

function Namespace:computed(remote: string, fn: (...any) -> any, dependencies: {any}): Computed.Computed<any>
	local fullName = qualify(self.name, remote)
	return Computed.new(fullName, fn, dependencies)
end

function Namespace:playerComputed(remote: string, fn: (...any) -> any, dependencies: {any}): Computed.Computed<any>
	local fullName = qualify(self.name, remote)
	return Computed.player(fullName, fn, dependencies)
end

function Namespace:teamComputed(remote: string, fn: (...any) -> any, dependencies: {any}): Computed.Computed<any>
	local fullName = qualify(self.name, remote)
	return Computed.team(fullName, fn, dependencies)
end

function Namespace:channel(name: string): Channel.Channel
	local fullName = qualify(self.name, name)
	return Channel.new(fullName)
end

return Namespace
