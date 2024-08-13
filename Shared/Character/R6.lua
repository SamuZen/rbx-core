local module = {}

function module.SetupHandSlots(model: Model)

    local function createSlot(part, att:Attachment, name)
        local existing = model:FindFirstChild(name)
        if existing then existing:Destroy() end
        local slotPart = Instance.new("Part")
        slotPart.Size = Vector3.new(0.5,0.5,0.5)
        slotPart.Anchored = false
        slotPart.CanCollide = false
        slotPart.CanQuery = false
        slotPart.Transparency = 0.5
        
        slotPart.Name = name
        slotPart.CFrame = att.WorldCFrame
        slotPart.Parent = model
        
        local existingMotor = part:FindFirstChild(name)
        if existingMotor then existingMotor:Destroy() end
        local motor = Instance.new("Motor6D")
        motor.Name = name
        motor.Part0 = part
        motor.Part1 = slotPart
        motor.C0 = att.CFrame
        motor.Parent = part
        
    end
    
    if model:FindFirstChild("LeftHandSlot") == nil then
		local arm = model:WaitForChild("Left Arm")
		createSlot(arm, arm.LeftGripAttachment, "LeftHandSlot")
    end
	if model:FindFirstChild("RightHandSlot") == nil then
		local arm = model:WaitForChild("Right Arm")
		createSlot(arm, arm.RightGripAttachment, "RightHandSlot")
    end
end

return module