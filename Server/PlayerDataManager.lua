--!nolint LocalShadow

-- ### Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- ### Modules
local Player = require(ReplicatedStorage.Source.Modules.Player)
local ProfileService = require(ServerStorage.Source.ProfileService)
local Core = require(ReplicatedStorage.Source.Modules.Core)
local Reflex = require(ReplicatedStorage.Source.Reflex)

-- ### Packages
local Signal = require(ReplicatedStorage.Source.Packages.signal)
--local TableUtil = require(ReplicatedStorage.Source.Packages["table-util"])
local Trove = require(ReplicatedStorage.Source.Packages.trove)

local RootProducer = require(ReplicatedStorage.Source.Shared.PlayerData.Producer)

local PlayerDataManager = {
    Name = "PlayerDataManager",
    signals = {
        playerProfileLoaded = Signal.new(),
        playerProfileRemoved = Signal.new(),
        beforePlayerRemoving = Signal.new(),
    },
    Client = {
        Broadcaster = Core.SecuredRemote.new(),
        Start = Core.SecuredRemote.new(),
    },
    profiles = {},
    producers = {} :: {[Player]: RootProducer.RootProducer},
    troves = {},
}
local self = PlayerDataManager

export type BaseSlice = {
    template: any,
    createProducer: (data: any) -> any,
}

local function GetSlices(): {[string]: BaseSlice}
    local slices = {}
    local slicesFolder = ReplicatedStorage.Source.Shared.PlayerData.Slices
    for _, child in slicesFolder:GetChildren() do
        if child.Name == "Producer" then continue end
        slices[child.Name] = require(child)
    end
    return slices
end

local function AssembleProfileTemplate(slices :{[string]: BaseSlice}): table
    local template = {}
    for sliceName, sliceModule in slices do
        template[sliceName] = sliceModule.template
    end
    return template
end

function PlayerDataManager.Init(databaseName: string, loadMiddleware: (table) -> table)
    local slices = GetSlices()
    local profileTemplate = AssembleProfileTemplate(slices)

    local playerProfileStore = ProfileService.GetProfileStore(databaseName, profileTemplate)
    
    local function clearPlayer(player)
        if self.troves[player] ~= nil then
            self.troves[player]:Destroy()
            self.troves[player] = nil
        end
    end

    Player.onPlayerAdded(function(player)
        self.troves[player] = Trove.new()

        local profile = playerProfileStore:LoadProfileAsync(`Player_{player.UserId}`, "ForceLoad")
        if profile == nil then
            player:Kick("Failed to load saved data. Please rejoin")
            profile:Release()
            clearPlayer(player)
            return
        end

        -- fix save
        profile:Reconcile()
        if loadMiddleware ~= nil then
            profile = loadMiddleware(profile)
        end
        
        -- if player leave or profile is loaded on another server
        profile:ListenToRelease(function()
            player:Kick("Your profile has been loaded remotely. Please rejoin")
            clearPlayer(player)
        end)

        -- release if data is loaded but player already left
        if not player:IsDescendantOf(Players) then
            profile:Release()
            clearPlayer(player)
            return
        end

        self.profiles[player] = profile

        --cleanup
        self.troves[player]:Add(function()
            local profile = self.profiles[player]
            if profile ~= nil then
                self.signals.beforePlayerRemoving:Fire(player)
                profile:Release()
            end
            self.profiles[player] = nil
        end)

        self.signals.playerProfileLoaded:Fire(player, profile.Data)
    end)

    Player.onPlayerRemoving(function(player)
        clearPlayer(player)
        self.signals.playerProfileRemoved:Fire(player)
    end)

    self.signals.playerProfileLoaded:Connect(function(player: Player, data: any)

        local producer = RootProducer.createRootProducer(data)
        self.producers[player] = producer

        local broadcaster = Reflex.createBroadcaster({
            producers = RootProducer.createProducers(data),
            dispatch = function(_player, actions)
                self.Client.Broadcaster.remote:FireClient(_player, actions)
            end
        })

        -- start broadcast when player is ready
        self.troves[player]:Add(self.Client.Start:Connect(function(_player)
            if player == _player then
                broadcaster:start(_player)
            end
        end))

        -- update profile service of changes
        local function selectAll(state)
            return state
        end
        producer:subscribe(selectAll, function(state: RootProducer.RootState, _)
            if self.profiles[player] ~= nil then
                self.profiles[player].Data = state
            else
                warn("State trying to update profile, but its missing!")
            end
        end)

        producer:applyMiddleware(broadcaster.middleware)

        --cleanup
        self.troves[player]:Add(function()
            local _producer = self.producers[player]
            if _producer ~= nil then
                _producer:destroy()
                self.producers[player] = nil
            end
            broadcaster:destroy()
        end)
        
    end)

end

function PlayerDataManager:GetPlayerProducerSync(player): RootProducer.RootProducer
    -- Yields until a Profile linked to a player is loaded or the player leaves
    local producer = self.producers[player]
    while producer == nil and player:IsDescendantOf(Players) == true do
        task.wait(0.1)
        producer = self.producer[player]
    end
    return producer
end

function PlayerDataManager:GetPlayerDataSync(player) : table
    local producer = self:GetPlayerProducerSync(player)
    if producer ~= nil then
        return producer:getState()
    end
end

function PlayerDataManager.Client.HandShake(player)
    return PlayerDataManager:GetPlayerDataSync(player)
end


return PlayerDataManager