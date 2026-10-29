local Policy = {}
local Roster = require(script.Parent.StaffMoralePolicy).Roster

local function count(value, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return 0
    end
    return math.clamp(math.floor(value), 0, maximum)
end

function Policy.Clean(saved)
    saved = type(saved) == "table" and saved or {}
    local recent = {}
    if type(saved.RecentCases) == "table" then
        for i = math.max(1, #saved.RecentCases - 7), #saved.RecentCases do
            local id = saved.RecentCases[i]
            if type(id) == "string" and id:match("^CW%-STAFF%-%u%-%d%d$") then
                table.insert(recent, id)
            end
        end
    end
    return {
        Completed = count(saved.Completed, 1000000),
        Arrivals = count(saved.Arrivals, 10000),
        NextStaff = math.clamp(count(saved.NextStaff, #Roster), 1, #Roster),
        RecentCases = recent,
        Pending = saved.Pending == true,
    }
end

function Policy.Due(state, expansion, settings, rng)
    if expansion < 3 then
        return false
    end
    state.Arrivals = math.min(state.Arrivals + 1, 10000)
    local minimum = math.clamp(tonumber(settings:GetAttribute("MinimumCompleted")) or 3, 0, 100)
    local guarantee = math.clamp(tonumber(settings:GetAttribute("GuaranteeEveryArrivals")) or 10, 1, 1000)
    if expansion == 3 and state.Completed < minimum and state.Arrivals >= guarantee then
        return true
    end
    local chance = tonumber(settings:GetAttribute("ChancePerArrival")) or 0.01
    if chance ~= chance then
        chance = 0.01
    end
    return rng:NextNumber() < math.clamp(chance, 0, 1)
end

function Policy.Complete(state)
    state.Completed = math.min(state.Completed + 1, 1000000)
    state.Arrivals = 0
    state.Pending = false
end

return Policy
