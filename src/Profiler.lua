--!strict
-- Profiler
-- Built-in metrics collection for remotes: latency, frequency, payload size.
--
-- Usage:
--   Net.profile("DamageDealt")
--   -- Later:
--   local metrics = Net.getMetrics("DamageDealt")
--   print(metrics.avgLatency, metrics.callsPerSecond, metrics.avgPayloadSize)

local RunService = game:GetService("RunService")

local Profiler = {}
local metrics: {[string]: {
	callCount: number,
	totalLatency: number,
	minLatency: number,
	maxLatency: number,
	lastCall: number,
	callsThisSecond: number,
	secondStart: number,
	peakCallsPerSec: number,
	totalPayloadSize: number,
	minPayloadSize: number,
	maxPayloadSize: number,
	errors: number,
}} = {}

local profilingEnabled: {[string]: boolean} = {}
local globalEnabled = false

function Profiler.enable(name: string?)
	if name then
		profilingEnabled[name] = true
		if not metrics[name] then
			metrics[name] = {
				callCount = 0,
				totalLatency = 0,
				minLatency = math.huge,
				maxLatency = 0,
				lastCall = 0,
				callsThisSecond = 0,
				secondStart = tick(),
				peakCallsPerSec = 0,
				totalPayloadSize = 0,
				minPayloadSize = math.huge,
				maxPayloadSize = 0,
				errors = 0,
			}
		end
	else
		globalEnabled = true
	end
end

function Profiler.disable(name: string?)
	if name then
		profilingEnabled[name] = false
	else
		globalEnabled = false
	end
end

function Profiler.isProfiling(name: string): boolean
	return profilingEnabled[name] == true or globalEnabled
end

function Profiler.record(name: string, latency: number, payloadSize: number, errored: boolean?)
	if not Profiler.isProfiling(name) then return end

	local m = metrics[name]
	if not m then return end

	m.callCount += 1
	m.totalLatency += latency
	m.minLatency = math.min(m.minLatency, latency)
	m.maxLatency = math.max(m.maxLatency, latency)
	m.lastCall = tick()
	m.totalPayloadSize += payloadSize
	m.minPayloadSize = math.min(m.minPayloadSize, payloadSize)
	m.maxPayloadSize = math.max(m.maxPayloadSize, payloadSize)
	if errored then
		m.errors += 1
	end

	-- Per-second tracking
	local now = tick()
	if now - m.secondStart >= 1 then
		m.peakCallsPerSec = math.max(m.peakCallsPerSec, m.callsThisSecond)
		m.callsThisSecond = 0
		m.secondStart = now
	end
	m.callsThisSecond += 1
end

function Profiler.getMetrics(name: string): {
	callCount: number,
	avgLatency: number,
	minLatency: number,
	maxLatency: number,
	callsPerSecond: number,
	peakCallsPerSec: number,
	avgPayloadSize: number,
	minPayloadSize: number,
	maxPayloadSize: number,
	errors: number,
}?
	local m = metrics[name]
	if not m then return nil end

	local now = tick()
	local elapsed = now - m.secondStart
	local cps = elapsed > 0 and m.callsThisSecond / elapsed or 0

	return {
		callCount = m.callCount,
		avgLatency = m.callCount > 0 and m.totalLatency / m.callCount or 0,
		minLatency = m.minLatency == math.huge and 0 or m.minLatency,
		maxLatency = m.maxLatency,
		callsPerSecond = cps,
		peakCallsPerSec = math.max(m.peakCallsPerSec, cps),
		avgPayloadSize = m.callCount > 0 and m.totalPayloadSize / m.callCount or 0,
		minPayloadSize = m.minPayloadSize == math.huge and 0 or m.minPayloadSize,
		maxPayloadSize = m.maxPayloadSize,
		errors = m.errors,
	}
end

function Profiler.getAllMetrics(): {[string]: {
	callCount: number,
	avgLatency: number,
	minLatency: number,
	maxLatency: number,
	callsPerSecond: number,
	peakCallsPerSec: number,
	avgPayloadSize: number,
	minPayloadSize: number,
	maxPayloadSize: number,
	errors: number,
}}
	local result = {}
	for name, _ in pairs(metrics) do
		result[name] = Profiler.getMetrics(name)
	end
	return result
end

function Profiler.reset(name: string?)
	if name then
		metrics[name] = nil
		profilingEnabled[name] = nil
	else
		metrics = {}
		profilingEnabled = {}
	end
end

function Profiler.report(): string
	local lines = {"=== RoNet Profiler Report ==="}
	for name, m in pairs(Profiler.getAllMetrics()) do
		table.insert(lines, string.format(
			"%s: %d calls | %.3fms avg | %.1f/sec | %d errors | %d bytes avg",
			name, m.callCount, m.avgLatency * 1000, m.callsPerSecond, m.errors, m.avgPayloadSize
		))
	end
	return table.concat(lines, "\n")
end

return Profiler
