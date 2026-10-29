-- Fixed EST, UTC-5 all year. Day end is 23:59:59 EST (displayed as 11:59 PM).
local Calendar = {}
Calendar.Offset = -5 * 3600
Calendar.SecondsPerDay = 86400
function Calendar.Day(timestamp)
    return math.floor((timestamp + Calendar.Offset) / 86400)
end
function Calendar.EndOfDay(day)
    return (day + 1) * 86400 - Calendar.Offset - 1
end
function Calendar.Label(day)
    return os.date("!%b %d, %Y", day * 86400)
end
function Calendar.CaptureLabel(timestamp)
    return os.date("!%b %d, %I:%M %p", timestamp + Calendar.Offset) .. " EST"
end
function Calendar.Steps(first, last, weekly)
    local steps = {}
    local step = 1
    if weekly then
        step = 7
    end
    for day = first, last, step do
        table.insert(steps, day)
    end
    if #steps == 0 or steps[#steps] ~= last then
        table.insert(steps, last)
    end
    return steps
end
function Calendar.Range(first, last, selected, weekly)
    if not weekly then
        return selected, selected
    end
    local steps = Calendar.Steps(first, last, true)
    for _, day in ipairs(steps) do
        -- Include the partial final week without inventing missing data.
        if day == selected then
            return math.max(first, day - 6), day
        end
    end
    return nil
end
return Calendar
