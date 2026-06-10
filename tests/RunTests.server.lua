--!strict
-- Run this in Studio to execute all tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.RoNetTests.TestRunner)
TestRunner.run()
