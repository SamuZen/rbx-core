local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- ### Packages
local TableUtil = require(ReplicatedStorage.Source.Packages["table-util"])

local Assets = {}

function Assets.GetFolder(name: string): Folder
    -- try replicated storage
    local folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild(name)
    if folder ~= nil then return folder end

    -- try workspace
    folder = Workspace:FindFirstChild("Assets") and Workspace.Assets:FindFirstChild(name)
    if folder ~= nil then return folder end

    -- try server storage
    if RunService:IsServer() then
        local ServerStorage = game:GetService("ServerStorage")
        folder = ServerStorage:FindFirstChild("Assets") and ServerStorage.Assets:FindFirstChild(name)
        if folder ~= nil then return folder end
    end

    if folder == nil then warn("Assets.GetFolder: Could not find asset folder: " .. name) end
    return nil
end

function Assets.ListAssetsOnPath(path: string)
    local instance = Assets.WaitForPath(path)
    local childrens = instance:GetChildren()
    return TableUtil.Map(childrens, function(value)
        return value.Name
    end)
end

function Assets.GetRandomNameOnPath(path: string)
    local list = Assets.ListAssetsOnPath(path)
    return list[math.random(1, #list)]
end

function Assets.WaitForPath(path: string): Folder
    local split = string.split(path, ".")
    local rootFolder = Assets.GetFolder(split[1])
    if #split == 1 then return rootFolder end

    local parent = rootFolder
    local instance = nil
    for i = 2, #split do
        instance = parent:WaitForChild(split[i])
        parent = instance
    end

    return instance
end

return Assets