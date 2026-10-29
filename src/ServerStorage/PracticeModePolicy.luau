-- Editable communication targets, not diagnoses or new safety-severity rules.
local Policy = {}
Policy.SkillProfiles = {
    ["De-escalation"] = { Mood = "Frustrated", Personality = "Impatient", CommunicationStyle = "Emotional" },
    ["Active Listening"] = { Mood = "Confused", Personality = "Reserved", CommunicationStyle = "Indirect" },
    ["Boundary Setting"] = { Mood = "Hurt", Personality = "PeoplePleasing", CommunicationStyle = "Indirect" },
    ["Problem Solving"] = { Mood = "Confused", Personality = "Analytical", CommunicationStyle = "Logical" },
    ["Emotional Awareness"] = { Mood = "Hurt", Personality = "Sensitive", CommunicationStyle = "Emotional" },
    ["Manipulation Recognition"] = {
        Mood = "Suspicious",
        Personality = "Skeptical",
        CommunicationStyle = "Uncertain",
    },
    ["Safety Judgment"] = { Mood = "Anxious", Personality = "Analytical", CommunicationStyle = "Uncertain" },
    ["Help Seeking"] = { Mood = "Anxious", Personality = "Reserved", CommunicationStyle = "Indirect" },
}
function Policy.Targets(history, definitions, config, previousTargets)
    local counts = {}
    for _, d in ipairs(definitions) do
        counts[d.Code] = { Correct = 0, Total = 0, Name = d.Name }
    end
    for i = math.max(1, #history - config.AccuracyWindowSize + 1), #history do
        local e = history[i]
        local c = counts[e.Code]
        if c then
            c.Total += 1
            if e.Correct then
                c.Correct += 1
            end
        end
    end
    local targets = {}
    for code, c in pairs(counts) do
        if c.Total > 0 and c.Correct / c.Total < config.AdaptiveGoalAccuracy then
            table.insert(targets, {
                Code = code,
                Name = c.Name,
                Accuracy = c.Correct / c.Total,
                Samples = c.Total,
                Preliminary = c.Total < (config.RecommendationMinCategoryAnswers or 3),
            })
        end
    end
    -- Falling out of the global last-50 window is not evidence of improvement.
    -- During an active practice session retain that target until measured again.
    for _, old in ipairs(previousTargets or {}) do
        local c = counts[old.Code]
        if c and c.Total == 0 then
            table.insert(targets, {
                Code = old.Code,
                Name = c.Name,
                Accuracy = old.Accuracy,
                Samples = 0,
                Preliminary = true,
                Unmeasured = true,
            })
        end
    end
    table.sort(targets, function(a, b)
        if a.Accuracy ~= b.Accuracy then
            return a.Accuracy < b.Accuracy
        end
        return a.Code < b.Code
    end)
    return targets
end
function Policy.Codes(targets)
    local codes = {}
    for _, t in ipairs(targets) do
        codes[t.Code] = true
    end
    return codes
end
function Policy.Signature(targets)
    local codes = {}
    for _, t in ipairs(targets) do
        table.insert(codes, t.Code)
    end
    table.sort(codes)
    return table.concat(codes, ",")
end
-- Ordered, editable aliases bridge the library's specific lowercase skill tags
-- to broad practice behaviors. The original skill tag remains in AI prompts.
Policy.SkillAliases = {
    { "Help Seeking", { "help seeking", "support", "reporting" } },
    { "Safety Judgment", { "safety", "danger", "threat", "risk", "emergency", "escape", "hazard" } },
    {
        "Manipulation Recognition",
        {
            "manipulat",
            "coerci",
            "blackmail",
            "scam",
            "grooming",
            "secrecy",
            "isolation",
            "guilt",
            "pressure",
            "verif",
            "evidence",
            "pattern",
            "deepfake",
        },
    },
    { "Boundary Setting", { "boundar", "refusal", "assertiv", "consent", "privacy" } },
    { "De-escalation", { "escalat", "self control", "patience", "regulation", "pause", "calm" } },
    { "Emotional Awareness", { "emotion", "empathy", "defensiv", "repair", "validation", "accountab" } },
    {
        "Active Listening",
        {
            "listen",
            "clarif",
            "assumption",
            "context",
            "tone",
            "inquiry",
            "information",
            "communicat",
            "perspective",
        },
    },
}
function Policy.SkillGroup(skill)
    local tag = string.lower(tostring(skill or ""))
    for name in pairs(Policy.SkillProfiles) do
        if string.lower(name) == tag then
            return name
        end
    end
    for _, rule in ipairs(Policy.SkillAliases) do
        for _, needle in ipairs(rule[2]) do
            if string.find(tag, needle, 1, true) then
                return rule[1]
            end
        end
    end
    return "Problem Solving"
end
function Policy.Profile(skill, fallback)
    return table.clone(Policy.SkillProfiles[Policy.SkillGroup(skill)] or fallback)
end
return Policy
