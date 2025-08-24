local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LoadingStructures = {}

-- ### Initialization data

LoadingStructures.isClientInitialized = Instance.new("BoolValue")
LoadingStructures.isClientInitialized.Name = 'isClientInitialized'
LoadingStructures.isClientInitialized.Value = false
LoadingStructures.isClientInitialized.Parent = ReplicatedFirst

LoadingStructures.clientInitialized = Instance.new("BindableEvent")
LoadingStructures.clientInitialized.Name = "clientInitialized"
LoadingStructures.clientInitialized.Parent = ReplicatedFirst

-- ### Loading data

LoadingStructures.loadingPercentage = Instance.new("NumberValue")
LoadingStructures.loadingPercentage.Name = 'loadingPercentage'
LoadingStructures.loadingPercentage.Parent = ReplicatedFirst

LoadingStructures.loadingDescription = Instance.new("StringValue")
LoadingStructures.loadingDescription.Name = 'loadingDescription'
LoadingStructures.loadingDescription.Parent = ReplicatedFirst

function LoadingStructures.SetDescription(description)
    LoadingStructures.loadingDescription.Value = description
end

return LoadingStructures