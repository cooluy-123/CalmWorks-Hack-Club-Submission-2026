local Policy = require(script.Parent.StaffMoralePolicy)
local Service = {}

function Service.New(settings, getSession, findStaff, changed, decayMultiplier, playerBusy)
    local self = {}
    local clocks = {}
    local currentSession
    local lastTickAt = os.clock()
    local rng = Random.new()

    local function interval()
        local minimum = Policy.Setting(settings, "DecaySecondsMin", 5, 1, 600)
        local maximum = Policy.Setting(settings, "DecaySecondsMax", 10, minimum, 600)
        return rng:NextNumber(minimum, maximum)
    end

    local function state()
        local session = getSession()
        if not session then
            clocks = {}
            currentSession = nil
            return nil
        end
        if session ~= currentSession then
            currentSession = session
            clocks = {}
            lastTickAt = os.clock()
        end
        if Policy.Initialize(session.StaffMorale, session.TycoonProgress.CompletedExpansions) then
            changed()
        end
        return session.StaffMorale
    end

    local function publish(model, entry, role, active)
        local morale = active and entry.Morale or 50
        local multiplier = 1
        if active and role ~= "Manager" then
            multiplier = Policy.Multiplier(morale)
        end
        model:SetAttribute("Morale", morale)
        model:SetAttribute("MoraleActive", active)
        model:SetAttribute("MoraleServiceMultiplier", multiplier)
        local gui = model:FindFirstChild("EmployeeMoraleGui", true)
        local label = gui and gui:FindFirstChild("MoraleLabel")
        if label and label:IsA("TextLabel") then
            local format = tostring(gui:GetAttribute("TextFormat") or "Morale: {morale}%")
            label.Text = format:gsub("{morale}", tostring(morale))
            local low = gui:GetAttribute("LowColor") or Color3.fromRGB(240, 80, 80)
            local middle = gui:GetAttribute("MiddleColor") or Color3.fromRGB(255, 210, 70)
            local high = gui:GetAttribute("HighColor") or Color3.fromRGB(85, 230, 120)
            if morale <= 50 then
                label.TextColor3 = low:Lerp(middle, morale / 50)
            else
                label.TextColor3 = middle:Lerp(high, (morale - 50) / 50)
            end
        end
    end

    local function resting(entry)
        if (entry.RecoveryRemaining or 0) > 0 then
            return true
        end
        if settings:GetAttribute("PauseLossWhileWaiting") ~= false
            and entry.Morale < Policy.Setting(settings, "VisitBelow", 50, 1, 100) then
            return true
        end
        return settings:GetAttribute("PauseLossDuringPlayerHelp") ~= false and playerBusy and playerBusy()
    end

    function self:Sync(tickDecay)
        local saved = state()
        if not saved then
            return
        end
        local now = os.clock()
        local elapsed = tickDecay and math.clamp(now - lastTickAt, 0, 3) or 0
        if tickDecay then
            lastTickAt = now
        end
        local dirty = false
        for _, staff in ipairs(Policy.Roster) do
            local model = findStaff(staff.Area, staff.Role)
            if model then
                local entry = saved.Entries[staff.Id]
                if elapsed > 0 and (entry.RecoveryRemaining or 0) > 0 then
                    entry.RecoveryRemaining = math.max(0, entry.RecoveryRemaining - elapsed)
                    dirty = true
                end
                if not clocks[staff.Id] or model:GetAttribute("OnConsultation") or resting(entry) then
                    clocks[staff.Id] = now + interval()
                elseif tickDecay and saved.Initialized and now >= clocks[staff.Id] then
                    clocks[staff.Id] = now + interval()
                    local loss = Policy.Setting(settings, "BaseDecayLoss", 1, 0, 10)
                    local boost = decayMultiplier and decayMultiplier() or 1
                    loss *= math.clamp(boost, 2 / 3, 1)
                    dirty = Policy.Lose(entry, loss, staff.Role, settings) or dirty
                end
                if not model:GetAttribute("OnConsultation") then
                    local status = entry.Morale < Policy.Setting(settings, "VisitBelow", 50, 1, 100)
                        and saved.Initialized and "WaitingForVisit" or "AtWork"
                    if model:GetAttribute("ConsultationState") ~= status then
                        model:SetAttribute("ConsultationState", status)
                    end
                end
                publish(model, entry, staff.Role, saved.Initialized)
            else
                clocks[staff.Id] = nil
            end
        end
        if dirty then
            changed()
        end
    end

    function self:Multiplier(area)
        local saved = state()
        if not saved or not saved.Initialized then
            return 1
        end
        for _, staff in ipairs(Policy.Roster) do
            if staff.Area == area and staff.Role ~= "Manager" then
                return Policy.Multiplier(saved.Entries[staff.Id].Morale)
            end
        end
        return 1
    end

    function self:Candidate(canVisit)
        local saved = state()
        local session = getSession()
        if not saved or not saved.Initialized then
            return nil
        end
        local selected, lowest
        local threshold = Policy.Setting(settings, "VisitBelow", 50, 1, 100)
        for offset = 0, #Policy.Roster - 1 do
            local index = (session.StaffConcerns.NextStaff - 1 + offset) % #Policy.Roster + 1
            local staff = Policy.Roster[index]
            local model = findStaff(staff.Area, staff.Role)
            local morale = saved.Entries[staff.Id].Morale
            if
                model
                and not model:GetAttribute("OnConsultation")
                and morale < threshold
                and (not canVisit or canVisit(staff))
            then
                if not lowest or morale < lowest then
                    selected, lowest = index, morale
                end
            end
        end
        return selected
    end

    function self:Customer(area, scenario, angry)
        local saved = state()
        if not saved or not saved.Initialized then
            return
        end
        local dirty = false
        for _, staff in ipairs(Policy.Roster) do
            if staff.Area == area then
                local model = findStaff(staff.Area, staff.Role)
                if model and not model:GetAttribute("OnConsultation") and not resting(saved.Entries[staff.Id]) then
                    local loss = Policy.CustomerLoss(scenario, angry, settings)
                    dirty = Policy.Lose(saved.Entries[staff.Id], loss, staff.Role, settings) or dirty
                end
            end
        end
        if dirty then
            changed()
            self:Sync(false)
        end
    end

    function self:Recover(id)
        local saved = state()
        if saved and saved.Initialized and saved.Entries[id] then
            Policy.Recover(saved.Entries[id])
            saved.Entries[id].RecoveryRemaining = Policy.Setting(settings, "RecoveryGraceSeconds", 120, 0, 600)
            clocks[id] = os.clock() + interval()
            changed()
            self:Sync(false)
        end
    end

    return self
end

return Service
