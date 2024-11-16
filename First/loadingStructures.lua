local ReplicatedFirst = game:GetService("ReplicatedFirst")

local loadingStructures = {}

-- ### Initialization data

loadingStructures.isClientInitialized = Instance.new("BoolValue")
loadingStructures.isClientInitialized.Name = 'isClientInitialized'
loadingStructures.isClientInitialized.Value = false
loadingStructures.isClientInitialized.Parent = ReplicatedFirst

loadingStructures.clientInitialized = Instance.new("BindableEvent")
loadingStructures.clientInitialized.Name = "clientInitialized"
loadingStructures.clientInitialized.Parent = ReplicatedFirst

-- ### Loading data

loadingStructures.loadingPercentage = Instance.new("NumberValue")
loadingStructures.loadingPercentage.Name = 'loadingPercentage'
loadingStructures.loadingPercentage.Parent = ReplicatedFirst

loadingStructures.loadingDescription = Instance.new("StringValue")
loadingStructures.loadingDescription.Name = 'loadingDescription'
loadingStructures.loadingDescription.Parent = ReplicatedFirst

return loadingStructures