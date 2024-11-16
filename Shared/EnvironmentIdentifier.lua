local EnvironmentIdentifier = {}
export type AmbientIdMapData = {
    environments: {[string]: number},
    defaultEnv: string,
    defaultPlace: string,
}

EnvironmentIdentifier.currentEnvironment = nil :: {placeName:string, environment: string, placeId: number} | nil
EnvironmentIdentifier.environmentData = {}

function EnvironmentIdentifier.Setup(map: AmbientIdMapData)
    local currentPlaceId = game.PlaceId
    -- find current

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
    warn(`AMBIENT: {EnvironmentIdentifier.currentEnvironment.environment} - PLACE: {EnvironmentIdentifier.currentEnvironment.placeName} ({EnvironmentIdentifier.currentEnvironment.placeId})`)
end

function EnvironmentIdentifier.IsEnv(env: string): boolean
    return EnvironmentIdentifier.currentEnvironment.environment == env
end

function EnvironmentIdentifier.IsId(id: number): boolean
    return EnvironmentIdentifier.currentEnvironment.placeId == id
end

function EnvironmentIdentifier.GetPlaceId(place: string): number
    return EnvironmentIdentifier.environmentData[place]
end

return EnvironmentIdentifier