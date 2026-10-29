local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local ActionFeedback =
    require(ReplicatedStorage:WaitForChild("CalmWorksShared"):WaitForChild("ActionFeedback"))
local Config = require(ReplicatedStorage.CalmWorksShared.Config)
local Entrance = require(ReplicatedStorage.CalmWorksShared.UIEntrance)
local Responsive = require(ReplicatedStorage.CalmWorksShared.ResponsiveUI)
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("CalmWorksSupportUI")
local openButton = gui:WaitForChild("OpenSupportButton")
local panel = gui:WaitForChild("SupportPanel")
local closeButton = panel.Header:WaitForChild("CloseButton")
local messagesFrame = panel:WaitForChild("Messages")
local inputBox = panel.Composer:WaitForChild("InputBox")
local sendButton = panel.Composer:WaitForChild("SendButton")
local statusLabel = panel:WaitForChild("StatusLabel")
local templates = gui:WaitForChild("MessageTemplates")
local openFRQHelp = gui:WaitForChild("OpenFRQHelp")
local contextChanged = gui:WaitForChild("FRQContextChanged")
local getFRQDraft = gui:WaitForChild("GetFRQDraft")
local contextCard = panel:WaitForChild("FRQContextCard")
Responsive.CaptureSupport(panel)
local normalPlaceholder = inputBox.PlaceholderText
local frqContext
local pendingText
local function setFRQContext(context)
    frqContext = context
    contextCard.Visible = context ~= nil
    if context then
        contextCard.Title.Text = UI.T("FRQHelp", "Title", context.Difficulty or 1, context.Stage or 1)
    end
    Responsive.Support(panel)
    inputBox.PlaceholderText = context and UI.T("FRQHelp", "Placeholder") or normalPlaceholder
end
local requestEvent = ReplicatedStorage.CalmWorksRemotes:WaitForChild("SupportChatRequest")
local responseEvent = ReplicatedStorage.CalmWorksRemotes:WaitForChild("SupportChatResponse")

local idleSendText = sendButton.Text
local sending = false
local historyRequested = false
local welcomeShown = false
local awaitingAcceptance = false

local function scrollToBottom()
    task.defer(function()
        task.wait()
        messagesFrame.CanvasPosition = Vector2.new(
            0,
            math.max(0, messagesFrame.AbsoluteCanvasSize.Y - messagesFrame.AbsoluteWindowSize.Y)
        )
    end)
end

local function layoutMessage(row)
    local bubble = row:FindFirstChild("Bubble")
    if not bubble then
        return
    end
    local text = bubble.Text
    local rowWidth = messagesFrame.AbsoluteSize.X * row.Size.X.Scale + row.Size.X.Offset
    local padding = bubble:FindFirstChildOfClass("UIPadding")
    local bubbleWidth = rowWidth * bubble.Size.X.Scale + bubble.Size.X.Offset
    if row.Parent == messagesFrame and bubble.AbsoluteSize.X > 0 then
        bubbleWidth = bubble.AbsoluteSize.X
    end
    if padding then
        bubbleWidth -= padding.PaddingLeft.Offset + padding.PaddingRight.Offset + bubbleWidth * (padding.PaddingLeft.Scale + padding.PaddingRight.Scale)
    end
    local bounds = TextService:GetTextSize(
        text,
        bubble.TextSize,
        bubble.Font,
        Vector2.new(math.max(20, math.floor(bubbleWidth) - 1), 10000)
    )
    if row:GetAttribute("AutoHeightEnabled") ~= false then
        row.Size = UDim2.new(
            row.Size.X.Scale,
            row.Size.X.Offset,
            0,
            math.max(
                row:GetAttribute("MinimumHeight") or 46,
                bounds.Y + (row:GetAttribute("VerticalPadding") or 26)
            )
        )
    end
    return row
end
messagesFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    for _, row in ipairs(messagesFrame:GetChildren()) do
        if row:IsA("Frame") and row:GetAttribute("CalmWorksChatMessage") == true then
            layoutMessage(row)
        end
    end
end)
local function addMessage(role, text)
    if type(text) ~= "string" or text == "" then
        return
    end
    local templateName = role == "user" and "UserMessage" or "AssistantMessage"
    local row = templates:WaitForChild(templateName):Clone()
    row.Name = templateName .. "_Runtime"
    row.Visible = true
    row:SetAttribute("CalmWorksChatMessage", true)
    local bubble = row:WaitForChild("Bubble")
    bubble.Text = text
    local lastWidth = 0
    bubble:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if row.Parent and math.abs(bubble.AbsoluteSize.X - lastWidth) > 0.1 then
            lastWidth = bubble.AbsoluteSize.X
            layoutMessage(row)
        end
    end)
    bubble:GetPropertyChangedSignal("TextSize"):Connect(function()
        if row.Parent then
            layoutMessage(row)
        end
    end)
    layoutMessage(row)
    row.Parent = messagesFrame
    task.defer(function()
        if row.Parent then
            layoutMessage(row)
        end
    end)
    scrollToBottom()
end

local function clearMessages()
    for _, child in ipairs(messagesFrame:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("CalmWorksChatMessage") == true then
            child:Destroy()
        end
    end
end

local function setSending(value, status)
    sending = value
    inputBox.TextEditable = not value
    sendButton.Interactable = not value
    sendButton.Text = value and UI.T("Support", "SendingIcon") or idleSendText
    statusLabel.Text = status or ""
end

local function showWelcomeIfEmpty()
    if welcomeShown then
        return
    end
    welcomeShown = true
    addMessage("assistant", UI.T("Support", "Welcome"))
end

local function requestHistory()
    if historyRequested then
        return
    end
    historyRequested = true
    statusLabel.Text = UI.T("Support", "LoadingHistory")
    requestEvent:FireServer({ Action = "History" })
end

local function openPanel()
    panel.Visible = true
    --openButton.Visible = false
    requestHistory()
    task.defer(function()
        if panel.Visible and not UserInputService.TouchEnabled then
            inputBox:CaptureFocus()
        end
    end)
end

local function closePanel()
    panel.Visible = false
    --openButton.Visible = true
    inputBox:ReleaseFocus()
end

openFRQHelp.Event:Connect(function(context)
    if type(context) ~= "table" or type(context.Id) ~= "string" then
        return
    end
    setFRQContext(context)
    openPanel()
end)
contextChanged.Event:Connect(function(context)
    if frqContext and (not context or context.Id ~= frqContext.Id) then
        setFRQContext(nil)
        closePanel() -- Return to the question/result instead of leaving stale help open.
    end
end)
contextCard.GeneralButton.Activated:Connect(function()
    setFRQContext(nil)
end)

local function submit()
    if sending then
        ActionFeedback.Error()
        return
    end
    local text = string.match(inputBox.Text, "^%s*(.-)%s*$") or ""
    if text == "" then
        ActionFeedback.Error()
        statusLabel.Text = UI.T("Support", "Empty")
        return
    end
    local count = utf8.len(text)
    if not count or count > Config.SupportChatMaxInputCharacters then
        ActionFeedback.Error()
        statusLabel.Text = UI.T("Support", "CharacterLimit", Config.SupportChatMaxInputCharacters)
        return
    end
    local draft
    if frqContext then
        local okay, value = pcall(function()
            return getFRQDraft:Invoke(frqContext.Id)
        end)
        if not okay or type(value) ~= "string" then
            ActionFeedback.Error()
            statusLabel.Text = UI.T("FRQHelp", "Expired")
            setFRQContext(nil)
            return
        end
        draft = value
        if
            #draft > Config.FRQMaxCharacters * 4
            or not utf8.len(draft)
            or utf8.len(draft) > Config.FRQMaxCharacters
        then
            ActionFeedback.Error()
            statusLabel.Text = UI.T("FRQHelp", "DraftLimit", Config.FRQMaxCharacters)
            return
        end
    end
    pendingText = text
    awaitingAcceptance = true
    setSending(true, UI.T("Support", "Sending"))
    inputBox.Text = ""
    requestEvent:FireServer({
        Action = "Send",
        Text = text,
        FRQContextId = frqContext and frqContext.Id,
        Draft = draft,
    })
end

openButton.Activated:Connect(function()
    setFRQContext(nil)
    openPanel()
end)
closeButton.Activated:Connect(closePanel)
sendButton.Activated:Connect(submit)
inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submit()
    end
end)

responseEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end
    if payload.Action == "History" then
        clearMessages()
        local messages = type(payload.Messages) == "table" and payload.Messages or {}
        for _, message in ipairs(messages) do
            addMessage(message.Role, message.Text)
        end
        statusLabel.Text = ""
        if #messages == 0 then
            showWelcomeIfEmpty()
        end
    elseif payload.Action == "Messages" then
        for _, message in ipairs(payload.Messages or {}) do
            if awaitingAcceptance and message.Role == "user" then
                awaitingAcceptance = false
                pendingText = nil
                ActionFeedback.AcceptedClick()
            end
            addMessage(message.Role, message.Text)
        end
        if payload.Complete ~= false then
            setSending(false, "")
        end
    elseif payload.Action == "Status" then
        statusLabel.Text = tostring(payload.Message or "")
    elseif payload.Action == "Error" then
        if awaitingAcceptance and pendingText and inputBox.Text == "" then
            inputBox.Text = pendingText
        end
        pendingText = nil
        if payload.Code == "FRQExpired" then
            setFRQContext(nil)
        end
        awaitingAcceptance = false
        ActionFeedback.Error()
        setSending(false, tostring(payload.Message or UI.T("Support", "Unavailable")))
        if payload.Code == "HistoryLoading" then
            historyRequested = false
        end
    end
end)

setFRQContext(nil)
panel.Visible = false
Entrance.Bind(panel)
openButton.Visible = true
inputBox.Text = ""
