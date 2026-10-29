local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local hud = script.Parent
local screenGui = hud:FindFirstAncestorWhichIsA("ScreenGui")
local label = hud:WaitForChild("MoneyLabel")
local popup = hud:WaitForChild("CashGainLabel")
local scale = label:WaitForChild("CashPulseScale")
local UI = require(ReplicatedStorage.CalmWorksShared.EditableUI)
local Cash = require(ReplicatedStorage.CalmWorksShared.CashFeedbackMath)
local remote = ReplicatedStorage.CalmWorksRemotes:WaitForChild("CashBalanceChanged")

local originalPosition = label.Position
local originalScale = math.max(0.01, scale.Scale)
local popupTextTransparency = popup.TextTransparency
local popupStrokeTransparency = popup.TextStrokeTransparency
local strokes = {}
for _, item in ipairs(popup:GetDescendants()) do
    if item:IsA("UIStroke") then
        strokes[item] = item.Transparency
    end
end

local displayed = 0
local balance = 0
local sequence = -1
local ready = false
local counter
local pulse
local floating
local renderConnection
local connections = {}
local syncRevision = 0
local destroyed = false
popup.Visible = false

local function number(object, name, fallback, minimum, maximum)
    return Cash.Number(object:GetAttribute(name), fallback, minimum, maximum)
end

local function showMoney(amount)
    displayed = amount
    label.Text = UI.T("HUD", "Money", tostring(amount))
end

local function setPulse(factor)
    -- Keep the center steady without changing the editable anchor or layout.
    local current = math.max(0.001, scale.Scale / originalScale)
    local parentSize = hud.AbsoluteSize
    if parentSize.X > 0 and parentSize.Y > 0 then
        local width = label.AbsoluteSize.X / current / parentSize.X
        local height = label.AbsoluteSize.Y / current / parentSize.Y
        local anchor = label.AnchorPoint
        label.Position = originalPosition + UDim2.fromScale(
            width * (1 - factor) * (0.5 - anchor.X),
            height * (1 - factor) * (0.5 - anchor.Y)
        )
    end
    scale.Scale = originalScale * factor
    if factor == 1 then
        label.Position = originalPosition
    end
end

local function drawPopup(now)
    if not floating then
        return
    end
    local lifetime = number(popup, "LifetimeSeconds", 1, 0.1, 5)
    local elapsed = now - floating.Started
    if elapsed >= lifetime then
        popup.Visible = false
        floating = nil
        return
    end
    local fadeIn = number(popup, "FadeInSeconds", 0.12, 0, lifetime)
    local fadeOut = number(popup, "FadeOutSeconds", 0.3, 0, lifetime)
    local opacity = Cash.Opacity(elapsed, lifetime, fadeIn, fadeOut)
    popup.TextTransparency = 1 - (1 - popupTextTransparency) * opacity
    popup.TextStrokeTransparency = 1 - (1 - popupStrokeTransparency) * opacity
    for stroke, transparency in pairs(strokes) do
        stroke.Transparency = 1 - (1 - transparency) * opacity
    end

    local position = label.AbsolutePosition
    local size = label.AbsoluteSize
    local textWidth = math.min(label.TextBounds.X, size.X)
    local right = position.X + (size.X + textWidth) / 2
    if label.TextXAlignment == Enum.TextXAlignment.Left then
        right = position.X + textWidth
    elseif label.TextXAlignment == Enum.TextXAlignment.Right then
        right = position.X + size.X
    end
    local progress = math.clamp(elapsed / lifetime, 0, 1)
    local startY = number(popup, "StartOffsetPixels", 10, -100, 100)
    local rise = number(popup, "RisePixels", 26, 0, 150)
    local x = right + number(popup, "GapPixels", 8, 0, 100)
    local y = position.Y + size.Y / 2 + startY - rise * progress
    local popupSize = popup.AbsoluteSize
    local camera = workspace.CurrentCamera
    if camera then
        local view = camera.ViewportSize
        local inset = Vector2.zero
        if screenGui and not screenGui.IgnoreGuiInset then
            inset = GuiService:GetGuiInset()
        end
        local left = 4 - inset.X
        local top = popupSize.Y / 2 + 4 - inset.Y
        x = math.clamp(x, left, math.max(left, view.X - inset.X - popupSize.X - 4))
        y = math.clamp(y, top, math.max(top, view.Y - inset.Y - popupSize.Y / 2 - 4))
    end
    local parentSize = hud.AbsoluteSize
    if parentSize.X > 0 and parentSize.Y > 0 then
        -- Ratios also work when an ancestor uses a responsive UIScale.
        popup.Position = UDim2.fromScale(
            (x + popupSize.X * popup.AnchorPoint.X - hud.AbsolutePosition.X) / parentSize.X,
            (y + popupSize.Y * (popup.AnchorPoint.Y - 0.5) - hud.AbsolutePosition.Y) / parentSize.Y
        )
    end
    popup.Visible = true
end

local function stopEffects()
    counter, pulse, floating = nil, nil, nil
    popup.Visible = false
    setPulse(1)
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

local function render()
    local now = os.clock()
    if hud:GetAttribute("CashAnimationsEnabled") == false then
        stopEffects()
        showMoney(balance)
        return
    end
    if counter then
        local value = Cash.Count(counter.From, balance, now - counter.Started, counter.Duration)
        if value ~= displayed then
            showMoney(value)
        end
        if value == balance then
            counter = nil
        end
    end
    if pulse then
        local elapsed = now - pulse.Started
        local factor = Cash.Pulse(elapsed, pulse.Duration, pulse.Peak, pulse.From)
        setPulse(factor)
        if elapsed >= pulse.Duration then
            pulse = nil
        end
    end
    drawPopup(now)
    if not counter and not pulse and not floating and renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

local function receive(newBalance, gain, newSequence, animate)
    if type(newBalance) ~= "number" or newBalance ~= newBalance or math.abs(newBalance) == math.huge then
        return
    end
    if type(newSequence) ~= "number" or newSequence <= sequence then
        return
    end
    sequence = newSequence
    balance = math.max(0, math.floor(newBalance))
    gain = Cash.Number(gain, 0, 0, balance)
    if not animate or not ready or hud:GetAttribute("CashAnimationsEnabled") == false then
        stopEffects()
        showMoney(balance)
        return
    end
    local now = os.clock()
    if gain > 0 then
        local step = number(hud, "CashStepSeconds", 0.025, 0.001, 0.2)
        local maximum = number(hud, "CashMaxCountSeconds", 1.5, 0.1, 5)
        counter = {From = displayed, Started = now, Duration = Cash.Duration(balance - displayed, step, maximum)}
        pulse = {
            Started = now,
            From = scale.Scale / originalScale,
            Duration = number(hud, "CashPulseSeconds", 0.3, 0.05, 2),
            Peak = number(hud, "CashPulseScale", 1.08, 1, 1.25),
        }
        local amount = gain
        if floating and now - floating.Started < number(popup, "LifetimeSeconds", 1, 0.1, 5) then
            amount += floating.Amount
        end
        floating = {Amount = amount, Started = now}
        popup.Text = UI.T("HUD", "CashGain", tostring(amount))
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(render)
        end
        render()
    else
        counter = nil
        showMoney(balance)
    end
end

local function initialize()
    if player:GetAttribute("DataLoaded") ~= true then
        return
    end
    ready = true
    sequence = player:GetAttribute("CashFeedbackSequence") or 0
    balance = math.max(0, math.floor(player:GetAttribute("Money") or 0))
    stopEffects()
    showMoney(balance)
end

table.insert(connections, remote.OnClientEvent:Connect(function(data)
    if type(data) == "table" then
        receive(data.Balance, data.Gain, data.Sequence, true)
    end
end))
table.insert(connections, player:GetAttributeChangedSignal("DataLoaded"):Connect(initialize))
table.insert(connections, player:GetAttributeChangedSignal("Money"):Connect(function()
    syncRevision += 1
    local revision = syncRevision
    -- Attributes are a silent recovery path; only the server's delta event creates an earnings effect.
    task.delay(0.25, function()
        if destroyed or revision ~= syncRevision or not ready then
            return
        end
        receive(player:GetAttribute("Money"), 0, player:GetAttribute("CashFeedbackSequence") or 0, false)
    end)
end))
table.insert(connections, hud:GetAttributeChangedSignal("CashAnimationsEnabled"):Connect(function()
    if hud:GetAttribute("CashAnimationsEnabled") == false then
        stopEffects()
        showMoney(balance)
    end
end))
script.Destroying:Connect(function()
    destroyed = true
    stopEffects()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
end)

showMoney(player:GetAttribute("Money") or 0)
initialize()

