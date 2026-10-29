local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("CalmWorksUI")
local support = playerGui:WaitForChild("CalmWorksSupportUI")
local effects = playerGui:WaitForChild("CalmWorksFullScreenEffects")
local Responsive = require(ReplicatedStorage.CalmWorksShared.ResponsiveUI)
local Entrance = require(ReplicatedStorage.CalmWorksShared.UIEntrance)
local dialogue = main.Dialogue
local panel = support.SupportPanel
local accuracy = main.AccuracyPanel
local frq = dialogue.FRQFrame.EntryScroll.Content
local feedback = effects.FRQFeedbackOverlay.FeedbackCard
local roots = {
    accuracy,
    effects.TutorialOverlay.TutorialCard,
    effects.BusinessVisitOverlay.VisitCard,
    effects.FeedbackOverlay.HintCard,
    feedback,
}
local feedbackLayout = {}
for _, item in ipairs({feedback.Title, feedback.OutcomeLabel, feedback.Disclosure, feedback.ScoreBar, feedback.AnalysisScroll, feedback.ScrollHint}) do
    feedbackLayout[item] = {Position = item.Position, Size = item.Size}
end

Responsive.CaptureSupport(panel)
for _, root in ipairs({main, support, effects}) do
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("TextButton") then
            Responsive.Reader(item)
        end
    end
end

local queued = false
local function update()
    queued = false
    Responsive.Dialogue(dialogue)
    Responsive.Support(panel)
    for _, root in ipairs(roots) do
        Responsive.Fit(root)
    end
    -- The short landscape viewport needs more room for the existing analysis scroll.
    if feedback.AbsoluteSize.Y < 400 then
        feedback.Title.Position = UDim2.fromOffset(14, 6)
        feedback.Title.Size = UDim2.new(0.65, -14, 0, 25)
        feedback.OutcomeLabel.Position = UDim2.new(1, -14, 0, 6)
        feedback.OutcomeLabel.Size = UDim2.new(0.32, 0, 0, 25)
        feedback.Disclosure.Position = UDim2.fromOffset(14, 34)
        feedback.Disclosure.Size = UDim2.new(1, -28, 0, 24)
        feedback.ScoreBar.Position = UDim2.fromOffset(14, 61)
        feedback.ScoreBar.Size = UDim2.new(1, -28, 0, 42)
        feedback.AnalysisScroll.Position = UDim2.fromOffset(14, 108)
        feedback.AnalysisScroll.Size = UDim2.new(1, -28, 1, -182)
    else
        for item, original in pairs(feedbackLayout) do
            item.Size, item.Position = original.Size, original.Position
        end
    end
end

local function schedule()
    if not queued then
        queued = true
        task.defer(update)
    end
end
main:GetPropertyChangedSignal("AbsoluteSize"):Connect(schedule)
main:GetPropertyChangedSignal("AbsolutePosition"):Connect(schedule)
effects:GetPropertyChangedSignal("AbsoluteSize"):Connect(schedule)
panel.FRQContextCard:GetPropertyChangedSignal("Visible"):Connect(schedule)
dialogue:GetPropertyChangedSignal("Visible"):Connect(schedule)
dialogue:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    Responsive.Dialogue(dialogue)
end)
frq.ResponseBox:GetPropertyChangedSignal("Text"):Connect(function()
    Responsive.Dialogue(dialogue)
end)
frq.ResponseBox.Focused:Connect(function()
    task.defer(function()
        dialogue.FRQFrame.EntryScroll.CanvasPosition = Vector2.new(0, 48)
    end)
end)

local function connectCamera()
    local camera = workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(schedule)
    end
    schedule()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
connectCamera()
