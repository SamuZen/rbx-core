local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Modules
local Signal = require(ReplicatedStorage.Source.Packages.signal)
local Trove = require(ReplicatedStorage.Source.Packages.trove)

local LocalCharacter = {}
LocalCharacter.__index = LocalCharacter
local self = LocalCharacter

LocalCharacter.onLoaded = Signal.new()
LocalCharacter.onRemoved = Signal.new()
LocalCharacter.onChanged = Signal.new()
LocalCharacter.onDied = Signal.new()

local started = false
local trove = Trove.new()

-- ### Public var
LocalCharacter.fullyLoaded = false
LocalCharacter.humanoid = false
LocalCharacter.character = false
LocalCharacter.rootPart = false


local diedConnection

function LocalCharacter.start()
    if started then return end
    started = true

    trove:Add(Players.LocalPlayer.CharacterAdded:Connect(function(characted: Model) self.onCurrentCharacterChanged(characted) end))
    trove:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self.onCurrentCharacterChanged(nil) end))

    self.onCurrentCharacterChanged(Players.LocalPlayer.Character)
end

function LocalCharacter.onCurrentCharacterChanged(_character: Model | nil)
    print("LocalCharacter - Changed: ", _character)
    LocalCharacter.character = _character
    if LocalCharacter.character then
        LocalCharacter.humanoid = LocalCharacter.character:WaitForChild("Humanoid") :: Humanoid
        if diedConnection ~= nil then diedConnection:Disconnect() diedConnection = nil end
        diedConnection = LocalCharacter.humanoid.Died:Connect(function()
            LocalCharacter.onDied:Fire()
        end)

        LocalCharacter.rootPart = LocalCharacter.character:WaitForChild("HumanoidRootPart")
        LocalCharacter.fullyLoaded = true
        LocalCharacter.onLoaded:Fire()
    else
        LocalCharacter.humanoid = nil
        LocalCharacter.rootPart = nil
        LocalCharacter.fullyLoaded = false
        LocalCharacter.onRemoved:Fire()
    end
    LocalCharacter.onChanged:Fire(LocalCharacter.character)
end

function LocalCharacter.waitCharacterSync()
    if self.fullyLoaded then return self.character end
    self.onLoaded:Wait()
    return self.character
end

return LocalCharacter