-- Recommend only measured categories below the goal in the recent attempt window.
local Recommendations = {}

local DEFAULTS = {
    NeedsPractice = "Improve these categories (goal: {goal}%; last {window} graded attempts):",
    CategoryLine = "• {category}: {accuracy}% ({correct}/{total} correct; {mistakes} {mistakeLabel}){note}",
    RepeatedNote = " — repeated mistakes",
    RelativeNote = " — mistakes are more frequent here than in your other measured categories",
    PreliminaryNote = " — preliminary; answer more to confirm",
    AllAtGoal = "Your measured categories meet the {goal}% goal. Continue practicing and improving!",
    PreliminaryAtGoal = "Your measured categories currently meet the {goal}% goal. These early results are preliminary; keep practicing to build confidence.",
    NeedsSamples = "Build a fuller picture by answering more questions in: {categories}.",
    NoSamples = "Answer some customer questions to start your personal recommendations. Your recent results will appear here.",
    RepeatedAtGoal = "Recurring mistakes to review, even though these categories meet the goal:",
}

local function format(template, values)
    return (
        template:gsub("{(%w+)}", function(key)
            return tostring(values[key] or "{" .. key .. "}")
        end)
    )
end

function Recommendations.Build(categories, config, templates)
    templates = templates or {}
    local function wording(key)
        local value = templates[key]
        return type(value) == "string" and value ~= "" and value or DEFAULTS[key]
    end
    local goal = config.AdaptiveGoalAccuracy or 0.85
    local minimum = config.RecommendationMinCategoryAnswers or 3
    local repeatMinimum = config.RecommendationRepeatMistakes or 2
    local repeatGap = config.RecommendationRepeatGap or 0.10
    local weak, repeatedAtGoal, all = {}, {}, {}
    local preliminary = false
    local totalAnswers = 0
    for _, category in ipairs(categories) do
        local correct = math.max(0, tonumber(category.Correct) or 0)
        local mistakes = math.max(0, tonumber(category.Incorrect) or 0)
        local total = correct + mistakes
        local item = {
            Code = category.Code,
            Name = category.Name,
            Correct = correct,
            Incorrect = mistakes,
            Total = total,
            Accuracy = total > 0 and correct / total or nil,
            Preliminary = total < minimum,
        }
        totalAnswers += total
        table.insert(all, item)
        if total > 0 and total < minimum then
            preliminary = true
        end
    end
    for _, item in ipairs(all) do
        if item.Total > 0 then
            local peerErrors, peerTotal = 0, 0
            for _, other in ipairs(all) do
                if other.Code ~= item.Code and other.Total >= minimum then
                    peerErrors += other.Incorrect
                    peerTotal += other.Total
                end
            end
            item.RelativeRepeat = item.Total >= minimum
                and item.Incorrect >= repeatMinimum
                and peerTotal > 0
                and (1 - item.Accuracy) - peerErrors / peerTotal >= repeatGap
            item.Repeated = item.Incorrect >= repeatMinimum
            if item.Accuracy < goal then
                table.insert(weak, item)
            end
        end
    end
    local function order(a, b)
        if a.Preliminary ~= b.Preliminary then
            return not a.Preliminary
        end
        if a.Accuracy ~= b.Accuracy then
            return a.Accuracy < b.Accuracy
        end
        if a.Incorrect ~= b.Incorrect then
            return a.Incorrect > b.Incorrect
        end
        return a.Code < b.Code
    end
    table.sort(weak, order)
    table.sort(repeatedAtGoal, order)
    local values = { goal = math.floor(goal * 100 + 0.5), window = config.AccuracyWindowSize or 50 }
    local lines, codes = {}, {}
    local function append(item)
        local note = item.Preliminary and wording("PreliminaryNote")
            or (
                item.RelativeRepeat and wording("RelativeNote")
                or (item.Repeated and wording("RepeatedNote") or "")
            )
        table.insert(
            lines,
            format(wording("CategoryLine"), {
                category = item.Name,
                accuracy = math.floor(item.Accuracy * 100 + 0.5),
                correct = item.Correct,
                total = item.Total,
                mistakes = item.Incorrect,
                mistakeLabel = item.Incorrect == 1 and "mistake" or "mistakes",
                note = note,
            })
        )
        table.insert(codes, item.Code)
    end
    if totalAnswers == 0 then
        table.insert(lines, wording("NoSamples"))
    else
        if #weak > 0 then
            table.insert(lines, format(wording("NeedsPractice"), values))
            for _, item in ipairs(weak) do
                append(item)
            end
        end
        if #weak == 0 then
            local key = preliminary and "PreliminaryAtGoal" or "AllAtGoal"
            table.insert(lines, format(wording(key), values))
        end
    end
    return {
        Text = table.concat(lines, "\n"),
        Codes = codes,
        PrimaryCode = codes[1],
        Weak = weak,
        RepeatedAtGoal = repeatedAtGoal,
        AllAtGoal = totalAnswers > 0 and #weak == 0 and not preliminary,
    }
end

Recommendations.DefaultTemplates = DEFAULTS

-- Weekly rates average saved daily percentages; overlapping last-50 windows
-- cannot be added up as independent answers or repeated mistakes.
function Recommendations.BuildAverage(categories, config, templates)
    templates = templates or {}
    local weak = {}
    local measured = 0
    local preliminary = false
    for _, c in ipairs(categories) do
        if c.Accuracy ~= nil and (c.MaxSamples or 0) > 0 and (c.MeasuredDays or 0) > 0 then
            measured += 1
            if c.MaxSamples < (config.RecommendationMinCategoryAnswers or 3) then
                preliminary = true
            end
            if c.Accuracy < (config.AdaptiveGoalAccuracy or 0.85) then
                table.insert(weak, c)
            end
        end
    end
    table.sort(weak, function(a, b)
        if a.Accuracy ~= b.Accuracy then
            return a.Accuracy < b.Accuracy
        end
        return a.Code < b.Code
    end)
    local lines, codes = {}, {}
    if #weak > 0 then
        table.insert(
            lines,
            templates.WeeklyNeedsPractice
                or "Categories below the goal in this period's daily-snapshot average:"
        )
        for _, c in ipairs(weak) do
            table.insert(codes, c.Code)
            table.insert(
                lines,
                format(
                    templates.WeeklyCategoryLine
                        or "• {category}: {accuracy}% average across {days} saved days{note}",
                    {
                        category = c.Name,
                        accuracy = math.floor(c.Accuracy * 100 + 0.5),
                        days = c.MeasuredDays,
                        note = c.MaxSamples < (config.RecommendationMinCategoryAnswers or 3)
                                and " — preliminary"
                            or "",
                    }
                )
            )
        end
    elseif measured == 0 then
        table.insert(
            lines,
            templates.WeeklyNeedsData or "No graded attempts were recorded for this period yet."
        )
    elseif preliminary then
        table.insert(
            lines,
            templates.WeeklyPreliminaryAtGoal
                or "The measured averages meet the goal, but the small samples are preliminary. Keep practicing to build confidence."
        )
    else
        table.insert(
            lines,
            templates.WeeklyAtGoal
                or "Your measured category averages meet the goal. Continue practicing and improving!"
        )
    end
    return { Text = table.concat(lines, "\n"), Codes = codes, PrimaryCode = codes[1] }
end
return Recommendations
