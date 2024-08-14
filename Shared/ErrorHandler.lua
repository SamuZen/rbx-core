

local ErrorHandler = {}

function ErrorHandler.CreateError(number, message)
    return {
        error = {
            code = number,
            message = message
        }
    }
end

function ErrorHandler.GetError(data: any)
    if typeof(data) == "table" and data.error ~= nil then
        return data.error.code, data.error.message
    end
end

return ErrorHandler