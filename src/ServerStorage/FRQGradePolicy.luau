-- Pure acceptance policy. Numeric scores describe practice evidence, not pass/fail.
local Policy = {}

function Policy.HasGroundedEvidence(grade, response)
    if grade.MinimumViable ~= true then
        return true
    end
    if type(grade.ActionEvidence) ~= "string" or type(response) ~= "string" then
        return false
    end
    local function normalize(text)
        text = text:lower()
        text = text:gsub("%s+", " ")
        text = text:match("^%s*(.-)%s*$")
        return text
    end
    local quote, answer = normalize(grade.ActionEvidence), normalize(response)
    return #quote >= 3 and #quote <= #answer and answer:find(quote, 1, true) ~= nil
end

function Policy.Task(scenario, defaultPrompt)
    -- ShortPrompt can override the normal short-answer task.
    if scenario.FRQ then
        local short = scenario.FRQ.ShortPrompt
        if type(short) == "string" and short ~= "" then
            return short
        end
    end
    return defaultPrompt
end

function Policy.Passes(grade, maximumRisk)
    if
        type(grade) ~= "table"
        or type(grade.MinimumViable) ~= "boolean"
        or type(grade.SafetyConcern) ~= "boolean"
    then
        return false
    end
    local risk = grade.EscalationRisk
    if type(risk) ~= "number" or risk ~= risk or risk < 0 or risk > 100 then
        return false
    end
    return grade.MinimumViable and not grade.SafetyConcern and risk <= maximumRisk
end

return Policy
