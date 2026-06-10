--!strict
-- Validator
-- Runtime payload validation against schemas.

local Types = require(script.Parent.Types)

local Validator = {}

local function validateValue(value: any, expectedType: string): (boolean, string?)
	local actualType = type(value)

	if expectedType == "any" then return true end
	if expectedType == "nil" and actualType == "nil" then return true end
	if expectedType == "boolean" and actualType == "boolean" then return true end
	if expectedType == "number" and actualType == "number" then return true end
	if expectedType == "string" and actualType == "string" then return true end
	if expectedType == "table" and actualType == "table" then return true end
	if expectedType == "function" and actualType == "function" then return true end
	if expectedType == "thread" and actualType == "thread" then return true end
	if expectedType == "userdata" and actualType == "userdata" then return true end

	local typeofValue = typeof(value)
	if expectedType == "Instance" and typeofValue == "Instance" then return true end
	if expectedType == "Player" and typeofValue == "Instance" and value:IsA("Player") then return true end
	if expectedType == "Vector3" and typeofValue == "Vector3" then return true end
	if expectedType == "Vector2" and typeofValue == "Vector2" then return true end
	if expectedType == "CFrame" and typeofValue == "CFrame" then return true end
	if expectedType == "Color3" and typeofValue == "Color3" then return true end
	if expectedType == "BrickColor" and typeofValue == "BrickColor" then return true end
	if expectedType == "UDim" and typeofValue == "UDim" then return true end
	if expectedType == "UDim2" and typeofValue == "UDim2" then return true end
	if expectedType == "Rect" and typeofValue == "Rect" then return true end
	if expectedType == "NumberRange" and typeofValue == "NumberRange" then return true end
	if expectedType == "NumberSequence" and typeofValue == "NumberSequence" then return true end
	if expectedType == "ColorSequence" and typeofValue == "ColorSequence" then return true end

	return false, string.format("Expected %s, got %s", expectedType, actualType == "userdata" and typeofValue or actualType)
end

function Validator.validate(payload: {any}, schema: Types.Schema): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "Schema must be a table"
	end

	for i, expected in ipairs(schema) do
		local value = payload[i]
		local expectedType: string
		local optional = false

		if type(expected) == "table" and expected.type then
			expectedType = expected.type
			optional = expected.optional or false
		elseif type(expected) == "string" then
			expectedType = expected
		else
			return false, string.format("Invalid schema entry at index %d", i)
		end

		if value == nil then
			if not optional then
				return false, string.format("Missing required argument #%d (%s)", i, expectedType)
			end
			continue
		end

		local valid, err = validateValue(value, expectedType)
		if not valid then
			return false, string.format("Argument #%d: %s", i, err)
		end
	end

	return true, nil
end

return Validator
