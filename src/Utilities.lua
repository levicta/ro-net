--!strict
-- Utilities
-- Common patterns: .once() for auto-disconnecting listeners,
-- .wait() for yielding until an event fires.

local Internal = require(script.Parent.Internal)
local Server = require(script.Parent.Server)
local Client = require(script.Parent.Client)

local Utilities = {}

function Utilities.once(name: string, handler: (...any) -> ()): RBXScriptConnection?
	local conn: RBXScriptConnection? = nil
	local wrapped = function(...)
		if conn then
			conn:Disconnect()
		end
		handler(...)
	end

	if Internal.isServer then
		conn = Server.on(name, wrapped :: any)
	else
		conn = Client.on(name, wrapped)
	end

	return conn
end

function Utilities.wait(name: string, timeout: number?): (...any)
	timeout = timeout or 60
	local thread = coroutine.running()
	local fired = false
	local result: {any} = {}

	local conn: RBXScriptConnection? = nil
	local wrapped = function(...)
		if fired then return end
		fired = true
		result = {...}
		if conn then
			conn:Disconnect()
		end
		if coroutine.status(thread) == "suspended" then
			task.spawn(function()
				coroutine.resume(thread, table.unpack(result))
			end)
		end
	end

	if Internal.isServer then
		conn = Server.on(name, wrapped :: any)
	else
		conn = Client.on(name, wrapped)
	end

	task.delay(timeout :: number, function()
		if not fired then
			fired = true
			if conn then
				conn:Disconnect()
			end
			if coroutine.status(thread) == "suspended" then
				task.spawn(function()
					coroutine.resume(thread, nil)
				end)
			end
		end
	end)

	return coroutine.yield()
end

return Utilities
