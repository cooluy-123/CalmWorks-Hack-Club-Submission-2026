local Scenarios = require(script.Parent.DashboardScenarios)
local Policy = {}
Policy.Kinds = { Workforce = true, Experience = true, Welfare = true, Efficiency = true }

function Policy.Number(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

function Policy.Clean(raw, now)
    raw = type(raw) == "table" and raw or {}
    now = now or os.time()
    local state = {
        Completed = math.floor(Policy.Number(raw.Completed, 0, 0, 1000000)),
        FirstTryCorrect = math.floor(Policy.Number(raw.FirstTryCorrect, 0, 0, 1000000)),
        NextAt = 0,
        Review = Policy.Number(raw.Review, 0, 0, 100),
        DecayElapsed = Policy.Number(raw.DecayElapsed, 0, 0, 599.999),
        Recent = {},
        RecentArrivals = {},
        Boost = nil,
        Pending = nil,
    }
    state.FirstTryCorrect = math.min(state.FirstTryCorrect, state.Completed)
    for _, id in ipairs(type(raw.Recent) == "table" and raw.Recent or {}) do
        if type(id) == "string" and #id <= 60 then
            table.insert(state.Recent, id)
            if #state.Recent > 6 then
                table.remove(state.Recent, 1)
            end
        end
    end
    for _, angry in ipairs(type(raw.RecentArrivals) == "table" and raw.RecentArrivals or {}) do
        table.insert(state.RecentArrivals, angry == true)
        if #state.RecentArrivals > 20 then
            table.remove(state.RecentArrivals, 1)
        end
    end
    state.Pending = Scenarios.CleanPending(raw.Pending)
    return state
end

function Policy.Definition(settings, kind)
    local folder = settings:FindFirstChild("Bonuses")
    local item = folder and folder:FindFirstChild(kind)
    if not item or not Policy.Kinds[kind] then
        return nil
    end
    local unit = kind == "Experience" and "Arrival" or "Service"
    return {
        Kind = kind,
        Unit = unit,
        Count = math.floor(
            Policy.Number(item:GetAttribute("Uses"), kind == "Efficiency" and 15 or 10, 1, 50)
        ),
        Service = Policy.Number(item:GetAttribute("ServiceMultiplier"), 1, 1, 1.10),
        Arrival = Policy.Number(item:GetAttribute("ArrivalMultiplier"), 1, 1, 1.05),
        Decay = Policy.Number(item:GetAttribute("DecayMultiplier"), 1, 0.75, 1),
        Name = item:GetAttribute("DisplayName") or item.Name,
    }
end

function Policy.Multiplier(state, settings, key)
    local review = Policy.Number(state and state.Review, 0, 0, 100)
    local multiplier = 1 + math.floor(review / 10) * 0.05
    if key == "Decay" then
        return 1 / multiplier
    elseif key == "Arrival" or key == "Service" then
        return multiplier
    end
    return 1
end

function Policy.Award(state, settings, upgraded)
    local name = upgraded and "UpgradedReviewGain" or "ReviewGain"
    local gain = Policy.Number(settings:GetAttribute(name), upgraded and 10 or 5, 1, 25)
    local before = state.Review
    state.Review = math.min(100, before + gain)
    return state.Review - before
end

function Policy.Advance(state, settings, upgraded, seconds)
    local name = upgraded and "UpgradedDecaySeconds" or "DecaySeconds"
    local duration = Policy.Number(settings:GetAttribute(name), upgraded and 90 or 60, 10, 600)
    local loss = Policy.Number(settings:GetAttribute("ReviewDecay"), 5, 1, 25)
    state.DecayElapsed += math.max(0, seconds)
    local ticks = math.floor(state.DecayElapsed / duration)
    state.DecayElapsed %= duration
    state.Review = math.max(0, state.Review - ticks * loss)
    return ticks > 0
end

function Policy.Arrival(state, angry)
    table.insert(state.RecentArrivals, angry == true)
    if #state.RecentArrivals > 20 then
        table.remove(state.RecentArrivals, 1)
    end
end

function Policy.Trigger(context, settings)
    local threshold = Policy.Number(settings:GetAttribute("LowMoraleThreshold"), 60, 10, 90)
    if context.StaffCount > 0 and context.AverageMorale < threshold then
        return "Welfare"
    end
    if context.QueueSamples >= 6 and context.QueueGap >= 1.25 and context.LongestAverage >= 2 then
        return "Queue"
    end
    if context.RecentAngry >= 3 then
        return "Angry"
    end
    return "Routine"
end

return Policy
