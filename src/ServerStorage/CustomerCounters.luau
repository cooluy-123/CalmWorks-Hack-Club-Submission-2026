local Navigation = require(script.Parent.CustomerNavigation)
local Routing = require(script.Parent.CustomerRouting)
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local AttentionPolicy = require(game.ReplicatedStorage.CalmWorksShared.AttentionPolicy)
local Counters = {}

function Counters.RequiresPlayer(data, executiveHelp)
    if not data then
        return false
    end
    if data.Angry == true or data.PersonalHelp == true then
        return true
    end
    return data.Kind == "Staff" and executiveHelp ~= true
end

function Counters.New(mainQueue, dataMap, points, settings, callbacks)
    local self = {
        Queues = { Main = mainQueue, Left = {}, Right = {}, UpperLeft = {}, UpperRight = {} },
        LastArea = 0,
        LastUpper = 0,
    }
    local areas = { "Main", "Left", "Right" }

    function self:Points(area)
        return area == "Main" and points or points:FindFirstChild(area)
    end

    function self:Queue(model)
        local data = dataMap[model]
        return self.Queues[data and data.Area or "Main"] or mainQueue
    end

    function self:IsFront(model)
        return model ~= nil and self:Queue(model)[1] == model
    end

    function self:ExecutiveHelp(model, data, area)
        return callbacks.CanServeStaff ~= nil and callbacks.CanServeStaff(model, data, area) == true
    end

    function self:PlayerOnlyStatus(area)
        local queue = self.Queues[area] or {}
        local waiting = 0
        for _, model in ipairs(queue) do
            if model.Parent and dataMap[model] and dataMap[model].Angry == true then
                waiting += 1
            end
        end
        local first = queue[1]
        local blocked = first ~= nil and first.Parent ~= nil and Counters.RequiresPlayer(dataMap[first], self:ExecutiveHelp(first, dataMap[first], area))
        return waiting, blocked
    end

    function self:HasStaffVisit(area)
        for _, model in ipairs(self.Queues[area] or {}) do
            local data = dataMap[model]
            if model.Parent and data and data.Kind == "Staff" then
                return true
            end
        end
        return false
    end

    function self:CanAutoClear(area)
        if not callbacks.Staffed(area) then
            return false
        end
        for _, model in ipairs(self.Queues[area] or {}) do
            local data = dataMap[model]
            if model.Parent and data then
                if data.Kind == "BusinessMan" or callbacks.Active() == model
                    or Counters.RequiresPlayer(data, self:ExecutiveHelp(model, data, area)) then
                    return false
                end
            end
        end
        return true
    end

    function self:CanAccept(area, reserved)
        local queue = self.Queues[area]
        if not queue then
            return false
        end
        if Routing.IsUpper(area) then
            if not callbacks.Upstairs or not callbacks.Upstairs() then
                return false
            end
        elseif area ~= "Main" and not callbacks.Expanded() then
            return false
        end
        local capacity = callbacks.Capacity(area)
        if not reserved and Routing.IsUpper(area) and callbacks.ReservedUpperSlots then
            capacity = math.max(1, capacity - callbacks.ReservedUpperSlots())
        end
        return #queue < capacity
    end

    function self:ChooseArea(floor, reserved, allowed)
        local choices = areas
        local enabled = callbacks.Expanded() and 3 or 1
        local last = self.LastArea
        if floor == "Upper" then
            choices = { "UpperLeft", "UpperRight" }
            enabled = 2
            last = self.LastUpper
        end
        local best, length
        for i = 1, enabled do
            local index = (last + i - 1) % enabled + 1
            local area = choices[index]
            local count = #self.Queues[area]
            if self:CanAccept(area, reserved) and (not allowed or allowed(area))
                and (not length or count < length) then
                best, length = index, count
            end
        end
        if best then
            if floor == "Upper" then
                self.LastUpper = best
            else
                self.LastArea = best
            end
            return choices[best]
        end
    end

    function self:SetAttention(model, needed)
        if model:GetAttribute("AttentionNeeded") ~= needed then
            model:SetAttribute("AttentionNeeded", needed)
        end
    end

    function self:Add(model, area)
        dataMap[model].Area = area
        model:SetAttribute("CounterArea", area)
        local owner = callbacks.Owner()
        model:SetAttribute("AttentionOwnerId", owner and owner.UserId)
        model:SetAttribute("AttentionVisitId", HttpService:GenerateGUID(false))
        model:SetAttribute("AttentionActive", true)
        self:SetAttention(model, false)
        CollectionService:AddTag(model, "CalmWorksHelpVisitor")
        table.insert(self.Queues[area], model)
    end

    function self:Remove(model)
        self:SetAttention(model, false)
        model:SetAttribute("AttentionActive", false)
        CollectionService:RemoveTag(model, "CalmWorksHelpVisitor")
        -- A missing visitor record must not leave a ghost blocking an upstairs queue.
        for _, queue in pairs(self.Queues) do
            local index = table.find(queue, model)
            if index then
                table.remove(queue, index)
            end
        end
    end

    local function move(model, target, valid)
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then
            return false
        end
        local deadline, nextMove = os.clock() + 18, 0
        while valid() and os.clock() < deadline do
            if
                (Vector3.new(root.Position.X, target.Y, root.Position.Z) - target).Magnitude < 2
                and math.abs(root.Position.Y - target.Y) < 6
            then
                return true
            end
            if os.clock() >= nextMove then
                humanoid:MoveTo(target)
                nextMove = os.clock() + 3
            end
            task.wait(0.15)
        end
        return false
    end

    function self:Update()
        for area, queue in pairs(self.Queues) do
            local markers = self:Points(area)
            for index, model in ipairs(queue) do
                local data = dataMap[model]
                local marker = markers and markers:FindFirstChild("Queue" .. index)
                if data and marker and model.Parent and data.Target ~= marker.Position then
                    data.Target = marker.Position
                    data.ArrivedAt = nil
                    data.Prompt.Enabled = false
                    self:SetAttention(model, false)
                    data.MoveVersion = (data.MoveVersion or 0) + 1
                    local version = data.MoveVersion
                    task.spawn(function()
                        local function valid()
                            return model.Parent and dataMap[model] == data and data.MoveVersion == version
                        end
                        if data.TransferPoints then
                            for i = data.TransferIndex or 1, #data.TransferPoints do
                                if not Navigation.Walk(model, data.TransferPoints[i], valid) then
                                    if valid() then
                                        callbacks.Stuck(model)
                                    end
                                    return
                                end
                                data.TransferIndex = i + 1
                            end
                        end
                        if Routing.IsUpper(area) and not data.Entered then
                            if not Navigation.Route(model, markers.Inbound, false, data, valid) then
                                if valid() then
                                    callbacks.Stuck(model)
                                end
                                return
                            end
                            data.Entered = true
                        elseif area ~= "Main" and not data.Entered then
                            for _, name in ipairs({ "Approach", "Entrance" }) do
                                if not data["Passed" .. name] then
                                    if not move(model, markers[name].Position, valid) then
                                        if valid() then
                                            callbacks.Stuck(model)
                                        end
                                        return
                                    end
                                    data["Passed" .. name] = true
                                end
                            end
                            data.Entered = true
                        end
                        local walk = move
                        if Routing.IsUpper(area) then
                            walk = Navigation.Walk
                        end
                        if walk(model, marker.Position, valid) then
                            if valid() then
                                data.ArrivedAt = os.clock()
                                if data.Kind == "Staff" then
                                    model:SetAttribute("ConsultationState", "WaitingInLine")
                                end
                            end
                        elseif valid() then
                            callbacks.Stuck(model)
                        end
                    end)
                end
            end
        end
    end

    function self:WalkOut(model, area)
        local markers = self:Points(area or "Main")
        task.spawn(function()
            local function valid()
                return model.Parent ~= nil
            end
            if markers and Routing.IsUpper(area) then
                if not Navigation.Route(model, markers.Inbound, true, nil, valid) then
                    warn("CalmWorks: upstairs exit route blocked; removing departing visitor.")
                    if model.Parent then
                        model:Destroy()
                    end
                    return
                end
            elseif markers and area ~= "Main" then
                move(model, markers.Entrance.Position, valid)
                move(model, markers.Approach.Position, valid)
            end
            move(model, points.Exit.Position, valid)
            if model.Parent then
                model:Destroy()
            end
        end)
    end

    function self:Reset()
        for _, queue in pairs(self.Queues) do
            for _, model in ipairs(queue) do
                self:SetAttention(model, false)
                model:SetAttribute("AttentionActive", false)
                CollectionService:RemoveTag(model, "CalmWorksHelpVisitor")
            end
            table.clear(queue)
        end
        self.LastArea = 0
        self.LastUpper = 0
    end

    function self:Tick()
        local owner = callbacks.Owner()
        if not owner then
            return
        end
        for area, queue in pairs(self.Queues) do
            local model = queue[1]
            local data = model and dataMap[model]
            if data and data.ArrivedAt and model.Parent then
                if not data.Serving and callbacks.RequestPersonalHelp then
                    callbacks.RequestPersonalHelp(owner, model, data, area)
                end
                if data.Kind == "BusinessMan" then
                    data.Prompt.Enabled = callbacks.Active() == nil
                elseif Counters.RequiresPlayer(data, self:ExecutiveHelp(model, data, area)) then
                    if data.Kind == "Staff" then
                        model:SetAttribute("ConsultationState", "WaitingForPlayer")
                    end
                    -- Player-only visitors hold this queue until their whole scenario is resolved.
                    data.Serving = false
                    data.ServiceOwner = nil
                    data.ServiceProgress = nil
                    data.ServiceLastAt = nil
                    model:SetAttribute("CounselorServing", false)
                    data.Prompt.Enabled = callbacks.Active() == nil
                elseif data.Serving then
                    if data.Kind == "Staff" then
                        model:SetAttribute("ConsultationState", "WithExecutive")
                    end
                    local now = os.clock()
                    local seconds = callbacks.ServiceSeconds and callbacks.ServiceSeconds(area)
                        or tonumber(settings:GetAttribute("CounselorServiceSeconds"))
                        or 12
                    if seconds ~= seconds or math.abs(seconds) == math.huge then
                        seconds = 12
                    end
                    seconds = math.clamp(seconds, 0.25, 240)
                    if callbacks.Staffed(area) and callbacks.Active() ~= model then
                        data.ServiceProgress += math.max(0, now - data.ServiceLastAt) / seconds
                    end
                    data.ServiceLastAt = now
                    model:SetAttribute("CounselorServiceSeconds", seconds)
                    if data.ServiceProgress >= 1 and data.ServiceOwner == owner and callbacks.Active() ~= model then
                        callbacks.Served(owner, model, data)
                    end
                else
                    if data.Kind == "Staff" then
                        model:SetAttribute("ConsultationState", "WaitingForExecutive")
                    end
                    data.Prompt.Enabled = callbacks.Active() == nil
                    local grace =
                        math.clamp(tonumber(settings:GetAttribute("PlayerHelpGraceSeconds")) or 8, 1, 120)
                    if
                        callbacks.Staffed(area)
                        and callbacks.Active() ~= model
                        and os.clock() - data.ArrivedAt >= grace
                    then
                        data.Serving = true
                        if data.Kind == "Staff" then
                            model:SetAttribute("ConsultationState", "WithExecutive")
                        end
                        data.Prompt.Enabled = false
                        model:SetAttribute("CounselorServing", true)
                        data.ServiceOwner = owner
                        data.ServiceProgress = 0
                        data.ServiceLastAt = os.clock()
                    end
                end
            end
            -- Only actionable front-of-line visitors should request the owner's attention.
            for index, visitor in ipairs(queue) do
                local entry = dataMap[visitor]
                local needed = AttentionPolicy.NeedsHelp(
                    entry,
                    index == 1,
                    callbacks.HasStaff and callbacks.HasStaff(area) or callbacks.Staffed(area),
                    callbacks.Active() == visitor,
                    self:ExecutiveHelp(visitor, entry, area)
                )
                self:SetAttention(visitor, needed)
            end
        end
    end

    task.spawn(function()
        local warnedAt = -math.huge
        while true do
            task.wait(0.25)
            local okay, reason = pcall(function()
                self:Tick()
            end)
            if not okay and os.clock() - warnedAt >= 30 then
                warnedAt = os.clock()
                warn("CalmWorks counter update failed; retrying: " .. tostring(reason))
            end
        end
    end)
    return self
end

return Counters
