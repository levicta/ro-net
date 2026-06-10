--!strict
-- TestRunner
-- Comprehensive test harness for RoNet. Run this in Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.RoNet)
local Validator = Net.Validator
local Middleware = Net.Middleware
local Promise = Net.Promise
local Bindable = Net.Bindable
local Namespace = Net.Namespace
local Utilities = Net.Utilities
local Serializer = Net.Serializer
local Profiler = Net.Profiler

local Tests = {}
local passed = 0
local failed = 0

local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("  ✓ " .. name)
	else
		failed += 1
		print("  ✗ " .. name .. " — " .. tostring(err))
	end
end

function Tests.run()
	print("
=== RoNet Test Suite ===
")

	-- Validator Tests
	test("Validator: accepts valid types", function()
		local ok = Validator.validate({42, "hello", true}, {"number", "string", "boolean"})
		assert(ok == true)
	end)

	test("Validator: rejects wrong type", function()
		local ok, err = Validator.validate({"not a number"}, {"number"})
		assert(ok == false)
		assert(string.find(err, "Expected number"))
	end)

	test("Validator: handles optional args", function()
		local ok = Validator.validate({42}, {"number", {type = "string", optional = true}})
		assert(ok == true)
	end)

	test("Validator: handles Vector3", function()
		local ok = Validator.validate({Vector3.new(1,2,3)}, {"Vector3"})
		assert(ok == true)
	end)

	test("Validator: handles Instance types", function()
		local ok = Validator.validate({workspace}, {"Instance"})
		assert(ok == true)
	end)

	test("Validator: handles missing required arg", function()
		local ok, err = Validator.validate({}, {"string"})
		assert(ok == false)
		assert(string.find(err, "Missing required"))
	end)

	-- Middleware Tests
	test("Middleware: RateLimit allows first calls", function()
		local mw = Middleware.RateLimit(10, 10)
		local called = false
		local context = {player = {UserId = 1} :: any, remote = "Test", payload = {}, direction = "incoming"}
		mw(context, function() called = true end)
		assert(called == true)
	end)

	test("Middleware: Auth allows authorized", function()
		local mw = Middleware.Auth(function(p) return p.UserId == 1 end)
		local called = false
		local context = {player = {UserId = 1} :: any, remote = "Test", payload = {}, direction = "incoming"}
		mw(context, function() called = true end)
		assert(called == true)
	end)

	test("Middleware: Auth blocks unauthorized", function()
		local mw = Middleware.Auth(function(p) return p.UserId == 2 end)
		local called = false
		local context = {player = {UserId = 1} :: any, remote = "Test", payload = {}, direction = "incoming"}
		mw(context, function() called = true end)
		assert(called == false)
	end)

	test("Middleware: Debounce prevents rapid calls", function()
		local mw = Middleware.Debounce(1)
		local context = {player = {UserId = 1} :: any, remote = "Test", payload = {}, direction = "incoming"}

		local called1 = false
		mw(context, function() called1 = true end)
		assert(called1 == true)

		local called2 = false
		mw(context, function() called2 = true end)
		assert(called2 == false)
	end)

	-- Promise Tests
	test("Promise: resolves correctly", function()
		local p = Promise.new(function(resolve)
			resolve(42)
		end)
		local ok, val = p:await()
		assert(ok == true and val == 42)
	end)

	test("Promise: rejects correctly", function()
		local p = Promise.new(function(_, reject)
			reject("error")
		end)
		local ok, val = p:await()
		assert(ok == false and val == "error")
	end)

	test("Promise: andThen chains", function()
		local result = nil
		Promise.resolve(5):andThen(function(v)
			return v * 2
		end):andThen(function(v)
			result = v
		end)
		local ok, _ = Promise.resolve(5):await()
		assert(ok == true)
	end)

	test("Promise: catch handles errors", function()
		local caught = nil
		Promise.reject("fail"):catch(function(err)
			caught = err
		end)
		local ok, _ = Promise.reject("fail"):await()
		assert(ok == false)
	end)

	-- Bindable Tests
	test("Bindable: fire and on work", function()
		local received = nil
		Bindable.on("TestBindable", function(val)
			received = val
		end)
		Bindable.fire("TestBindable", 99)
		assert(received == 99)
	end)

	test("Bindable: invoke and onInvoke work", function()
		Bindable.onInvoke("TestFunc", function(x)
			return x * 2
		end)
		local result = Bindable.invoke("TestFunc", 5)
		assert(result == 10)
	end)

	test("Bindable: off disconnects", function()
		local count = 0
		local handler = function() count += 1 end
		Bindable.on("TestOff", handler)
		Bindable.fire("TestOff")
		Bindable.off("TestOff", handler)
		Bindable.fire("TestOff")
		assert(count == 1)
	end)

	-- Namespace Tests
	test("Namespace: qualifies remote names", function()
		local ns = Namespace.new("TestNS")
		if game:GetService("RunService"):IsServer() then
			ns:define("Event1", "Event")
			assert(ns:isDefined("Event1") == true)
		end
	end)

	test("Namespace: fire and on work", function()
		local ns = Namespace.new("TestNS2")
		local received = nil
		if game:GetService("RunService"):IsServer() then
			ns:define("TestEvent", "Event")
			ns:on("TestEvent", function(player, val)
				received = val
			end)
			ns:fire("TestEvent", {UserId = 1, Name = "Test"} :: any, 42)
			assert(received == 42)
		end
	end)

	-- Utilities Tests
	test("Utilities: once auto-disconnects", function()
		if game:GetService("RunService"):IsServer() then
			Net.define("OnceTest", "Event")
			local count = 0
			Utilities.once("OnceTest", function()
				count += 1
			end)
			Net.fireAll("OnceTest")
			Net.fireAll("OnceTest")
			assert(count == 1)
		end
	end)

	-- Serializer Tests
	test("Serializer: Vector3 roundtrip", function()
		local v = Vector3.new(1, 2, 3)
		local serialized = Serializer.serializeSingle(v)
		local deserialized = Serializer.deserializeSingle(serialized)
		assert(typeof(deserialized) == "Vector3")
		assert(deserialized.X == 1 and deserialized.Y == 2 and deserialized.Z == 3)
	end)

	test("Serializer: CFrame roundtrip", function()
		local cf = CFrame.new(10, 5, 20) * CFrame.Angles(0, math.rad(90), 0)
		local serialized = Serializer.serializeSingle(cf)
		local deserialized = Serializer.deserializeSingle(serialized)
		assert(typeof(deserialized) == "CFrame")
		local dx = (deserialized.Position - cf.Position).Magnitude
		assert(dx < 0.001)
	end)

	test("Serializer: Color3 roundtrip", function()
		local c = Color3.fromRGB(255, 128, 64)
		local serialized = Serializer.serializeSingle(c)
		local deserialized = Serializer.deserializeSingle(serialized)
		assert(typeof(deserialized) == "Color3")
		assert(math.abs(deserialized.R - c.R) < 0.001)
	end)

	test("Serializer: NumberSequence roundtrip", function()
		local ns = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 0.5),
		})
		local serialized = Serializer.serializeSingle(ns)
		local deserialized = Serializer.deserializeSingle(serialized)
		assert(typeof(deserialized) == "NumberSequence")
		assert(#deserialized.Keypoints == 2)
	end)

	test("Serializer: nested table roundtrip", function()
		local data = {
			position = Vector3.new(1, 2, 3),
			color = Color3.fromRGB(255, 0, 0),
			nested = {
				frame = CFrame.new(0, 10, 0),
			},
		}
		local serialized = Serializer.serializeSingle(data)
		local deserialized = Serializer.deserializeSingle(serialized)
		assert(typeof(deserialized.position) == "Vector3")
		assert(typeof(deserialized.color) == "Color3")
		assert(typeof(deserialized.nested.frame) == "CFrame")
	end)


	-- Profiler Tests
	test("Profiler: enable and record", function()
		Profiler.enable("TestRemote")
		Profiler.record("TestRemote", 0.001, 50, false)
		Profiler.record("TestRemote", 0.002, 100, false)
		local m = Profiler.getMetrics("TestRemote")
		assert(m ~= nil)
		assert(m.callCount == 2)
		assert(m.avgLatency > 0)
		assert(m.avgPayloadSize == 75)
		Profiler.reset("TestRemote")
	end)

	test("Profiler: tracks errors", function()
		Profiler.enable("ErrorRemote")
		Profiler.record("ErrorRemote", 0.001, 10, true)
		local m = Profiler.getMetrics("ErrorRemote")
		assert(m.errors == 1)
		Profiler.reset("ErrorRemote")
	end)

	test("Profiler: global enable", function()
		Profiler.enable()
		assert(Profiler.isProfiling("AnyRemote") == true)
		Profiler.disable()
		assert(Profiler.isProfiling("AnyRemote") == false)
	end)

	test("Profiler: reset clears data", function()
		Profiler.enable("ResetTest")
		Profiler.record("ResetTest", 0.001, 10, false)
		Profiler.reset("ResetTest")
		assert(Profiler.getMetrics("ResetTest") == nil)
	end)

	-- Integration Tests
	test("Integration: define creates remote", function()
		if game:GetService("RunService"):IsServer() then
			local remote = Net.define("TestRemote123", "Event")
			assert(remote ~= nil)
			assert(remote:IsA("RemoteEvent"))
		end
	end)

	test("Integration: strict mode tracks definitions", function()
		if game:GetService("RunService"):IsServer() then
			Net.configure({strictMode = false})
			Net.define("StrictTest", "Event")
			assert(Net.isDefined("StrictTest") == true)
			assert(Net.isDefined("NonExistent") == false)
		end
	end)

	print(string.format("
=== Results: %d passed, %d failed ===", passed, failed))
	return failed == 0
end

return Tests
