local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Entrance = require(game:GetService("ReplicatedStorage").CalmWorksShared.UIEntrance)
local Responsive = require(ReplicatedStorage.CalmWorksShared.ResponsiveUI)
local ActionFeedback =
    require(ReplicatedStorage:WaitForChild("CalmWorksShared"):WaitForChild("ActionFeedback"))
local Config = require(ReplicatedStorage.CalmWorksShared.Config)
local ScenarioText = require(ReplicatedStorage.CalmWorksShared:WaitForChild("ScenarioText"))

local player = Players.LocalPlayer
local gui = script.Parent:IsA("ScreenGui") and script.Parent or player.PlayerGui:WaitForChild("CalmWorksUI")
local effectsGui = player.PlayerGui:WaitForChild("CalmWorksFullScreenEffects")
local remotes = ReplicatedStorage:WaitForChild("CalmWorksRemotes")
local openDialogue = remotes:WaitForChild("OpenDialogue")
local submitAnswer = remotes:WaitForChild("SubmitAnswer")
local completeTutorial = remotes:WaitForChild("CompleteTutorial")
local businessManTemplate = ReplicatedStorage:WaitForChild("CalmWorksBusinessManTemplate")
local guidanceTemplate = ReplicatedStorage:WaitForChild("CalmWorksGuidanceTemplate")

local hud = gui:WaitForChild("HUD")
local ratingLabel = hud:WaitForChild("RatingLabel")
local dialogue = gui:WaitForChild("Dialogue")
local accuracyButton = gui:WaitForChild("AccuracyButton")
local supportGui = player.PlayerGui:WaitForChild("CalmWorksSupportUI")
local supportButton = supportGui:WaitForChild("OpenSupportButton")
local supportPanel = supportGui:WaitForChild("SupportPanel")
local correctSound = gui:WaitForChild("correct")
local nameLabel = dialogue:WaitForChild("NameLabel")
local categoryLabel = dialogue:WaitForChild("CategoryLabel")
local difficultyLabel = dialogue:WaitForChild("DifficultyLabel")
local dashboardClose = dialogue:WaitForChild("DashboardCloseButton")
local closeDashboard = remotes:WaitForChild("CloseDashboard")
local continueDashboard = remotes:WaitForChild("ContinueDashboard")
local promptLabel = dialogue:WaitForChild("PromptLabel")
local choicesFrame = dialogue:WaitForChild("ChoicesFrame")
local frqFrame = dialogue:WaitForChild("FRQFrame")
local frqContent = frqFrame:WaitForChild("EntryScroll"):WaitForChild("Content")
local taskPrompt = frqContent:WaitForChild("TaskPrompt")
local frqHelpButton = frqContent:WaitForChild("HelpButton")
local openFRQHelp = supportGui:WaitForChild("OpenFRQHelp")
local frqContextChanged = supportGui:WaitForChild("FRQContextChanged")
local getFRQDraft = supportGui:WaitForChild("GetFRQDraft")
local responseBox = frqContent:WaitForChild("ResponseBox")
local characterCount = frqFrame:WaitForChild("CharacterCount")
local aiDisclosure = dialogue:WaitForChild("AIDisclosure")
local scenarioLoading = dialogue:WaitForChild("ScenarioLoadingFrame")
-- AIDisclosure.Text is the editable default. Optional variants are opt-in.
local statusLabel = dialogue:WaitForChild("StatusLabel")
local submitButton = dialogue:WaitForChild("SubmitButton")
local overlay = effectsGui:WaitForChild("FeedbackOverlay")
local hintCard = overlay:WaitForChild("HintCard")
local hintText = hintCard:WaitForChild("HintText")
local retryButton = hintCard:WaitForChild("RetryButton")
local frqFeedbackOverlay = effectsGui:WaitForChild("FRQFeedbackOverlay")
local frqFeedbackCard = frqFeedbackOverlay:WaitForChild("FeedbackCard")
local frqScoreBar = frqFeedbackCard:WaitForChild("ScoreBar")
local frqAnalysisScroll = frqFeedbackCard:WaitForChild("AnalysisScroll")
local frqAdditionalScores = frqAnalysisScroll:WaitForChild("AdditionalScoresText")
local frqScrollHint = frqFeedbackCard:WaitForChild("ScrollHint")
local frqOutcome = frqFeedbackCard:WaitForChild("OutcomeLabel")
local frqContinue = frqFeedbackCard:WaitForChild("ContinueButton")
local frqDashboardClose = frqFeedbackCard:WaitForChild("DashboardCloseButton")
local frqContinuePosition = frqContinue.Position
local frqContinueSize = frqContinue.Size
local tutorialOverlay = effectsGui:WaitForChild("TutorialOverlay")
local tutorialCard = tutorialOverlay:WaitForChild("TutorialCard")
local tutorialDialogueText = tutorialCard:WaitForChild("DialogueText")
local tutorialNextButton = tutorialCard:WaitForChild("NextButton")
local choiceButtons, choiceStrokes, choiceDefaults = {}, {}, {}
for index = 1, 3 do
    local button = choicesFrame:FindFirstChild("Choice" .. index, true)
    assert(button and button:IsA("GuiButton"), "Missing editable Choice" .. index .. " button")
    choiceButtons[index] = button
    choiceStrokes[index] = button:WaitForChild("ChoiceStroke")
    local stroke = choiceStrokes[index]
    choiceDefaults[index] =
        { Color = stroke.Color, Thickness = stroke.Thickness, Transparency = stroke.Transparency }
end

local COLORS = {
    Accent = gui:GetAttribute("AccentColor") or Color3.fromRGB(65, 126, 235),
    Green = gui:GetAttribute("GreenColor") or Color3.fromRGB(44, 174, 112),
    Red = gui:GetAttribute("RedColor") or Color3.fromRGB(220, 72, 72),
    Muted = gui:GetAttribute("MutedColor") or Color3.fromRGB(104, 113, 130),
    Neutral = gui:GetAttribute("NeutralColor") or Color3.fromRGB(202, 208, 218),
}
local selectedIndex
local currentMode = "MCQ"
local frqMaxCharacters = 500
local pendingFRQNextStage
local pendingFRQComplete = false
local hideDashboard
local busy = false
local currentScenarioToken
local dashboardComplete = false
local currentFRQContext
local continuationId = 0
local continueConsultation
local dismissCompletedFeedback
getFRQDraft.OnInvoke = function(id)
    if
        currentFRQContext
        and currentFRQContext.Id == id
        and dialogue.Visible
        and currentMode == "FRQ"
        and not busy
    then
        return responseBox.Text
    end
    return nil
end
frqHelpButton.Activated:Connect(function()
    if not currentFRQContext or busy then
        ActionFeedback.Error()
        return
    end
    responseBox:ReleaseFocus()
    openFRQHelp:Fire(currentFRQContext)
    ActionFeedback.AcceptedClick()
end)
dialogue:GetPropertyChangedSignal("Visible"):Connect(function()
    if not dialogue.Visible then
        continuationId += 1
        dismissCompletedFeedback = nil
        currentFRQContext = nil
        frqContextChanged:Fire(nil)
    end
end)

local headerDefaults = {}
for _, item in ipairs({nameLabel, categoryLabel, difficultyLabel}) do
    local constraint = item:FindFirstChildOfClass("UIAspectRatioConstraint")
    headerDefaults[item] = {
        Position = item.Position, Size = item.Size,
        Constraint = constraint, AspectRatio = constraint and constraint.AspectRatio,
    }
end
local function setConsultationHeader(enabled)
    for item, original in pairs(headerDefaults) do
        for _, property in ipairs({"Position", "Size"}) do
            local value = enabled and item:GetAttribute("Online" .. property)
            item[property] = typeof(value) == "UDim2" and value or original[property]
        end
        if original.Constraint then
            local ratio = enabled and item:GetAttribute("OnlineAspectRatio")
            if type(ratio) ~= "number" or ratio <= 0 or ratio >= math.huge then
                ratio = original.AspectRatio
            end
            original.Constraint.AspectRatio = ratio
        end
    end
end

local function applyDialogueLayout()
    Responsive.Dialogue(dialogue)
end
task.defer(applyDialogueLayout)

local TUTORIAL_MESSAGES = UI.Sequence("Tutorial")
local tutorialIndex = 0
local tutorialActive = false
local activeBusinessMan
local guidanceBeam
local guidanceArrow
local guidanceOrigin
local clearGuidance

dialogue.Visible = false
Entrance.Bind(dialogue, false)
scenarioLoading.Visible = false
overlay.Visible = false
frqFeedbackOverlay.Visible = false
tutorialOverlay.Visible = false

local function updateFRQScrollHint()
    frqScrollHint.Visible = frqFeedbackOverlay.Visible
        and frqAnalysisScroll.AbsoluteCanvasSize.Y > frqAnalysisScroll.AbsoluteWindowSize.Y + 4
end
frqAnalysisScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateFRQScrollHint)
frqAnalysisScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateFRQScrollHint)
frqFeedbackOverlay:GetPropertyChangedSignal("Visible"):Connect(updateFRQScrollHint)

local accuracyButtonDefaultVisible = accuracyButton.Visible
local function syncDialogueButtons()
    if dialogue.Visible then
        accuracyButton.Visible = false
        supportButton.Visible = false
    else
        accuracyButton.Visible = accuracyButtonDefaultVisible
        if not supportPanel.Visible then
            supportButton.Visible = true
        end
    end
end
dialogue:GetPropertyChangedSignal("Visible"):Connect(syncDialogueButtons)
supportButton:GetPropertyChangedSignal("Visible"):Connect(function()
    if dialogue.Visible and supportButton.Visible then
        supportButton.Visible = false
    end
end)
accuracyButton:GetPropertyChangedSignal("Visible"):Connect(function()
    if dialogue.Visible and accuracyButton.Visible then
        accuracyButton.Visible = false
    end
end)
syncDialogueButtons()

local function clearBusinessMan()
    if activeBusinessMan then
        activeBusinessMan:Destroy()
        activeBusinessMan = nil
    end
end

local function closeTutorial(markComplete)
    tutorialActive = false
    tutorialOverlay.Visible = false
    clearBusinessMan()
    if markComplete then
        completeTutorial:FireServer()
    end
end

local function beginTutorial()
    if
        tutorialActive
        or player:GetAttribute("TutorialCompleted")
        or player:GetAttribute("OwnsBusiness")
        or not activeBusinessMan
    then
        return
    end
    tutorialActive = true
    activeBusinessMan:SetAttribute("ConversationOwnerId", player.UserId)
    tutorialIndex = 1
    tutorialDialogueText.Text = TUTORIAL_MESSAGES[tutorialIndex]
    -- Preserve the editable NextButton.Text.
    local prompt = activeBusinessMan:FindFirstChild("TalkPrompt", true)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Enabled = false
    end
    if clearGuidance then
        clearGuidance()
    end
    tutorialOverlay.Visible = true
end

local function showTutorialIfNeeded()
    if
        tutorialActive
        or activeBusinessMan
        or not player:GetAttribute("DataLoaded")
        or player:GetAttribute("TutorialCompleted")
        or player:GetAttribute("OwnsBusiness")
    then
        return
    end
    tutorialOverlay.Visible = false
    activeBusinessMan = businessManTemplate:Clone()
    activeBusinessMan.Name = "BusinessMan"
    activeBusinessMan.Parent = workspace
    local prompt = activeBusinessMan:FindFirstChild("TalkPrompt", true)
    assert(prompt and prompt:IsA("ProximityPrompt"), "CalmWorksBusinessManTemplate needs TalkPrompt")
    prompt.Enabled = true
    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer and triggeringPlayer ~= player then
            return
        end
        beginTutorial()
    end)
end

tutorialNextButton.Activated:Connect(function()
    if not tutorialActive then
        return
    end
    if tutorialIndex < #TUTORIAL_MESSAGES then
        tutorialIndex += 1
        tutorialDialogueText.Text = TUTORIAL_MESSAGES[tutorialIndex]
    else
        closeTutorial(true)
    end
end)

clearGuidance = function()
    if guidanceBeam then
        guidanceBeam:Destroy()
        guidanceBeam = nil
    end
    if guidanceArrow then
        guidanceArrow:Destroy()
        guidanceArrow = nil
    end
    if guidanceOrigin then
        guidanceOrigin:Destroy()
        guidanceOrigin = nil
    end
end

local function refreshGuidance(character)
    clearGuidance()
    if not player:GetAttribute("DataLoaded") or player:GetAttribute("OwnsBusiness") then
        return
    end
    character = character or player.Character
    if not character then
        return
    end
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not root or player:GetAttribute("OwnsBusiness") then
        return
    end

    local tutorialCompleted = player:GetAttribute("TutorialCompleted") == true
    local target
    if tutorialCompleted then
        target = workspace.CalmWorksTycoon.ClaimPad:FindFirstChild("ClaimGuideTarget", true)
    else
        target = activeBusinessMan and activeBusinessMan:FindFirstChild("BusinessManGuideTarget", true)
    end
    if not target or not target:IsA("Attachment") then
        return
    end

    guidanceOrigin = guidanceTemplate:WaitForChild("PlayerOrigin"):Clone()
    guidanceOrigin.Name = "CalmWorksGuideOrigin"
    guidanceOrigin.Parent = root

    guidanceBeam = guidanceTemplate:WaitForChild("ClaimBeam"):Clone()
    -- The arrow artwork faces opposite the Beam's UV direction, so the endpoints are reversed. Negative speed still scrolls player -> target.
    guidanceBeam.Attachment0 = target
    guidanceBeam.Attachment1 = guidanceOrigin
    guidanceBeam.TextureSpeed = -math.abs(guidanceBeam.TextureSpeed)
    guidanceBeam.Parent = guidanceOrigin

    local arrowTemplate = tutorialCompleted and guidanceTemplate:FindFirstChild("ClaimArrow")
    if arrowTemplate and arrowTemplate:IsA("BillboardGui") then
        guidanceArrow = arrowTemplate:Clone()
        guidanceArrow.Adornee = target.Parent
        guidanceArrow.StudsOffset = Vector3.zero
        guidanceArrow.StudsOffsetWorldSpace = target.WorldPosition
            - target.Parent.Position
            + Vector3.new(0, 3.2, 0)
        guidanceArrow.Parent = target.Parent
    end
end

local function updateHUD()
    local stars = math.clamp(player:GetAttribute("Stars") or 0, 0, 5)
    ratingLabel.Text = UI.T(
        "HUD",
        stars == 1 and "OneStar" or "Stars",
        string.rep("★", stars) .. string.rep("☆", 5 - stars),
        stars
    )
end

local function resetChoices()
    for index, item in ipairs(choiceStrokes) do
        local base = choiceDefaults[index]
        item.Color, item.Thickness, item.Transparency = base.Color, base.Thickness, base.Transparency
    end
end

local function selectChoice(index)
    if busy then
        return
    end
    selectedIndex = index
    resetChoices()
    choiceStrokes[index].Color, choiceStrokes[index].Thickness, choiceStrokes[index].Transparency =
        COLORS.Accent,
        dialogue:GetAttribute("SelectedOutlineThickness") or 3,
        dialogue:GetAttribute("SelectedOutlineTransparency") or 0
    statusLabel.Text, statusLabel.TextColor3 = UI.T("Dialogue", "Ready"), COLORS.Muted
end

for index, button in ipairs(choiceButtons) do
    Responsive.BindChoice(button, function()
        selectChoice(index)
    end)
end

local function showDialogueStage(data, animate)
    Entrance.Finish(dialogue)
    dismissCompletedFeedback = nil
    continuationId += 1
    continueConsultation = nil
    frqDashboardClose.Visible = false
    setConsultationHeader(data.IsDashboard == true)
    currentScenarioToken = data.ContextToken
    dashboardComplete = false
    dashboardClose.Visible = data.IsDashboard == true
    if data.IsDashboard then
        dashboardClose.Text = UI.T("Dashboard", "Close")
    end
    difficultyLabel.Visible = true
    selectedIndex, busy = nil, false
    scenarioLoading.Visible = false
    promptLabel.Visible, submitButton.Visible = true, true
    currentMode = "MCQ"
    if data.Mode == "FRQ" then
        currentMode = "FRQ"
    end
    currentFRQContext = nil
    if currentMode == "FRQ" and type(data.FRQContextId) == "string" then
        currentFRQContext = {
            Id = data.FRQContextId,
            Difficulty = data.Difficulty,
            Stage = data.StageIndex,
        }
    end
    frqContextChanged:Fire(currentFRQContext)
    frqMaxCharacters = tonumber(data.MaxCharacters) or 500
    resetChoices()
    nameLabel.Text = data.CustomerName
    categoryLabel.Text = tostring(data.CategoryCode or "—")
    promptLabel.Text = ScenarioText.OneParagraph(data.Prompt)
    difficultyLabel.Text = UI.T("Dialogue", "Difficulty", data.Difficulty or 1)
    choicesFrame.Visible = currentMode == "MCQ"
    frqFrame.Visible = currentMode == "FRQ"
    aiDisclosure.Visible = currentMode == "FRQ" or data.IsAIGenerated == true
    if aiDisclosure:GetAttribute("UseTextVariants") == true then
        local variant = aiDisclosure:GetAttribute(data.IsAIGenerated and "GeneratedText" or "FRQText")
        if type(variant) == "string" then
            aiDisclosure.Text = variant
        end
    end
    if currentMode == "FRQ" then
        submitButton.Text = UI.T("Dialogue", "SubmitFRQ")
        taskPrompt.Text = ScenarioText.OneParagraph(data.FRQPrompt or UI.T("Dialogue", "DefaultFRQ"))
        responseBox.Text = ""
        characterCount.Text = UI.T("Dialogue", "CharacterCount", 0, frqMaxCharacters)
    else
        submitButton.Text = UI.T("Dialogue", "SubmitMCQ")
        for index, button in ipairs(choiceButtons) do
            button.Text = UI.T("Dialogue", "Choice", index, (data.Choices or {})[index] or "")
        end
    end
    if (data.StageCount or 1) > 1 then
        local key = "MCQPart"
        if currentMode == "FRQ" then
            key = "FRQPart"
        end
        statusLabel.Text = UI.T("Dialogue", key, data.StageIndex or 1, data.StageCount)
    else
        local key = "MCQInstruction"
        if currentMode == "FRQ" then
            key = "FRQInstruction"
        end
        statusLabel.Text = UI.T("Dialogue", key)
    end
    if data.IsDashboard and currentMode == "MCQ" and (data.StageCount or 1) == 1 then
        statusLabel.Text = UI.T("Dashboard", "Instruction")
    end
    statusLabel.TextColor3 = COLORS.Muted
    applyDialogueLayout()
    dialogue.Visible = true
    if animate then
        Entrance.Play(dialogue)
    end
end

local function scheduleCompletedFeedback()
    continuationId += 1
    local id = continuationId
    local seconds = dialogue:GetAttribute("FinalFeedbackSeconds")
    if type(seconds) ~= "number" or seconds ~= seconds or math.abs(seconds) == math.huge then
        seconds = 15
    end
    seconds = math.clamp(seconds, 1, 120)

    submitButton.Text = UI.T("Dialogue", "FinalNext")
    dismissCompletedFeedback = function()
        -- An old timer must never close a newer customer's question.
        if id ~= continuationId or not dialogue.Visible then
            return
        end
        continuationId += 1
        dismissCompletedFeedback = nil
        pendingFRQNextStage = nil
        pendingFRQComplete = false
        frqFeedbackOverlay.Visible = false
        overlay.Visible = false
        dialogue.Visible = false
        busy = false
        selectedIndex = nil
    end
    task.delay(seconds, dismissCompletedFeedback)
end

local function scheduleConsultation(result)
    continuationId += 1
    local id = continuationId
    local token = currentScenarioToken
    local name = result.Mode == "FRQ" and "OnlineFRQFeedbackSeconds" or "OnlineFeedbackSeconds"
    local seconds = dialogue:GetAttribute(name)
    if type(seconds) ~= "number" or seconds ~= seconds or math.abs(seconds) == math.huge then
        seconds = result.Mode == "FRQ" and 12 or 5
    end
    seconds = math.clamp(seconds, 1, 120)
    continueConsultation = function()
        if id ~= continuationId or token ~= currentScenarioToken or not dialogue.Visible then
            return
        end
        continuationId += 1
        continueConsultation = nil
        pendingFRQNextStage = nil
        pendingFRQComplete = false
        frqFeedbackOverlay.Visible = false
        frqDashboardClose.Visible = false
        if result.NextStage then
            showDialogueStage(result.NextStage, false)
        else
            busy = true
            submitButton.Visible = false
            promptLabel.Visible = false
            frqFrame.Visible = false
            scenarioLoading.Visible = true
            continueDashboard:FireServer(token)
        end
    end
    local advance = continueConsultation
    task.delay(seconds, advance)
end

responseBox:GetPropertyChangedSignal("Text"):Connect(function()
    local count = utf8.len(responseBox.Text) or #responseBox.Text
    characterCount.Text = UI.T("Dialogue", "CharacterCount", count, frqMaxCharacters)
    characterCount.TextColor3 = count > frqMaxCharacters and COLORS.Red or COLORS.Muted
end)

local function showFRQFeedback(result)
    if result.Correct then
        currentFRQContext = nil
        frqContextChanged:Fire(nil)
    end
    local analysis = result.Analysis
    local scores = analysis.Scores
    frqScoreBar.DeEscalationScore.Text = UI.T("FRQ", "DeEscalation", tostring(scores.DeEscalation))
    frqScoreBar.BoundarySettingScore.Text = UI.T("FRQ", "BoundarySetting", tostring(scores.BoundarySetting))
    frqScoreBar.EscalationRiskScore.Text = UI.T("FRQ", "EscalationRisk", tostring(scores.EscalationRisk))
    local scoreDetails = {
        UI.T("FRQ", "OverallScore", analysis.WeightedScore or 0),
        UI.T("FRQ", "AdditionalScores", scores.ActiveListening, scores.ProblemSolving),
    }
    if type(analysis.RubricScores) == "table" then
        table.insert(scoreDetails, UI.T("FRQ", "RubricHeading"))
        for _, item in ipairs(analysis.RubricScores) do
            table.insert(scoreDetails, UI.T("FRQ", "RubricLine", item.Label, item.Score, item.Weight))
        end
    end
    frqAdditionalScores.Text = table.concat(scoreDetails, "\n")
    frqAnalysisScroll.SummaryText.Text = UI.T("FRQ", "Assessment", analysis.Summary)
        .. (
            result.CustomerReaction
                and "\n\n" .. UI.T("Dialogue", "CustomerReaction", result.CustomerReaction)
            or ""
        )
    if result.IsDashboard and result.Correct and not result.Continue then
        frqAnalysisScroll.SummaryText.Text ..= "\n\n" .. result.Success
    end
    frqAnalysisScroll.StrengthText.Text = UI.T("FRQ", "Strength", analysis.Strength)
    frqAnalysisScroll.ImprovementText.Text =
        UI.T("FRQ", result.Correct and "OptionalImprovement" or "Improvement", analysis.Improvement)
    frqAnalysisScroll.ModelResponseText.Text = UI.T("FRQ", "Example", analysis.ModelResponse)
    frqAnalysisScroll.CanvasPosition = Vector2.zero
    frqOutcome.Text = result.Correct and UI.T("FRQ", "Ready") or UI.T("FRQ", "Revise")
    frqOutcome.TextColor3 = result.Correct and COLORS.Green or COLORS.Red
    frqContinue.Text = result.Correct
            and (result.Continue and UI.T("FRQ", "NextPart") or UI.T("FRQ", "Finish"))
        or UI.T("FRQ", "ReviseButton")
    pendingFRQNextStage = result.NextStage
    pendingFRQComplete = result.Correct and not result.Continue
    frqDashboardClose.Visible = currentScenarioToken ~= nil
    frqDashboardClose.Text = UI.T("Dashboard", "Close")
    frqContinue.Position = frqContinuePosition
    frqContinue.Size = frqContinueSize
    if currentScenarioToken then
        frqContinue.Position = frqContinue:GetAttribute("OnlinePosition") or frqContinuePosition
        frqContinue.Size = frqContinue:GetAttribute("OnlineSize") or frqContinueSize
    end
    frqFeedbackOverlay.Visible = true
    if result.Correct and result.IsDashboard then
        frqContinue.Text = UI.T("Dashboard", result.Continue and "NextPart" or "NextCustomer")
        scheduleConsultation(result)
    elseif result.Correct and not result.Continue then
        frqContinue.Text = UI.T("Dialogue", "FinalNext")
        scheduleCompletedFeedback()
    end
end

frqContinue.Activated:Connect(function()
    if dismissCompletedFeedback then
        dismissCompletedFeedback()
        return
    end
    if continueConsultation then
        continueConsultation()
        return
    end
    frqFeedbackOverlay.Visible = false
    if pendingFRQNextStage then
        local nextStage = pendingFRQNextStage
        pendingFRQNextStage = nil
        showDialogueStage(nextStage, false)
    elseif pendingFRQComplete then
        if currentScenarioToken then
            closeDashboard:FireServer(currentScenarioToken)
            hideDashboard()
        end
        dialogue.Visible = false
        pendingFRQComplete = false
        busy = false
    else
        busy = false
        statusLabel.Text = UI.T("Dialogue", "Revise")
        statusLabel.TextColor3 = COLORS.Muted
    end
end)

retryButton.Activated:Connect(function()
    overlay.Visible, selectedIndex, busy = false, nil, false
    resetChoices()
    statusLabel.Text, statusLabel.TextColor3 = UI.T("Dialogue", "Retry"), COLORS.Muted
end)

hideDashboard = function()
    dismissCompletedFeedback = nil
    continuationId += 1
    continueConsultation = nil
    frqDashboardClose.Visible = false
    setConsultationHeader(false)
    frqFeedbackOverlay.Visible = false
    scenarioLoading.Visible = false
    currentFRQContext = nil
    frqContextChanged:Fire(nil)
    pendingFRQNextStage = nil
    pendingFRQComplete = false
    dialogue.Visible = false
    overlay.Visible = false
    dashboardClose.Visible = false
    difficultyLabel.Visible = true
    currentScenarioToken = nil
    dashboardComplete = false
    busy = false
    selectedIndex = nil
end

local function closeConsultation()
    if not currentScenarioToken then
        return
    end
    closeDashboard:FireServer(currentScenarioToken)
    hideDashboard()
end
dashboardClose.Activated:Connect(closeConsultation)
frqDashboardClose.Activated:Connect(closeConsultation)

submitButton.Activated:Connect(function()
    if dismissCompletedFeedback then
        dismissCompletedFeedback()
        return
    end
    if dashboardComplete then
        closeDashboard:FireServer(currentScenarioToken)
        hideDashboard()
        return
    end
    if busy then
        ActionFeedback.Error()
        return
    end
    local answer
    if currentMode == "FRQ" then
        answer = string.match(responseBox.Text, "^%s*(.-)%s*$") or ""
        local answerCharacters = utf8.len(answer) or #answer
        if answerCharacters == 0 then
            ActionFeedback.Error()
            statusLabel.Text, statusLabel.TextColor3 = UI.T("Dialogue", "EmptyFRQ"), COLORS.Red
            return
        end
        if answerCharacters < Config.FRQMinCharacters then
            ActionFeedback.Error()
            statusLabel.Text, statusLabel.TextColor3 = UI.T("Dialogue", "ShortFRQ"), COLORS.Red
            return
        end
        if answerCharacters > frqMaxCharacters then
            ActionFeedback.Error()
            statusLabel.Text, statusLabel.TextColor3 =
                UI.T("Dialogue", "CharacterLimit", frqMaxCharacters), COLORS.Red
            return
        end
    else
        if not selectedIndex then
            ActionFeedback.Error()
            statusLabel.Text, statusLabel.TextColor3 = UI.T("Dialogue", "EmptyMCQ"), COLORS.Red
            return
        end
        answer = selectedIndex
    end
    busy, submitButton.Text = true, UI.T("Dialogue", "Checking")
    if currentMode == "FRQ" then
        statusLabel.Text, statusLabel.TextColor3 = UI.T("Dialogue", "Analyzing"), COLORS.Muted
    end
    local submittedToken = currentScenarioToken
    local submittedId = continuationId
    local ok, result = pcall(function()
        return submitAnswer:InvokeServer(answer, submittedToken)
    end)
    if submittedId ~= continuationId or (submittedToken and submittedToken ~= currentScenarioToken) then
        return
    end
    submitButton.Text = currentMode == "FRQ" and UI.T("Dialogue", "SubmitFRQ")
        or UI.T("Dialogue", "SubmitMCQ")
    if ok and result and result.SwitchToMCQ and result.NextStage then
        ActionFeedback.Error()
        showDialogueStage(result.NextStage, false)
        statusLabel.Text, statusLabel.TextColor3 =
            result.Error or UI.T("Dialogue", "GradingFallback"), COLORS.Red
        return
    end
    if not ok or not result or result.Error then
        ActionFeedback.Error()
        statusLabel.Text, statusLabel.TextColor3 =
            result and result.Error or UI.T("Dialogue", "CheckFailed"), COLORS.Red
        busy = false
        return
    end
    if result.Mode == "FRQ" and result.Analysis then
        if result.Correct then
            correctSound:Play()
        else
            ActionFeedback.Error()
        end
        showFRQFeedback(result)
        return
    end
    if result.Correct then
        choiceStrokes[selectedIndex].Color, choiceStrokes[selectedIndex].Thickness, choiceStrokes[selectedIndex].Transparency =
            COLORS.Green,
            dialogue:GetAttribute("ResultOutlineThickness") or 4,
            dialogue:GetAttribute("ResultOutlineTransparency") or 0
        if result.IsDashboard and not result.Continue then
            correctSound:Play()
            statusLabel.Text = UI.T("Dashboard", "GoodChoice")
            statusLabel.TextColor3 = COLORS.Green
            promptLabel.Text = result.Success
            choicesFrame.Visible = false
            submitButton.Visible = false
            dashboardComplete = true
            scheduleConsultation(result)
            return
        end
        if result.Continue and result.NextStage then
            statusLabel.Text, statusLabel.TextColor3 =
                result.CustomerReaction or UI.T("Dialogue", "NextStage"), COLORS.Green
            correctSound:Play()
            task.wait(0.8)
            if submittedId ~= continuationId or (submittedToken and submittedToken ~= currentScenarioToken) then
                return
            end
            showDialogueStage(result.NextStage, false)
            return
        end
        correctSound:Play()
        statusLabel.Text, statusLabel.TextColor3 =
            UI.T("Dialogue", "Reward", tostring(result.Reward), result.Success), COLORS.Green
        scheduleCompletedFeedback()
        return
    end
    ActionFeedback.Error()
    local mixed = result.Outcome == "Mixed"
    local hintKey = mixed and "MixedHint" or (result.Outcome == "Risky" and "RiskyHint" or "Hint")
    choiceStrokes[selectedIndex].Color, choiceStrokes[selectedIndex].Thickness, choiceStrokes[selectedIndex].Transparency =
        mixed and (dialogue:GetAttribute("MixedOutlineColor") or Color3.fromRGB(218, 155, 52)) or COLORS.Red,
        dialogue:GetAttribute("ResultOutlineThickness") or 4,
        dialogue:GetAttribute("ResultOutlineTransparency") or 0
    hintText.Text = (
        result.CustomerReaction
            and UI.T("Dialogue", "CustomerReaction", result.CustomerReaction) .. "\n\n"
        or ""
    ) .. UI.T("Dialogue", hintKey, result.Hint)
    overlay.Visible = true
end)

openDialogue.OnClientEvent:Connect(function(data)
    if data.Closed then
        if currentScenarioToken == data.ContextToken then
            hideDashboard()
        end
        return
    end
    continuationId += 1
    dismissCompletedFeedback = nil
    continueConsultation = nil
    frqDashboardClose.Visible = false
    dashboardClose.Visible = false
    difficultyLabel.Visible = true
    currentScenarioToken = nil
    dashboardComplete = false
    overlay.Visible = false
    frqFeedbackOverlay.Visible = false
    if data.Loading then
        setConsultationHeader(data.IsDashboard == true)
        currentScenarioToken = data.ContextToken
        dashboardClose.Visible = data.IsDashboard == true
        if data.IsDashboard then
            dashboardClose.Text = UI.T("Dashboard", "Close")
        end
        busy, selectedIndex = true, nil
        nameLabel.Text = data.CustomerName
        categoryLabel.Text = tostring(data.CategoryCode or "")
        difficultyLabel.Text = UI.T("Dialogue", "Difficulty", data.Difficulty or 1)
        promptLabel.Visible, choicesFrame.Visible, frqFrame.Visible = false, false, false
        aiDisclosure.Visible, submitButton.Visible = false, false
        statusLabel.Text = ""
        local wasVisible = dialogue.Visible
        scenarioLoading.Visible, dialogue.Visible = true, true
        applyDialogueLayout()
        if not wasVisible then
            Entrance.Play(dialogue)
        end
        return
    end
    showDialogueStage(data, true)
end)

player:GetAttributeChangedSignal("Stars"):Connect(updateHUD)
player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
    showTutorialIfNeeded()
    refreshGuidance(player.Character)
end)
player:GetAttributeChangedSignal("TutorialCompleted"):Connect(function()
    if player:GetAttribute("TutorialCompleted") then
        closeTutorial(false)
        refreshGuidance(player.Character)
    else
        clearGuidance()
        showTutorialIfNeeded()
        refreshGuidance(player.Character)
    end
end)
player:GetAttributeChangedSignal("OwnsBusiness"):Connect(function()
    if player:GetAttribute("OwnsBusiness") then
        closeTutorial(false)
        clearGuidance()
    else
        showTutorialIfNeeded()
        refreshGuidance(player.Character)
    end
end)
player.CharacterAdded:Connect(function(character)
    task.defer(refreshGuidance, character)
end)

updateHUD()
task.defer(showTutorialIfNeeded)
task.defer(refreshGuidance, player.Character)
