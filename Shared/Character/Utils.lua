local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Modules
local Weld = require(ReplicatedStorage.Source.Modules.Weld)

local Character = {}
Character.__index = Character

function Character.getCharacterFromPart(instance: Instance)
    local model = instance:FindFirstAncestorWhichIsA("Model")
    if model:IsA("Tool") then
        model = instance:FindFirstAncestorWhichIsA("Model")
    end
    return model
end

function Character.isPlayerCharacter(instance: Instance)
    return Players:GetPlayerFromCharacter(instance) ~= nil
end

function Character.getHumanoidFromInstance(instance: Instance): Humanoid | nil
    local character = Character.getCharacterFromPart(instance)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    return humanoid
end

function Character.getRootPart(character: Model): BasePart | nil
    return character:FindFirstChild("HumanoidRootPart")
end

function Character.isCharacterPart(part: BasePart, character: Model)
    return part:IsDescendantOf(character)
end

function Character.isPartAccessory(part: BasePart): boolean
    local isAccessory = part.Parent:IsA("Accessory")
    if isAccessory then
        --warn("Is accessory!")
        return true
    end
    isAccessory = part.Parent.ClassName == "Accessory" 
    if isAccessory then
        warn("Is accessory 2!")
        return true
    end

    return false
    --if not part.Parent:IsA("Accessory") then return false end
end

function Character.weldModel(character: Model, model: Model, attachAt: string, offset: CFrame)
    if not character then
		return warn("Cannot create weapon without character!")
	end

	local selectedPart = character:FindFirstChild(attachAt) or character:WaitForChild(attachAt, 5)
	assert(selectedPart, "Cannot find part to attach: ", attachAt)

	local weld = Weld(selectedPart, model.PrimaryPart)
	model:PivotTo(selectedPart.CFrame * (offset or CFrame.new()))
	model.Parent = character
    return weld
end

function Character.onCharacterAdded(player: Player, callback: (character: Model) -> any): RBXScriptConnection
    if player.Character then
        callback(player.Character)
    end
    local connection = player.CharacterAdded:Connect(callback)
    local con; con = Players.PlayerRemoving:Connect(function(_player)
        if _player == player then
            con:Disconnect()
            if connection ~= nil then
                connection:Disconnect()
            end
        end
    end)
    return connection
end

function Character.ChangeDefaultAnimation(character: Model, animations)
    if animations == nil then return warn("no default animations to change") end

    local animate = character:FindFirstChild("Animate")
    if animate == nil then return end
    -- idle
    if animations.idle ~= nil then
        animate.idle.Animation1.AnimationId = animations.idle
        if animations.idle2 == nil then
           animate.idle.Animation2.AnimationId = animations.idle
        else
           animate.idle.Animation2.AnimationId = animations.idle2
        end
    end

    -- walk
    if animations.walk ~= nil then
        animate.walk.WalkAnim.AnimationId = animations.walk
    end

    -- run
    if animations.run ~= nil then
        animate.run.runAnim.AnimationId = animations.run
    end
end

return Character