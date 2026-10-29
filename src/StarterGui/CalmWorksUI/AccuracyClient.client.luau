local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Entrance = require(ReplicatedStorage.CalmWorksShared.UIEntrance)

local player = Players.LocalPlayer
local gui = script.Parent
local remotes = ReplicatedStorage:WaitForChild("CalmWorksRemotes")
local getAccuracyData = remotes:WaitForChild("GetAccuracyData")
local accuracyUpdated = remotes:WaitForChild("AccuracyUpdated")

local openButton = gui:WaitForChild("AccuracyButton")
local panel = gui:WaitForChild("AccuracyPanel")
local closeButton = panel.Header:WaitForChild("CloseButton")
local contentScroll = panel:WaitForChild("ContentScroll")
local overallCard = contentScroll:WaitForChild("OverallCard")
local renderRadar =
    require(gui:WaitForChild("SkillsRadarRenderer")).Bind(contentScroll:WaitForChild("SkillsTrackerCard"))
local overallLabel = overallCard:WaitForChild("OverallLabel")
local overallCounts = overallCard:WaitForChild("OverallCounts")
local overallFill = overallCard.ProgressTrack:WaitForChild("Fill")
local focusSummary = overallCard:WaitForChild("FocusSummary")
local categoryList = contentScroll:WaitForChild("CategoryList")

local function palette(name, fallback)
    local value = panel:GetAttribute(name)
    return typeof(value) == "Color3" and value or fallback
end
local COLORS = {
    Accent = palette("AccentColor", Color3.fromRGB(65, 126, 235)),
    Green = palette("GoalColor", Color3.fromRGB(44, 174, 112)),
    Orange = palette("MediumColor", Color3.fromRGB(230, 151, 54)),
    Red = palette("LowColor", Color3.fromRGB(220, 72, 72)),
    Muted = palette("MutedColor", Color3.fromRGB(104, 113, 130)),
    Neutral = palette("NeutralTextColor", Color3.fromRGB(39, 50, 69)),
}

local rowsByCode = {}
for _, child in ipairs(categoryList:GetChildren()) do
    if child:IsA("Frame") then
        local code = child:GetAttribute("CategoryCode")
        if type(code) == "string" then
            rowsByCode[code] = child
        end
    end
end

local columnLabels = contentScroll:WaitForChild("ColumnLabels")
local layoutObjects =
    { overallCard, focusSummary, overallCard.ProgressTrack, columnLabels.Accuracy, categoryList }
for _, row in pairs(rowsByCode) do
    table.insert(layoutObjects, row)
    for _, item in ipairs(row:GetChildren()) do
        if item:IsA("GuiObject") then
            table.insert(layoutObjects, item)
        end
    end
end
local editorLayout = UI.CaptureLayout(layoutObjects)
local editorAnswersVisible = columnLabels.Answers.Visible
local function applyResponsiveLayout()
    if panel:GetAttribute("AutoLayoutEnabled") == false then
        return
    end
    local compact = contentScroll.AbsoluteSize.X < (panel:GetAttribute("CompactBreakpoint") or 410)
    if not compact then
        UI.RestoreLayout(editorLayout)
        columnLabels.Answers.Visible = editorAnswersVisible
        return
    end
    overallCard.Size = UDim2.new(
        1,
        -8,
        0,
        overallCard:GetAttribute(compact and "CompactHeight" or "DesktopHeight") or (compact and 132 or 106)
    )
    focusSummary.TextWrapped = true
    focusSummary.TextTruncate = Enum.TextTruncate.None
    focusSummary.Size = UDim2.fromScale(0.93, compact and 0.30 or 0.24)
    overallCard.ProgressTrack.Position = UDim2.fromScale(0.035, compact and 0.82 or 0.76)
    overallCard.ProgressTrack.Size = UDim2.fromScale(0.93, compact and 0.10 or 0.13)
    columnLabels.Answers.Visible = not compact
    columnLabels.Accuracy.Text = compact and UI.T("Accuracy", "Rate") or UI.T("Accuracy", "Accuracy")
    columnLabels.Accuracy.Position = compact and UDim2.new(1, -70, 0, 0) or UDim2.new(0.85, 0, 0, 0)
    columnLabels.Accuracy.Size = compact and UDim2.new(0, 70, 1, 0) or UDim2.new(0.15, 0, 1, 0)
    categoryList.Size = UDim2.new(1, -8, 0, compact and 900 or 710)
    categoryList.CanvasSize = UDim2.fromOffset(0, compact and 900 or 710)
    for _, row in pairs(rowsByCode) do
        row.Size = UDim2.new(1, -2, 0, compact and 82 or 62)
        row.NameLabel.Position = compact and UDim2.new(0, 59, 0, 2) or UDim2.new(0, 59, 0, 5)
        row.NameLabel.Size = compact and UDim2.new(1, -112, 0, 38) or UDim2.new(0.47, -59, 0, 24)
        row.NameLabel.TextWrapped = compact
        row.NameLabel.TextSize = compact and 11 or 13
        row.CountsLabel.Position = compact and UDim2.new(0, 12, 0, 43) or UDim2.new(0.47, 4, 0, 5)
        row.CountsLabel.Size = compact and UDim2.new(1, -24, 0, 19) or UDim2.new(0.36, -8, 0, 24)
        row.CountsLabel.TextXAlignment = compact and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        row.CountsLabel.TextSize = compact and 11 or 12
        row.PercentLabel.Position = compact and UDim2.new(1, -47, 0, 5) or UDim2.new(0.83, 0, 0, 5)
        row.PercentLabel.Size = compact and UDim2.fromOffset(36, 24) or UDim2.new(0.15, -4, 0, 24)
        row.ProgressTrack.Position = compact and UDim2.new(0, 12, 1, -16) or UDim2.new(0, 12, 1, -18)
    end
end
contentScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyResponsiveLayout)
task.defer(applyResponsiveLayout)

local requestInProgress = false

local function accuracyColor(accuracy)
    if accuracy == nil then
        return COLORS.Muted
    end
    if accuracy >= 0.85 then
        return COLORS.Green
    end
    if accuracy >= 0.5 then
        return COLORS.Accent
    end
    if accuracy >= 0.25 then
        return COLORS.Orange
    end
    return COLORS.Red
end

local function percentText(accuracy)
    if accuracy == nil then
        return UI.T("Accuracy", "NoScore")
    end
    return tostring(math.floor(math.clamp(accuracy, 0, 1) * 100 + 0.5)) .. "%"
end

local function setFill(fill, accuracy, color)
    local amount = accuracy and math.clamp(accuracy, 0, 1) or 0
    TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(amount, 1),
        BackgroundColor3 = color,
    }):Play()
end

local function resetRows()
    for _, row in pairs(rowsByCode) do
        row.CountsLabel.Text = UI.T("Accuracy", "EmptyCounts")
        row.PercentLabel.Text = UI.T("Accuracy", "NoScore")
        row.PercentLabel.TextColor3 = COLORS.Muted
        setFill(row.ProgressTrack.Fill, nil, COLORS.Muted)
    end
end

local function renderAccuracy(data)
    if type(data) ~= "table" then
        return
    end
    resetRows()

    local totalCorrect = math.max(0, math.floor(tonumber(data.TotalCorrect) or 0))
    local totalIncorrect = math.max(0, math.floor(tonumber(data.TotalIncorrect) or 0))
    local overallAccuracy = tonumber(data.OverallAccuracy)
    local overallColor = accuracyColor(overallAccuracy)

    if data.Ready == false then
        overallLabel.Text = UI.T("Accuracy", "LoadingSaved")
    else
        overallLabel.Text = UI.T("Accuracy", "Overall", percentText(overallAccuracy))
    end
    overallLabel.TextColor3 = overallAccuracy and overallColor or COLORS.Neutral
    overallCounts.Text = UI.T("Accuracy", "Counts", totalCorrect, totalIncorrect)
    if data.IsWeekly then
        overallLabel.Text = UI.T("Accuracy", "Average", percentText(overallAccuracy))
        overallCounts.Text = UI.T("Accuracy", "DailySnapshots", data.MeasuredDays or 0)
    elseif data.HasData == false then
        overallLabel.Text = UI.T("Accuracy", "MissingDate")
        overallCounts.Text = UI.T("Accuracy", "MissingSnapshot")
    end
    setFill(overallFill, overallAccuracy, overallColor)

    renderRadar(data)
    if type(data.Categories) ~= "table" then
        return
    end
    local primaryFocus, focusCount
    focusCount = 0
    for _, category in ipairs(data.Categories) do
        if category.FocusActive == true then
            focusCount += 1
            if
                not primaryFocus
                or (tonumber(category.Accuracy) or 1) < (tonumber(primaryFocus.Accuracy) or 1)
            then
                primaryFocus = category
            end
        end
        local row = rowsByCode[category.Code]
        if row then
            local correct = math.max(0, math.floor(tonumber(category.Correct) or 0))
            local incorrect = math.max(0, math.floor(tonumber(category.Incorrect) or 0))
            local accuracy = tonumber(category.Accuracy)
            local color = accuracyColor(accuracy)
            if type(category.Name) == "string" and category.Name ~= "" then
                row.NameLabel.Text = row:GetAttribute("DisplayName") or category.Name
            end
            row.CountsLabel.Text = UI.T("Accuracy", "Counts", correct, incorrect)
            if data.IsWeekly then
                row.CountsLabel.Text = UI.T("Accuracy", "MeasuredDays", category.MeasuredDays or 0)
            elseif data.HasData == false then
                row.CountsLabel.Text = UI.T("Accuracy", "NoData")
            end
            row.PercentLabel.Text = percentText(accuracy)
            row.PercentLabel.TextColor3 = color
            setFill(row.ProgressTrack.Fill, accuracy, color)
        end
    end
    if primaryFocus then
        local additional = focusCount > 1 and UI.T("Accuracy", "AdditionalFocus", focusCount - 1) or ""
        focusSummary.Text = UI.T(
            "Accuracy",
            "Focus",
            primaryFocus.Name or primaryFocus.Code,
            tonumber(primaryFocus.FocusCorrect) or 0,
            tonumber(data.MasteryCorrect) or 10,
            tonumber(primaryFocus.FocusMistakes) or 0,
            tonumber(data.MasteryMistakes) or 1,
            additional
        )
        focusSummary.TextColor3 = COLORS.Accent
    else
        focusSummary.Text =
            UI.T("Accuracy", "Goal", math.floor((tonumber(data.TargetAccuracy) or 0.85) * 100 + 0.5))
        focusSummary.TextColor3 = COLORS.Muted
    end
    if data.Historical then
        focusSummary.Text = data.IsWeekly and UI.T("Accuracy", "WeeklyNote")
            or UI.T("Accuracy", "HistoricalNote")
    end
end

local receiveAccuracy = require(gui:WaitForChild("ProgressController")).Bind(gui, renderAccuracy)

local ActionFeedback = require(game:GetService("ReplicatedStorage").CalmWorksShared.ActionFeedback)

local function requestAccuracy()
    if requestInProgress then
        return
    end
    requestInProgress = true
    overallLabel.Text = UI.T("Accuracy", "Loading")
    task.spawn(function()
        local success, result = pcall(function()
            return getAccuracyData:InvokeServer()
        end)
        requestInProgress = false
        if success and type(result) == "table" then
            receiveAccuracy(result)
        else
            if panel.Visible then
                ActionFeedback.Error()
            end
            overallLabel.Text = UI.T("Accuracy", "Unavailable")
            overallLabel.TextColor3 = COLORS.Red
            overallCounts.Text = UI.T("Accuracy", "Retry")
        end
    end)
end

local function setPanelVisible(visible)
    panel.Visible = visible
    if visible then
        contentScroll.CanvasPosition = Vector2.new(0, 0)
    end
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
    if panel.Visible then
        requestAccuracy()
    end
end)

openButton.Activated:Connect(function()
    setPanelVisible(not panel.Visible)
end)
closeButton.Activated:Connect(function()
    setPanelVisible(false)
end)
accuracyUpdated.OnClientEvent:Connect(receiveAccuracy)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not panel.Visible then
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape then
        setPanelVisible(false)
    end
end)

player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
    if panel.Visible and player:GetAttribute("DataLoaded") then
        requestAccuracy()
    end
end)

panel.Visible = false
Entrance.Bind(panel)
resetRows()
