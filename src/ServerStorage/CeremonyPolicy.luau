local Policy = {}

function Policy.Number(value, fallback, low, high)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, low, high)
end

function Policy.Eligible(progress, maxed)
    return type(progress) == "table" and progress.CompletedExpansions == 4
        and progress.FinalVisitCompleted == true and progress.Won ~= true and maxed == true
end

function Policy.ClosingNeeded(progress)
    return type(progress) == "table" and progress.Won == true
        and progress.CeremonyClosingSeen == false
end

function Policy.Timeline(settings)
    local function number(name, fallback, low, high)
        return Policy.Number(settings:GetAttribute(name), fallback, low, high)
    end
    local cut = number("CloseupSeconds", 1.25, 0.4, 5)
    local reveal = cut + number("FallSeconds", 1.35, 0.5, 5)
    local overview = reveal + number("ZoomOutSeconds", 2.5, 0.5, 6)
    local fade = overview + number("OverviewHoldSeconds", 5, 5, 15)
    local duration = number("FadeSeconds", 0.65, 0.25, 2)
    return {Cut = cut, Reveal = reveal, Overview = overview, Fade = fade,
        Return = fade + duration, Finish = fade + duration * 2}
end

function Policy.CanFinish(active, player, token, now)
    return active ~= nil and active.Player == player and active.Phase == "Playing"
        and type(token) == "string" and token == active.Token
        and now >= active.StartAt + active.Timeline.Finish - 0.05
end

return Policy

