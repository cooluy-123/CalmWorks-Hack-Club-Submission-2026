local Navigation = require(script.Parent.CustomerNavigation)
local Staff = {}
local Seating = require(script.Parent.PrivateSeating)
local Policy = require(script.Parent.StaffMoralePolicy)

function Staff.New(settings, points, findStaff, moraleSettings)
    local self = { Active = nil, NextVisitAt = 0, RetryAt = {} }

    function self:CanTake(staff)
        if os.clock() < (self.RetryAt[staff.Id] or 0) then
            return false
        end
        local model = findStaff(staff.Area, staff.Role)
        local root = model and model:FindFirstChild("HumanoidRootPart")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        return root ~= nil and humanoid ~= nil and humanoid.Health > 0
            and root:FindFirstChild("StaffHelpPrompt") ~= nil
            and model:FindFirstChild("StaffConcernGui", true) ~= nil
    end

    function self:Away(area, role)
        local record = self.Active
        return record ~= nil and record.Area == area and record.Role == role
    end

    local function restore(record)
        for _, connection in ipairs(record.Connections) do
            connection:Disconnect()
        end
        if record.Track then
            record.Track:Stop(0)
            record.Track:Destroy()
        end
        local model = record.Model
        if not model.Parent then
            return
        end
        local humanoid = record.Humanoid
        humanoid:Move(Vector3.zero)
        humanoid.EvaluateStateMachine = false
        for part, values in pairs(record.Parts) do
            if part.Parent then
                part.Anchored = true
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                part.CFrame = values.CFrame
                part.CanCollide = values.CanCollide
                part.CanTouch = values.CanTouch
                part.CanQuery = values.CanQuery
                part.CollisionGroup = values.CollisionGroup
            end
        end
        for motor, transform in pairs(record.Motors) do
            if motor.Parent then
                motor.Transform = transform
            end
        end
        for part, values in pairs(record.Parts) do
            if part.Parent then
                part.Anchored = values.Anchored
            end
        end
        humanoid.AutoRotate = record.AutoRotate
        humanoid.WalkSpeed = record.WalkSpeed
        humanoid.EvaluateStateMachine = record.EvaluateStateMachine
        record.Prompt.Enabled = false
        record.Gui.Enabled = false
        model:SetAttribute("OnConsultation", false)
        model:SetAttribute("ConsultationState", "AtWork")
        model:SetAttribute("ConsultationStairway", nil)
    end

    function self:Recover(model)
        local record = self.Active
        if not record or record.Model ~= model then
            return
        end
        self.Active = nil
        restore(record)
        local delay = math.clamp(tonumber(settings:GetAttribute("MinimumSecondsBetweenVisits")) or 60, 0, 600)
        if not record.Helped then
            self.RetryAt[record.StaffId] = os.clock() + Policy.Setting(moraleSettings, "FailedVisitRetrySeconds", 30, 5, 600)
            delay = 2
        elseif record.MoraleDriven then
            delay = Policy.Setting(moraleSettings, "MoraleVisitGapSeconds", 8, 0, 600)
        end
        self.NextVisitAt = os.clock() + delay
    end

    function self:Take(state, preferred, canVisit)
        if self.Active or os.clock() < self.NextVisitAt then
            return nil
        end
        local last = preferred and 0 or #Policy.Roster - 1
        for offset = 0, last do
            local index = ((preferred or state.NextStaff) - 1 + offset) % #Policy.Roster + 1
            local staff = Policy.Roster[index]
            local area = staff.Area
            local role = staff.Role
            local model
            if self:CanTake(staff) and (not canVisit or canVisit(staff)) then
                model = findStaff(area, role)
            end
            local root = model and model:FindFirstChild("HumanoidRootPart")
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            local prompt = root and root:FindFirstChild("StaffHelpPrompt")
            local gui = model and model:FindFirstChild("StaffConcernGui", true)
            if model and root and humanoid and prompt and gui and humanoid.Health > 0 then
                if staff.Private then
                    Seating.Stand(model)
                    local approach = model:FindFirstChild("PrivateApproach")
                    if approach and approach.Value then
                        model:PivotTo(CFrame.new(approach.Value.Position))
                    end
                end
                local record = {
                    Model = model,
                    StaffId = staff.Id,
                    MoraleDriven = preferred ~= nil,
                    Root = root,
                    Humanoid = humanoid,
                    Prompt = prompt,
                    Gui = gui,
                    Area = area,
                    HomeRoom = staff.Room or area,
                    Private = staff.Private,
                    Role = role,
                    Home = root.Position,
                    Parts = {},
                    Motors = {},
                    Connections = {},
                    AutoRotate = humanoid.AutoRotate,
                    WalkSpeed = humanoid.WalkSpeed,
                    EvaluateStateMachine = humanoid.EvaluateStateMachine,
                }
                for _, item in ipairs(model:GetDescendants()) do
                    if item:IsA("BasePart") then
                        record.Parts[item] = {
                            CFrame = item.CFrame,
                            Anchored = item.Anchored,
                            CanCollide = item.CanCollide,
                            CanTouch = item.CanTouch,
                            CanQuery = item.CanQuery,
                            CollisionGroup = item.CollisionGroup,
                        }
                        item.Anchored = false
                        item.CanCollide = false
                        item.CanTouch = false
                        item.CollisionGroup = "CalmWorksCustomers"
                    elseif item:IsA("Motor6D") then
                        record.Motors[item] = item.Transform
                    end
                end
                -- The root supplies floor contact; the customer group prevents player/NPC collisions.
                root.CanCollide = true
                humanoid.EvaluateStateMachine = true
                humanoid.AutoRotate = true
                humanoid.PlatformStand = false
                humanoid.WalkSpeed = math.clamp(tonumber(settings:GetAttribute("WalkSpeed")) or 10, 6, 20)
                root:SetNetworkOwner(nil)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                local animation = model:FindFirstChild("ConsultationWalk")
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animation and animator then
                    local okay, track = pcall(function()
                        return animator:LoadAnimation(animation)
                    end)
                    if okay then
                        record.Track = track
                        track.Looped = true
                        track.Priority = Enum.AnimationPriority.Movement
                        table.insert(
                            record.Connections,
                            humanoid.Running:Connect(function(speed)
                                if speed > 0.1 then
                                    if not track.IsPlaying then
                                        track:Play(0.15)
                                    end
                                    track:AdjustSpeed(math.clamp(speed / 10, 0.5, 1.5))
                                elseif track.IsPlaying then
                                    track:Stop(0.2)
                                end
                            end)
                        )
                    else
                        warn("CalmWorks staff walk animation unavailable: " .. tostring(track))
                    end
                end
                self.Active = record
                state.NextStaff = index % #Policy.Roster + 1
                model:SetAttribute("OnConsultation", true)
                model:SetAttribute("ConsultationState", "Travelling")
                gui.Enabled = true
                return record
            end
        end
        return nil
    end

    function self:Return(model, upperArea)
        local record = self.Active
        if not record or record.Model ~= model then
            return
        end
        record.Prompt.Enabled = false
        record.Returning = true
        model:SetAttribute("ConsultationState", "Returning")
        task.spawn(function()
            local timeout = math.clamp(tonumber(settings:GetAttribute("RouteTimeoutSeconds")) or 120, 30, 300)
            local deadline = os.clock() + timeout
            local function valid()
                return self.Active == record and model.Parent ~= nil and os.clock() < deadline
            end
            local okay, arrived = pcall(function()
                local markers = points:FindFirstChild(upperArea)
                local route = markers and markers:FindFirstChild("Inbound")
                local steps = route and route:GetChildren() or {}
                table.sort(steps, function(a, b)
                    return a.Name < b.Name
                end)
                if record.TransferPoints then
                    for i = #record.TransferPoints, 1, -1 do
                        if not Navigation.Walk(model, record.TransferPoints[i], valid) then
                            return false
                        end
                    end
                    return Navigation.Walk(model, record.Home, valid)
                end
                -- Return to the stair foot, then the original workstation, not the street exit.
                for i = #steps, 3, -1 do
                    if not Navigation.Walk(model, steps[i].Position, valid) then
                        return false
                    end
                end
                return #steps > 0 and Navigation.Walk(model, record.Home, valid)
            end)
            if self.Active == record then
                if not okay or not arrived then
                    warn("CalmWorks: staff return route blocked; safely restoring the workstation.")
                end
                self:Recover(model)
            end
        end)
    end

    function self:Reset()
        local record = self.Active
        self.Active = nil
        if record then
            restore(record)
        end
        self.NextVisitAt = 0
        table.clear(self.RetryAt)
    end

    return self
end

return Staff
