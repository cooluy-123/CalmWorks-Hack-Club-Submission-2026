local Progress = {}
local noticeIds = { "M2", "GameComplete", "FinalBusinessManArrived", "CeremonyPending" }
for i = 1, 4 do
    table.insert(noticeIds, "M3_" .. i)
    table.insert(noticeIds, "M5_" .. i)
end

function Progress.Restore(saved)
    local result = { Notices = {} }
    local notices = type(saved) == "table" and saved.Notices
    for _, id in ipairs(noticeIds) do
        result.Notices[id] = type(notices) == "table" and notices[id] == true
    end
    return result
end

function Progress.Snapshot(state)
    return Progress.Restore(state)
end

function Progress.Notice(state, id)
    if not table.find(noticeIds, id) or state.Notices[id] then
        return false
    end
    state.Notices[id] = true
    return true
end

function Progress.Merge(previous, current)
    local result = Progress.Restore(current)
    local saved = Progress.Restore(previous)
    for _, id in ipairs(noticeIds) do
        result.Notices[id] = result.Notices[id] or saved.Notices[id]
    end
    return result
end

function Progress.CanAdvance(data, token, index, now)
    return type(token) == "string"
        and token == data.VisitToken
        and type(index) == "number"
        and index == data.VisitIndex
        and index % 1 == 0
        and now - (data.LastAdvanceAt or -math.huge) >= 0.12
end

return Progress
