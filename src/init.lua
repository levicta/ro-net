--!strict
-- RoNet
-- A clean, intuitive networking framework for Roblox.
--
-- Usage:
--   local Net = require(path.to.RoNet)
--
--   -- Server
--   Net.on("EventName", function(player, data) ... end)
--   Net.fire("EventName", player, data)
--   Net.onInvoke("FuncName", function(player, id) return result end)
--
--   -- Client
--   Net.on("EventName", function(data) ... end)
--   Net.fire("EventName", data)
--   local result = Net.invoke("FuncName", id)

local Internal = require(script.Internal)
local Server = require(script.Server)
local Client = require(script.Client)
local Middleware = require(script.Middleware)
local Types = require(script.Types)
local Validator = require(script.Validator)
local Promise = require(script.Promise)
local Bindable = require(script.Bindable)
local Namespace = require(script.Namespace)
local Utilities = require(script.Utilities)
local Serializer = require(script.Serializer)
local Profiler = require(script.Profiler)
local Zone = require(script.Zone)
local Observable = require(script.Observable)
local PlayerObservable = require(script.PlayerObservable)
local TeamObservable = require(script.TeamObservable)
local Computed = require(script.Computed)
local Batch = require(script.Batch)

Batch.init()

local RoNet = {}

-- Export submodules for advanced usage
RoNet.Server = Server
RoNet.Client = Client
RoNet.Middleware = Middleware
RoNet.Validator = Validator
RoNet.Types = Types
RoNet.Promise = Promise
RoNet.Bindable = Bindable
RoNet.Namespace = Namespace
RoNet.Utilities = Utilities
RoNet.Serializer = Serializer
RoNet.Profiler = Profiler
RoNet.Zone = Zone
RoNet.Observable = Observable
RoNet.PlayerObservable = PlayerObservable
RoNet.TeamObservable = TeamObservable
RoNet.Computed = Computed
RoNet.Batch = Batch

-- Configuration
function RoNet.configure(config: Types.Config)
	Internal.setConfig(config)
end

-- Namespace factory
function RoNet.namespace(name: string): typeof(Namespace.new(""))
	return Namespace.new(name)
end

-- Utilities (context-aware)
function RoNet.once(name: string, handler: (...any) -> ()): RBXScriptConnection?
	return Utilities.once(name, handler)
end

function RoNet.wait(name: string, timeout: number?): (...any)
	return Utilities.wait(name, timeout)
end

-- Serialization helpers
function RoNet.serialize(...): {any}
	return Serializer.serialize(...)
end

function RoNet.deserialize(args: {any}): {any}
	return Serializer.deserialize(args)
end

-- Profiler
function RoNet.profile(name: string)
	Profiler.enable(name)
end

function RoNet.unprofile(name: string)
	Profiler.disable(name)
end

function RoNet.getMetrics(name: string)
	return Profiler.getMetrics(name)
end

function RoNet.getAllMetrics()
	return Profiler.getAllMetrics()
end

function RoNet.resetMetrics(name: string?)
	Profiler.reset(name)
end

function RoNet.profilerReport(): string
	return Profiler.report()
end

-- Observable factory
function RoNet.observable(name: string, initialValue: any): Observable.Observable<any>
	return Observable.new(name, initialValue)
end

-- PlayerObservable factory
function RoNet.playerObservable(name: string, initialValue: any): PlayerObservable.PlayerObservable<any>
	return PlayerObservable.new(name, initialValue)
end

-- TeamObservable factory
function RoNet.teamObservable(name: string, initialValue: any): TeamObservable.TeamObservable<any>
	return TeamObservable.new(name, initialValue)
end

-- Computed factory
function RoNet.computed(name: string, fn: (...any) -> any, dependencies: {any}): Computed.Computed<any>
	return Computed.new(name, fn, dependencies)
end

-- PlayerComputed factory
function RoNet.playerComputed(name: string, fn: (...any) -> any, dependencies: {any}): Computed.Computed<any>
	return Computed.player(name, fn, dependencies)
end

-- TeamComputed factory
function RoNet.teamComputed(name: string, fn: (...any) -> any, dependencies: {any}): Computed.Computed<any>
	return Computed.team(name, fn, dependencies)
end

-- Context-aware unified API
if Internal.isServer then
	function RoNet.on(name: string, handler: (player: Player, ...any) -> (), middleware: Types.Middleware?): RBXScriptConnection
		return Server.on(name, handler, middleware)
	end

	function RoNet.off(name: string)
		return Server.off(name)
	end

	function RoNet.fire(name: string, player: Player, ...)
		return Server.fire(name, player, ...)
	end

	function RoNet.fireAll(name: string, ...)
		return Server.fireAll(name, ...)
	end

	function RoNet.fireExcept(name: string, exceptPlayer: Player, ...)
		return Server.fireExcept(name, exceptPlayer, ...)
	end

	function RoNet.fireInZone(name: string, zoneData: Types.Zone, ...)
		return Server.fireInZone(name, zoneData, ...)
	end

	function RoNet.fireExceptInZone(name: string, zoneData: Types.Zone, exceptPlayer: Player, ...)
		return Server.fireExceptInZone(name, zoneData, exceptPlayer, ...)
	end

	function RoNet.fireBatch(player: Player, events: {Types.BatchEvent})
		return Server.fireBatch(player, events)
	end

	function RoNet.fireBatchAll(events: {Types.BatchEvent})
		return Server.fireBatchAll(events)
	end

	function RoNet.fireBatchExcept(exceptPlayer: Player, events: {Types.BatchEvent})
		return Server.fireBatchExcept(exceptPlayer, events)
	end

	function RoNet.onInvoke(name: string, handler: (player: Player, ...any) -> any, middleware: Types.Middleware?)
		return Server.onInvoke(name, handler, middleware)
	end

	function RoNet.invoke(name: string, player: Player, ...): any
		return Server.invoke(name, player, ...)
	end

	function RoNet.invokeAsync(name: string, player: Player, timeout: number?, ...): typeof(Promise.new(function() end))
		return Server.invokeAsync(name, player, timeout, ...)
	end

	function RoNet.define(name: string, remoteType: string)
		return Internal.createRemote(name, remoteType :: Types.RemoteType)
	end

	function RoNet.defineMany(definitions: {{name: string, type: string}})
		for _, def in ipairs(definitions) do
			Internal.createRemote(def.name, def.type :: Types.RemoteType)
		end
	end

	function RoNet.isDefined(name: string): boolean
		return Internal.isDefined(name)
	end
else
	function RoNet.on(name: string, handler: (...any) -> (), middleware: Types.Middleware?): RBXScriptConnection?
		return Client.on(name, handler, middleware)
	end

	function RoNet.off(name: string)
		return Client.off(name)
	end

	function RoNet.fire(name: string, ...)
		return Client.fire(name, ...)
	end

	function RoNet.invoke(name: string, ...): any
		return Client.invoke(name, ...)
	end

	function RoNet.invokeAsync(name: string, timeout: number?, ...): typeof(Promise.new(function() end))
		return Client.invokeAsync(name, timeout, ...)
	end

	function RoNet.onInvoke(name: string, handler: (...any) -> any)
		return Client.onInvoke(name, handler)
	end
end

return RoNet
