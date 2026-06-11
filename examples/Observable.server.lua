--!strict
-- Example: State Synchronization Helpers (Observed State) — Server

local Net = require(game.ReplicatedStorage.RoNet)

-- Create a reactive state variable for the current round number
local Round = Net.observable("RoundNumber", 0)

-- Update it — all clients receive the new value immediately
Round:set(1)
task.wait(2)
Round:set(2)
task.wait(2)
Round:set(3)

-- React to changes on the server too
Round:onChange(function(newRound)
    print("Server: Round changed to", newRound)
    if newRound >= 3 then
        print("Final round!")
        Round:destroy()
    end
end)

-- With namespaces
local Game = Net.namespace("Game")
local Score = Game:observable("TeamScore", 0)
Score:set(100)
