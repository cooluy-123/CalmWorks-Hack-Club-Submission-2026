local Rates = {}

local function number(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

function Rates.Upgrades(purchases, visits, area)
    local result = { Managed = false, PaintingMultiplier = 1 }
    for index, settings in ipairs(visits) do
        local owned = purchases[tostring(index)] or {}
        local reference = settings:FindFirstChild("PadsTemplate")
        local pads = reference and reference.Value
        if pads then
            for _, pad in ipairs(pads:GetChildren()) do
                local id = pad:GetAttribute("UpgradeId")
                if owned[id] == true and pad:GetAttribute("CounterArea") == area then
                    if pad:GetAttribute("UpgradeKind") == "Manager" then
                        result.Managed = true
                    elseif pad:GetAttribute("UpgradeKind") == "Painting" then
                        local multiplier = number(pad:GetAttribute("CustomerRateMultiplier"), 1.05, 1, 2)
                        result.PaintingMultiplier = math.min(result.PaintingMultiplier * multiplier, 5)
                    end
                end
            end
        end
    end
    return result
end

function Rates.ServiceSeconds(config, settings, stars, managed, executive)
    local key = "CounselorServiceSeconds"
    if executive then
        key = "ExecutiveServiceSeconds"
    end
    local seconds = number(settings:GetAttribute(key), 12, 1, 120)
    if managed then
        local rate = number(config.SpawnRatePerStar, 1, 1, 5)
        stars = math.floor(number(stars, 0, 0, 5))
        seconds /= rate ^ stars
    end
    return math.clamp(seconds, 0.25, 120)
end

function Rates.AngryMultiplier(dataMap, settings)
    -- Kept for older callers. Angry visitors now hold their queue, not arrival rates.
    return 1
end

return Rates
