local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local blur = Lighting:WaitForChild("CalmWorksBlur")
local tag = "CalmWorksFocusPanel"
local panels = {}
local connections = {}
local tween
local revision = 0
local targetSize = 0
local queued = false
local stopped = false

local function number(value, fallback, low, high)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, low, high)
end

local function visible(panel)
    if not panel:IsDescendantOf(playerGui) or panel:GetAttribute("BackgroundBlurEnabled") == false then
        return false
    end

    local current = panel
    local screen = false
    while current and current ~= playerGui do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        if current:IsA("ScreenGui") then
            screen = true
            if not current.Enabled then
                return false
            end
        end
        current = current.Parent
    end
    return screen
end

local function apply(size)
    if size == targetSize then
        return
    end
    targetSize = size
    revision += 1
    local currentRevision = revision
    if tween then
        tween:Cancel()
        tween = nil
    end

    local seconds = number(blur:GetAttribute("FadeSeconds"), 0.18, 0, 1)
    if size > 0 then
        blur.Enabled = true
    end
    if seconds == 0 then
        blur.Size = size
        blur.Enabled = size > 0
        return
    end

    local active = TweenService:Create(blur, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = size})
    tween = active
    active.Completed:Once(function(state)
        -- An older fade must not disable a newly opened panel's blur.
        if stopped or revision ~= currentRevision or state ~= Enum.PlaybackState.Completed then
            return
        end
        if size == 0 then
            blur.Enabled = false
        end
        if tween == active then
            tween = nil
        end
    end)
    active:Play()
end

local function update()
    queued = false
    if stopped then
        return
    end

    local size = 0
    if blur:GetAttribute("FocusEnabled") ~= false then
        local normal = number(blur:GetAttribute("FocusSize"), 6, 0, 56)
        for panel in pairs(panels) do
            if visible(panel) then
                local requested = number(panel:GetAttribute("BackgroundBlurSize"), normal, 0, 56)
                size = math.max(size, requested)
            end
        end
    end
    apply(size)
end

local function schedule()
    if queued or stopped then
        return
    end
    queued = true
    task.defer(update)
end

local function disconnect(list)
    for _, connection in ipairs(list) do
        connection:Disconnect()
    end
    table.clear(list)
end

local function untrack(panel)
    local entry = panels[panel]
    if entry then
        disconnect(entry.Connections)
        disconnect(entry.Ancestors)
        panels[panel] = nil
        schedule()
    end
end

local function watchAncestors(panel, entry)
    disconnect(entry.Ancestors)
    local current = panel
    while current and current ~= playerGui do
        if current:IsA("GuiObject") then
            table.insert(entry.Ancestors, current:GetPropertyChangedSignal("Visible"):Connect(schedule))
        elseif current:IsA("ScreenGui") then
            table.insert(entry.Ancestors, current:GetPropertyChangedSignal("Enabled"):Connect(schedule))
        end
        current = current.Parent
    end
end

local function track(panel)
    if panels[panel] or not panel:IsA("GuiObject") or not panel:IsDescendantOf(playerGui) then
        return
    end
    local entry = {Connections = {}, Ancestors = {}}
    panels[panel] = entry
    watchAncestors(panel, entry)
    table.insert(entry.Connections, panel:GetAttributeChangedSignal("BackgroundBlurEnabled"):Connect(schedule))
    table.insert(entry.Connections, panel:GetAttributeChangedSignal("BackgroundBlurSize"):Connect(schedule))
    table.insert(entry.Connections, panel.AncestryChanged:Connect(function()
        if not panel:IsDescendantOf(playerGui) then
            untrack(panel)
            return
        end
        watchAncestors(panel, entry)
        schedule()
    end))
    schedule()
end

-- This is a local presentation effect; gameplay and other Lighting effects are untouched.
blur.Enabled = false
blur.Size = 0
table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(track))
table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack))
table.insert(connections, playerGui.DescendantAdded:Connect(function(object)
    if CollectionService:HasTag(object, tag) then
        track(object)
    end
end))
for _, panel in ipairs(CollectionService:GetTagged(tag)) do
    track(panel)
end
for _, name in ipairs({"FocusEnabled", "FocusSize", "FadeSeconds"}) do
    table.insert(connections, blur:GetAttributeChangedSignal(name):Connect(schedule))
end
table.insert(connections, script.Destroying:Connect(function()
    stopped = true
    revision += 1
    if tween then
        tween:Cancel()
    end
    disconnect(connections)
    for _, entry in pairs(panels) do
        disconnect(entry.Connections)
        disconnect(entry.Ancestors)
    end
    table.clear(panels)
    blur.Size = 0
    blur.Enabled = false
end))
schedule()
