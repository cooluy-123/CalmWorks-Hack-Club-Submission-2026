local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tycoon = workspace:WaitForChild("CalmWorksTycoon")
local hoverSound = tycoon:WaitForChild("ui button hover")
local clickSound = tycoon:WaitForChild("ui-simple-button-click")

local HOVER_FACTOR = script:GetAttribute("HoverFactor") or 0.9
local PRESS_FACTOR = script:GetAttribute("PressFactor") or 0.8
local BOUNCE_FACTOR = script:GetAttribute("BounceFactor") or 1.1
local LERP_SPEED = script:GetAttribute("LerpSpeed") or 32

local states = {}

local function playFromStart(sound)
    sound.TimePosition = 0
    sound:Play()
end

local function canUse(button)
    if button:GetAttribute("CalmWorksButtonEffectsDisabled") == true or not button.Interactable then
        return false
    end

    local object = button
    while object and object ~= playerGui do
        if object:IsA("GuiObject") and not object.Visible then
            return false
        elseif object:IsA("LayerCollector") and not object.Enabled then
            return false
        end
        object = object.Parent
    end
    return object == playerGui
end

local function updateTooltip(state)
    local tooltip = state.tooltip
    if tooltip and tooltip.Parent then
        tooltip.Visible = canUse(state.button)
            and (state.hovering or state.selected)
            and not state.tooltipDismissed
            and state.button:GetAttribute("TooltipEnabled") ~= false
    end
end

local function reset(state)
    state.sequence += 1
    state.busy = false
    state.hovering = false
    state.selected = false
    state.pressed = false
    state.current = state.baseScale
    state.target = state.baseScale
    state.scale.Scale = state.baseScale
    updateTooltip(state)
end

local function waitForScale(state, goal, timeout)
    local started = os.clock()
    repeat
        RunService.RenderStepped:Wait()
    until math.abs(state.current - goal) <= 0.015 or os.clock() - started >= timeout
end

local function animateClick(state)
    state.sequence += 1
    local sequence = state.sequence
    state.busy = true

    state.target = state.baseScale * PRESS_FACTOR
    waitForScale(state, state.target, 0.11)
    if sequence ~= state.sequence then
        return
    end

    state.target = state.baseScale * BOUNCE_FACTOR
    waitForScale(state, state.target, 0.14)
    if sequence ~= state.sequence then
        return
    end

    state.target = state.baseScale
    waitForScale(state, state.target, 0.13)
    if sequence ~= state.sequence then
        return
    end
    state.busy = false
end

local function attach(button)
    if states[button] or button:GetAttribute("CalmWorksButtonEffectsDisabled") == true then
        return
    end
    local screen = button:FindFirstAncestorWhichIsA("ScreenGui")
    if not screen or not screen.Name:match("^CalmWorks") then
        return
    end

    local scale = button:FindFirstChild("CalmWorksButtonLerpScale")
    if not scale or not scale:IsA("UIScale") then
        warn("Add a CalmWorksButtonLerpScale UIScale in Studio to animate " .. button:GetFullName())
        return
    end

    local state = {
        button = button,
        scale = scale,
        baseScale = scale.Scale,
        current = scale.Scale,
        target = scale.Scale,
        hovering = false,
        selected = false,
        pressed = false,
        tooltipDismissed = false,
        tooltip = button:FindFirstChild("Tooltip"),
        busy = false,
        sequence = 0,
    }
    states[button] = state

    if state.tooltip and not state.tooltip:IsA("GuiObject") then
        state.tooltip = nil
    end
    updateTooltip(state)

    local function hover(active, selected)
        if selected then
            state.selected = active
        else
            state.hovering = active
        end
        state.tooltipDismissed = false
        updateTooltip(state)
        if not canUse(button) then
            reset(state)
            return
        end
        if not state.busy and not state.pressed then
            if state.hovering or state.selected then
                state.target = state.baseScale * HOVER_FACTOR
                if active then
                    playFromStart(hoverSound)
                end
            else
                state.target = state.baseScale
            end
        end
    end

    button.MouseEnter:Connect(function()
        hover(true, false)
    end)
    button.MouseLeave:Connect(function()
        hover(false, false)
    end)
    button.SelectionGained:Connect(function()
        hover(true, true)
    end)
    button.SelectionLost:Connect(function()
        hover(false, true)
    end)

    button.InputBegan:Connect(function(input)
        if state.busy or not canUse(button) then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            state.pressed = true
            state.target = state.baseScale * PRESS_FACTOR
        end
    end)

    button.Activated:Connect(function()
        if not canUse(button) then
            return
        end
        state.pressed = false
        state.tooltipDismissed = true
        updateTooltip(state)
        -- Action buttons supply success/error audio after their own validation.
        if button:GetAttribute("CalmWorksActionManagedAudio") ~= true then
            playFromStart(clickSound)
        end
        task.spawn(animateClick, state)
    end)

    button.Destroying:Connect(function()
        states[button] = nil
    end)
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
    if descendant:IsA("GuiButton") then
        attach(descendant)
    end
end

playerGui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("GuiButton") then
        task.defer(attach, descendant)
    end
end)

-- A press dragged off a button should not leave it stuck at 0.8x.
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    for _, state in pairs(states) do
        if state.pressed then
            state.pressed = false
            if not state.busy then
                state.target = state.baseScale
                if state.hovering or state.selected then
                    state.target = state.baseScale * HOVER_FACTOR
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    local alpha = 1 - math.exp(-LERP_SPEED * deltaTime)
    for button, state in pairs(states) do
        if button.Parent then
            if not canUse(button) then
                if state.current ~= state.baseScale or state.hovering or state.selected or state.busy or state.pressed then
                    reset(state)
                end
                updateTooltip(state)
                continue
            end
            updateTooltip(state)
            state.current += (state.target - state.current) * alpha
            state.scale.Scale = state.current
        else
            states[button] = nil
        end
    end
end)
