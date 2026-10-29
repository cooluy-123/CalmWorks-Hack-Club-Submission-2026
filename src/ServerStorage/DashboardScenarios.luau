local Library = require(script.Parent.ScenarioLibrary)
local Scenarios = {}
local byId = {}
for _, scenario in ipairs(Library) do
    byId[scenario.Id] = scenario
end

local function text(value, maximum, allowEmpty)
    return type(value) == "string" and #value <= maximum
        and (allowEmpty or #value > 0) and utf8.len(value) ~= nil
end

local function integer(value, minimum, maximum)
    return type(value) == "number" and value % 1 == 0 and value >= minimum and value <= maximum
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

function Scenarios.CleanScenario(raw)
    if type(raw) ~= "table" then
        return nil
    end
    local source = byId[raw.TemplateId or raw.Id]
    if not source or (raw.Mode ~= "MCQ" and raw.Mode ~= "FRQ") then
        return nil
    end
    if raw.Mode == "FRQ" and not source.FRQ then
        return nil
    end
    if raw.SourceKind ~= "AI" and raw.SourceKind ~= "Library" then
        return nil
    end
    if not text(raw.Id, 120) or not text(raw.Title, 200) or not text(raw.Feedback, 2000) then
        return nil
    end
    if type(raw.Stages) ~= "table" or #raw.Stages ~= #source.Stages then
        return nil
    end

    -- Only server-created snapshots are stored; rubrics and scoring metadata stay tied to the library.
    local result = copy(source)
    result.TemplateId = source.Id
    result.Id = raw.Id
    result.Title = raw.Title
    result.Feedback = raw.Feedback
    result.SourceKind = raw.SourceKind
    result.SourceVersion = raw.SourceVersion
    result.Mode = raw.Mode
    result.TargetSkill = text(raw.TargetSkill, 120) and raw.TargetSkill or source.Skills[1]
    result.Stages = {}
    for i, stage in ipairs(raw.Stages) do
        if type(stage) ~= "table" or not text(stage.Prompt, 6000) then
            return nil
        end
        if not integer(stage.BestIndex, 1, 3) then
            return nil
        end
        local clean = {Prompt = stage.Prompt, StageNumber = i, BestIndex = stage.BestIndex,
            Choices = {}, ChoiceFeedback = {}, ChoiceOutcomes = {}, ChoiceKeys = {}, ChoiceResultScores = {}}
        local seen = {}
        for j = 1, 3 do
            local choice = type(stage.Choices) == "table" and stage.Choices[j]
            local feedback = type(stage.ChoiceFeedback) == "table" and stage.ChoiceFeedback[j]
            local key = type(stage.ChoiceKeys) == "table" and stage.ChoiceKeys[j]
            local original = table.find(source.Stages[i].ChoiceKeys, key)
            if not text(choice, 1500) or not text(feedback, 2000, true) or not original or seen[key] then
                return nil
            end
            seen[key] = true
            if (j == stage.BestIndex) ~= (original == source.Stages[i].BestIndex) then
                return nil
            end
            clean.Choices[j] = choice
            clean.ChoiceFeedback[j] = feedback
            clean.ChoiceKeys[j] = key
            clean.ChoiceOutcomes[j] = source.Stages[i].ChoiceOutcomes[original]
            clean.ChoiceResultScores[j] = source.Stages[i].ChoiceResultScores[original]
        end
        clean.BestKey = clean.ChoiceKeys[clean.BestIndex]
        result.Stages[i] = clean
    end
    if type(raw.CustomerProfile) == "table" then
        result.CustomerProfile = {}
        for _, key in ipairs({"Mood", "CurrentMood", "Personality", "CommunicationStyle", "Prominent"}) do
            if text(raw.CustomerProfile[key], 80) then
                result.CustomerProfile[key] = raw.CustomerProfile[key]
            end
        end
    end
    return result
end

function Scenarios.CleanPending(raw)
    if type(raw) ~= "table" or raw.Version ~= 2 or not text(raw.Name, 40) then
        return nil
    end
    local scenario = Scenarios.CleanScenario(raw.Scenario)
    if not scenario or not integer(raw.StageIndex, 1, #scenario.Stages) then
        return nil
    end
    local result = {
        Version = 2,
        Name = raw.Name,
        Scenario = scenario,
        StageIndex = raw.StageIndex,
        RecordedStages = {},
        FirstCorrect = raw.FirstCorrect ~= false,
    }
    for i = 1, #scenario.Stages do
        result.RecordedStages[i] = type(raw.RecordedStages) == "table" and raw.RecordedStages[i] == true
    end
    return result
end

function Scenarios.NewPending(scenario, settings, rng)
    local names = {}
    local folder = settings:FindFirstChild("CustomerNames")
    for _, item in ipairs(folder and folder:GetChildren() or {}) do
        if item:IsA("StringValue") and text(item.Value, 40) then
            table.insert(names, item.Value)
        end
    end
    local name = #names > 0 and names[rng:NextInteger(1, #names)] or "Customer"
    return Scenarios.CleanPending({
        Version = 2, Name = name, Scenario = scenario, StageIndex = 1,
        RecordedStages = {}, FirstCorrect = true,
    })
end

return Scenarios
