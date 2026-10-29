local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local effects = script.Parent
local overlay = effects:WaitForChild("BusinessVisitOverlay")
local card = overlay:WaitForChild("VisitCard")
local remotes = ReplicatedStorage:WaitForChild("CalmWorksRemotes")
local ui = require(ReplicatedStorage.CalmWorksShared.EditableUI)
local feedback = require(ReplicatedStorage.CalmWorksShared.ActionFeedback)
local pending
local current
local busy = false

local function canOpen()
    if player:GetAttribute("CeremonyActive") == true or player:GetAttribute("CalmWorksLoadingComplete") == false then
        return false
    end
    local main = player.PlayerGui:FindFirstChild("CalmWorksUI")
    if not main or main.Dialogue.Visible or main.AccuracyPanel.Visible then
        return false
    end
    for _, name in ipairs({ "TutorialOverlay", "FeedbackOverlay", "FRQFeedbackOverlay" }) do
        local frame = effects:FindFirstChild(name)
        if frame and frame.Visible then
            return false
        end
    end
    local support = player.PlayerGui:FindFirstChild("CalmWorksSupportUI")
    if support and support.SupportPanel.Visible then
        return false
    end
    -- A requested mentor conversation takes priority over queued notices.
    return true
end

local function show(data)
    current = data
    card.DialogueText.Text = data.Text
    card.StatusLabel.Text = ""
    overlay.Visible = true
end

overlay.Visible = false
local opened = remotes.OpenBusinessVisit.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" or type(data.Token) ~= "string" or type(data.Text) ~= "string" then
        return
    end
    if current and current.Token == data.Token then
        return
    end
    pending = data
end)
local closed = remotes.CloseBusinessVisit.OnClientEvent:Connect(function(token)
    if current and current.Token == token then
        current = nil
        overlay.Visible = false
        busy = false
    end
    if pending and pending.Token == token then
        pending = nil
    end
end)

card.NextButton.Activated:Connect(function()
    if busy or not current then
        return
    end
    busy = true
    local previous = current
    local ok, result = pcall(function()
        if previous.CeremonyClosing then
            return remotes.AdvanceCeremony:InvokeServer(previous.Token, previous.Index)
        end
        return remotes.AdvanceBusinessVisit:InvokeServer(previous.Token, previous.Index)
    end)
    busy = false
    if current ~= previous then
        return
    end
    if not ok or type(result) ~= "table" or result.Error then
        feedback.Error()
        card.StatusLabel.Text = ui.T("BusinessVisitStatus", "Retry")
        if ok and type(result) == "table" and type(result.Error) == "string" then
            card.StatusLabel.Text = result.Error
        end
        if ok and type(result) == "table" and result.Closed then
            current = nil
            overlay.Visible = false
        end
        return
    end
    if result.Complete then
        current = nil
        overlay.Visible = false
    else
        show(result)
    end
end)

task.spawn(function()
    while effects.Parent do
        if pending and not current and canOpen() then
            local nextPage = pending
            pending = nil
            show(nextPage)
        end
        task.wait(0.15)
    end
end)
effects.Destroying:Connect(function()
    opened:Disconnect()
    closed:Disconnect()
end)
