local HttpService = game:GetService("HttpService")
local Schema = {}

local function text(minimum, maximum)
    return { type = "string", minLength = minimum, maxLength = maximum }
end

local function array(items, count)
    return { type = "array", items = items, minItems = count, maxItems = count }
end

local function object(properties, required)
    return { type = "object", properties = properties, required = required, additionalProperties = false }
end

function Schema.Writer(source)
    local stage = object({
        Background = text(35, 420),
        CustomerInsight = text(3, 220),
        Choices = array(text(25, 210), 3),
        ChoiceFeedback = array(text(15, 260), 3),
    }, { "Background", "CustomerInsight", "Choices", "ChoiceFeedback" })
    return HttpService:JSONEncode(object({
        Title = text(4, 80),
        Feedback = text(20, 320),
        Stages = array(stage, #source.Stages),
    }, { "Title", "Feedback", "Stages" }))
end

function Schema.Reviewer(source)
    local required = {
        "Safe",
        "Grounded",
        "UniqueBest",
        "PlausibleChoices",
        "DifficultyAligned",
        "CoherentStages",
        "FeedbackAccurate",
        "TargetSkillAligned",
        "ChoiceRolesPreserved",
        "NoPersonalData",
        "CustomerAligned",
        "BackgroundFirst",
        "CustomerVoice",
    }
    local properties = {}
    for _, key in ipairs(required) do
        properties[key] = { type = "boolean" }
    end
    if source.WorkplaceContext then
        properties.WorkplaceAligned = { type = "boolean" }
        table.insert(required, "WorkplaceAligned")
    end
    properties.Analysis = array(text(1, 180), #source.Stages)
    properties.BestKeys = array({ type = "string", enum = { "A", "B", "C" } }, #source.Stages)
    table.insert(required, "Analysis")
    table.insert(required, "BestKeys")
    return HttpService:JSONEncode(object(properties, required))
end

function Schema.Checker(source)
    return HttpService:JSONEncode(object({
        Safe = { type = "boolean" },
        UniqueBest = { type = "boolean" },
        BestKeys = array({ type = "string", enum = { "A", "B", "C" } }, #source.Stages),
        Reasoning = array(text(1, 180), #source.Stages),
    }, { "Safe", "UniqueBest", "BestKeys", "Reasoning" }))
end

return Schema
