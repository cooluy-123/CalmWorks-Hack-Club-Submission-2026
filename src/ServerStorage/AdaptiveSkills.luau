-- Saved practice state and bounded category weights for CalmWorks.
local AdaptiveSkills = {}

local function finiteCount(value)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return 0
    end
    return math.clamp(math.floor(value), 0, 1000000)
end

local function restoreHistory(raw, maximum)
    local history = {}
    if type(raw) ~= "table" then
        return history
    end
    for _, outcome in ipairs(raw) do
        if outcome == "C" or outcome == "M" then
            table.insert(history, outcome)
            if #history > maximum then
                table.remove(history, 1)
            end
        end
    end
    return history
end

local function addOutcome(history, outcome, maximum)
    table.insert(history, outcome)
    if #history > maximum then
        table.remove(history, 1)
    end
end

function AdaptiveSkills.NewStats()
    return { Correct = 0, Incorrect = 0, Recent = {}, FocusActive = false, FocusWindow = {} }
end

function AdaptiveSkills.RestoreStats(raw, config)
    local stats = AdaptiveSkills.NewStats()
    if type(raw) ~= "table" then
        return stats
    end
    stats.Correct = finiteCount(raw.Correct)
    stats.Incorrect = finiteCount(raw.Incorrect)
    stats.Recent = restoreHistory(raw.Recent, config.AdaptiveRecentAnswers)
    stats.FocusActive = raw.FocusActive == true
    stats.FocusWindow = stats.FocusActive
            and restoreHistory(
                raw.FocusWindow,
                config.AdaptiveMasteryCorrect + config.AdaptiveMasteryMistakes
            )
        or {}
    return stats
end

function AdaptiveSkills.SnapshotStats(stats, config)
    local clean = AdaptiveSkills.RestoreStats(stats, config)
    return clean
end

function AdaptiveSkills.FocusProgress(stats)
    local correct, mistakes = 0, 0
    for _, outcome in ipairs(stats.FocusWindow or {}) do
        if outcome == "C" then
            correct += 1
        else
            mistakes += 1
        end
    end
    return correct, mistakes
end

function AdaptiveSkills.Record(stats, correct, config)
    local outcome = correct and "C" or "M"
    if correct then
        stats.Correct += 1
    else
        stats.Incorrect += 1
    end
    stats.Recent = stats.Recent or {}
    stats.FocusWindow = stats.FocusWindow or {}
    addOutcome(stats.Recent, outcome, config.AdaptiveRecentAnswers)

    if stats.FocusActive then
        addOutcome(stats.FocusWindow, outcome, config.AdaptiveMasteryCorrect + config.AdaptiveMasteryMistakes)
        local focusCorrect, focusMistakes = AdaptiveSkills.FocusProgress(stats)
        if
            focusCorrect >= config.AdaptiveMasteryCorrect
            and focusMistakes <= config.AdaptiveMasteryMistakes
        then
            stats.FocusActive = false
            stats.FocusWindow = {}
            stats.Recent = {}
            return "mastered"
        end
    else
        local recentCorrect = 0
        for _, result in ipairs(stats.Recent) do
            if result == "C" then
                recentCorrect += 1
            end
        end
        if
            #stats.Recent >= config.AdaptiveMinSamples
            and recentCorrect / #stats.Recent < config.AdaptiveGoalAccuracy
        then
            stats.FocusActive = true
            stats.FocusWindow = { outcome }
            return "focused"
        end
    end
    return "unchanged"
end

local function smoothedAccuracy(stats)
    local correct = finiteCount(stats and stats.Correct)
    local incorrect = finiteCount(stats and stats.Incorrect)
    return (correct + 2) / (correct + incorrect + 2), correct + incorrect
end

-- Old saves have no Mode. Keep their category accuracy but never guess their format.
function AdaptiveSkills.CleanHistoryEntry(entry, categoryByCode)
    if type(entry) ~= "table" or not categoryByCode[entry.Code] or type(entry.Correct) ~= "boolean" then
        return nil
    end
    local clean = { Code = entry.Code, Correct = entry.Correct }
    if entry.Mode == "MCQ" or entry.Mode == "FRQ" then
        clean.Mode = entry.Mode
    end
    if
        type(entry.Difficulty) == "number"
        and entry.Difficulty % 1 == 0
        and entry.Difficulty >= 1
        and entry.Difficulty <= 5
    then
        clean.Difficulty = entry.Difficulty
    end
    if type(entry.TargetSkill) == "string" and #entry.TargetSkill <= 100 then
        clean.TargetSkill = entry.TargetSkill
    end
    return clean
end

function AdaptiveSkills.WindowMetrics(history, code, mode, skill, maximum)
    local correct, samples = 0, 0
    history = type(history) == "table" and history or {}
    for index = math.max(1, #history - (maximum or 50) + 1), #history do
        local entry = history[index]
        if
            type(entry) == "table"
            and type(entry.Correct) == "boolean"
            and (not code or entry.Code == code)
            and (not mode or entry.Mode == mode)
            and (not skill or entry.TargetSkill == skill)
        then
            samples += 1
            if entry.Correct then
                correct += 1
            end
        end
    end
    return { Correct = correct, Samples = samples, Accuracy = samples > 0 and correct / samples or nil }
end

function AdaptiveSkills.GenerationContext(history, source, categories, config)
    local maximum = config.AccuracyWindowSize or 50
    -- Save one canonical target, never a comma-joined list that individual lookups cannot match.
    local target = source.Skills[1] or source.Skill
    local lowest = math.huge
    for _, skill in ipairs(source.Skills) do
        local metric = AdaptiveSkills.WindowMetrics(history, nil, source.Mode, skill, maximum)
        if metric.Samples >= config.AdaptiveMinSamples and metric.Accuracy < lowest then
            lowest, target = metric.Accuracy, skill
        end
    end
    local weaknesses = {}
    for _, category in ipairs(categories) do
        local metric = AdaptiveSkills.WindowMetrics(history, category.Code, nil, nil, maximum)
        if metric.Samples >= config.AdaptiveMinSamples and metric.Accuracy < config.AdaptiveGoalAccuracy then
            table.insert(
                weaknesses,
                { CategoryCode = category.Code, Accuracy = metric.Accuracy, Samples = metric.Samples }
            )
        end
    end
    return {
        Window = maximum,
        GoalAccuracy = config.AdaptiveGoalAccuracy,
        TargetSkill = target,
        Category = AdaptiveSkills.WindowMetrics(history, source.CategoryCode, nil, nil, maximum),
        Format = AdaptiveSkills.WindowMetrics(history, nil, source.Mode, nil, maximum),
        CategoryFormat = AdaptiveSkills.WindowMetrics(
            history,
            source.CategoryCode,
            source.Mode,
            nil,
            maximum
        ),
        TargetPractice = AdaptiveSkills.WindowMetrics(history, nil, source.Mode, target, maximum),
        WeakCategories = weaknesses,
        Note = "Graded practice attempts, including retries; not clinical or separate skill mastery scores. Older saved entries retain the outcomes originally recorded.",
    }
end

function AdaptiveSkills.CategoryWeights(profile, categories, config, answerHistory, mode)
    local window = {}
    if type(answerHistory) == "table" and #answerHistory > 0 then
        for _, category in ipairs(categories) do
            window[category.Code] = { Correct = 0, Incorrect = 0 }
        end
        for _, entry in ipairs(answerHistory) do
            local counts = type(entry) == "table" and window[entry.Code]
            if counts then
                if entry.Correct == true then
                    counts.Correct += 1
                else
                    counts.Incorrect += 1
                end
            end
        end
    end
    local weights = {}
    for _, category in ipairs(categories) do
        local code = category.Code
        local stats = type(profile) == "table" and profile[code] or nil
        local accuracy, total = smoothedAccuracy(window[code] or stats)
        local peerSum, peerCount = 0, 0
        for _, other in ipairs(categories) do
            if other.Code ~= code then
                local peerAccuracy, peerTotal =
                    smoothedAccuracy(window[other.Code] or (type(profile) == "table" and profile[other.Code]))
                if peerTotal >= config.AdaptiveMinSamples then
                    peerSum += peerAccuracy
                    peerCount += 1
                end
            end
        end
        local peerAverage = peerCount > 0 and peerSum / peerCount or config.AdaptiveGoalAccuracy
        local weight = 1
        if total >= config.AdaptiveMinSamples then
            local goalGap = math.max(0, config.AdaptiveGoalAccuracy - accuracy) / config.AdaptiveGoalAccuracy
            local peerGap = math.max(0, peerAverage - accuracy)
            weight += 2 * goalGap + peerGap
        end
        if stats and stats.FocusActive then
            weight += config.AdaptiveFocusBonus
        end
        if mode then
            local metric =
                AdaptiveSkills.WindowMetrics(answerHistory, code, mode, nil, config.AccuracyWindowSize)
            if metric.Samples >= config.AdaptiveMinSamples then
                local smoothed = (metric.Correct + 2) / (metric.Samples + 2)
                weight += (config.AdaptiveFormatBonus or 0.75) * math.max(
                    0,
                    config.AdaptiveGoalAccuracy - smoothed
                ) / config.AdaptiveGoalAccuracy
            end
        end
        weights[code] = math.clamp(weight, 1, config.AdaptiveMaximumWeight)
    end
    return weights
end

return AdaptiveSkills
