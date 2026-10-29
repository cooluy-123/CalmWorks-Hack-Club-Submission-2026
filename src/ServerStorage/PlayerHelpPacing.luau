local Pacing = {}

function Pacing.Number(settings, name, fallback, minimum, maximum)
    local value = settings:GetAttribute(name)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        value = fallback
    end
    return math.clamp(value, minimum, maximum)
end

function Pacing.RequiresPlayer(data, hasStaff, executiveHelp)
    if not data then
        return false
    end
    if data.Kind == "BusinessMan" then
        return true
    end
    if data.Kind == "Staff" then
        return data.Angry == true or data.PersonalHelp == true or executiveHelp ~= true
    end
    if data.Private then
        return not hasStaff
    end
    return data.Angry == true or data.PersonalHelp == true or not hasStaff
end

function Pacing.New(settings, clock)
    clock = clock or os.clock
    local self = {LastRequestAt = -math.huge, BreakUntil = 0}

    function self:Reset()
        self.LastRequestAt = -math.huge
        self.BreakUntil = 0
    end

    function self:CanRequest(context, kind, area)
        if settings:GetAttribute("Enabled") == false then
            return true
        end
        local maximum = math.floor(Pacing.Number(settings, "MaxOutstanding", 2, 1, 8))
        local perRoom = math.floor(Pacing.Number(settings, "MaxPerRoom", 1, 1, 4))
        if context.Count >= maximum then
            return false
        end
        if area and (context.Rooms[area] or 0) >= perRoom then
            return false
        end
        if context.Busy and settings:GetAttribute("PauseDuringDialogue") ~= false then
            return false
        end
        local now = clock()
        local gap = Pacing.Number(settings, "RequestSpacingSeconds", 25, 5, 300)
        if now < self.BreakUntil or now - self.LastRequestAt < gap then
            return false
        end
        if kind ~= "Staff" and kind ~= "Mentor" and context.StaffPriority
            and settings:GetAttribute("PrioritizeStaff") ~= false then
            return false
        end
        return true
    end

    function self:Requested()
        self.LastRequestAt = clock()
    end

    function self:Helped()
        self.BreakUntil = clock() + Pacing.Number(settings, "AfterHelpBreakSeconds", 12, 0, 300)
    end

    function self:ReservedUpperSlots(expansion)
        if expansion < 3 or settings:GetAttribute("Enabled") == false then
            return 0
        end
        return math.floor(Pacing.Number(settings, "ReservedUpperSlots", 1, 0, 2))
    end

    return self
end

return Pacing

