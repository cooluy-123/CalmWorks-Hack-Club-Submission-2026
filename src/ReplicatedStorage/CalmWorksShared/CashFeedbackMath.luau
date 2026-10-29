local Cash = {}

function Cash.Number(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

function Cash.Duration(amount, stepSeconds, maximum)
    return math.min(math.max(0, amount) * stepSeconds, maximum)
end

function Cash.Count(start, target, elapsed, duration)
    if duration <= 0 or elapsed >= duration or target <= start then
        return target
    end
    local progress = math.clamp(elapsed / duration, 0, 1)
    return math.min(target, start + math.floor((target - start) * progress + 0.000001))
end

function Cash.Pulse(elapsed, duration, peak, start)
    if duration <= 0 or elapsed >= duration then
        return 1
    end
    local progress = math.clamp(elapsed / duration, 0, 1)
    if progress < 0.35 then
        local blend = 1 - (1 - progress / 0.35) ^ 2
        return start + (peak - start) * blend
    end
    local blend = (progress - 0.35) / 0.65
    return 1 + (peak - 1) * (1 - blend) ^ 2
end

function Cash.Opacity(elapsed, lifetime, fadeIn, fadeOut)
    if elapsed < 0 or elapsed >= lifetime then
        return 0
    end
    local entering = fadeIn > 0 and math.min(1, elapsed / fadeIn) or 1
    local leaving = fadeOut > 0 and math.min(1, (lifetime - elapsed) / fadeOut) or 1
    return math.clamp(math.min(entering, leaving), 0, 1)
end

return Cash
