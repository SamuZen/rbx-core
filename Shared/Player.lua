local Character = require(script.Parent.Character.Utils)

local Players = game:GetService("Players")
local Player = {}
Player.__index = Player

local localPlayer = Players.LocalPlayer

function Player.getHumanoidRootPart(player: Player): BasePart
    if player and player.Character then
        local part = player.Character:FindFirstChild("HumanoidRootPart")
        return part
    end
end

function Player.isLocalPlayerPart(part: BasePart): boolean
    if localPlayer.Character == nil then return false end
    return part:IsDescendantOf(localPlayer.Character)
end

function Player.onPlayerAdded(callback: (player: Player) -> nil): RBXScriptConnection
    local connection
    task.spawn(function()
        connection = Players.PlayerAdded:Connect(function(player)
            callback(player)
        end)
        for _, player in Players:GetPlayers() do
            callback(player)
        end
    end)
    return connection
end

function Player.onPlayerRemoving(callback: (player: Player) -> nil): RBXScriptConnection
    local connection = Players.PlayerRemoving:Connect(function(player)
        callback(player)
    end)
    return connection
end

function Player.getPlayerFromPart(part: BasePart): Player | nil
    local character = Character.getCharacterFromPart(part)
    if character == nil then return nil end
    return Players:GetPlayerFromCharacter(character)
end

return Player