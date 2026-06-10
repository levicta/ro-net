--!strict
-- Promise
-- Lightweight promise implementation for async invoke with timeout.

export type Promise = {
	andThen: (self: Promise, onFulfilled: (any) -> any, onRejected: ((string) -> any)?) -> Promise,
	catch: (self: Promise, onRejected: (string) -> any) -> Promise,
	await: (self: Promise) -> (boolean, any),
	_status: string,
	_value: any,
	_callbacks: {{resolve: (any) -> (), reject: (string) -> ()}},
}

local Promise = {}
Promise.__index = Promise

function Promise.new(executor: (resolve: (any) -> (), reject: (string) -> ()) -> ()): Promise
	local self = setmetatable({}, Promise) :: any
	self._status = "pending"
	self._value = nil
	self._callbacks = {}

	local function resolve(value: any)
		if self._status ~= "pending" then return end
		self._status = "fulfilled"
		self._value = value
		for _, cb in ipairs(self._callbacks) do
			cb.resolve(value)
		end
		self._callbacks = {}
	end

	local function reject(reason: string)
		if self._status ~= "pending" then return end
		self._status = "rejected"
		self._value = reason
		for _, cb in ipairs(self._callbacks) do
			cb.reject(reason)
		end
		self._callbacks = {}
	end

	local ok, err = pcall(function()
		executor(resolve, reject)
	end)
	if not ok then
		reject(tostring(err))
	end

	return self :: Promise
end

function Promise:andThen(onFulfilled: (any) -> any, onRejected: ((string) -> any)?): Promise
	return Promise.new(function(resolve, reject)
		local function handle()
			if self._status == "fulfilled" then
				local ok, result = pcall(function()
					return onFulfilled(self._value)
				end)
				if ok then
					resolve(result)
				else
					reject(tostring(result))
				end
			elseif self._status == "rejected" then
				if onRejected then
					local ok, result = pcall(function()
						return onRejected(self._value)
					end)
					if ok then
						resolve(result)
					else
						reject(tostring(result))
					end
				else
					reject(self._value)
				end
			else
				table.insert(self._callbacks, {
					resolve = function(value: any)
						local ok, result = pcall(function()
							return onFulfilled(value)
						end)
						if ok then
							resolve(result)
						else
							reject(tostring(result))
						end
					end,
					reject = function(reason: string)
						if onRejected then
							local ok, result = pcall(function()
								return onRejected(reason)
							end)
							if ok then
								resolve(result)
							else
								reject(tostring(result))
							end
						else
							reject(reason)
						end
					end,
				})
			end
		end
		handle()
	end)
end

function Promise:catch(onRejected: (string) -> any): Promise
	return self:andThen(function(v) return v end, onRejected)
end

function Promise:await(): (boolean, any)
	if self._status == "fulfilled" then
		return true, self._value
	elseif self._status == "rejected" then
		return false, self._value
	else
		-- Spin-wait (not ideal but works in Roblox context)
		while self._status == "pending" do
			task.wait(0.03)
		end
		return self._status == "fulfilled", self._value
	end
end

function Promise.resolve(value: any): Promise
	return Promise.new(function(resolve)
		resolve(value)
	end)
end

function Promise.reject(reason: string): Promise
	return Promise.new(function(_, reject)
		reject(reason)
	end)
end

return Promise
