local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Shared = game.ReplicatedStorage:WaitForChild("CalmWorksShared")
local settings = Shared:WaitForChild("NPCPresentation")
local Policy = require(Shared.NPCPresentationPolicy)
local player = Players.LocalPlayer
local records = {}
local looking = {}
local staticLooking = {}
local cue = settings.ConsultationHighlight:Clone()
cue.Name = "LocalConsultationHighlight"
cue.Enabled = false
cue.Parent = player.PlayerGui

local function setting(name, fallback)
    local value = settings:GetAttribute(name)
    if type(value) ~= "number" or value ~= value then
        return fallback
    end
    return value
end

local function register(gui)
    if not gui:IsA("BillboardGui") then
        return
    end
    local head = gui.Parent
    local model = head and head.Parent
    if not head or head.Name ~= "Head" or not model or not model:IsA("Model")
        or not model:FindFirstChildOfClass("Humanoid") or Players:GetPlayerFromCharacter(model) then
        return
    end
    local record = records[model]
    if not record then
        record = { Head = head, Guis = {} }
        records[model] = record
    end
    if record.Guis[gui] then
        return
    end
    local entry = { Offset = gui.StudsOffsetWorldSpace, MaxDistance = gui.MaxDistance, Shift = Vector3.zero }
    record.Guis[gui] = entry
    entry.Connection = gui:GetPropertyChangedSignal("MaxDistance"):Connect(function()
        if gui.MaxDistance ~= entry.AppliedDistance then
            entry.MaxDistance = gui.MaxDistance
        end
    end)
    entry.OffsetConnection = gui:GetPropertyChangedSignal("StudsOffsetWorldSpace"):Connect(function()
        if gui.StudsOffsetWorldSpace ~= entry.AppliedOffset then
            entry.Offset = gui.StudsOffsetWorldSpace
        end
    end)
end

local function apply(gui, entry, visible, shift)
    entry.AppliedDistance = visible and entry.MaxDistance or 0
    entry.AppliedOffset = entry.Offset + shift
    entry.Shift = shift
    gui.MaxDistance = entry.AppliedDistance
    gui.StudsOffsetWorldSpace = entry.AppliedOffset
end

local function restore(record)
    for gui, entry in pairs(record.Guis) do
        if gui.Parent then
            apply(gui, entry, true, Vector3.zero)
        end
    end
end

local function updateLabels()
    local camera = workspace.CurrentCamera
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not camera or not root then
        for _, record in pairs(records) do
            restore(record)
        end
        cue.Enabled = false
        return
    end
    local enabled = settings:GetAttribute("Enabled") ~= false
    local candidates = {}
    local closest
    local closestDistance = setting("CueDistance", 18)
    for model, record in pairs(records) do
        if not model:IsDescendantOf(workspace) then
            restore(record)
            for _, entry in pairs(record.Guis) do
                entry.Connection:Disconnect()
                entry.OffsetConnection:Disconnect()
            end
            records[model] = nil
            continue
        end
        local distance = (record.Head.Position - root.Position).Magnitude
        local active = model:GetAttribute("ConversationOwnerId") == player.UserId
        local needed = model:GetAttribute("AttentionOwnerId") == player.UserId
            and model:GetAttribute("AttentionActive") == true
            and model:GetAttribute("AttentionNeeded") == true
            and model:GetAttribute("CounselorServing") ~= true
        if enabled and needed and distance < closestDistance then
            closest, closestDistance = model, distance
        end
        if enabled and settings:GetAttribute("AvoidLabelOverlap") ~= false
            and distance <= setting("LabelDistance", 80) then
            table.insert(candidates, {
                Model = model, Record = record, Distance = distance,
                Priority = active and 0 or (needed and 1 or 2),
            })
        elseif enabled and settings:GetAttribute("AvoidLabelOverlap") ~= false then
            for gui, entry in pairs(record.Guis) do
                if gui.Parent then
                    apply(gui, entry, false, Vector3.zero)
                end
            end
        else
            restore(record)
        end
    end
    table.sort(candidates, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        if a.Distance ~= b.Distance then
            return a.Distance < b.Distance
        end
        return a.Model:GetFullName() < b.Model:GetFullName()
    end)
    local occupied = {}
    for _, item in ipairs(candidates) do
        local record = item.Record
        local headPoint, onScreen = camera:WorldToViewportPoint(record.Head.Position)
        if not onScreen or headPoint.Z <= 0 then
            restore(record)
            continue
        end
        local pixelsPerStud = camera.ViewportSize.Y
            / (2 * math.tan(math.rad(camera.FieldOfView / 2)) * headPoint.Z)
        local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
        for gui, entry in pairs(record.Guis) do
            if gui.Parent and gui.Enabled and item.Distance <= entry.MaxDistance then
                local center = record.Head.Position + camera.CFrame:VectorToWorldSpace(gui.StudsOffset) + entry.Offset
                local point = camera:WorldToViewportPoint(center)
                local scale = camera.ViewportSize.Y
                    / (2 * math.tan(math.rad(camera.FieldOfView / 2)) * math.max(0.1, point.Z))
                local size = Vector2.new(gui.Size.X.Scale * scale + gui.Size.X.Offset,
                    gui.Size.Y.Scale * scale + gui.Size.Y.Offset)
                local p = Vector2.new(point.X, point.Y) - size / 2
                    + Vector2.new(gui.SizeOffset.X * size.X, gui.SizeOffset.Y * size.Y)
                if size.X > 0 and size.Y > 0 then
                    left, top = math.min(left, p.X), math.min(top, p.Y)
                    right, bottom = math.max(right, p.X + size.X), math.max(bottom, p.Y + size.Y)
                end
            end
        end
        if left == math.huge then
            restore(record)
            continue
        end
        local rect = { X = left, Y = top, W = right - left, H = bottom - top }
        local shift, placed = Policy.Place(rect, occupied, setting("LabelStepPixels", 24),
            setting("LabelLiftSteps", 4), setting("LabelGapPixels", 4), camera.ViewportSize)
        -- Keep the nearest/active visitor legible; crowded distant labels return as the view opens.
        if not shift and #occupied == 0 then
            shift, placed = 0, rect
        end
        if placed then
            table.insert(occupied, placed)
        end
        local offset = camera.CFrame.UpVector * (-(shift or 0) / math.max(0.01, pixelsPerStud))
        for gui, entry in pairs(record.Guis) do
            if gui.Parent then
                apply(gui, entry, shift ~= nil, offset)
            end
        end
    end
    cue.Adornee = closest
    cue.Enabled = enabled and settings:GetAttribute("ShowReadyCue") ~= false and closest ~= nil
end

local function updateGaze(dt)
    local target = player.Character and player.Character:FindFirstChild("Head")
    local alive = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    for model, record in pairs(records) do
        local active = settings:GetAttribute("Enabled") ~= false
            and settings:GetAttribute("FacePlayer") ~= false
            and model:GetAttribute("ConversationOwnerId") == player.UserId
            and target and alive and alive.Health > 0
        if active then
            local neck = model:FindFirstChild("Neck", true)
            if neck and neck:IsA("Motor6D") and neck.Part0 and neck.Part1 then
                if not looking[model] then
                    looking[model] = { Neck = neck, Original = neck.C0, Angle = CFrame.identity }
                end
            end
        end
        if active and model:GetAttribute("TutorialOnly") == true and not model:FindFirstChild("Neck", true) then
            local anchored = true
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    anchored = false
                    break
                end
            end
            if anchored and not staticLooking[model] then
                staticLooking[model] = model:GetPivot()
            end
        end
        local originalPivot = staticLooking[model]
        if originalPivot then
            local desired = originalPivot
            if active then
                local position = originalPivot.Position
                local toward = Vector3.new(target.Position.X, position.Y, target.Position.Z)
                if (toward - position).Magnitude > 0.1 then
                    desired = CFrame.lookAt(position, toward)
                end
            end
            model:PivotTo(model:GetPivot():Lerp(desired, 1 - math.exp(-setting("TurnSpeed", 7) * dt)))
            if not active then
                local _, angle = (model:GetPivot():Inverse() * originalPivot):ToAxisAngle()
                if math.abs(angle) < 0.001 then
                    model:PivotTo(originalPivot)
                    staticLooking[model] = nil
                end
            end
        end
        local look = looking[model]
        if look then
            local neck = look.Neck
            if not neck.Parent or not neck.Part0 then
                looking[model] = nil
                continue
            end
            local desired = CFrame.identity
            if active and (target.Position - record.Head.Position).Magnitude < setting("FaceDistance", 28) then
                local direction = neck.Part0.CFrame:VectorToObjectSpace(target.Position - record.Head.Position)
                local yaw = math.atan2(-direction.X, -direction.Z)
                local pitch = math.atan2(direction.Y, math.max(0.01, Vector2.new(direction.X, direction.Z).Magnitude))
                yaw = math.clamp(yaw, -math.rad(setting("MaxYaw", 65)), math.rad(setting("MaxYaw", 65)))
                pitch = math.clamp(pitch, -math.rad(setting("MaxPitch", 20)), math.rad(setting("MaxPitch", 20)))
                pitch += math.sin(os.clock() * 1.8) * math.rad(setting("IdleDegrees", 0.5))
                desired = CFrame.Angles(pitch, yaw, 0)
            end
            look.Angle = look.Angle:Lerp(desired, 1 - math.exp(-setting("TurnSpeed", 7) * dt))
            neck.C0 = CFrame.new(look.Original.Position) * look.Angle * look.Original.Rotation
            if not active then
                local _, angle = look.Angle:ToAxisAngle()
                if math.abs(angle) < 0.001 then
                    neck.C0 = look.Original
                    looking[model] = nil
                end
            end
        end
    end
    for model in pairs(staticLooking) do
        if not records[model] then
            staticLooking[model] = nil
        end
    end
    for model, look in pairs(looking) do
        if not records[model] then
            if look.Neck.Parent then
                look.Neck.C0 = look.Original
            end
            looking[model] = nil
        end
    end
end

for _, object in ipairs(workspace:GetDescendants()) do
    register(object)
end
workspace.DescendantAdded:Connect(function(object)
    if object:IsA("BillboardGui") then
        task.defer(register, object)
    end
end)
RunService.PreSimulation:Connect(updateGaze)
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
    elapsed += dt
    if elapsed >= setting("LabelUpdateSeconds", 0.15) then
        elapsed = 0
        updateLabels()
    end
end)
