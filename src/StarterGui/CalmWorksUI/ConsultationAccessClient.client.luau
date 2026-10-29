local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local supportGui = player.PlayerGui:WaitForChild("CalmWorksSupportUI")
local effects = player.PlayerGui:WaitForChild("CalmWorksFullScreenEffects")
local remotes = ReplicatedStorage:WaitForChild("CalmWorksRemotes")
local feedback = require(ReplicatedStorage.CalmWorksShared.ActionFeedback)
local Entrance = require(ReplicatedStorage.CalmWorksShared.UIEntrance)
local button = gui:WaitForChild("OnlineConsultationsButton")
local accuracy = gui:WaitForChild("AccuracyButton")
local support = supportGui:WaitForChild("OpenSupportButton")
local blockers = {
    gui:WaitForChild("Dialogue"),
    gui:WaitForChild("AccuracyPanel"),
    supportGui:WaitForChild("SupportPanel"),
    effects:WaitForChild("TutorialOverlay"),
    effects:WaitForChild("BusinessVisitOverlay"),
    effects:WaitForChild("FeedbackOverlay"),
    effects:WaitForChild("FRQFeedbackOverlay"),
}
local pending = false
local request = 0
local lastClick = -math.huge
local connections = {}
local buttonSizes = {}
for _, item in ipairs({accuracy, support, button}) do
    buttonSizes[item] = item.Size
end

local function connect(signal, callback)
    table.insert(connections, signal:Connect(callback))
end

local function setting(name, fallback, low, high)
    local value = gui:GetAttribute(name)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, low, high)
end

local function unlocked()
    return player:GetAttribute("DataLoaded") == true
        and player:GetAttribute("OnlineConsultationsUnlocked") == true
end

local function blocked()
    for _, frame in ipairs(blockers) do
        if frame.Visible then
            return true
        end
    end
    return false
end

local function refresh()
    local available = unlocked()
    local hidden = blocked()
    button.Visible = available and not hidden
    accuracy.Visible = not hidden
    support.Visible = not hidden
    if gui:GetAttribute("QuickButtonsAutoLayout") == false then
        return
    end
    local buttons = {accuracy, support}
    if available then
        table.insert(buttons, button)
    end
    local center = setting("QuickButtonsCenterY", 0.5, 0.2, 0.8)
    local spacing = setting("QuickButtonsSpacingY", 0.084, 0.06, 0.15)
    local x = setting("QuickButtonsLeftX", 0.0265, 0, 0.8)
    local height = math.max(gui.AbsoluteSize.Y, 1)
    local minimum = setting("QuickButtonsMinimumPixels", 36, 24, 64)
    local gap = setting("QuickButtonsMinimumGap", 10, 4, 24)
    local side = math.max(minimum, buttonSizes[accuracy].Y.Scale * height + buttonSizes[accuracy].Y.Offset)
    side = math.min(side, height / 5)
    spacing = math.max(spacing, (side * 1.1 + gap) / height)
    for i, item in ipairs(buttons) do
        item.Size = UDim2.fromOffset(side, side)
        local scale = item:FindFirstChild("CalmWorksButtonLerpScale")
        local factor = 1
        if scale and scale:IsA("UIScale") then
            factor = math.max(scale.Scale, 0.01)
        end
        -- LeftX remains the resting left edge; animations pivot around the center.
        local halfWidth = item.AbsoluteSize.X / factor / 2
        local parentWidth = math.max(item.Parent.AbsoluteSize.X, 1)
        Entrance.SetPosition(item, UDim2.fromScale(x + halfWidth / parentWidth, center + (i - (#buttons + 1) / 2) * spacing))
    end
end

connect(button.Activated, function()
    if not unlocked() or blocked() then
        feedback.Error()
        return
    end
    if pending or os.clock() - lastClick < 1 then
        return
    end
    lastClick = os.clock()
    pending = true
    request += 1
    local current = request
    remotes.OpenDashboard:FireServer()
    task.delay(4, function()
        if request == current then
            pending = false
        end
    end)
end)
connect(remotes.OpenDialogue.OnClientEvent, function(data)
    if type(data) == "table" and data.IsDashboard and not data.Closed and pending then
        pending = false
        feedback.AcceptedClick()
    end
end)
connect(remotes.ActionRejected.OnClientEvent, function()
    pending = false
end)
connect(player:GetAttributeChangedSignal("DataLoaded"), refresh)
connect(player:GetAttributeChangedSignal("OnlineConsultationsUnlocked"), refresh)
for _, frame in ipairs(blockers) do
    connect(frame:GetPropertyChangedSignal("Visible"), refresh)
end
for _, name in ipairs({"QuickButtonsAutoLayout", "QuickButtonsCenterY", "QuickButtonsSpacingY", "QuickButtonsLeftX"}) do
    connect(gui:GetAttributeChangedSignal(name), refresh)
end
script.Destroying:Connect(function()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
end)
for _, item in ipairs({accuracy, support, button}) do
    connect(item:GetPropertyChangedSignal("AbsoluteSize"), refresh)
end
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), refresh)
refresh()

for _, item in ipairs({accuracy, support, button}) do
    Entrance.Bind(item)
end
local entranceReady = false
local function showInitialButtons()
    if entranceReady or player:GetAttribute("DataLoaded") ~= true
        or player:GetAttribute("CalmWorksLoadingComplete") == false then
        return
    end
    entranceReady = true
    for _, item in ipairs({accuracy, support, button}) do
        if item.Visible then
            Entrance.Play(item)
        end
    end
end
connect(player:GetAttributeChangedSignal("DataLoaded"), showInitialButtons)
connect(player:GetAttributeChangedSignal("CalmWorksLoadingComplete"), showInitialButtons)
showInitialButtons()
