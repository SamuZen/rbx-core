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

function Player.getPlayersWithText(text: string, me: Player): Player | nil
    local allPlayers = Players:GetPlayers():: {Player}
    if text == "me" then return {me} end
    if text == "all" then return Players:GetPlayers() end

    local targets = {}
    for _, _player in allPlayers do
        local lowerName = string.lower(_player.DisplayName)
        if string.find(lowerName, text) then
            table.insert(targets, _player)
        end
    end
    return targets
end

return Player