-- Server-only, formative AI grading for editable CalmWorks FRQ scenarios.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")
local CustomerBehavior = require(ServerStorage:WaitForChild("CustomerBehavior"))

local Config = require(ReplicatedStorage:WaitForChild("CalmWorksShared"):WaitForChild("Config"))
local generator = ServerStorage:WaitForChild("CalmWorksFRQGrader")
assert(generator:IsA("TextGenerator"), "CalmWorksFRQGrader must be an editable TextGenerator")

local GradePolicy = require(ServerStorage:WaitForChild("FRQGradePolicy"))
local FeedbackPolicy = require(ServerStorage:WaitForChild("FRQFeedbackPolicy"))
local FRQGrader = {}

local function trim(value)
    return string.match(value, "^%s*(.-)%s*$") or ""
end

local function filterForPlayer(text, player)
    local ok, result = pcall(function()
        local filtered =
            TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PrivateChat)
        return filtered:GetNonChatStringForUserAsync(player.UserId)
    end)
    if not ok or type(result) ~= "string" then
        return nil
    end
    return trim(result)
end

local function score(value)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    if value < 0 or value > 100 then
        return nil
    end
    return math.floor(value + 0.5)
end

local function readFeedback(parsed, player)
    local settings = generator:GetAttributes()
    if not FeedbackPolicy.Validate(parsed, settings) then
        return nil
    end
    local feedback = {}
    for _, field in ipairs(FeedbackPolicy.Fields) do
        feedback[field] = filterForPlayer(parsed[field], player)
        if not feedback[field] then
            return nil
        end
    end
    -- Filtered-out words must not leave an empty or meaningless explanation.
    if not FeedbackPolicy.Validate(feedback, settings) then
        return nil
    end
    return feedback
end

local function decode(raw)
    if type(raw) ~= "string" then
        return nil
    end
    local json = string.match(raw, "{.*}")
    if not json then
        return nil
    end
    local ok, parsed = pcall(HttpService.JSONDecode, HttpService, json)
    if ok and type(parsed) == "table" then
        return parsed
    end
    return nil
end

local function parseGrade(raw, player, rubric, response)
    local parsed = decode(raw)
    if not parsed then
        return nil
    end
    local scores = {
        DeEscalation = score(parsed.DeEscalation),
        BoundarySetting = score(parsed.BoundarySetting),
        ActiveListening = score(parsed.ActiveListening),
        ProblemSolving = score(parsed.ProblemSolving),
        EscalationRisk = score(parsed.EscalationRisk),
    }
    for _, key in ipairs({
        "DeEscalation",
        "BoundarySetting",
        "ActiveListening",
        "ProblemSolving",
        "EscalationRisk",
    }) do
        if scores[key] == nil then
            return nil
        end
    end
    if type(parsed.SafetyConcern) ~= "boolean" or type(parsed.MinimumViable) ~= "boolean" then
        return nil
    end
    if not GradePolicy.HasGroundedEvidence(parsed, response) then
        return nil
    end
    local feedback = readFeedback(parsed, player)
    local rubricScores
    local quality
    if rubric then
        if type(parsed.RubricScores) ~= "table" or #parsed.RubricScores ~= #rubric then
            return nil
        end
        rubricScores = {}
        quality = 0
        for index, dimension in ipairs(rubric) do
            local value = score(parsed.RubricScores[index])
            if value == nil then
                return nil
            end
            quality += value * dimension.Weight / 100
            table.insert(rubricScores, { Label = dimension.Label, Weight = dimension.Weight, Score = value })
        end
    else
        quality = 0.35 * scores.DeEscalation
            + 0.2 * scores.BoundarySetting
            + 0.2 * scores.ActiveListening
            + 0.25 * scores.ProblemSolving
            - 0.15 * scores.EscalationRisk
    end
    -- Rubric scores remain useful coaching evidence, not a completion barrier.
    local passed = GradePolicy.Passes(parsed, Config.FRQMaximumEscalationRisk)
    return {
        Passed = passed,
        Scores = scores,
        WeightedScore = math.clamp(math.floor(quality + 0.5), 0, 100),
        RubricScores = rubricScores,
        Summary = feedback and feedback.Summary,
        Strength = feedback and feedback.Strength,
        Improvement = feedback and feedback.Improvement,
        ModelResponse = feedback and feedback.ModelResponse,
    }, feedback ~= nil
end

function FRQGrader.Grade(player, scenario, stageIndex, response)
    if type(response) ~= "string" then
        return nil, "Write a response before submitting."
    end
    response = trim(response)
    local responseCharacters = utf8.len(response)
    if not responseCharacters or #response > 2000 then
        return nil, "That response could not be processed safely."
    end
    if responseCharacters < Config.FRQMinCharacters then
        return nil, "Write one safe next step before submitting."
    end
    if responseCharacters > Config.FRQMaxCharacters then
        return nil, "Keep your response under " .. Config.FRQMaxCharacters .. " characters."
    end
    local filteredResponse = filterForPlayer(response, player)
    if not filteredResponse or filteredResponse == "" then
        return nil, "Roblox could not safely process that response."
    end
    local stage = scenario.Stages[stageIndex]
    if not stage then
        return nil, "This scenario is no longer available."
    end
    -- Keep the actual answer unambiguous. Reference solutions can cause a small
    -- model to grade the reference instead of the player, so they are not sent.
    local request = {
        Instruction = "Grade only ResponseToGrade. First accept any safe, relevant, minimally useful first step, including a brief action fragment or a partially effective approach. Then provide optional coaching scores. Missing details, low rubric coverage, spelling and not being the best answer are not failure reasons. Quote the actual action exactly in ActionEvidence; never invent one.",
        Scenario = {
            Title = scenario.Title,
            Category = scenario.Category,
            Difficulty = scenario.Difficulty,
            Stage = stageIndex,
            StageCount = #scenario.Stages,
            Situation = stage.Prompt,
            Task = GradePolicy.Task(scenario, Config.FRQDefaultPrompt),
            TargetSkills = scenario.Skills,
            CoachingRubric = scenario.FRQ and scenario.FRQ.Rubric or nil,
            Customer = CustomerBehavior.Context(scenario.CustomerProfile),
        },
        ResponseToGrade = filteredResponse,
    }
    local prompt = HttpService:JSONEncode(request)
    local generatedOkay, generated = pcall(function()
        return generator:GenerateTextAsync({ UserPrompt = prompt, MaxTokens = Config.FRQGradingMaxTokens })
    end)
    if not generatedOkay then
        warn("CalmWorks FRQ AI grading unavailable: " .. tostring(generated))
        return nil, "AI grading is unavailable right now."
    end
    local grade, hasFeedback = parseGrade(
        type(generated) == "table" and generated.GeneratedText or nil,
        player,
        scenario.FRQ and scenario.FRQ.Rubric or nil,
        filteredResponse
    )
    if not grade then
        warn("CalmWorks FRQ AI grading returned an invalid or unfilterable response")
        return nil, "AI grading could not produce safe, structured feedback."
    end
    if not hasFeedback then
        -- Repair only the commentary; never change the validated decision or scores.
        request.FeedbackOnly = true
        request.Instruction = "Write detailed, response-specific coaching in all four feedback fields. The confirmed decision and scores are fixed. Explain why, offer one practical improvement, and include a concrete example; a passing answer never needs revision to keep its pass."
        request.ConfirmedAssessment = {
            Passed = grade.Passed,
            Scores = grade.Scores,
            WeightedScore = grade.WeightedScore,
        }
        local repairedOkay, repaired = pcall(function()
            return generator:GenerateTextAsync({
                UserPrompt = HttpService:JSONEncode(request),
                MaxTokens = Config.FRQGradingMaxTokens,
            })
        end)
        local feedback
        if repairedOkay and type(repaired) == "table" then
            feedback = readFeedback(decode(repaired.GeneratedText), player)
        end
        if not feedback then
            warn("CalmWorks FRQ feedback remained too brief, invalid or unfilterable after one repair")
            return nil, "AI grading could not produce safe, detailed feedback."
        end
        for _, field in ipairs(FeedbackPolicy.Fields) do
            grade[field] = feedback[field]
        end
    end
    return grade
end

return FRQGrader
