--!strict
-- Example: State Synchronization Helpers (Observed State) — Client

local Net = require(game.ReplicatedStorage.RoNet)

-- Create a reactive state variable for the current round number
local Round = Net.observable("RoundNumber", 0)

-- Immediately read the cached value (starts at initial value until server syncs)
print("Current round:", Round:get())

-- React to every server update automatically
Round:onChange(function(newRound)
    print("Client: Round is now", newRound)
    updateRoundUI(newRound)
end)

-- With namespaces
local Game = Net.namespace("Game")
local Score = Game:observable("TeamScore", 0)
Score:onChange(function(val)
    leaderboard:Update(val)
end)
