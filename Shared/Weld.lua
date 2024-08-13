local function _weld(p0: BasePart, p1: BasePart): WeldConstraint
    local weld = Instance.new("WeldConstraint")
    weld.Parent = p0
    weld.Part0 = p0
    weld.Part1 = p1
    return weld
end

return _weld