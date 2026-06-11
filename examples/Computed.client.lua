--!strict
-- Example: Computed Observables — Client

local Net = require(game.ReplicatedStorage.RoNet)

-- Global computed
local TotalScore = Net.computed("TotalScore", function()
    return 0
end, {})

TotalScore:onChange(function(total)
    updateScoreUI(total)
end)

-- Player computed
local PlayerPower = Net.playerComputed("PlayerPower", function()
    return 0
end, {})

PlayerPower:onChange(function(power)
    updatePowerUI(power)
end)

-- Team computed
local TeamPower = Net.teamComputed("TeamPower", function()
    return 0
end, {})

TeamPower:onChange(function(power)
    updateTeamPowerUI(power)
end)
