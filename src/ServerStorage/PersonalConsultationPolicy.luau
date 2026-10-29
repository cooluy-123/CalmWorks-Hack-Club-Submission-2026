local Policy = {}

local function number(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

function Policy.Threshold(settings, expansion)
    local stage = math.clamp(math.floor(number(expansion, 0, 0, 4)), 1, 3)
    local defaults = { 8, 10, 12 }
    return math.floor(number(settings:GetAttribute("AfterAutomatic" .. stage), defaults[stage], 1, 100))
end

function Policy.Due(state, expansion, settings, lastRequestAt, now)
    if expansion < 1 or settings:GetAttribute("Enabled") == false then
        return false
    end
    local count = number(state.AutomaticSinceHelp, 0, 0, 1000000)
    if count < Policy.Threshold(settings, expansion) then
        return false
    end
    local delay = number(settings:GetAttribute("StaggerSeconds"), 45, 5, 300)
    return lastRequestAt == nil or now - lastRequestAt >= delay
end

function Policy.Automatic(state)
    state.AutomaticSinceHelp = math.min(number(state.AutomaticSinceHelp, 0, 0, 1000000) + 1, 1000000)
end

function Policy.Helped(state)
    -- Only a fully resolved player scenario clears the saved automatic-service count.
    state.AutomaticSinceHelp = 0
end

return Policy
