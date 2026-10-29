local Values = {}

function Values.Clean(saved, limit)
    saved = type(saved) == "table" and saved or {}
    local function count(value, maximum)
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
            return 0
        end
        return math.clamp(math.floor(value), 0, maximum)
    end
    return {
        RichSeen = saved.RichSeen == true,
        AutomaticSinceHelp = count(saved.AutomaticSinceHelp, 1000000),
        Arrivals = count(saved.Arrivals, 1000000),
        GuaranteeAt = count(saved.GuaranteeAt, limit or 10),
        AngryArrivals = count(saved.AngryArrivals, 1000000),
        AngrySpawned = count(saved.AngrySpawned, 1000000),
        AngryGoal = count(saved.AngryGoal, 3),
    }
end

function Values.AngryGoal(state, settings, rng)
    if state.AngryGoal < 2 then
        state.AngryGoal = rng:NextInteger(2, 3)
    end
    return state.AngryGoal
end

local function chance(settings, name, fallback)
    local value = tonumber(settings:GetAttribute(name))
    if not value or value ~= value or math.abs(value) == math.huge then
        value = fallback
    end
    return math.clamp(value, 0, 1)
end

function Values.AngryChance(expansion, settings)
    if expansion < 2 then
        return 0
    elseif expansion >= 3 then
        return chance(settings, "UpperAngryChance", 0.1)
    end
    return chance(settings, "AngryChance", 0.05)
end

function Values.RollAngry(state, expansion, maxed, settings, rng)
    if expansion < 2 then
        return false
    end
    state.AngryArrivals = math.min(state.AngryArrivals + 1, 1000000)
    return rng:NextNumber() < Values.AngryChance(expansion, settings)
end

function Values.CommitAngry(state)
    state.AngrySpawned = math.min(state.AngrySpawned + 1, 1000000)
end

function Values.Kind(state, expansion, maxed, settings, rng)
    if expansion >= 2 then
        -- One roll keeps Rich and Angry mutually exclusive.
        local angry = Values.AngryChance(expansion, settings)
        local rich = chance(settings, "UpperRichChance", 0.1)
        local total = angry + rich
        if total > 1 then
            angry /= total
            rich /= total
        end
        state.AngryArrivals = math.min(state.AngryArrivals + 1, 1000000)
        local roll = rng:NextNumber()
        if roll < angry then
            return "Angry"
        elseif roll < angry + rich then
            return "Rich"
        end
        return "Standard"
    end
    if Values.Roll(state, expansion, maxed, settings, rng) then
        return "Rich"
    end
    return "Standard"
end

function Values.Roll(state, expansion, maxed, settings, rng)
    if expansion ~= 1 or (maxed and state.RichSeen) then
        return false
    end
    local limit =
        math.clamp(math.floor(tonumber(settings:GetAttribute("RichGuaranteeByArrival")) or 10), 1, 100)
    if state.GuaranteeAt < 1 then
        state.GuaranteeAt = rng:NextInteger(1, limit)
    end
    state.Arrivals += 1
    local chance = math.clamp(tonumber(settings:GetAttribute("RichChance")) or 0.01, 0, 1)
    return rng:NextNumber() < chance
        or (not state.RichSeen and (maxed or state.Arrivals >= state.GuaranteeAt))
end

function Values.Reward(difficulty, stars, rich, config, settings)
    local normal = config.RewardPerDifficulty * difficulty + config.RewardPerStar * stars
    local multiplier = 1
    if rich then
        multiplier = tonumber(settings:GetAttribute("RichRewardMultiplier")) or 2
        if multiplier ~= multiplier or math.abs(multiplier) == math.huge then
            multiplier = 2
        end
        multiplier = math.clamp(multiplier, 1, 100)
    end
    return math.floor(normal * multiplier)
end

return Values
