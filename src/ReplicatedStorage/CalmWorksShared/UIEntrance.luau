local RunService = game:GetService("RunService")

local Entrance = {}
local states = {}
local active = {}

local function number(frame, name, fallback, low, high)
    local value = frame:GetAttribute(name)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, low, high)
end

local function shown(frame)
    local item = frame
    while item do
        if item:IsA("GuiObject") and not item.Visible then
            return false
        elseif item:IsA("LayerCollector") and not item.Enabled then
            return false
        end
        item = item.Parent
    end
    return frame.Parent ~= nil
end

local function addProperty(state, item, property)
    local value = item[property]
    table.insert(state.values, {
        Item = item,
        Property = property,
        Base = value,
        Written = value,
    })
end

local function capture(state, item)
    if state.captured[item] then
        return
    end
    state.captured[item] = true
    if item:IsA("GuiObject") then
        addProperty(state, item, "BackgroundTransparency")
    end
    if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
        addProperty(state, item, "TextTransparency")
        addProperty(state, item, "TextStrokeTransparency")
    elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then
        addProperty(state, item, "ImageTransparency")
    end
    if item:IsA("ScrollingFrame") then
        addProperty(state, item, "ScrollBarImageTransparency")
    elseif item:IsA("UIStroke") then
        addProperty(state, item, "Transparency")
    elseif item:IsA("CanvasGroup") then
        addProperty(state, item, "GroupTransparency")
    end
end

local function opacity(state, amount)
    for _, value in ipairs(state.values) do
        local item = value.Item
        if item.Parent and (item == state.frame or item:IsDescendantOf(state.frame)) then
            local current = item[value.Property]
            -- Preserve a result outline, chart update or message arriving during the fade.
            if math.abs(current - value.Written) > 0.00001 then
                value.Base = current
            end
            local target = 1 - (1 - value.Base) * amount
            if current ~= target then
                item[value.Property] = target
            end
            value.Written = item[value.Property]
        end
    end
end

local function position(state, amount)
    local frame = state.frame
    local goal = state.goal
    local start = goal + UDim2.fromOffset(state.offsetX or 0, state.offsetY or 0)
    if frame:GetAttribute("OpenAnimationFromBottom") == true then
        start = UDim2.new(goal.X.Scale, goal.X.Offset + (state.offsetX or 0), 1, state.offsetY or 0)
    end
    state.writtenPosition = start:Lerp(goal, amount)
    frame.Position = state.writtenPosition
end

local function finish(state)
    active[state.frame] = nil
    state.running = false
    if state.added then
        state.added:Disconnect()
        state.added = nil
    end
    opacity(state, 1)
    state.values = {}
    state.captured = {}
    state.amount = 1
    state.writtenPosition = state.goal
    state.frame.Position = state.goal
end

function Entrance.SetPosition(frame, goal)
    local state = states[frame]
    if not state then
        frame.Position = goal
        return
    end
    state.goal = goal
    position(state, state.amount or 1)
end

function Entrance.Finish(frame)
    local state = states[frame]
    if state and state.running then
        finish(state)
    end
end

function Entrance.Play(frame)
    local state = states[frame]
    if not state then
        Entrance.Bind(frame, false)
        state = states[frame]
    end
    if state.running then
        finish(state)
    end
    if not shown(frame) then
        return
    end

    local seconds = number(frame, "OpenAnimationSeconds", 0.25, 0, 2)
    if frame:GetAttribute("OpenAnimationEnabled") == false or seconds == 0 then
        return
    end
    state.values = {}
    state.captured = {}
    capture(state, frame)
    for _, item in ipairs(frame:GetDescendants()) do
        capture(state, item)
    end
    state.added = frame.DescendantAdded:Connect(function(item)
        if state.running then
            capture(state, item)
            opacity(state, state.amount)
        end
    end)
    state.duration = seconds
    state.elapsed = 0
    state.amount = 0
    state.offsetX = number(frame, "OpenAnimationOffsetX", 0, -300, 300)
    state.offsetY = number(frame, "OpenAnimationOffset", 30, -300, 300)
    state.running = true
    active[frame] = state
    opacity(state, 0)
    position(state, 0)
end

function Entrance.Bind(frame, automatic)
    if states[frame] then
        return
    end
    local state = {
        frame = frame,
        goal = frame.Position,
        writtenPosition = frame.Position,
        amount = 1,
        values = {},
        captured = {},
        connections = {},
    }
    states[frame] = state
    table.insert(state.connections, frame:GetPropertyChangedSignal("Position"):Connect(function()
        if frame.Position ~= state.writtenPosition then
            state.goal = frame.Position
            position(state, state.amount)
        end
    end))
    table.insert(state.connections, frame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not frame.Visible then
            Entrance.Finish(frame)
        elseif automatic ~= false then
            Entrance.Play(frame)
        end
    end))
    local screen = frame:FindFirstAncestorWhichIsA("ScreenGui")
    if screen then
        table.insert(state.connections, screen:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not screen.Enabled then
                Entrance.Finish(frame)
            elseif automatic ~= false and frame.Visible then
                Entrance.Play(frame)
            end
        end))
    end
    table.insert(state.connections, frame:GetAttributeChangedSignal("OpenAnimationEnabled"):Connect(function()
        if frame:GetAttribute("OpenAnimationEnabled") == false then
            Entrance.Finish(frame)
        end
    end))
    table.insert(state.connections, frame.Destroying:Connect(function()
        active[frame] = nil
        if state.added then
            state.added:Disconnect()
        end
        for _, connection in ipairs(state.connections) do
            connection:Disconnect()
        end
        states[frame] = nil
    end))
end

RunService.RenderStepped:Connect(function(deltaTime)
    for frame, state in pairs(active) do
        if not shown(frame) then
            finish(state)
        else
            state.elapsed += deltaTime
            local progress = math.clamp(state.elapsed / state.duration, 0, 1)
            state.amount = 1 - (1 - progress) ^ 2
            opacity(state, state.amount)
            position(state, state.amount)
            if progress >= 1 then
                finish(state)
            end
        end
    end
end)

return Entrance
