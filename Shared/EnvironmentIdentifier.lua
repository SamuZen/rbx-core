local EnvironmentIdentifier = {}
export type AmbientIdMapData = {
    Environments: {[string]: number | {number}},
    DefaultEnv: string,
}

EnvironmentIdentifier.CurrentEnvironment = nil :: {Key: string, Id: number} | nil
EnvironmentIdentifier.Environments = {}

function EnvironmentIdentifier.Setup(map: AmbientIdMapData)
    local currentPlaceId = game.PlaceId
    -- find current

    local found = false
    for key, placeId in map.Environments do
        local ids
        if typeof(placeId) == "number" then
            ids = {placeId}
        else
            ids = placeId
        end

        for _, id in ids do
            if currentPlaceId == id then
                EnvironmentIdentifier.CurrentEnvironment = {
                    Id = id,
                    Key = key,
                }
                found = true
                break
            end
        end
    end

    if not found then
        EnvironmentIdentifier.CurrentEnvironment = {
            Id = currentPlaceId,
            Key = map.DefaultEnv,
        }
    end
    warn(`AMBIENT: {EnvironmentIdentifier.CurrentEnvironment.Key} - PLACEID:{EnvironmentIdentifier.CurrentEnvironment.Id}`)
end

function EnvironmentIdentifier.IsKey(key: string)
    return EnvironmentIdentifier.CurrentEnvironment.Key == key
end

function EnvironmentIdentifier.IsId(id: number)
    return EnvironmentIdentifier.CurrentEnvironment.Id == id
end

return EnvironmentIdentifier