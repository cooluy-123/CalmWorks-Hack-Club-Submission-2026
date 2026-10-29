local Policy = {}

function Policy.Number(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

function Policy.Choose(stations, settings, unstaffedCount, lastUnstaffedAt, now, rng)
    local available, staffed = {}, {}
    for _, station in ipairs(stations) do
        if station.Available then
            table.insert(available, station)
            if station.Staffed then
                table.insert(staffed, station)
            end
        end
    end
    local chance = Policy.Number(settings:GetAttribute("PrivateChance"), 0.02, 0, 1)
    if #staffed > 0 then
        if rng:NextNumber() < chance then
            return staffed[rng:NextInteger(1, #staffed)]
        end
        return nil
    end
    local cooldown = Policy.Number(settings:GetAttribute("UnstaffedArrivalGap"), 180, 30, 1800)
    local maximum = Policy.Number(settings:GetAttribute("MaxUnstaffedSessions"), 1, 1, 8)
    local factor = Policy.Number(settings:GetAttribute("UnstaffedChanceMultiplier"), 0.2, 0, 1)
    if #available == 0 or unstaffedCount >= maximum or now - lastUnstaffedAt < cooldown then
        return nil
    end
    if rng:NextNumber() < chance * factor then
        return available[rng:NextInteger(1, #available)]
    end
    return nil
end

function Policy.Reward(normalReward, settings)
    local multiplier = Policy.Number(settings:GetAttribute("RewardMultiplier"), 4, 1, 10)
    return math.floor(normalReward * multiplier)
end

return Policy
