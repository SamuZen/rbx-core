local Players = game:GetService("Players")
local Player = {}
Player.__index = Player

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

return Player