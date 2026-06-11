--!strict
-- Example: Team Observable — Server

local Net = require(game.ReplicatedStorage.RoNet)

-- Create a team-scoped state variable for team scores
local TeamScore = Net.teamObservable("TeamScore", 0)

-- Update a team's score — only members of that team receive the update
TeamScore:set(team, 150)

-- React to team score changes on the server
TeamScore:onChange(function(team, newScore)
    print(team.Name .. " score: " .. newScore)
end)

-- With namespaces
local Game = Net.namespace("Game")
local TeamBaseHealth = Game:teamObservable("TeamBaseHealth", 1000)
TeamBaseHealth:set(team, 750)
