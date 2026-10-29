local Policy = {}

Policy.Fields = {"Summary", "Strength", "Improvement", "ModelResponse"}

local defaults = {
    Summary = 22,
    Strength = 14,
    Improvement = 22,
    ModelResponse = 20,
}

function Policy.WordCounts(text)
    local count, unique, highest = 0, 0, 0
    local seen = {}
    for word in text:lower():gmatch("%S+") do
        word = word:gsub("%p", "")
        if word:find("%a") then
            count += 1
            if not seen[word] then
                seen[word] = 0
                unique += 1
            end
            seen[word] += 1
            highest = math.max(highest, seen[word])
        end
    end
    return count, unique, highest
end

local function setting(settings, name, default, low, high)
    local value = settings and settings[name]
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return default
    end
    return math.clamp(math.floor(value), low, high)
end

function Policy.Validate(feedback, settings)
    if type(feedback) ~= "table" then
        return false, "missing feedback"
    end
    local maximum = setting(settings, "FeedbackMaxCharacters", 900, 200, 1800)
    local seen = {}
    for _, field in ipairs(Policy.Fields) do
        local text = feedback[field]
        if type(text) ~= "string" then
            return false, field .. " missing"
        end
        local length = utf8.len(text)
        if not length or length > maximum then
            return false, field .. " too long or invalid"
        end
        local minimum = setting(settings, "Feedback" .. field .. "MinWords", defaults[field], 10, 80)
        local count, unique, highest = Policy.WordCounts(text)
        if count < minimum or unique < 8 or highest > count * 0.4 then
            return false, field .. " too brief or repetitive"
        end
        local normalized = text:lower():gsub("%p", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
        if seen[normalized] then
            return false, "duplicate feedback sections"
        end
        seen[normalized] = true
    end
    return true
end

return Policy
