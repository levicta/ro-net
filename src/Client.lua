--!strict
-- Client
-- Client-side API for handling and emitting remote calls.

local Internal = require(script.Parent.Internal)
local Middleware = require(script.Parent.Middleware)
local Types = require(script.Parent.Types)
local Promise = require(script.Parent.Promise)
local Profiler = require(script.Parent.Profiler)

local Client = {}
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

function Client.on(name: string, handler: (...any) -> (), middleware: Types.Middleware?): RBXScriptConnection?
	local remote = Internal.getRemote(name) :: RemoteEvent?
	if not remote then
		warn(string.format("[RoNet] Cannot listen to '%s': remote not found", name))
		return nil
	end

	eventHandlers[name] = {
		handler = handler,
		middleware = parseMiddleware(middleware),
		connection = nil,
	}

	local conn = remote.OnClientEvent:Connect(function(...)
		local start = tick()
		local payload = {...}
		local payloadSize = 0
		for _, v in ipairs(payload) do
			payloadSize += #tostring(v)
		end

		local context: Types.Context = {
			player = nil,
			remote = name,
			payload = payload,
			direction = "incoming",
		}

		local success, result = pcall(function()
			return Middleware.run(context, eventHandlers[name].middleware, function()
				handler(table.unpack(payload))
			end)
		end)

		local latency = tick() - start
		Profiler.record(name, latency, payloadSize, not success)

		if not success then
			warn(string.format("[RoNet] Error in client handler for '%s': %s", name, tostring(result)))
		end
	end)

	eventHandlers[name].connection = conn
	return conn
end

function Client.off(name: string)
	if eventHandlers[name] and eventHandlers[name].connection then
		eventHandlers[name].connection:Disconnect()
		eventHandlers[name].connection = nil
	end
end

function Client.dispatch(name: string, player: Player?, ...)
	local handlerEntry = eventHandlers[name]
	if not handlerEntry then
		return
	end

	local payload = {...}
	task.spawn(function()
		local success, result = pcall(function()
			return handlerEntry.handler(table.unpack(payload))
		end)
		if not success then
			warn(string.format("[RoNet] Error in batch-dispatched client handler for '%s': %s", name, tostring(result)))
		end
	end)
end

function Client.fire(name: string, ...)
	local remote = Internal.getRemote(name) :: RemoteEvent?
	if not remote then
		warn(string.format("[RoNet] Cannot fire '%s': remote not found", name))
		return
	end

	local payload = {...}
	local context: Types.Context = {
		player = nil,
		remote = name,
		payload = payload,
		direction = "outgoing",
	}

	local success, result = pcall(function()
		return Middleware.run(context, {}, function()
			remote:FireServer(table.unpack(payload))
		end)
	end)

	if not success then
		warn(string.format("[RoNet] Error firing '%s': %s", name, tostring(result)))
	end
end

function Client.invoke(name: string, ...): any
	local remote = Internal.getRemote(name) :: RemoteFunction?
	if not remote then
		warn(string.format("[RoNet] Cannot invoke '%s': remote not found", name))
		return nil
	end

	local payload = {...}
	local context: Types.Context = {
		player = nil,
		remote = name,
		payload = payload,
		direction = "outgoing",
	}

	local success, result = pcall(function()
		return Middleware.run(context, {}, function()
			return remote:InvokeServer(table.unpack(payload))
		end)
	end)

	if not success then
		warn(string.format("[RoNet] Error invoking '%s': %s", name, tostring(result)))
		return nil
	end

	return result
end

function Client.invokeAsync(name: string, timeout: number?, ...): typeof(Promise.new(function() end))
	timeout = timeout or 5
	return Promise.new(function(resolve, reject)
		task.spawn(function()
			local remote = Internal.getRemote(name) :: RemoteFunction?
			if not remote then
				reject(string.format("Remote '%s' not found", name))
				return
			end

			local payload = {...}
			local done = false

			task.delay(timeout :: number, function()
				if not done then
					done = true
					reject(string.format("Invoke '%s' timed out after %ds", name, timeout :: number))
				end
			end)

			local success, invokeResult = pcall(function()
				return remote:InvokeServer(table.unpack(payload))
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

function Client.onInvoke(name: string, handler: (...any) -> any)
	local remote = Internal.getRemote(name) :: RemoteFunction?
	if not remote then
		warn(string.format("[RoNet] Cannot set invoke handler for '%s': remote not found", name))
		return
	end

	invokeHandlers[name] = {
		handler = handler,
		middleware = {},
	}

	remote.OnClientInvoke = function(...)
		local start = tick()
		local payload = {...}
		local payloadSize = 0
		for _, v in ipairs(payload) do
			payloadSize += #tostring(v)
		end

		local context: Types.Context = {
			player = nil,
			remote = name,
			payload = payload,
			direction = "incoming",
		}

		local success, result = pcall(function()
			return Middleware.run(context, invokeHandlers[name].middleware, function()
				return handler(table.unpack(payload))
			end)
		end)

		local latency = tick() - start
		Profiler.record(name, latency, payloadSize, not success)

		if not success then
			warn(string.format("[RoNet] Error in client invoke handler for '%s': %s", name, tostring(result)))
			return nil
		end

		return result
	end
end

return Client
