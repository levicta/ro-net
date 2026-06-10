--!strict
-- Bindable
-- Same-context event/function wrapper for server↔server or client↔client communication.

local Bindable = {}
local events: {[string]: {BindableEvent}} = {}
local funcs: {[string]: {BindableFunction}} = {}
local handlers: {[string]: {(...any) -> ()}} = {}
local invokeHandlers: {[string]: (...any) -> any} = {}

function Bindable.on(name: string, handler: (...any) -> ())
	if not events[name] then
		events[name] = Instance.new("BindableEvent")
		events[name].Name = name
	end

	if not handlers[name] then
		handlers[name] = {}
	end

	table.insert(handlers[name], handler)

	events[name].Event:Connect(function(...)
		for _, h in ipairs(handlers[name]) do
			local success, err = pcall(h, ...)
			if not success then
				warn(string.format("[RoNet.Bindable] Error in '%s': %s", name, tostring(err)))
			end
		end
	end)
end

function Bindable.off(name: string, handler: (...any) -> ())
	if not handlers[name] then return end
	for i, h in ipairs(handlers[name]) do
		if h == handler then
			table.remove(handlers[name], i)
			break
		end
	end
end

function Bindable.fire(name: string, ...)
	if not events[name] then
		events[name] = Instance.new("BindableEvent")
		events[name].Name = name
	end
	events[name]:Fire(...)
end

function Bindable.onInvoke(name: string, handler: (...any) -> any)
	if not funcs[name] then
		funcs[name] = Instance.new("BindableFunction")
		funcs[name].Name = name
	end

	invokeHandlers[name] = handler

	funcs[name].OnInvoke = function(...)
		local success, result = pcall(handler, ...)
		if not success then
			warn(string.format("[RoNet.Bindable] Invoke error in '%s': %s", name, tostring(result)))
			return nil
		end
		return result
	end
end

function Bindable.invoke(name: string, ...): any
	if not funcs[name] then
		warn(string.format("[RoNet.Bindable] No handler for '%s'", name))
		return nil
	end
	local success, result = pcall(function()
		return funcs[name]:Invoke(...)
	end)
	if not success then
		warn(string.format("[RoNet.Bindable] Invoke failed for '%s': %s", name, tostring(result)))
		return nil
	end
	return result
end

return Bindable
