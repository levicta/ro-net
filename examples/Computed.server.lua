--!strict
-- Example: Computed Observables — Server

local Net = require(game.ReplicatedStorage.RoNet)

-- Global computed
local RedScore = Net.observable("RedScore", 0)
local BlueScore = Net.observable("BlueScore", 0)
local TotalScore = Net.computed("TotalScore", function(red, blue)
    return red + blue
end, {RedScore, BlueScore})

RedScore:set(10)
BlueScore:set(20)
-- TotalScore automatically recalculates to 30

-- Player computed
local PlayerLevel = Net.playerObservable("PlayerLevel", 1)
local PlayerMultiplier = Net.playerObservable("PlayerMultiplier", 1)
local PlayerPower = Net.playerComputed("PlayerPower", function(player, level, multiplier)
    return level * multiplier
end, {PlayerLevel, PlayerMultiplier})

PlayerLevel:set(player, 5)
-- PlayerPower auto-recalculates for that player

-- Team computed
local TeamAttack = Net.teamObservable("TeamAttack", 10)
local TeamDefense = Net.teamObservable("TeamDefense", 5)
local TeamPower = Net.teamComputed("TeamPower", function(team, attack, defense)
    return attack + defense
end, {TeamAttack, TeamDefense})

TeamAttack:set(team, 15)
-- TeamPower auto-recalculates for that team
