-- Compact immutable daily snapshots. No player text, money, or purchases are stored here.
local Calendar = require(game.ReplicatedStorage.CalmWorksShared.ProgressCalendar)
local Recommendations = require(script.Parent.PracticeRecommendations)
local History = {}
local function integer(n, low, high)
    return type(n) == "number" and n == n and n % 1 == 0 and n >= low and n <= high
end
local function count(n, maximum)
    return integer(n, 0, maximum) and n or 0
end
function History.Clean(raw, definitions, config, now)
    local today = Calendar.Day(now)
    local minimum = today - (config.ProgressRetentionDays or 3650) + 1
    local byDay = {}
    if type(raw) == "table" then
        for _, r in ipairs(raw) do
            if
                type(r) == "table"
                and integer(r.Day, minimum, today)
                and integer(r.At, 0, now)
                and Calendar.Day(r.At) == r.Day
                and type(r.Rows) == "table"
            then
                local rows = {}
                local total = 0
                for _, d in ipairs(definitions) do
                    local v = type(r.Rows[d.Code]) == "table" and r.Rows[d.Code] or {}
                    local c, w =
                        count(v[1], config.AccuracyWindowSize), count(v[2], config.AccuracyWindowSize)
                    total += c + w
                    rows[d.Code] = { c, w, count(v[3], 1000), count(v[4], 1000), v[5] == true }
                end
                if total <= config.AccuracyWindowSize and (not byDay[r.Day] or r.At >= byDay[r.Day].At) then
                    byDay[r.Day] = { Day = r.Day, At = r.At, Rows = rows }
                end
            end
        end
    end
    local result = {}
    for _, r in pairs(byDay) do
        table.insert(result, r)
    end
    table.sort(result, function(a, b)
        return a.Day < b.Day
    end)
    return result
end
function History.Record(snapshot, timestamp)
    local rows = {}
    for _, c in ipairs(snapshot.Categories) do
        rows[c.Code] = {
            c.Correct or 0,
            c.Incorrect or 0,
            c.FocusCorrect or 0,
            c.FocusMistakes or 0,
            c.FocusActive == true,
        }
    end
    return { Day = Calendar.Day(timestamp), At = timestamp, Rows = rows }
end
function History.Merge(a, b, definitions, config, now)
    local both = {}
    for _, r in ipairs(type(a) == "table" and a or {}) do
        table.insert(both, r)
    end
    for _, r in ipairs(type(b) == "table" and b or {}) do
        table.insert(both, r)
    end
    return History.Clean(both, definitions, config, now)
end
function History.Meta(records, now)
    local today = Calendar.Day(now)
    local days = #records
    local hasToday = days > 0 and records[days].Day == today
    return {
        FirstDay = days > 0 and records[1].Day or today,
        LastDay = today,
        Today = today,
        SavedDays = days,
        WeeklyAvailable = days >= 7,
        LastCheckpoint = hasToday and records[days].At or nil,
    }
end
function History.View(records, definitions, config, templates, day, weekly, now)
    local meta = History.Meta(records, now)
    if not integer(day, meta.FirstDay, meta.LastDay) then
        return nil, "Choose a saved date within the slider range."
    end
    if weekly and not meta.WeeklyAvailable then
        return nil, "Weekly Average unlocks after seven saved days."
    end
    local first, last = Calendar.Range(meta.FirstDay, meta.LastDay, day, weekly)
    if not first then
        return nil, "Choose a weekly cadence step."
    end
    local selected = {}
    for _, r in ipairs(records) do
        if r.Day >= first and r.Day <= last then
            table.insert(selected, r)
        end
    end
    local data = {
        Ready = true,
        Historical = true,
        IsWeekly = weekly,
        PeriodStart = first,
        PeriodEnd = last,
        HasData = #selected > 0,
        SavedDays = #selected,
        PeriodDays = last - first + 1,
        Categories = {},
        WindowSize = config.AccuracyWindowSize,
        TargetAccuracy = config.AdaptiveGoalAccuracy,
        MasteryCorrect = config.AdaptiveMasteryCorrect,
        MasteryMistakes = config.AdaptiveMasteryMistakes,
        TotalCorrect = 0,
        TotalIncorrect = 0,
        TotalAnswers = 0,
        Progress = meta,
    }
    local overallSum, overallDays = 0, 0
    for _, r in ipairs(selected) do
        local correct, total = 0, 0
        for _, v in pairs(r.Rows) do
            correct += v[1]
            total += v[1] + v[2]
        end
        if total > 0 then
            overallSum += correct / total
            overallDays += 1
        end
        data.CapturedAt = math.max(data.CapturedAt or 0, r.At)
    end
    for _, d in ipairs(definitions) do
        local row = {
            Code = d.Code,
            Name = d.Name,
            Correct = 0,
            Incorrect = 0,
            Total = 0,
            MeasuredDays = 0,
            MaxSamples = 0,
        }
        local sum = 0
        for _, r in ipairs(selected) do
            local v = r.Rows[d.Code] or { 0, 0, 0, 0, false }
            local total = v[1] + v[2]
            if weekly then
                if total > 0 then
                    sum += v[1] / total
                    row.MeasuredDays += 1
                    row.MaxSamples = math.max(row.MaxSamples, total)
                end
            else
                row.Correct, row.Incorrect, row.Total = v[1], v[2], total
                row.Accuracy = total > 0 and v[1] / total or nil
                row.FocusCorrect, row.FocusMistakes, row.FocusActive = v[3], v[4], v[5]
            end
        end
        if weekly then
            row.Accuracy = row.MeasuredDays > 0 and sum / row.MeasuredDays or nil
            -- A lower bound on distinct answers, never a sum of overlapping windows.
            row.Total = row.MaxSamples
        end
        table.insert(data.Categories, row)
        data.TotalCorrect += row.Correct
        data.TotalIncorrect += row.Incorrect
        data.TotalAnswers += row.Total
    end
    data.OverallAccuracy = overallDays > 0 and overallSum / overallDays or nil
    data.MeasuredDays = overallDays
    local rec
    if weekly then
        rec = Recommendations.BuildAverage(data.Categories, config, templates)
    else
        rec = Recommendations.Build(data.Categories, config, templates)
    end
    data.Recommendation = rec.Text
    data.RecommendationCategoryCode = rec.PrimaryCode
    data.RecommendationCategoryCodes = rec.Codes
    if not data.HasData then
        data.Recommendation =
            "No snapshot was saved for this date. Missing days are not treated as 0% accuracy."
    end
    return data
end
return History
