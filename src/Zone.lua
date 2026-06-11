--!strict
-- Zone
-- Spatial/zone-based player filtering for interest management.

local Players = game:GetService("Players")

local Zone = {}

export type Zone = {
	origin: Vector3,
	radius: number,
}

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Zone.fromPosition(origin: Vector3, radius: number): Zone
	return {
		origin = origin,
		radius = radius,
	} :: Zone
end

function Zone.fromCFrame(cframe: CFrame, radius: number): Zone
	return {
		origin = cframe.Position,
		radius = radius,
	} :: Zone
end

function Zone.fromPart(part: BasePart, radius: number): Zone
	return {
		origin = part.Position,
		radius = radius,
	} :: Zone
end

function Zone.isPlayerInZone(player: Player, zone: Zone): boolean
	local root = getRoot(player)
	if not root then
		return false
	end
	return (root.Position - zone.origin).Magnitude <= zone.radius
end

function Zone.getPlayersInZone(zone: Zone): {Player}
	local result: {Player} = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if Zone.isPlayerInZone(player, zone) then
			table.insert(result, player)
		end
	end
	return result
end

return Zone
