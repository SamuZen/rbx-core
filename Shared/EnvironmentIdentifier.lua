local EnvironmentIdentifier = {}
export type AmbientIdMapData = {
    environments: {[string]: number},
    defaultEnv: string,
    defaultPlace: string,
}

EnvironmentIdentifier.currentEnvironment = nil :: {placeName:string, environment: string, placeId: number} | nil
EnvironmentIdentifier.environmentData = {}
EnvironmentIdentifier.envData = nil

local setuped = false
local setupedEvent = Instance.new("BindableEvent")

function EnvironmentIdentifier.Setup(map: AmbientIdMapData)
    local currentPlaceId = game.PlaceId
    -- find current
    EnvironmentIdentifier.envData = map

    local found = false
    for envName, envData in map.mapEnvPlaceId do
        for placeName, id in envData do
            if currentPlaceId == id then
                EnvironmentIdentifier.currentEnvironment = {
                    placeId = id,
                    environment = envName,
                    placeName = placeName,
                }
                found = true

                EnvironmentIdentifier.environmentData = envData

                break
            end
        end
    end

    if not found then
        EnvironmentIdentifier.currentEnvironment = {
            placeId = currentPlaceId,
            environment = map.defaultEnv,
            placeName = map.defaultPlace,
        }
    end
    print(`AMBIENT: {EnvironmentIdentifier.currentEnvironment.environment} - PLACE: {EnvironmentIdentifier.currentEnvironment.placeName} ({EnvironmentIdentifier.currentEnvironment.placeId})`)
	setuped = true
	setupedEvent:Fire()
end

function EnvironmentIdentifier.IsEnv(env: string): boolean
	if not setuped then setupedEvent.Event:Wait() end
    return EnvironmentIdentifier.currentEnvironment.environment == env
end

function EnvironmentIdentifier.IsId(id: number): boolean
	if not setuped then setupedEvent.Event:Wait() end
    return EnvironmentIdentifier.currentEnvironment.placeId == id
end

function EnvironmentIdentifier.GetPlaceId(place: string): number
	if not setuped then setupedEvent.Event:Wait() end
    return EnvironmentIdentifier.environmentData[place]
end

function EnvironmentIdentifier.Select(data: {[string]: any})
	if not setuped then setupedEvent.Event:Wait() end
    return data[EnvironmentIdentifier.currentEnvironment.environment]
end

function EnvironmentIdentifier.GetPlaceIdWithName(name: string): number
	if not setuped then setupedEvent.Event:Wait() end
	return EnvironmentIdentifier.envData.mapEnvPlaceId[EnvironmentIdentifier.currentEnvironment.environment][name]
end

return EnvironmentIdentifier