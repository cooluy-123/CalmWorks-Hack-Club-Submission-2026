local Policy = {}

Policy.Roster = {
    { Id = "MainCounselor", Area = "Main", Role = "Counselor", Stage = "1" },
    { Id = "MainManager", Area = "Main", Role = "Manager", Stage = "2" },
    { Id = "LeftCounselor", Area = "Left", Role = "Counselor", Stage = "1" },
    { Id = "LeftManager", Area = "Left", Role = "Manager", Stage = "2" },
    { Id = "RightCounselor", Area = "Right", Role = "Counselor", Stage = "1" },
    { Id = "RightManager", Area = "Right", Role = "Manager", Stage = "2" },
    { Id = "UpperLeftExecutiveConsulter", Area = "UpperLeft", Role = "Executive", Stage = "2" },
    { Id = "UpperRightExecutiveConsulter", Area = "UpperRight", Role = "Executive", Stage = "2" },
    {
        Id = "PrivateMainLeftCounselor",
        Area = "PrivateMainLeft",
        Room = "Main",
        Role = "Counselor",
        Stage = "4",
        Private = true,
    },
    {
        Id = "PrivateMainRightCounselor",
        Area = "PrivateMainRight",
        Room = "Main",
        Role = "Counselor",
        Stage = "4",
        Private = true,
    },
    { Id = "PrivateLeftCounselor", Area = "PrivateLeft", Room = "Left", Role = "Counselor", Stage = "4", Private = true },
    { Id = "PrivateRightCounselor", Area = "PrivateRight", Room = "Right", Role = "Counselor", Stage = "4", Private = true },
    {
        Id = "PrivateUpperLeftFrontCounselor",
        Area = "PrivateUpperLeftFront",
        Room = "UpperLeft",
        Role = "Counselor",
        Stage = "4",
        Private = true,
    },
    {
        Id = "PrivateUpperLeftBackCounselor",
        Area = "PrivateUpperLeftBack",
        Room = "UpperLeft",
        Role = "Counselor",
        Stage = "4",
        Private = true,
    },
    {
        Id = "PrivateUpperRightFrontCounselor",
        Area = "PrivateUpperRightFront",
        Room = "UpperRight",
        Role = "Counselor",
        Stage = "4",
        Private = true,
    },
    {
        Id = "PrivateUpperRightBackCounselor",
        Area = "PrivateUpperRightBack",
        Room = "UpperRight",
        Role = "Counselor",
        Stage = "4",
        Private = true,
    },
}

local function number(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return math.clamp(fallback, minimum, maximum)
    end
    return math.clamp(value, minimum, maximum)
end

function Policy.Setting(settings, key, fallback, minimum, maximum)
    return number(settings:GetAttribute(key), fallback, minimum, maximum)
end

function Policy.Clean(saved)
    saved = type(saved) == "table" and saved or {}
    local initialized = saved.Initialized == true
    local entries = type(saved.Entries) == "table" and saved.Entries or {}
    local result = { Initialized = initialized, Entries = {}, DecayNextRemaining = number(saved.DecayNextRemaining, 0, 0, 86400) }
    for _, staff in ipairs(Policy.Roster) do
        local entry = type(entries[staff.Id]) == "table" and entries[staff.Id] or {}
        result.Entries[staff.Id] = {
            Morale = math.floor(number(entry.Morale, 100, 0, 100)),
            LossRemainder = number(entry.LossRemainder, 0, 0, 0.999999),
            RecoveryRemaining = number(entry.RecoveryRemaining, 0, 0, 600),
            DecayDelayRemaining = type(entry.DecayDelayRemaining) == "number"
                and number(entry.DecayDelayRemaining, 0, 0, 86400) or nil,
        }
    end
    return result
end

function Policy.Initialize(state, expansion)
    if expansion < 3 or state.Initialized then
        return false
    end
    state.Initialized = true
    state.DecayNextRemaining = 0
    for _, entry in pairs(state.Entries) do
        entry.Morale = 100
        entry.LossRemainder = 0
        entry.RecoveryRemaining = 0
        entry.DecayDelayRemaining = nil
    end
    return true
end

function Policy.Multiplier(morale)
    morale = math.floor(number(morale, 50, 0, 100))
    -- A speed band changes only after a complete ten-point drop from 100.
    return (5 + math.ceil(morale / 10)) / 10
end

function Policy.LossDivisor(role, settings)
    if role == "Manager" then
        return Policy.Setting(settings, "ManagerLossDivisor", 1.5, 1, 10)
    elseif role == "Executive" then
        return Policy.Setting(settings, "ExecutiveLossDivisor", 2, 1, 10)
    end
    return 1
end

function Policy.Lose(entry, amount, role, settings)
    if entry.Morale <= 0 then
        return false
    end
    local loss = number(amount, 0, 0, 100) / Policy.LossDivisor(role, settings)
    if loss <= 0 then
        return false
    end
    local total = entry.LossRemainder + loss
    local whole = math.floor(total + 0.0000001)
    entry.Morale = math.max(0, entry.Morale - whole)
    entry.LossRemainder = math.max(0, total - whole)
    if entry.Morale == 0 then
        entry.LossRemainder = 0
    end
    return true
end

function Policy.CustomerLoss(scenario, angry, settings)
    scenario = type(scenario) == "table" and scenario or {}
    local difficulty = math.floor(number(scenario.Difficulty, 1, 1, 5))
    local amount = difficulty * Policy.Setting(settings, "LossPerDifficulty", 1, 0, 10)
    if scenario.Mode == "FRQ" then
        amount += Policy.Setting(settings, "FRQExtraLoss", 1, 0, 5)
    end
    if angry then
        amount += Policy.Setting(settings, "AngryBaseLoss", 4, 0, 20)
        amount = math.clamp(amount, 5, 10)
    end
    return amount
end

function Policy.Recover(entry)
    entry.RecoveryRemaining = 0
    entry.DecayDelayRemaining = nil
    entry.Morale = 100
    entry.LossRemainder = 0
end

return Policy
