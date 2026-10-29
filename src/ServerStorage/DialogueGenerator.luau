-- Server-only difficulty selector and answer shuffler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("CalmWorksShared"):WaitForChild("Config"))
local ScenarioLibrary = require(script.Parent:WaitForChild("ScenarioLibrary"))
ScenarioLibrary = require(script.Parent:WaitForChild("ScenarioPolishOverrides")).Apply(ScenarioLibrary)
local WorkplaceLibrary = require(script.Parent:WaitForChild("WorkplaceScenarioLibrary"))
local AdaptiveSkills = require(script.Parent:WaitForChild("AdaptiveSkills"))
local CustomerBehavior = require(script.Parent:WaitForChild("CustomerBehavior"))
local PracticePolicy = require(script.Parent:WaitForChild("PracticeModePolicy"))
local categoryDefinitions = assert(ScenarioLibrary.Metadata and ScenarioLibrary.Metadata.Categories)

local DialogueGenerator = {}
local rng = Random.new()
local fallbackRecentIds = {}
local RECENT_WINDOW = math.clamp(Config.ScenarioRecentWindow or 12, 1, 100)
local scenariosById = {}
local profileHistories = setmetatable({}, { __mode = "k" })
local scenariosByDifficulty = {}

for difficulty = 1, 5 do
    scenariosByDifficulty[difficulty] = {}
end

for _, scenario in ipairs(ScenarioLibrary) do
    assert(type(scenario.Id) == "string", "Every CalmWorks scenario needs an Id")
    assert(
        type(scenario.Difficulty) == "number" and scenariosByDifficulty[scenario.Difficulty],
        string.format("Scenario %s has an invalid difficulty", tostring(scenario.Id))
    )
    assert(
        type(scenario.CategoryCode) == "string" and type(scenario.Category) == "string",
        string.format("Scenario %s needs category metadata", tostring(scenario.Id))
    )
    assert(
        type(scenario.EloSeed) == "number" and type(scenario.Severity) == "number",
        string.format("Scenario %s needs ELO seed and severity metadata", tostring(scenario.Id))
    )
    assert(
        type(scenario.Skills) == "table" and #scenario.Skills >= 1,
        string.format("Scenario %s needs at least one skill", tostring(scenario.Id))
    )
    assert(
        type(scenario.Stages) == "table" and #scenario.Stages >= 1,
        string.format("Scenario %s needs at least one stage", scenario.Id)
    )
    if scenario.FRQ then
        assert(
            type(scenario.FRQ.Prompt) == "string"
                and type(scenario.FRQ.Rubric) == "table"
                and #scenario.FRQ.Rubric == 5,
            string.format("Scenario %s has invalid FRQ metadata", scenario.Id)
        )
        local weightTotal = 0
        for _, dimension in ipairs(scenario.FRQ.Rubric) do
            assert(
                type(dimension.Label) == "string"
                    and type(dimension.Anchor) == "string"
                    and type(dimension.Weight) == "number",
                string.format("Scenario %s has an invalid FRQ rubric dimension", scenario.Id)
            )
            weightTotal += dimension.Weight
        end
        assert(weightTotal == 100, string.format("Scenario %s FRQ weights must total 100", scenario.Id))
    end
    for stageIndex, stage in ipairs(scenario.Stages) do
        assert(
            type(stage.Prompt) == "string" and type(stage.Choices) == "table" and #stage.Choices == 3,
            string.format(
                "Scenario %s stage %d must have one prompt and three choices",
                scenario.Id,
                stageIndex
            )
        )
        assert(
            type(stage.ChoiceFeedback) == "table" and #stage.ChoiceFeedback == 3,
            string.format(
                "Scenario %s stage %d must have feedback for all three choices",
                scenario.Id,
                stageIndex
            )
        )
        assert(
            type(stage.ChoiceOutcomes) == "table" and #stage.ChoiceOutcomes == 3,
            string.format(
                "Scenario %s stage %d must have outcomes for all three choices",
                scenario.Id,
                stageIndex
            )
        )
        assert(
            type(stage.ChoiceResultScores) == "table" and #stage.ChoiceResultScores == 3,
            string.format(
                "Scenario %s stage %d must have result scores for all three choices",
                scenario.Id,
                stageIndex
            )
        )
        assert(
            type(stage.ChoiceKeys) == "table" and #stage.ChoiceKeys == 3,
            string.format(
                "Scenario %s stage %d must have source keys for all three choices",
                scenario.Id,
                stageIndex
            )
        )
        assert(
            type(stage.BestIndex) == "number" and stage.Choices[stage.BestIndex],
            string.format("Scenario %s stage %d has an invalid answer key", scenario.Id, stageIndex)
        )
    end
    scenariosById[scenario.Id] = scenario
    table.insert(scenariosByDifficulty[scenario.Difficulty], scenario)
end

assert(#ScenarioLibrary == 100, string.format("Expected 100 CalmWorks scenarios, found %d", #ScenarioLibrary))
for difficulty = 1, 5 do
    assert(
        #scenariosByDifficulty[difficulty] == 20,
        string.format("Difficulty %d should contain 20 scenarios", difficulty)
    )
end

local function wasRecentlyUsed(id, recentIds)
    for _, recentId in ipairs(recentIds) do
        if recentId == id then
            return true
        end
    end
    return false
end

function DialogueGenerator.CleanRecentIds(raw)
    local result = {}
    if type(raw) == "table" then
        for i = math.max(1, #raw - RECENT_WINDOW + 1), #raw do
            if type(raw[i]) == "string" and scenariosById[raw[i]] then
                table.insert(result, raw[i])
            end
        end
    end
    return result
end

local function chooseDifficulty(stars)
    stars = math.clamp(math.floor(tonumber(stars) or 0), 0, Config.MaxStars)
    local weights = Config.DifficultyWeightsByStars[stars]
    assert(weights and #weights >= 1, string.format("Missing difficulty weights for %d stars", stars))
    local total = 0
    for _, weight in ipairs(weights) do
        total += math.max(0, weight)
    end
    assert(total > 0, string.format("Difficulty weights for %d stars must total above zero", stars))
    local roll = rng:NextNumber(0, total)
    local running = 0
    for difficulty, weight in ipairs(weights) do
        running += math.max(0, weight)
        if roll <= running then
            return difficulty
        end
    end
    return #weights
end

local function chooseScenario(
    difficulty,
    profile,
    recentIds,
    answerHistory,
    frqOnly,
    customerProfile,
    forcedCodes,
    reservedIds
)
    local pool = scenariosByDifficulty[difficulty]
    if customerProfile.SpecialType == "Angry" then
        local compatible = {}
        for _, scenario in ipairs(pool) do
            if table.find(CustomerBehavior.Tags(scenario).Moods, "Angry") then
                table.insert(compatible, scenario)
            end
        end
        if #compatible == 0 then
            return nil
        end
        pool = compatible
    end
    if forcedCodes then
        local targeted = {}
        for _, s in ipairs(pool) do
            if forcedCodes[s.CategoryCode] then
                table.insert(targeted, s)
            end
        end
        if #targeted == 0 then
            return nil
        end
        pool = targeted
    end
    if frqOnly then
        local safePool = {}
        for _, scenario in ipairs(pool) do
            -- Authored FRQs are curated for their specific scenarios. The generic FRQ
            -- remains limited to lower-level, lower-severity cases.
            if
                scenario.FRQ
                or (
                    difficulty <= 2
                    and not scenario.ContentFlag
                    and scenario.Severity <= Config.FRQMaximumScenarioSeverity
                )
            then
                table.insert(safePool, scenario)
            end
        end
        if #safePool == 0 then
            return nil
        end
        pool = safePool
    end
    local unreserved = {}
    for _, scenario in ipairs(pool) do
        if not reservedIds or not reservedIds[scenario.Id] then
            table.insert(unreserved, scenario)
        end
    end
    if #unreserved > 0 then
        pool = unreserved
    end
    local available = {}
    for _, scenario in ipairs(pool) do
        if not wasRecentlyUsed(scenario.Id, recentIds) then
            table.insert(available, scenario)
        end
    end
    if #available == 0 then
        -- Tiny practice pools rotate oldest-first instead of resetting all recency.
        local oldest = math.huge
        for _, scenario in ipairs(pool) do
            local lastUsed = 0
            for i, id in ipairs(recentIds) do
                if id == scenario.Id then
                    lastUsed = i
                end
            end
            if lastUsed < oldest then
                oldest = lastUsed
                available = { scenario }
            elseif lastUsed == oldest then
                table.insert(available, scenario)
            end
        end
    end

    local groups = {}
    for _, scenario in ipairs(available) do
        local code = scenario.CategoryCode
        groups[code] = groups[code] or {}
        table.insert(groups[code], scenario)
    end
    local categoryCodes = {}
    for _, category in ipairs(categoryDefinitions) do
        if groups[category.Code] then
            table.insert(categoryCodes, category.Code)
        end
    end
    assert(#categoryCodes > 0, "No available CalmWorks scenario categories")
    -- Keep multiple practice targets represented without changing their difficulty gates.
    if forcedCodes and #categoryCodes > 1 then
        local streak, lastCode = 0, nil
        for i = #recentIds, 1, -1 do
            local code
            for _, s in ipairs(ScenarioLibrary) do
                if s.Id == recentIds[i] then
                    code = s.CategoryCode
                    break
                end
            end
            if not code or (lastCode and code ~= lastCode) then
                break
            end
            lastCode = code
            streak += 1
        end
        if streak >= (Config.PracticeMaximumCategoryStreak or 2) then
            local index = table.find(categoryCodes, lastCode)
            if index then
                table.remove(categoryCodes, index)
            end
        end
    end

    local chosenCode
    if rng:NextNumber() < Config.AdaptiveExplorationChance then
        chosenCode = categoryCodes[rng:NextInteger(1, #categoryCodes)]
    else
        local weights = AdaptiveSkills.CategoryWeights(
            profile,
            categoryDefinitions,
            Config,
            answerHistory,
            frqOnly and "FRQ" or "MCQ"
        )
        local totalWeight = 0
        for _, code in ipairs(categoryCodes) do
            totalWeight += weights[code]
        end
        local roll = rng:NextNumber(0, totalWeight)
        local running = 0
        for _, code in ipairs(categoryCodes) do
            running += weights[code]
            if roll <= running then
                chosenCode = code
                break
            end
        end
        chosenCode = chosenCode or categoryCodes[#categoryCodes]
    end

    local categoryPool = groups[chosenCode]
    local scenario = CustomerBehavior.ChoosePreset(categoryPool, customerProfile, rng)
    table.insert(recentIds, scenario.Id)
    if #recentIds > RECENT_WINDOW then
        table.remove(recentIds, 1)
    end
    return scenario
end

local function shuffleStage(stage)
    local options = {}
    for index, choice in ipairs(stage.Choices) do
        table.insert(options, {
            Text = choice,
            Feedback = stage.ChoiceFeedback[index],
            Outcome = stage.ChoiceOutcomes[index],
            ResultScore = stage.ChoiceResultScores[index],
            Key = stage.ChoiceKeys[index],
            IsBest = index == stage.BestIndex,
        })
    end
    for index = #options, 2, -1 do
        local swapIndex = rng:NextInteger(1, index)
        options[index], options[swapIndex] = options[swapIndex], options[index]
    end
    local shuffled = {
        StageNumber = stage.StageNumber,
        Prompt = stage.Prompt,
        Choices = {},
        ChoiceFeedback = {},
        ChoiceOutcomes = {},
        ChoiceResultScores = {},
        ChoiceKeys = {},
    }
    for index, option in ipairs(options) do
        shuffled.Choices[index] = option.Text
        shuffled.ChoiceFeedback[index] = option.Feedback
        shuffled.ChoiceOutcomes[index] = option.Outcome
        shuffled.ChoiceResultScores[index] = option.ResultScore
        shuffled.ChoiceKeys[index] = option.Key
        if option.IsBest then
            shuffled.BestIndex = index
            shuffled.BestKey = option.Key
        end
    end
    return shuffled
end

local function buildScenario(source, useFRQ)
    local generated = {
        Id = source.Id,
        TemplateId = source.Id,
        SourceKind = "Library",
        Title = source.Title,
        CategoryCode = source.CategoryCode,
        Category = source.Category,
        Difficulty = source.Difficulty,
        EloSeed = source.EloSeed,
        Severity = source.Severity,
        Skills = table.clone(source.Skills),
        Skill = source.Skill,
        Feedback = source.Feedback,
        ContentFlag = source.ContentFlag,
        FRQ = source.FRQ,
        SourceVersion = ScenarioLibrary.SourceVersion,
        Mode = useFRQ and "FRQ" or "MCQ",
        Stages = {},
    }
    for _, stage in ipairs(source.Stages) do
        table.insert(generated.Stages, shuffleStage(stage))
    end
    return generated
end

function DialogueGenerator.Generate(
    stars,
    categoryAccuracy,
    recentIds,
    answerHistory,
    forcedCodes,
    recentProfiles,
    reservedIds,
    specialType
)
    recentIds = type(recentIds) == "table" and recentIds or fallbackRecentIds
    recentProfiles = recentProfiles or profileHistories[recentIds] or {}
    profileHistories[recentIds] = recentProfiles
    local difficulty = chooseDifficulty(stars)
    local customerProfile = CustomerBehavior.Roll(difficulty, rng, specialType)
    local useFRQ = rng:NextNumber() < (Config.FRQChanceByDifficulty[difficulty] or 0)
    local source = chooseScenario(
        difficulty,
        categoryAccuracy,
        recentIds,
        answerHistory,
        useFRQ,
        customerProfile,
        forcedCodes,
        reservedIds
    )
    if not source then
        useFRQ = false
        source = chooseScenario(
            difficulty,
            categoryAccuracy,
            recentIds,
            answerHistory,
            false,
            customerProfile,
            forcedCodes,
            reservedIds
        )
    end
    if not source and specialType == "Angry" and forcedCodes then
        -- A safety-compatible angry case takes priority if a practice category has none.
        forcedCodes = nil
        source = chooseScenario(
            difficulty,
            categoryAccuracy,
            recentIds,
            answerHistory,
            false,
            customerProfile,
            nil,
            reservedIds
        )
    end
    assert(source, "No eligible scenario for the selected practice categories")
    local generated = buildScenario(source, useFRQ)
    if forcedCodes then
        local context =
            AdaptiveSkills.GenerationContext(answerHistory, generated, categoryDefinitions, Config)
        generated.TargetSkill = context.TargetSkill
        generated.PracticeTarget = true
        customerProfile = PracticePolicy.Profile(context.TargetSkill, customerProfile)
    end
    customerProfile.SpecialType = specialType
    if specialType == "Angry" then
        customerProfile.Mood = "Angry"
    end
    customerProfile = CustomerBehavior.Finalize(customerProfile, source, rng, recentProfiles)
    table.insert(recentProfiles, customerProfile.Mood .. "|" .. customerProfile.Personality)
    while #recentProfiles > math.clamp(Config.CustomerRecentProfileWindow or 6, 1, 30) do
        table.remove(recentProfiles, 1)
    end
    return CustomerBehavior.ApplyPresentation(generated, customerProfile, Config)
end

function DialogueGenerator.GenerateWorkplace(
    role,
    stars,
    categoryAccuracy,
    recentCases,
    answerHistory,
    area,
    recentProfiles
)
    local difficulty = math.min(chooseDifficulty(stars), 3)
    local pool = {}
    local oldest = math.huge
    -- Rotate eligible cases without erasing the player's ordinary scenario history.
    for _, source in ipairs(WorkplaceLibrary) do
        if source.WorkplaceRole == role and source.Difficulty == difficulty then
            local lastUsed = 0
            for i, id in ipairs(recentCases) do
                if id == source.Id then
                    lastUsed = i
                end
            end
            if lastUsed < oldest then
                pool = { source }
                oldest = lastUsed
            elseif lastUsed == oldest then
                table.insert(pool, source)
            end
        end
    end
    assert(#pool > 0, "Missing workplace scenarios for " .. role)
    local useFRQ = rng:NextNumber() < (Config.FRQChanceByDifficulty[difficulty] or 0)
    local weights = AdaptiveSkills.CategoryWeights(
        categoryAccuracy,
        categoryDefinitions,
        Config,
        answerHistory,
        useFRQ and "FRQ" or "MCQ"
    )
    local total = 0
    for _, source in ipairs(pool) do
        total += weights[source.CategoryCode] or 1
    end
    local roll = rng:NextNumber(0, total)
    local source = pool[#pool]
    for _, candidate in ipairs(pool) do
        roll -= weights[candidate.CategoryCode] or 1
        if roll <= 0 then
            source = candidate
            break
        end
    end
    table.insert(recentCases, source.Id)
    while #recentCases > 8 do
        table.remove(recentCases, 1)
    end
    local generated = buildScenario(source, useFRQ)
    generated.SourceVersion = "WorkplaceV1"
    generated.WorkplaceContext = {
        Business = "CalmWorks",
        VisitorRole = role,
        Station = area,
        PlayerRole = "Business owner",
        Domain = "Fictional workplace and customer-service concerns",
    }
    local profile = CustomerBehavior.Roll(difficulty, rng)
    profile = CustomerBehavior.Finalize(profile, source, rng, recentProfiles or {})
    if recentProfiles then
        table.insert(recentProfiles, profile.Mood .. "|" .. profile.Personality)
        while #recentProfiles > 6 do
            table.remove(recentProfiles, 1)
        end
    end
    return CustomerBehavior.ApplyPresentation(generated, profile, Config)
end

return DialogueGenerator