--!strict
-- Serializer
-- Converts non-serializable Roblox types to plain tables for remote transmission,
-- and reconstructs them on the receiving end.
--
-- Supported: Vector3, Vector2, CFrame, Color3, BrickColor, UDim, UDim2,
--            Rect, NumberRange, NumberSequence, ColorSequence

local Serializer = {}

local function serializeValue(value: any): any
	local t = typeof(value)

	if t == "Vector3" then
		return {__type = "Vector3", X = value.X, Y = value.Y, Z = value.Z}
	elseif t == "Vector2" then
		return {__type = "Vector2", X = value.X, Y = value.Y}
	elseif t == "CFrame" then
		local px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		return {__type = "CFrame", components = {px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22}}
	elseif t == "Color3" then
		return {__type = "Color3", R = value.R, G = value.G, B = value.B}
	elseif t == "BrickColor" then
		return {__type = "BrickColor", name = value.Name}
	elseif t == "UDim" then
		return {__type = "UDim", Scale = value.Scale, Offset = value.Offset}
	elseif t == "UDim2" then
		return {__type = "UDim2", X = {Scale = value.X.Scale, Offset = value.X.Offset}, Y = {Scale = value.Y.Scale, Offset = value.Y.Offset}}
	elseif t == "Rect" then
		return {__type = "Rect", Min = {X = value.Min.X, Y = value.Min.Y}, Max = {X = value.Max.X, Y = value.Max.Y}}
	elseif t == "NumberRange" then
		return {__type = "NumberRange", Min = value.Min, Max = value.Max}
	elseif t == "NumberSequence" then
		local keypoints = {}
		for _, kp in ipairs(value.Keypoints) do
			table.insert(keypoints, {Time = kp.Time, Value = kp.Value, Envelope = kp.Envelope})
		end
		return {__type = "NumberSequence", keypoints = keypoints}
	elseif t == "ColorSequence" then
		local keypoints = {}
		for _, kp in ipairs(value.Keypoints) do
			table.insert(keypoints, {Time = kp.Time, Value = {R = kp.Value.R, G = kp.Value.G, B = kp.Value.B}})
		end
		return {__type = "ColorSequence", keypoints = keypoints}
	elseif t == "table" then
		local copy = {}
		for k, v in pairs(value) do
			copy[k] = serializeValue(v)
		end
		return copy
	else
		return value
	end
end

local function deserializeValue(value: any): any
	if type(value) ~= "table" then
		return value
	end

	if value.__type == "Vector3" then
		return Vector3.new(value.X, value.Y, value.Z)
	elseif value.__type == "Vector2" then
		return Vector2.new(value.X, value.Y)
	elseif value.__type == "CFrame" then
		return CFrame.new(table.unpack(value.components))
	elseif value.__type == "Color3" then
		return Color3.new(value.R, value.G, value.B)
	elseif value.__type == "BrickColor" then
		return BrickColor.new(value.name)
	elseif value.__type == "UDim" then
		return UDim.new(value.Scale, value.Offset)
	elseif value.__type == "UDim2" then
		return UDim2.new(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	elseif value.__type == "Rect" then
		return Rect.new(value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
	elseif value.__type == "NumberRange" then
		return NumberRange.new(value.Min, value.Max)
	elseif value.__type == "NumberSequence" then
		local keypoints = {}
		for _, kp in ipairs(value.keypoints) do
			table.insert(keypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value, kp.Envelope))
		end
		return NumberSequence.new(keypoints)
	elseif value.__type == "ColorSequence" then
		local keypoints = {}
		for _, kp in ipairs(value.keypoints) do
			table.insert(keypoints, ColorSequenceKeypoint.new(kp.Time, Color3.new(kp.Value.R, kp.Value.G, kp.Value.B)))
		end
		return ColorSequence.new(keypoints)
	else
		local copy = {}
		for k, v in pairs(value) do
			copy[k] = deserializeValue(v)
		end
		return copy
	end
end

function Serializer.serialize(...): {any}
	local args = {...}
	local result = {}
	for i, v in ipairs(args) do
		result[i] = serializeValue(v)
	end
	return result
end

function Serializer.deserialize(args: {any}): {any}
	local result = {}
	for i, v in ipairs(args) do
		result[i] = deserializeValue(v)
	end
	return result
end

function Serializer.serializeSingle(value: any): any
	return serializeValue(value)
end

function Serializer.deserializeSingle(value: any): any
	return deserializeValue(value)
end

return Serializer
