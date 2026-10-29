-- Server-owned traits and editable R6 template selection. No client can choose an answer key or severity.
local ServerStorage = game:GetService("ServerStorage")
local Definitions = require(script.Parent.CustomerBehaviorDefinitions)
local Catalog = require(script.Parent.ScenarioCustomerProfiles)
local Text = require(game.ReplicatedStorage.CalmWorksShared:WaitForChild("ScenarioText"))
local Behavior = {}
local warned = {}
local moodNeighbors = {
    Calm = { "Confused", "Annoyed" },
    Annoyed = { "Frustrated", "Angry" },
    Frustrated = { "Annoyed", "Angry" },
    Angry = { "Frustrated", "Defensive" },
    Anxious = { "Panicked", "Confused" },
    Panicked = { "Anxious" },
    Hurt = { "Embarrassed", "Anxious" },
    Embarrassed = { "Hurt", "Ashamed" },
    Ashamed = { "Embarrassed" },
    Confused = { "Anxious", "Suspicious" },
    Suspicious = { "Confused", "Defensive" },
    Defensive = { "Frustrated", "Suspicious" },
}

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for k, v in pairs(value) do
        result[k] = copy(v)
    end
    return result
end

local function contains(list, key)
    return table.find(list or {}, key) ~= nil
end

local function allowed(definition, level, key, source, specialType)
    if not definition or definition.Enabled == false or (definition.Weight or 1) <= 0 then
        return false
    end
    if key == "Panicked" and (not source or source.Severity < 3) then
        return false
    end
    if key == "Angry" then
        return specialType == "Angry"
    end
    return level >= (definition.MinLevel or 1)
end

local function pick(keys, definitions, level, rng, source, fallback, specialType)
    local options, total = {}, 0
    for _, key in ipairs(keys) do
        local item = definitions[key]
        if allowed(item, level, key, source, specialType) then
            -- More demanding presentation becomes somewhat more common at higher levels.
            local weight = (item.Weight or 1)
                * math.max(0.4, 1 + 0.10 * (level - 3) * ((item.Challenge or 2) - 2))
            total += weight
            table.insert(options, { Key = key, Weight = weight })
        end
    end
    if #options == 0 then
        return fallback
    end
    local roll = rng:NextNumber() * total
    for _, item in ipairs(options) do
        roll -= item.Weight
        if roll <= 0 then
            return item.Key
        end
    end
    return options[#options].Key
end

function Behavior.Roll(level, rng, specialType)
    return {
        SpecialType = specialType,
        Mood = specialType == "Angry" and "Angry"
            or pick(Definitions.MoodOrder, Definitions.Moods, level, rng, nil, "Calm"),
        Personality = pick(
            Definitions.PersonalityOrder,
            Definitions.Personalities,
            level,
            rng,
            nil,
            "Direct"
        ),
        CommunicationStyle = pick(Definitions.StyleOrder, Definitions.Styles, level, rng, nil, "Brief"),
    }
end

function Behavior.Tags(source)
    return source.CustomerTags
        or Catalog[source.TemplateId or source.Id]
        or {
            Moods = { "Calm", "Confused" },
            Personalities = { "Direct", "Analytical" },
            Styles = { "Brief", "Logical" },
        }
end

function Behavior.MatchScore(source, profile)
    local tags = Behavior.Tags(source)
    local score = 0
    if contains(tags.Moods, profile.Mood) then
        score += 6
    else
        for _, neighbor in ipairs(moodNeighbors[profile.Mood] or {}) do
            if contains(tags.Moods, neighbor) then
                score += 2
                break
            end
        end
    end
    if contains(tags.Personalities, profile.Personality) then
        score += 3
    end
    if contains(tags.Styles, profile.CommunicationStyle) then
        score += 1
    end
    return score
end

function Behavior.ChoosePreset(pool, profile, rng)
    assert(#pool > 0, "No eligible customer presets")
    local best, score = {}, -math.huge
    for _, source in ipairs(pool) do
        local candidateScore = Behavior.MatchScore(source, profile)
        if candidateScore > score then
            score = candidateScore
            best = { source }
        elseif candidateScore == score then
            table.insert(best, source)
        end
    end
    return best[rng:NextInteger(1, #best)], score
end

function Behavior.Finalize(profile, source, rng, recentProfiles)
    profile = copy(profile)
    local tags = Behavior.Tags(source)
    local level = source.Difficulty
    for _, entry in ipairs({
        { "Mood", tags.Moods, Definitions.Moods, "Calm" },
        { "Personality", tags.Personalities, Definitions.Personalities, "Direct" },
        { "CommunicationStyle", tags.Styles, Definitions.Styles, "Brief" },
    }) do
        local key, list, definitions, fallback = table.unpack(entry)
        if
            not contains(list, profile[key])
            or not allowed(definitions[profile[key]], level, profile[key], source, profile.SpecialType)
        then
            profile[key] = pick(list, definitions, level, rng, source, fallback, profile.SpecialType)
        end
    end
    local lockedMood = profile.SpecialType == "Angry" and "Angry" or nil
    if lockedMood then
        assert(contains(tags.Moods, lockedMood), "Angry customers need a compatible reviewed scenario")
        profile.Mood = lockedMood
    end
    -- Prefer a less recent pair, but only from the scenario's reviewed traits.
    if type(recentProfiles) == "table" and #recentProfiles > 0 then
        local function lastUsed(mood, personality)
            local last = 0
            local key = mood .. "|" .. personality
            for i, previous in ipairs(recentProfiles) do
                if previous == key then
                    last = i
                end
            end
            return last
        end
        local oldest = lastUsed(profile.Mood, profile.Personality)
        local choices = { { Mood = profile.Mood, Personality = profile.Personality } }
        if oldest > 0 then
            for _, mood in ipairs(tags.Moods) do
                for _, personality in ipairs(tags.Personalities) do
                    if
                        (not lockedMood or mood == lockedMood)
                        and allowed(Definitions.Moods[mood], level, mood, source, profile.SpecialType)
                        and allowed(Definitions.Personalities[personality], level, personality, source)
                    then
                        local age = lastUsed(mood, personality)
                        if age < oldest then
                            oldest = age
                            choices = { { Mood = mood, Personality = personality } }
                        elseif age == oldest then
                            table.insert(choices, { Mood = mood, Personality = personality })
                        end
                    end
                end
            end
            local selected = choices[rng:NextInteger(1, #choices)]
            profile.Mood = selected.Mood
            profile.Personality = selected.Personality
        end
    end
    if
        profile.CommunicationStyle == "Confrontational"
        and not contains({ "Angry", "Defensive", "Frustrated" }, profile.Mood)
    then
        profile.CommunicationStyle = "Brief"
    end
    profile.InitialMood = profile.Mood
    profile.CurrentMood = profile.Mood
    profile.MatchedTemplateId = source.TemplateId or source.Id
    return profile
end

function Behavior.CleanRecentProfiles(raw, maximum)
    local result = {}
    if type(raw) == "table" then
        for i = math.max(1, #raw - maximum + 1), #raw do
            if type(raw[i]) == "string" then
                local mood, personality = raw[i]:match("^(%a+)|(%a+)$")
                if Definitions.Moods[mood] and Definitions.Personalities[personality] then
                    table.insert(result, raw[i])
                end
            end
        end
    end
    return result
end

function Behavior.Context(profile)
    if type(profile) ~= "table" then
        return nil
    end
    local mood = Definitions.Moods[profile.Mood] or Definitions.Moods.Calm
    local personality = Definitions.Personalities[profile.Personality] or Definitions.Personalities.Direct
    local style = Definitions.Styles[profile.CommunicationStyle] or Definitions.Styles.Brief
    return {
        Mood = mood.Label,
        Personality = personality.Label,
        CommunicationStyle = style.Label,
        MoodGuidance = mood.Guide,
        PersonalityGuidance = personality.Guide,
        StyleGuidance = style.Guide,
        Constraint = "Presentation only: preserve facts, responsibility, safety severity, answer roles, and assigned difficulty. Mood never determines actual danger.",
    }
end

function Behavior.ApplyPresentation(scenario, profile, config)
    scenario.CustomerProfile = copy(profile)
    local mood = Definitions.Moods[profile.Mood] or Definitions.Moods.Calm
    local personality = Definitions.Personalities[profile.Personality] or Definitions.Personalities.Direct
    local style = Definitions.Styles[profile.CommunicationStyle] or Definitions.Styles.Brief
    for index, stage in ipairs(scenario.Stages) do
        stage.BasePrompt = stage.BasePrompt or stage.Prompt
        local cues = index == 1 and { mood.Cue, personality.Cue } or { mood.Cue }
        if profile.CommunicationStyle ~= "Brief" and style.Cue ~= "" then
            table.insert(cues, 1, style.Cue)
        end
        local background = Text.OneParagraph(stage.BasePrompt)
        local insight = Text.OneParagraph(table.concat(cues, " "))
        local maximum = config.CustomerPromptMaxCharacters or 420
        while #cues > 0 and (utf8.len(Text.Compose(background, insight)) or math.huge) > maximum do
            table.remove(cues, 1)
            insight = Text.OneParagraph(table.concat(cues, " "))
        end
        -- Facts first, then perspective, without inserted line breaks.
        -- BasePrompt retains untouched pack text for repeat-safe presentation.
        stage.Background, stage.CustomerInsight = background, insight
        stage.Prompt = Text.Compose(background, insight)
    end
    return scenario
end

function Behavior.Title(profile, mode)
    local mood = Definitions.Moods[profile.CurrentMood or profile.Mood] or Definitions.Moods.Calm
    local personality = Definitions.Personalities[profile.Personality] or Definitions.Personalities.Direct
    if mode == "Both" then
        return mood.Label .. " • " .. personality.Label
    end
    if mode == "Mood" then
        return mood.Label
    end
    if mode == "Personality" then
        return personality.Label
    end
    return (mood.Prominence or 1) >= (personality.Prominence or 1) and mood.Label or personality.Label
end

function Behavior.UpdateModel(model, profile)
    model:SetAttribute("Mood", profile.CurrentMood or profile.Mood)
    model:SetAttribute("InitialMood", profile.InitialMood or profile.Mood)
    model:SetAttribute("Personality", profile.Personality)
    model:SetAttribute("CommunicationStyle", profile.CommunicationStyle)
    local title = Behavior.Title(profile, model:GetAttribute("OverheadTitleMode") or "Auto")
    if model:GetAttribute("CustomerValue") == "Angry" then
        title = model:GetAttribute("PermanentOverheadText") or "Angry"
    end
    model:SetAttribute("DominantTrait", title)
    local head = model:FindFirstChild("Head")
    local gui = head and head:FindFirstChild("CustomerNameGui")
    local label = gui and gui:FindFirstChild("BehaviorLabel")
    if label and label:IsA("TextLabel") then
        label.Text = title
        if model:GetAttribute("CustomerValue") == "Angry" then
            label.TextColor3 = model:GetAttribute("PermanentOverheadColor") or Color3.fromRGB(255, 65, 65)
        end
    end
end

function Behavior.React(model, profile, outcome, sensitive)
    local mood = Definitions.Moods[profile.CurrentMood or profile.Mood] or Definitions.Moods.Calm
    -- Sensitive cases are not made more dangerous or 'solved' by changing an emotion label.
    if not sensitive then
        local nextMood = outcome == "Optimal" and mood.Helpful or (outcome == "Risky" and mood.Risky or nil)
        if nextMood == "Angry" and profile.SpecialType ~= "Angry" then
            nextMood = "Frustrated"
        end
        if nextMood and Definitions.Moods[nextMood] then
            profile.CurrentMood = nextMood
        end
    end
    if model then
        Behavior.UpdateModel(model, profile)
    end
    local reactions = Definitions.Reactions or {}
    return reactions[outcome]
        or (
            outcome == "Optimal" and "That gives me a clearer next step."
            or outcome == "Risky" and "I am concerned that could make the situation worse."
            or "I am not sure that addresses the main problem yet."
        )
end

function Behavior.ValidTemplate(model)
    if not model or not model:IsA("Model") then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        return false
    end
    for _, name in ipairs({
        "HumanoidRootPart",
        "Head",
        "Torso",
        "Left Arm",
        "Right Arm",
        "Left Leg",
        "Right Leg",
    }) do
        local part = model:FindFirstChild(name)
        if not part or not part:IsA("BasePart") then
            return false
        end
    end
    local connectedJoints = 0
    for _, joint in ipairs(model:GetDescendants()) do
        if
            joint:IsA("Motor6D")
            and joint.Part0
            and joint.Part1
            and joint.Part0:IsDescendantOf(model)
            and joint.Part1:IsDescendantOf(model)
        then
            connectedJoints += 1
        end
    end
    if connectedJoints < 6 then
        return false
    end
    local gui = model.Head:FindFirstChild("CustomerNameGui")
    local name = gui and gui:FindFirstChild("NameLabel")
    local behavior = gui and gui:FindFirstChild("BehaviorLabel")
    local prompt = model.HumanoidRootPart:FindFirstChild("HelpPrompt")
    return gui
            and gui:IsA("BillboardGui")
            and name
            and name:IsA("TextLabel")
            and behavior
            and behavior:IsA("TextLabel")
            and prompt
            and prompt:IsA("ProximityPrompt")
            and true
        or false
end

function Behavior.GetTemplate(profile, appearance)
    if profile.SpecialType == "Angry" then
        return ServerStorage:WaitForChild("CalmWorksAngryNoobTemplate")
    end
    local folder = ServerStorage:FindFirstChild("CalmWorksCustomerTemplates")
    local mood = folder and folder:FindFirstChild(profile.Mood)
    local selected = mood and mood:FindFirstChild(appearance)
    if Behavior.ValidTemplate(selected) then
        return selected
    end
    local key = profile.Mood .. "/" .. appearance
    if not warned[key] then
        warned[key] = true
        warn(
            "CalmWorks customer template missing/invalid: " .. key .. "; using the original editable R6 noob."
        )
    end
    return ServerStorage:WaitForChild("CalmWorksNoobTemplate")
end

return Behavior