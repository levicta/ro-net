--!strict
-- Server
-- Server-side API for handling and emitting remote calls.

local Players = game:GetService("Players")
local Internal = require(script.Parent.Internal)
local Middleware = require(script.Parent.Middleware)
local Types = require(script.Parent.Types)
local Promise = require(script.Parent.Promise)
local Profiler = require(script.Parent.Profiler)

local Server = {}
local eventHandlers: {[string]: Types.HandlerEntry} = {}
local invokeHandlers: {[string]: Types.HandlerEntry} = {}

local function parseMiddleware(middleware: Types.Middleware?): {Types.MiddlewareFn}
	local list: {Types.MiddlewareFn} = {}
	if not middleware then
		return list
	end
	if type(middleware) == "function" then
		 table.insert(list, middleware)
	elseif type(middleware) == "table" then
		for _, m in ipairs(middleware) do
			if type(m) == "function" then
				table.insert(list, m)
			end
		end
	end
	return list
end

function Server.on(name: string, handler: (player: Player, ...any) -> (), middleware: Types.Middleware?): RBXScriptConnection
	local remote = Internal.createRemote(name, "Event") :: RemoteEvent

	eventHandlers[name] = {
		handler = handler,
		middleware = parseMiddleware(middleware),
		connection = nil,
	}

	local conn = remote.OnServerEvent:Connect(function(player: Player, ...)
		local start = tick()
		local payload = {...}
		local payloadSize = 0
		for _, v in ipairs(payload) do
			payloadSize += #tostring(v)
		end

		local context: Types.Context = {
			player = player,
			remote = name,
			payload = payload,
			direction = "incoming",
		}

		local success, result = pcall(function()
			return Middleware.run(context, eventHandlers[name].middleware, function()
				handler(player, table.unpack(payload))
			end)
		end)

		local latency = tick() - start
		Profiler.record(name, latency, payloadSize, not success)

		if not success then
			warn(string.format("[RoNet] Error in handler for '%s': %s", name, tostring(result)))
		end
	end)

	eventHandlers[name].connection = conn
	return conn
end

function Server.off(name: string)
	if eventHandlers[name] and eventHandlers[name].connection then
		eventHandlers[name].connection:Disconnect()
		eventHandlers[name].connection = nil
	end
end

function Server.fire(name: string, player: Player, ...)
	local remote = Internal.getRemote(name) :: RemoteEvent?
	if not remote then
		warn(string.format("[RoNet] Cannot fire '%s': remote not found", name))
		return
	end

	local payload = {...}
	local context: Types.Context = {
		player = player,
		remote = name,
		payload = payload,
		direction = "outgoing",
	}

	local success, result = pcall(function()
		return Middleware.run(context, {}, function()
			remote:FireClient(player, table.unpack(payload))
		end)
	end)

	if not success then
		warn(string.format("[RoNet] Error firing '%s': %s", name, tostring(result)))
	end
end

function Server.fireAll(name: string, ...)
	local remote = Internal.getRemote(name) :: RemoteEvent?
	if not remote then
		warn(string.format("[RoNet] Cannot fireAll '%s': remote not found", name))
		return
	end

	local payload = {...}
	for _, player in ipairs(Players:GetPlayers()) do
		local context: Types.Context = {
			player = player,
			remote = name,
			payload = payload,
			direction = "outgoing",
		}

		pcall(function()
			Middleware.run(context, {}, function()
				remote:FireClient(player, table.unpack(payload))
			end)
		end)
	end
end

function Server.fireExcept(name: string, exceptPlayer: Player, ...)
	local remote = Internal.getRemote(name) :: RemoteEvent?
	if not remote then
		warn(string.format("[RoNet] Cannot fireExcept '%s': remote not found", name))
		return
	end

	local payload = {...}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= exceptPlayer then
			local context: Types.Context = {
				player = player,
				remote = name,
				payload = payload,
				direction = "outgoing",
			}

			pcall(function()
				Middleware.run(context, {}, function()
					remote:FireClient(player, table.unpack(payload))
				end)
			end)
		end
	end
end

function Server.onInvoke(name: string, handler: (player: Player, ...any) -> any, middleware: Types.Middleware?)
	local remote = Internal.createRemote(name, "Function") :: RemoteFunction

	invokeHandlers[name] = {
		handler = handler,
		middleware = parseMiddleware(middleware),
	}

	remote.OnServerInvoke = function(player: Player, ...)
		local start = tick()
		local payload = {...}
		local payloadSize = 0
		for _, v in ipairs(payload) do
			payloadSize += #tostring(v)
		end

		local context: Types.Context = {
			player = player,
			remote = name,
			payload = payload,
			direction = "incoming",
		}

		local success, result = pcall(function()
			return Middleware.run(context, invokeHandlers[name].middleware, function()
				return handler(player, table.unpack(payload))
			end)
		end)

		local latency = tick() - start
		Profiler.record(name, latency, payloadSize, not success)

		if not success then
			warn(string.format("[RoNet] Error in invoke handler for '%s': %s", name, tostring(result)))
			return nil
		end

		return result
	end
end

function Server.invoke(name: string, player: Player, ...): any
	local remote = Internal.getRemote(name) :: RemoteFunction?
	if not remote then
		warn(string.format("[RoNet] Cannot invoke '%s' to client: remote not found", name))
		return nil
	end

	local payload = {...}
	local context: Types.Context = {
		player = player,
		remote = name,
		payload = payload,
		direction = "outgoing",
	}

	local success, result = pcall(function()
		return Middleware.run(context, {}, function()
			return remote:InvokeClient(player, table.unpack(payload))
		end)
	end)

	if not success then
		warn(string.format("[RoNet] Error invoking '%s' to client: %s", name, tostring(result)))
		return nil
	end

	return result
end

function Server.invokeAsync(name: string, player: Player, timeout: number?, ...): typeof(Promise.new(function() end))
	timeout = timeout or 5
	return Promise.new(function(resolve, reject)
		task.spawn(function()
			local remote = Internal.getRemote(name) :: RemoteFunction?
			if not remote then
				reject(string.format("Remote '%s' not found", name))
				return
			end

			local payload = {...}
			local result
			local done = false

			task.delay(timeout :: number, function()
				if not done then
					done = true
					reject(string.format("Invoke '%s' timed out after %ds", name, timeout :: number))
				end
			end)

			local success, invokeResult = pcall(function()
				return remote:InvokeClient(player, table.unpack(payload))
			end)

			if not done then
				done = true
				if success then
					resolve(invokeResult)
				else
					reject(tostring(invokeResult))
				end
			end
		end)
	end)
end

return Server
