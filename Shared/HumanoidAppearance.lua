-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Data
local Appearances = require(ReplicatedStorage.Source.Shared.Database.Appearances)

-- ### Types
local CharacterDataTypes = require(ReplicatedStorage.Source.Shared.PlayerData.Slices.characters.Types)

local HumanoidAppearance = {}

export type AccessoryData = {{
    type: string,
    id: number,
}}

export type OutfitData = {
    face: string,
    shirt: string,
    pants: string,
 
    bodyColor: string,

    head: string,
    leftArm: string,
    leftLeg: string,
    rightArm: string,
    rightLeg: string,
    torso: string,

    accessories: AccessoryData,
}

function HumanoidAppearance.AssembleCharacterAppearanceData(data: CharacterDataTypes.VisualData)
    local outfitData: OutfitData = {}

    -- clone body
    outfitData = table.clone(Appearances.body[data.body])

    -- set clothing
    outfitData.shirt = Appearances.shirt[data.shirt]
    outfitData.pants = Appearances.pants[data.pants]

    -- set body color
    outfitData.bodyColor = Appearances.bodyColor[data.bodyColor]

    -- create accessories
    outfitData.accessories = {}

    -- hair
    table.insert(outfitData.accessories, { type = "Hair", id = Appearances.hair[data.hair] })

    return outfitData
end

function HumanoidAppearance.CreateAppearance(data: CharacterDataTypes.VisualData)
    local outfitData = HumanoidAppearance.AssembleCharacterAppearanceData(data)
    return HumanoidAppearance.CreateAppearance(outfitData)
end

function HumanoidAppearance.Create(data: OutfitData)
    local hd = Instance.new("HumanoidDescription")

    hd.Face = data.face or 238983378
    hd.Shirt = data.shirt or 10737157363
    hd.Pants = data.pants or 8388705060

    local defaultColor = Color3.fromRGB(214, 161, 126)

    hd.HeadColor = data.bodyColor or defaultColor
    hd.LeftArmColor = data.bodyColor or defaultColor
    hd.LeftLegColor = data.bodyColor or defaultColor
    hd.RightArmColor = data.bodyColor or defaultColor
    hd.RightLegColor = data.bodyColor or defaultColor
    hd.TorsoColor = data.bodyColor or defaultColor

    hd.Head = data.head or 0
    hd.LeftArm = data.leftArm or 376530220
    hd.LeftLeg = data.leftLeg or 376531300
    hd.RightArm = data.rightArm or 376531012
    hd.RightLeg = data.rightLeg or 376531703
    hd.Torso = data.torso or 376532000

    local accessoriesData = {}
    for i, accData in data.accessories or {} do
        table.insert(accessoriesData, {
            Order = i,
            AssetId = accData.id,
            Puffiness = 0.5,
            AccessoryType = Enum.AccessoryType[accData.type]
        })
    end

    if #accessoriesData > 0 then
        hd:SetAccessories(accessoriesData, false)
    end
    --humanoid:ApplyDescription(hd)
    --hd:Destroy()
    return hd
end

function HumanoidAppearance.ApplyAppearance(humanoid, data)
    local hd = HumanoidAppearance.Create(data)
    humanoid:ApplyDescription(hd)
    hd:Destroy()
end

return HumanoidAppearance