--!nolint LocalShadow

-- ### Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- ### Modules
local Player = require(ReplicatedStorage.Source.CoreModules.Player)
local ProfileService = require(ServerStorage.Source.ProfileService)
local Core = require(ReplicatedStorage.Source.CoreModules.Core)
local Reflex = require(ReplicatedStorage.Source.Packages.reflex)

-- ### Fusion
local Fusion = require(ReplicatedStorage.Source.Fusion)

-- ### Packages
local Signal = require(ReplicatedStorage.Source.Packages.signal)
local Trove = require(ReplicatedStorage.Source.Packages.trove)

local RootProducer = require(ReplicatedStorage.Source.Shared.PlayerData.Producer)

local PlayerDataManager = {
    Name = "PlayerDataManager",
    signals = {
        playerProfileLoaded = Signal.new(),
        playerProfileRemoved = Signal.new(),
        beforePlayerRemoving = Signal.new(),
        playerDataLoaded = Signal.new(),
    },
    Client = {
        Broadcaster = Core.SecuredRemote.new(),
        Start = Core.SecuredRemote.new(),
    },
    profiles = {},
    producers = {} :: {[Player]: RootProducer.RootProducer},
    states = {} :: {[Player]: RootProducer.RootFusionState},
    scopes = {},
    troves = {},
}
local self = PlayerDataManager

export type BaseSlice = {
    template: any,
    createProducer: (data: any) -> any,
}

function PlayerDataManager.Init(databaseName: string, loadMiddleware: (table) -> table)

    local profileTemplate = RootProducer.createDataTemplate()

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

        profile.Data = RootProducer.fixUserData(profile.Data)

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
            local _profile = self.profiles[player]
            if _profile ~= nil then
                self.signals.beforePlayerRemoving:Fire(player)
                _profile:Release()
            end
            self.profiles[player] = nil
            Fusion.doCleanup(self.scopes[player])
            self.states[player] = nil
            self.scopes[player] = nil
        end)

        self.signals.playerProfileLoaded:Fire(player, profile.Data)
    end)

    Player.onPlayerRemoving(function(player)
        clearPlayer(player)
        self.signals.playerProfileRemoved:Fire(player)
    end)

    self.signals.beforePlayerRemoving:Connect(function(player: Player)
        pcall(function()
            if self.profiles[player].Data.account ~= nil then
                self.profiles[player].Data.account.lastExit = tick()
                local sessionDuration = math.round(
                    self.profiles[player].Data.account.lastExit -
                    self.profiles[player].Data.account.lastJoin
                )
                self.profiles[player].Data.account.playTime += sessionDuration
            end
        end)
    end)

    self.signals.playerProfileLoaded:Connect(function(player: Player, data: any)
        local producer = RootProducer.createRootProducer(data) :: RootProducer.RootProducer
        self.producers[player] = producer
        
        local scope = Fusion.scoped(Fusion)
        self.states[player] = RootProducer.createFusionState(scope, producer)
        self.scopes[player] = scope

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

        -- account base data
        pcall(function()
            producer.increaseLoginCount()
            producer.setLastJoin()
            producer.setIsRobloxVip(player.MembershipType == Enum.MembershipType.Premium)
        end)

        -- check gamepass
        pcall(function()
            local gamepassData = require(ReplicatedStorage.Source.Shared.Database.Gamepass)
            local MarketplaceService = game:GetService("MarketplaceService")
            local passes = {}
            producer.setOwnedGamePasses({})
            
            for localId, data in gamepassData.Passes do
                print(`checking if user has pass: {localId}`)
                
                local hasPass = false
                local success, message
                local try = 0
                -- Check if user already owns the pass

                while not success and try < 10 do
                    success, message = pcall(function()
                        hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, data.id)
                    end)
                    if not success then
                        task.wait(0.5)
                        try += 1
                    end
                end

                if not success then
                    -- Issue a warning and exit the function
                    error("Error while checking if player has pass: " .. tostring(message))
                    return
                end

                if hasPass then
                    -- Assign user the ability or bonus related to the pass
                    print(player.Name .. " owns the Pass with ID " .. data.id)
                    passes[data.id] = true
                end

            end
        
            producer.setOwnedGamePasses(passes)
        end)
    
        -- check badges
        pcall(function()
            local badgesData = require(ReplicatedStorage.Source.Shared.Database.Badge)
            local BadgeService = game:GetService("BadgeService")
            local badges = {}
            producer.setOwnedBadges({})
            
            for localId, data in badgesData.Badges do
                print(`checking if user has pass: {localId}`)
                
                BadgeService:AwardBadge(player.UserId, data.id)

                local has = false
                local success, message
                local try = 0
                -- Check if user already owns the pass

                while not success and try < 10 do
                    success, message = pcall(function()
                        has = BadgeService:UserHasBadgeAsync(player.UserId, data.id)
                    end)
                    if not success then
                        task.wait(0.5)
                        try += 1
                    end
                end

                if not success then
                    -- Issue a warning and exit the function
                    error("Error while checking if player has badge: " .. tostring(message))
                    return
                end

                if has then
                    -- Assign user the ability or bonus related to the pass
                    print(player.Name .. " owns the Badge with ID " .. data.id)
                    badges[data.id] = true
                end

            end
        
            producer.setOwnedBadges(badges)
        end)

        self.signals.playerDataLoaded:Fire(player)
    end)

end

function PlayerDataManager:PlayerProducer(player: Player): RootProducer.RootProducer
    return self.producers[player]
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