export type Class = {
    New: () -> ClassInstance
}

export type ClassInstance = {
    T: number,
    Reset: () -> nil,
    GetDelta: () -> number,
    GetDeltaString: (nil, decimals: number) -> string,
    Destroy: () -> nil,
}

local BenchmarkClock: Class | ClassInstance = {}
BenchmarkClock.__index = BenchmarkClock
function BenchmarkClock.New(): ClassInstance
    local self = setmetatable({}, BenchmarkClock)
    self.T = os:clock()
    return self
end

function BenchmarkClock:Reset()
    self.T = os:clock()
end

function BenchmarkClock:GetDelta()
    return self.T - os:clock()
end

function BenchmarkClock:GetDeltaString(decimals)
    decimals = math.round(decimals)
    local delta = self:GetDelta()
    return string.format("%." .. decimals .. "f", delta)
end

function BenchmarkClock:Destroy()
    self.T = nil
end

return BenchmarkClock