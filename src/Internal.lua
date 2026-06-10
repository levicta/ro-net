--!strict
-- Internal
-- Handles RemoteEvent/RemoteFunction lifecycle, registry, and context detection.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteType = "Event" | "Function"

local FOLDER_NAME = "RoNetRemotes"
local registry: {[string]: RemoteEvent | RemoteFunction} = {}
local defined: {[string]: boolean} = {}

local Internal = {}

Internal.isServer = RunService:IsServer()
Internal.isClient = RunService:IsClient()
Internal.isStudio = RunService:IsStudio()
Internal.strictMode = false

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	return folder :: Folder
end

function Internal.setConfig(config: {[string]: any})
	if config.strictMode ~= nil then
		Internal.strictMode = config.strictMode
	end
end

function Internal.createRemote(name: string, remoteType: RemoteType): RemoteEvent | RemoteFunction
	defined[name] = true

	if registry[name] then
		return registry[name]
	end

	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		registry[name] = existing :: RemoteEvent | RemoteFunction
		return registry[name]
	end

	local remote: RemoteEvent | RemoteFunction
	if remoteType == "Event" then
		remote = Instance.new("RemoteEvent")
	else
		remote = Instance.new("RemoteFunction")
	end

	remote.Name = name
	remote.Parent = folder
	registry[name] = remote

	return remote
end

function Internal.getRemote(name: string): RemoteEvent | RemoteFunction?
	if registry[name] then
		return registry[name]
	end

	local folder = getFolder()

	if Internal.isServer then
		local existing = folder:FindFirstChild(name)
		if existing then
			registry[name] = existing :: RemoteEvent | RemoteFunction
			return registry[name]
		end
		if Internal.strictMode and not defined[name] then
			error(string.format("[RoNet] Strict mode: remote '%s' was not defined. Use Net.define() first.", name))
		end
		return nil
	else
		local remote = folder:WaitForChild(name, 15)
		if remote then
			registry[name] = remote :: RemoteEvent | RemoteFunction
			return registry[name]
		else
			if Internal.strictMode then
				error(string.format("[RoNet] Strict mode: remote '%s' not found after 15s. Is it defined on the server?", name))
			else
				warn(string.format("[RoNet] Timed out waiting for remote '%s'. Is it defined on the server?", name))
			end
			return nil
		end
	end
end

function Internal.isDefined(name: string): boolean
	return defined[name] == true
end

function Internal.defineRemotes(definitions: {{name: string, type: RemoteType}})
	if not Internal.isServer then
		return
	end
	for _, def in ipairs(definitions) do
		Internal.createRemote(def.name, def.type)
	end
end

return Internal
