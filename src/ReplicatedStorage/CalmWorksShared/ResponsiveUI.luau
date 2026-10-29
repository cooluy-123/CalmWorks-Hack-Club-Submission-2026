local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local Entrance = require(script.Parent.UIEntrance)

local Responsive = {}
local originals = setmetatable({}, {__mode = "k"})
local readers = setmetatable({}, {__mode = "k"})

local function setting(item, name, fallback, low, high)
    local value = item:GetAttribute(name)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, low, high)
end

local function remember(item)
    if not originals[item] then
        local limit = item:FindFirstChildOfClass("UISizeConstraint")
        originals[item] = {
            Size = item.Size,
            Position = item.Position,
            Minimum = limit and limit.MinSize,
            Maximum = limit and limit.MaxSize,
        }
    end
    return originals[item]
end

function Responsive.Bounds(parent)
    local rect = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
    local origin = parent.AbsolutePosition
    local low = Vector2.new(math.max(0, rect.Min.X - origin.X), math.max(0, rect.Min.Y - origin.Y))
    local high = Vector2.new(math.min(parent.AbsoluteSize.X, rect.Max.X - origin.X), math.min(parent.AbsoluteSize.Y, rect.Max.Y - origin.Y))
    return low, high
end

local textStates = setmetatable({}, {__mode = "k"})

-- The authored Size is a bounding box, not a request to fill the screen.
function Responsive.DesignedSize(size, parentSize, ratio, minimum, maximum)
    local width = math.max(1, size.X.Scale * parentSize.X + size.X.Offset)
    local height = math.max(1, size.Y.Scale * parentSize.Y + size.Y.Offset)
    if minimum and maximum then
        width = math.clamp(width, minimum.X, maximum.X)
        height = math.clamp(height, minimum.Y, maximum.Y)
    end
    if ratio and ratio > 0 then
        width = math.min(width, height * ratio)
        height = width / ratio
    end
    return Vector2.new(width, height)
end

local function baseline(frame)
    local original = remember(frame)
    local reference = frame:GetAttribute("BaselineViewport")
    if typeof(reference) ~= "Vector2" or reference.X <= 0 or reference.Y <= 0 then
        reference = frame.Parent.AbsoluteSize
    end
    local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint")
    local ratio = aspect and aspect.AspectRatio
    local size = Responsive.DesignedSize(original.Size, reference, ratio, original.Minimum, original.Maximum)
    return size, reference
end

function Responsive.CaptureText(frame)
    if textStates[frame] then
        return
    end
    local state = {}
    textStates[frame] = state
    local function capture(item)
        if not (item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox")) then
            return
        end
        if item.Parent.Name == "ReadingScroll" then
            return
        end
        table.insert(state, {
            Item = item,
            Size = item.TextSize,
        })
    end
    for _, item in ipairs(frame:GetDescendants()) do
        capture(item)
    end
    frame.DescendantAdded:Connect(function(item)
        capture(item)
        task.defer(function()
            if frame.Parent then
                Responsive.ScaleText(frame, frame:GetAttribute("CurrentLayoutScale") or 1)
            end
        end)
    end)
end

function Responsive.ScaleText(frame, factor)
    Responsive.CaptureText(frame)
    for _, entry in ipairs(textStates[frame]) do
        local item = entry.Item
        if item.Parent and item:IsDescendantOf(frame) and not item.TextScaled then
            item.TextSize = entry.Size * factor
        end
    end
end

-- This calculation is independent of the last device size, so rotation cannot accumulate scale.
function Responsive.Calculate(baseSize, reference, parentSize, low, high, anchor, position, axis, margin, viewport)
    local space = high - low
    local scaleViewport = viewport or parentSize
    local factor = scaleViewport.X / reference.X
    if axis == "Height" then
        factor = scaleViewport.Y / reference.Y
    end
    factor = math.min(factor, math.max(1, space.X - margin * 2) / baseSize.X, math.max(1, space.Y - margin * 2) / baseSize.Y)
    local size = baseSize * math.max(0.001, factor)
    local desired = Vector2.new(position.X.Scale * parentSize.X + position.X.Offset, position.Y.Scale * parentSize.Y + position.Y.Offset)
    local x = math.clamp(desired.X, low.X + margin + size.X * anchor.X, high.X - margin - size.X * (1 - anchor.X))
    local y = math.clamp(desired.Y, low.Y + margin + size.Y * anchor.Y, high.Y - margin - size.Y * (1 - anchor.Y))
    return size, Vector2.new(x, y), factor
end

function Responsive.Fit(frame)
    if frame:GetAttribute("ResponsiveEnabled") == false then
        return
    end
    Responsive.CaptureText(frame)
    local original = remember(frame)
    local baseSize, reference = baseline(frame)
    local parent = frame.Parent
    local low, high = Responsive.Bounds(parent)
    local margin = setting(frame, "SafeMargin", 8, 0, 40)
    if high.X - low.X <= margin * 2 + 1 or high.Y - low.Y <= margin * 2 + 1 then
        return
    end
    local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint")
    local axis = "Width"
    if aspect and aspect.DominantAxis == Enum.DominantAxis.Height then
        axis = "Height"
    end
    local ratio = aspect and aspect.AspectRatio
    local desiredSize = Responsive.DesignedSize(original.Size, parent.AbsoluteSize, ratio, original.Minimum, original.Maximum)
    local size, position = Responsive.Calculate(desiredSize, parent.AbsoluteSize, parent.AbsoluteSize,
        low, high, frame.AnchorPoint, original.Position, axis, margin, parent.AbsoluteSize)
    local factor = math.min(size.X / baseSize.X, size.Y / baseSize.Y)
    local sizeLimit = frame:FindFirstChildOfClass("UISizeConstraint")
    if sizeLimit then
        -- Runtime constraints must allow the proportional result on small screens.
        sizeLimit.MinSize = Vector2.zero
        sizeLimit.MaxSize = Vector2.new(math.max(sizeLimit.MaxSize.X, size.X), math.max(sizeLimit.MaxSize.Y, size.Y))
    end
    frame.Size = UDim2.fromScale(size.X / parent.AbsoluteSize.X, size.Y / parent.AbsoluteSize.Y)
    frame:SetAttribute("CurrentLayoutScale", factor)
    Responsive.ScaleText(frame, factor)
    Entrance.SetPosition(frame, UDim2.fromScale(position.X / parent.AbsoluteSize.X, position.Y / parent.AbsoluteSize.Y))
end

local function readerRoot(item)
    local parent = item.Parent
    while parent and not parent:IsA("ScreenGui") do
        if typeof(parent:GetAttribute("BaselineSize")) == "Vector2" then
            return parent
        end
        parent = parent.Parent
    end
end

function Responsive.Reader(item)
    if readers[item] then
        return
    end
    local scroll = item:FindFirstChild("ReadingScroll")
    if not scroll then
        return
    end
    readers[item] = true
    local text = scroll:WaitForChild("Content")
    local root = readerRoot(item)
    local function update(reset)
        -- TextScaled labels render themselves; the scroll copy must not override them.
        if item.TextScaled then
            return
        end
        local width = math.max(1, scroll.AbsoluteWindowSize.X - 8)
        local factor = root and root:GetAttribute("CurrentLayoutScale") or 1
        local baseFont = scroll:GetAttribute("ReadableTextSize")
        if type(baseFont) ~= "number" or baseFont ~= baseFont or baseFont <= 0 or baseFont == math.huge then
            baseFont = item.TextSize
        end
        local fontSize = baseFont * factor
        text.Text = item.Text
        text.TextSize = fontSize
        text.TextColor3 = item.TextColor3
        text.FontFace = item.FontFace
        text.RichText = item.RichText
        local bounds = TextService:GetTextSize(text.Text, text.TextSize, text.Font, Vector2.new(width, 100000))
        text.Size = UDim2.new(1, -8, 0, math.max(scroll.AbsoluteWindowSize.Y, bounds.Y + 4))
        scroll.CanvasSize = UDim2.fromOffset(0, bounds.Y + 4)
        scroll.ScrollingEnabled = bounds.Y + 4 > scroll.AbsoluteWindowSize.Y
        if reset then
            scroll.CanvasPosition = Vector2.zero
        end
    end
    local function modeChanged()
        scroll.Visible = not item.TextScaled
        if item.TextScaled then
            item.TextTransparency = item:GetAttribute("OriginalTextTransparency") or 0
        else
            item.TextTransparency = 1
        end
        update(true)
    end
    item:GetPropertyChangedSignal("TextScaled"):Connect(modeChanged)
    item:GetPropertyChangedSignal("Text"):Connect(function()
        update(true)
    end)
    item:GetPropertyChangedSignal("TextColor3"):Connect(function()
        text.TextColor3 = item.TextColor3
    end)
    item:GetPropertyChangedSignal("FontFace"):Connect(function()
        update(false)
    end)
    scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
        update(false)
    end)
    scroll:GetAttributeChangedSignal("ReadableTextSize"):Connect(function()
        update(false)
    end)
    if root then
        root:GetAttributeChangedSignal("CurrentLayoutScale"):Connect(function()
            update(false)
        end)
    end
    modeChanged()
end

function Responsive.BindChoice(button, callback)
    local scroll = button:FindFirstChild("ReadingScroll")
    local start
    if scroll then
        scroll.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                start = {Input = input, Position = input.Position, Canvas = scroll.CanvasPosition}
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if not start then
                return
            end
            local same = input == start.Input or input.UserInputType == Enum.UserInputType.MouseButton1 and start.Input.UserInputType == Enum.UserInputType.MouseButton1
            if not same then
                return
            end
            local moved = (input.Position - start.Position).Magnitude
            local scrolled = (scroll.CanvasPosition - start.Canvas).Magnitude
            local point = Vector2.new(input.Position.X, input.Position.Y) - scroll.AbsolutePosition
            start = nil
            if moved <= 8 and scrolled <= 4 and point.X >= 0 and point.Y >= 0 and point.X <= scroll.AbsoluteSize.X and point.Y <= scroll.AbsoluteSize.Y and button.Interactable then
                callback()
            end
        end)
    end
    button.Activated:Connect(callback)
end

function Responsive.Dialogue(frame)
    Responsive.Fit(frame)
    local frq = frame.FRQFrame
    local entry = frq.EntryScroll
    local content = entry.Content
    local box = content.ResponseBox
    local width = math.max(40, entry.AbsoluteWindowSize.X - 24)
    local bounds = TextService:GetTextSize(box.Text, box.TextSize, box.Font, Vector2.new(width, 100000))
    local height = math.max(setting(entry, "MinimumEntryHeight", 80, 50, 300), bounds.Y + 18)
    box.Size = UDim2.new(1, -16, 0, height)
    content.Size = UDim2.new(1, -6, 0, 56 + height + 4)
    entry.CanvasSize = UDim2.fromOffset(0, 56 + height + 4)
end

function Responsive.Support(panel)
    Responsive.Fit(panel)
    local width, height = panel.AbsoluteSize.X, panel.AbsoluteSize.Y
    local compact = width < 350 or height < 440
    local header = panel.Header
    for _, item in ipairs({header, panel.Messages, panel.Composer, panel.StatusLabel, panel.FRQContextCard}) do
        remember(item)
    end
    if compact then
        header.Size = UDim2.new(1, 0, 0, 48)
        header.Title.Position = UDim2.new(0.04, 0, 0, 5)
        header.Title.Size = UDim2.new(0.78, 0, 0, 21)
        header.Subtitle.Position = UDim2.new(0.04, 0, 0, 27)
        header.Subtitle.Size = UDim2.new(0.9, 0, 0, 16)
        header.CloseButton.Size = UDim2.fromOffset(28, 28)
        header.CloseButton.Position = UDim2.new(1, -20, 0, 19)
        panel.Composer.Position = UDim2.new(0.031387, 0, 1, -39)
        panel.Composer.Size = UDim2.new(0.937225, 0, 0, 34)
        panel.Composer.SendButton.Size = UDim2.fromOffset(28, 28)
        panel.Composer.SendButton.Position = UDim2.new(1, -16, 0.5, 0)
        panel.Composer.InputBox.Size = UDim2.new(1, -38, 1, -6)
        panel.Composer.InputBox.Position = UDim2.fromOffset(3, 3)
        panel.StatusLabel.Position = UDim2.new(0.04, 0, 1, -57)
        panel.StatusLabel.Size = UDim2.new(0.92, 0, 0, 16)
    else
        for _, item in ipairs({header, panel.Composer, panel.StatusLabel}) do
            item.Size, item.Position = originals[item].Size, originals[item].Position
        end
        for _, item in ipairs({header.Title, header.Subtitle, header.CloseButton, panel.Composer.SendButton, panel.Composer.InputBox}) do
            local original = remember(item)
            item.Size, item.Position = original.Size, original.Position
        end
    end
    local top = compact and 52 or height * originals[panel.Messages].Position.Y.Scale + originals[panel.Messages].Position.Y.Offset
    if panel.FRQContextCard.Visible then
        panel.FRQContextCard.Position = UDim2.new(0.026903, 0, 0, top)
        top += panel.FRQContextCard.Size.Y.Offset + setting(panel.FRQContextCard, "BottomGap", 6, 0, 30)
    end
    local bottom = compact and height - 60 or height * 0.826602
    panel.Messages.Position = UDim2.new(0.026903, 0, 0, top)
    panel.Messages.Size = UDim2.new(0.946193, 0, 0, math.max(16, bottom - top))
end

function Responsive.CaptureSupport(panel)
    for _, item in ipairs({panel, panel.Header, panel.Header.Title, panel.Header.Subtitle, panel.Header.CloseButton, panel.Messages, panel.Composer, panel.Composer.SendButton, panel.Composer.InputBox, panel.StatusLabel, panel.FRQContextCard}) do
        remember(item)
    end
end

return Responsive
