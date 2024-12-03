local Players = game:GetService("Players")
local Player = {}
Player.__index = Player

function Player.onPlayerAdded(callback: (player: Player) -> nil): RBXScriptConnection
    local connection
    task.spawn(function()
        connection = Players.PlayerAdded:Connect(function(player)
            task.spawn(callback, player)
        end)
        for _, player in Players:GetPlayers() do
            task.spawn(callback, player)
        end
    end)
    return connection
end

function Player.onPlayerRemoving(callback: (player: Player) -> nil): RBXScriptConnection
    local connection = Players.PlayerRemoving:Connect(function(player)
        task.spawn(callback, player)
    end)
    return connection
end

return Player