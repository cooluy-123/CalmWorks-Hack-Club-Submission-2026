local Policy = require(script.Parent.PrivateSessionPolicy)
local Seating = require(script.Parent.PrivateSeating)
local Navigation = require(script.Parent.CustomerNavigation)
local Routing = require(script.Parent.CustomerRouting)
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Service = {}

function Service.New(settings, points, callbacks)
    local self = { Slots = {}, Root = nil, LastUnstaffedAt = -math.huge }
    local rng = Random.new()

    function self:Employee(id)
        return callbacks.Employee(id)
    end

    function self:IsStaffed(id)
        local employee = self:Employee(id)
        local humanoid = employee and employee:FindFirstChildOfClass("Humanoid")
        return humanoid ~= nil and humanoid.Health > 0 and not callbacks.Away(id)
    end

    function self:Busy(id)
        local slot = self.Slots[id]
        return slot and slot.Token ~= nil
    end

    function self:Sync()
        local root = callbacks.Root()
        if root ~= self.Root then
            self:Reset()
            self.Root = root
            if root then
                for _, station in ipairs(root.Stations:GetChildren()) do
                    self.Slots[station.Name] = {
                        Id = station.Name,
                        Station = station,
                        Room = station:GetAttribute("Room"),
                    }
                end
            end
        end
        for id, slot in pairs(self.Slots) do
            local employee = self:Employee(id)
            if employee and not callbacks.Away(id) then
                local humanoid = employee:FindFirstChildOfClass("Humanoid")
                if
                    humanoid
                    and humanoid.Health > 0
                    and not Seating.IsSeated(employee, slot.Station.CounselorSeat)
                then
                    Seating.Sit(employee, slot.Station.CounselorSeat)
                end
            end
        end
    end

    function self:Reserve()
        self:Sync()
        local choices = {}
        local unstaffed = 0
        for id, slot in pairs(self.Slots) do
            local employee = self:Employee(id)
            local humanoid = employee and employee:FindFirstChildOfClass("Humanoid")
            local staffed = humanoid ~= nil and humanoid.Health > 0 and not callbacks.Away(id)
            local available = not slot.Token
                and not slot.Station.CustomerSeat.Occupant
                and not callbacks.Away(id)
            if not staffed and callbacks.AllowPlayerRequest and not callbacks.AllowPlayerRequest(slot.Room) then
                available = false
            end
            if employee and (employee:GetAttribute("Morale") or 100) < 50 then
                available = false
            end
            if slot.Token and not staffed then
                unstaffed += 1
            end
            table.insert(choices, { Id = id, Available = available, Staffed = staffed })
        end
        table.sort(choices, function(a, b)
            return a.Id < b.Id
        end)
        local chosen = Policy.Choose(choices, settings, unstaffed, self.LastUnstaffedAt, os.clock(), rng)
        if not chosen then
            return nil
        end
        local slot = self.Slots[chosen.Id]
        slot.Token = {}
        slot.ReservedAt = os.clock()
        slot.WasStaffed = chosen.Staffed
        return slot
    end

    function self:Release(slot)
        if not slot then
            return
        end
        slot.Token = nil
        slot.Model = nil
        slot.Leaving = nil
        slot.ReservedAt = nil
    end

    function self:IsReady(model)
        local data = callbacks.Data(model)
        local slot = data and data.Private and self.Slots[data.PrivateStation]
        return slot ~= nil and slot.Model == model and data.ArrivedAt ~= nil and not slot.Leaving
    end

    function self:Begin(slot, model)
        local data = callbacks.Data(model)
        if not slot.Token or not data then
            return false
        end
        slot.Model = model
        local token = slot.Token
        local owner = callbacks.Owner()
        if not slot.WasStaffed then
            self.LastUnstaffedAt = os.clock()
        end
        model:SetAttribute("PrivateSession", true)
        model:SetAttribute("PrivateStation", slot.Id)
        model:SetAttribute("CounterArea", slot.Room)
        model:SetAttribute("AttentionOwnerId", owner.UserId)
        model:SetAttribute("AttentionVisitId", HttpService:GenerateGUID(false))
        model:SetAttribute("AttentionActive", true)
        model:SetAttribute("AttentionNeeded", false)
        CollectionService:AddTag(model, "CalmWorksHelpVisitor")
        local title = settings.PrivateTitle:Clone()
        title.Adornee = model.Head
        title.Parent = model.Head
        local deadline = os.clock()
            + Policy.Number(settings:GetAttribute("RouteTimeoutSeconds"), 120, 30, 300)
        task.spawn(function()
            local function valid()
                return self.Slots[slot.Id] == slot
                    and slot.Token == token
                    and model.Parent ~= nil
                    and callbacks.Owner() == owner
                    and os.clock() < deadline
            end
            local okay, arrived = pcall(function()
                local room = slot.Room
                local markers = room == "Main" and points or points:FindFirstChild(room)
                if Routing.IsUpper(room) then
                    if not Navigation.Route(model, markers.Inbound, false, nil, valid) then
                        return false
                    end
                elseif room ~= "Main" then
                    for _, name in ipairs({ "Approach", "Entrance" }) do
                        if not Navigation.Walk(model, markers[name].Position, valid) then
                            return false
                        end
                    end
                end
                if not Navigation.Walk(model, slot.Station.Approach.Position, valid) then
                    return false
                end
                if not valid() then
                    return false
                end
                if data.WalkTrack then
                    data.WalkTrack:Stop(0)
                end
                if not Seating.Sit(model, slot.Station.CustomerSeat) then
                    return false
                end
                data.ArrivedAt = os.clock()
                data.PrivateLastTick = os.clock()
                data.PrivateProgress = 0
                return true
            end)
            if self.Slots[slot.Id] == slot and slot.Token == token and (not okay or not arrived) then
                self:Release(slot)
                callbacks.Failed(model)
                warn(
                    "CalmWorks: private appointment route unavailable; released the reservation without payment."
                )
            end
        end)
        if not self:IsStaffed(slot.Id) then
            callbacks.Notice(owner, "PrivateCustomerArrived", model)
        end
        return true
    end

    function self:Remove(model)
        local data = callbacks.Data(model)
        local id = data and data.PrivateStation or model:GetAttribute("PrivateStation")
        local slot = id and self.Slots[id]
        if slot and slot.Model == model then
            self:Release(slot)
        end
        model:SetAttribute("AttentionNeeded", false)
        model:SetAttribute("AttentionActive", false)
        CollectionService:RemoveTag(model, "CalmWorksHelpVisitor")
    end

    function self:Depart(model, data)
        local slot = self.Slots[data.PrivateStation]
        if not slot or slot.Model ~= model then
            model:Destroy()
            return
        end
        local token = slot.Token
        slot.Leaving = true
        local departure = slot.Station.Approach.CFrame
        data.Prompt.Enabled = false
        model:SetAttribute("AttentionNeeded", false)
        model:SetAttribute("AttentionActive", false)
        CollectionService:RemoveTag(model, "CalmWorksHelpVisitor")
        task.spawn(function()
            Seating.Stand(model)
            task.wait(0.1)
            if not model.Parent then
                return
            end
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = departure
                root.CanCollide = true
                root:SetNetworkOwner(nil)
            end
            if slot.Token == token then
                self:Release(slot)
            end
            callbacks.WalkOut(model, slot.Room)
        end)
    end

    function self:Tick()
        self:Sync()
        local owner = callbacks.Owner()
        if not owner then
            return
        end
        local now = os.clock()
        for id, slot in pairs(self.Slots) do
            local model = slot.Model
            local data = model and callbacks.Data(model)
            if data and data.ArrivedAt and not slot.Leaving then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if
                    not humanoid
                    or humanoid.Health <= 0
                    or not Seating.IsSeated(model, slot.Station.CustomerSeat)
                then
                    self:Remove(model)
                    callbacks.Failed(model)
                    continue
                end
                local employee = self:Employee(id)
                local staffHumanoid = employee and employee:FindFirstChildOfClass("Humanoid")
                local staffed = staffHumanoid ~= nil and staffHumanoid.Health > 0 and not callbacks.Away(id)
                local active = callbacks.Active()
                data.Prompt.Enabled = active == nil
                data.Serving = staffed and active ~= model
                model:SetAttribute("CounselorServing", data.Serving)
                model:SetAttribute("AttentionNeeded", not staffed and active ~= model)
                local elapsed = math.clamp(now - (data.PrivateLastTick or now), 0, 2)
                data.PrivateLastTick = now
                local grace = Policy.Number(settings:GetAttribute("PlayerHelpGraceSeconds"), 15, 3, 120)
                if staffed and active ~= model and now - data.ArrivedAt >= grace then
                    local seconds = callbacks.ServiceSeconds(id)
                    data.PrivateProgress += elapsed / math.max(1, seconds)
                    if data.PrivateProgress >= 1 and not data.PrivateCompleted then
                        data.PrivateCompleted = true
                        callbacks.Completed(owner, model, data)
                    end
                end
            elseif slot.Token and not model and now - slot.ReservedAt > 10 then
                self:Release(slot)
            end
        end
    end

    function self:Snapshot()
        local result = {}
        for id, slot in pairs(self.Slots) do
            table.insert(result, {
                Id = id,
                Room = slot.Room,
                Occupied = slot.Token ~= nil,
                Staffed = self:Employee(id) ~= nil,
                Away = callbacks.Away(id),
            })
        end
        table.sort(result, function(a, b)
            return a.Id < b.Id
        end)
        return result
    end

    function self:Reset()
        local old = self.Slots
        self.Slots = {}
        self.Root = nil
        self.LastUnstaffedAt = -math.huge
        for _, slot in pairs(old) do
            if slot.Model and slot.Model.Parent then
                callbacks.Failed(slot.Model)
            end
        end
    end

    return self
end

return Service

