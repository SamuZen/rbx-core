-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Modules
local Reflex = require(ReplicatedStorage.Source.Packages.reflex)

-- ### Packages
local Fusion = require(ReplicatedStorage.Source.Fusion)

local RootProducer = require(ReplicatedStorage.Source.Shared.PlayerData.Producer)

-- ### Modules
local Net = require(ReplicatedStorage.Source.CoreModules.Net)

local PlayerDataManager = {
    Name = "PlayerDataManager",
    producer = nil :: RootProducer.RootProducer,
    state = nil :: RootProducer.RootFusionState,
}
local self = PlayerDataManager

function PlayerDataManager.Init()

    -- initialize server communication - fetch initial data
    local function handShake()
        local success
        local data
        local errCount = 0
        while not success and errCount < 5 do
            success, data = pcall(function()
                return Net.InvokeServer("PlayerDataManager.HandShake")
            end)
            if success then
                print("hand shake success!")
            else
                print("hand shake failed!")
                print(data)
                errCount += 1
                task.wait(0.5)
                print('trying again ', errCount)
            end
        end
        if not success then return end
        return data
    end
    local myData = handShake()
    if myData == nil then
        error("ERROR: Failed to Initialize client Data! Talk to the devs if this happens again!")
    end
    
    -- create local producer
    self.producer = RootProducer.createRootProducer(myData)

    local scope = Fusion.scoped(Fusion)
    self.state = RootProducer.createFusionState(scope, self.producer)

    -- create action receiver
    local receiver = Reflex.createBroadcastReceiver({
        start = function() Net.FireToServer("PlayerDataManager.Start") end
    })

    -- connect receiver to remote event
    local PlayerDataManagerNet = Net.Get("PlayerDataManager")
    PlayerDataManagerNet.re.Broadcaster.OnClientEvent:Connect(function(actions)
        receiver:dispatch(actions)
    end)

    -- connect receiver to producer
    self.producer:applyMiddleware(receiver.middleware)
end

function PlayerDataManager.Start()

end

return PlayerDataManager