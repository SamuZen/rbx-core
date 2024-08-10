-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ### Core Modules
local BenchmarkClock = require(script.BenchmarkClock)

-- ### Modules
local SecuredRemote = require(script.SecuredRemote)
local t = require(script.t)

local Core = {}
Core.LOG = false

-- ### Expose Modules
Core.SecuredRemote = SecuredRemote
Core.t = t

Core.InitializationFiles = {} :: {ModuleScript}
Core.Folder = nil
Core.NetFolder = nil

function Core.Log(message)
    if Core.LOG then print(message) end
end

function Core.AddFolderToInitialization(folder: Folder, deep: boolean, initialization)
    local f
    if deep then f = folder.GetDescendants else f = folder.GetChildren end
    for _, child in f(folder) do
        if child:IsA("ModuleScript") then
            Core.AddSingleFileToInitialization(child, initialization)
        end
    end
end

function Core.AddSingleFileToInitialization(file: ModuleScript, initialization)
    table.insert(initialization or Core.InitializationFiles, file)
end

function Core.AddFilesToInitialization(files: {ModuleScript}, initialization)
    for _, file in files do
        Core.AddSingleFileToInitialization(file, initialization)
    end
end

-- ### Decoupled Initialization

function Core.CreateInitialization()
    return {}
end

-- ### Utils

local function createFolder(name, parent)
    local f = Instance.new("Folder")
    f.Name = name
    f.Parent = parent
    return f
end

-- ### Internal NET

function Core.HandleSecuredRemote(securedRemote: SecuredRemote.SecuredRemote<any, any>, nameSpace: string, name: string)
    securedRemote.remote.Name = name
    securedRemote.remote.Parent = Core.NetFolder:FindFirstChild(nameSpace) or createFolder(nameSpace, Core.NetFolder)
end

function Core.HandleUnreliableRemote(remote: UnreliableRemoteEvent, nameSpace: string, name: string)
    remote.Name = name
    remote.Parent = Core.NetFolder:FindFirstChild(nameSpace) or createFolder(nameSpace, Core.NetFolder)
end

function Core.CreateFunction(name: string, nameSpace: string, func: () -> nil)
    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = name
    remoteFunction.Parent = Core.NetFolder:FindFirstChild(nameSpace) or createFolder(nameSpace, Core.NetFolder)
    remoteFunction.OnServerInvoke = func
end

function Core.Initialize(initialization, skipInitStart)
    if initialization == nil then
        initialization = Core.InitializationFiles
    end
    local clock = BenchmarkClock.New()

    if RunService:IsServer() and Core.Folder == nil then
        Core.Folder = createFolder("Core", ReplicatedStorage)
        Core.NetFolder = createFolder("Net", Core.Folder)
    end

    -- require
    local scripts = {}

    warn("requiring " .. clock:GetDeltaString(3))
    for _, file in initialization do
        Core.Log(file.Name)
        local success, result = pcall(function()
            return require(file)
        end)
        if success then
            scripts[file.Name] = result
        else
            warn(result)
        end
    end

    -- custom init
    if RunService:IsServer() then
        warn("Pre-Init Net" .. clock:GetDeltaString(3))
        for _, file in initialization do
            local scriptModule = scripts[file.Name]
            if scriptModule.Client ~= nil then
                Core.Log(file.Name)
                for key, value in scriptModule.Client do
                    if typeof(value) == "table" then
                        Core.HandleSecuredRemote(value, scriptModule.Name, key)
                    elseif typeof(value) == "function" then
                        Core.CreateFunction(key, scriptModule.Name, value)
                    end
                end
            end

            -- unreliable events
            if scriptModule.UClient ~= nil then
                Core.Log(file.Name)
                for key, value in scriptModule.UClient do
                    if value:IsA("UnreliableRemoteEvent") then
                        Core.HandleUnreliableRemote(value, scriptModule.Name, key)
                    end
                end
            end

        end
    end

    if not skipInitStart then
        -- init
        warn("Init " .. clock:GetDeltaString(3))
        for _, file in initialization do
            if scripts[file.Name] ~= nil and scripts[file.Name].Init ~= nil then
                Core.Log(file.Name)
                scripts[file.Name]:Init()
            end
        end

        -- start
        warn("Start " .. clock:GetDeltaString(3))
        for _, file in initialization do
            task.spawn(function()
                if scripts[file.Name] ~= nil and scripts[file.Name].Start ~= nil then
                    Core.Log(file.Name)
                    scripts[file.Name]:Start()
                end
            end)
        end
    end

    scripts = nil
    clock:Destroy()
end

return Core