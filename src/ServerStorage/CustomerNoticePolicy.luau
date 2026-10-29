local Policy = {}

function Policy.NeedsHelp(data, staffed, active, executiveHelp)
    if not data or active or data.Serving then
        return false
    end
    if data.Private then
        return not staffed
    end
    if data.Kind == "BusinessMan" or data.Angry or data.PersonalHelp then
        return true
    end
    if data.Kind == "Staff" then
        return executiveHelp ~= true
    end
    return not staffed
end

function Policy.Ready(data, staffed, active, actionable, settings, executiveHelp)
    if settings:GetAttribute("Enabled") == false or not Policy.NeedsHelp(data, staffed, active, executiveHelp) then
        return false
    end
    if settings:GetAttribute("ReadyOnly") == false then
        return true
    end
    return data.ArrivedAt ~= nil and actionable == true
end

function Policy.GapReady(settings, previous, now)
    local seconds = settings:GetAttribute("MinimumGapSeconds")
    if type(seconds) ~= "number" or seconds ~= seconds or math.abs(seconds) == math.huge then
        seconds = 20
    end
    return now - previous >= math.clamp(seconds, 0, 300)
end

return Policy