local Seating = {}

function Seating.IsSeated(model, seat)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local weld = seat and seat:FindFirstChild("SeatWeld")
    return humanoid ~= nil
        and humanoid.Sit
        and seat.Occupant == humanoid
        and weld ~= nil
        and weld.Part1 ~= nil
        and weld.Part1:IsDescendantOf(model)
end

function Seating.Stand(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local seat = humanoid and humanoid.SeatPart
    if seat then
        local weld = seat:FindFirstChild("SeatWeld")
        if weld and weld.Part1 and weld.Part1:IsDescendantOf(model) then
            weld:Destroy()
        end
    end
    for _, motor in ipairs(model:GetDescendants()) do
        if motor:IsA("Motor6D") then
            local original = motor:GetAttribute("PrivateOriginalC0")
            if original then
                motor.C0 = original
                motor:SetAttribute("PrivateOriginalC0", nil)
            end
        end
    end
    if humanoid then
        humanoid.Sit = false
        humanoid.EvaluateStateMachine = true
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

function Seating.Sit(model, seat)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 or not seat then
        return false
    end
    if seat.Occupant and seat.Occupant ~= humanoid then
        return false
    end
    if Seating.IsSeated(model, seat) then
        return true
    end
    -- Roblox can retain a stale SeatPart after standing. Renew only that runtime seat.
    if humanoid.SeatPart == seat then
        local parent = seat.Parent
        local replacement = seat:Clone()
        local oldWeld = replacement:FindFirstChild("SeatWeld")
        if oldWeld then
            oldWeld:Destroy()
        end
        seat:Destroy()
        replacement.Parent = parent
        seat = replacement
    end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CollisionGroup = "CalmWorksCustomers"
        end
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
    humanoid.EvaluateStateMachine = true
    humanoid.AutoRotate = false
    root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    seat:Sit(humanoid)
    -- R6 templates have no Animate script; keep an editable joint-based seated pose.
    local torso = model:FindFirstChild("Torso")
    if torso then
        for _, name in ipairs({ "Left Hip", "Right Hip" }) do
            local motor = torso:FindFirstChild(name)
            if motor and not motor:GetAttribute("PrivateOriginalC0") then
                motor:SetAttribute("PrivateOriginalC0", motor.C0)
                local angle = name == "Left Hip" and -90 or 90
                motor.C0 *= CFrame.Angles(0, 0, math.rad(angle))
            end
        end
    end
    return Seating.IsSeated(model, seat)
end

return Seating

