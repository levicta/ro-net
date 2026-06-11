--!strict
-- Example: Team Observable — Client

local Net = require(game.ReplicatedStorage.RoNet)

-- Create a team-scoped state variable
local TeamScore = Net.teamObservable("TeamScore", 0)

-- Immediately read the cached value (starts at initial value until server syncs)
print("Team score:", TeamScore:get())

-- React to team score updates
TeamScore:onChange(function(newScore)
    updateTeamUI(newScore)
end)

-- With namespaces
local Game = Net.namespace("Game")
local TeamBaseHealth = Game:teamObservable("TeamBaseHealth", 1000)
TeamBaseHealth:onChange(function(health)
    updateBaseHealth(health)
end)
