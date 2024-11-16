-- ### Roblox Services
local Player = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDump = {
    playerGui = nil :: ScreenGui,
}

function PlayerDump.Init()
    if RunService:IsServer() then return end
    PlayerDump.playerGui = Player.LocalPlayer:WaitForChild("PlayerGui")
end

return PlayerDump