--!strict
-- Middleware
-- Built-in middleware and the execution pipeline.

local Types = require(script.Parent.Types)
local Internal = require(script.Parent.Internal)

local Middleware = {}

function Middleware.run(context: Types.Context, middlewareList: {Types.MiddlewareFn}, final: () -> any): any
	local index = 0
	local count = #middlewareList

	local function nextFn(): any
		index += 1
		if index <= count then
			local success, result = pcall(function()
				return middlewareList[index](context, nextFn)
			end)
			if not success then
				warn(string.format("[RoNet] Middleware error on '%s': %s", context.remote, tostring(result)))
				return nil
			end
			return result
		else
			local success, result = pcall(final)
			if not success then
				error(result)
			end
			return result
		end
	end

	return nextFn()
end

function Middleware.RateLimit(maxPerSecond: number, burstSize: number?): Types.MiddlewareFn
	burstSize = burstSize or maxPerSecond
	local buckets: {[number]: {tokens: number, lastUpdate: number}} = {}

	return function(context: Types.Context, next: () -> any)
		local player = context.player
		if not player then
			return next()
		end

		local now = tick()
		local bucket = buckets[player.UserId]
		if not bucket then
			bucket = {tokens = burstSize :: number, lastUpdate = now}
			buckets[player.UserId] = bucket
		end

		local elapsed = now - bucket.lastUpdate
		bucket.tokens = math.min(burstSize :: number, bucket.tokens + elapsed * maxPerSecond)
		bucket.lastUpdate = now

		if bucket.tokens >= 1 then
			bucket.tokens -= 1
			return next()
		else
			if Internal.isStudio then
				warn(string.format("[RoNet] Rate limit exceeded for %s on '%s'", player.Name, context.remote))
			end
			return nil
		end
	end
end

function Middleware.Logger(): Types.MiddlewareFn
	return function(context: Types.Context, next: () -> any)
		local playerName = context.player and context.player.Name or "Client"
		print(string.format("[RoNet] %s | %s | %s | args: %d",
			context.direction,
			context.remote,
			playerName,
			#context.payload
		))
		return next()
	end
end

function Middleware.Validate(schema: Types.Schema): Types.MiddlewareFn
	local Validator = require(script.Parent.Validator)
	return function(context: Types.Context, next: () -> any)
		if context.direction == "incoming" then
			local valid, err = Validator.validate(context.payload, schema)
			if not valid then
				warn(string.format("[RoNet] Validation failed for '%s': %s", context.remote, err))
				return nil
			end
		end
		return next()
	end
end

function Middleware.Auth(checkFn: (player: Player) -> boolean): Types.MiddlewareFn
	return function(context: Types.Context, next: () -> any)
		local player = context.player
		if not player then
			return next()
		end
		if checkFn(player) then
			return next()
		else
			warn(string.format("[RoNet] Auth failed for %s on '%s'", player.Name, context.remote))
			return nil
		end
	end
end

function Middleware.Debounce(cooldown: number): Types.MiddlewareFn
	local lastCall: {[number]: number} = {}

	return function(context: Types.Context, next: () -> any)
		local player = context.player
		if not player then
			return next()
		end

		local now = tick()
		local last = lastCall[player.UserId] or 0
		if now - last < cooldown then
			return nil
		end

		lastCall[player.UserId] = now
		return next()
	end
end

return Middleware
