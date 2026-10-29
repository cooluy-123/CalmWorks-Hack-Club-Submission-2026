-- Shared text/layout helpers. Wording lives in the saved UIText StringValues.
local UI = {}
local catalog = script.Parent:WaitForChild("UIText")
local warned = {}

function UI.T(group, key, ...)
    local folder = catalog:FindFirstChild(group)
    local value
    if folder then
        value = folder:FindFirstChild(key)
    end
    if not value or not value:IsA("StringValue") then
        local id = group .. "." .. key
        if not warned[id] then
            warned[id] = true
            warn("Missing editable UI text: " .. id)
        end
        return ""
    end
    if select("#", ...) == 0 then
        return value.Value
    end
    local ok, result = pcall(string.format, value.Value, ...)
    if ok then
        return result
    end
    -- A typo in editable placeholders must not interrupt gameplay or saving.
    local id = group .. "." .. key .. ":" .. value.Value
    if not warned[id] then
        warned[id] = true
        warn("Check editable UI placeholders: " .. value:GetFullName())
    end
    return value.Value
end

function UI.Sequence(group)
    local folder = catalog:FindFirstChild(group)
    local values = {}
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("StringValue") then
                table.insert(values, v)
            end
        end
    end
    table.sort(values, function(a, b)
        return a.Name < b.Name
    end)
    local result = {}
    for _, v in ipairs(values) do
        table.insert(result, v.Value)
    end
    return result
end

function UI.CaptureLayout(objects)
    local saved = {}
    for _, object in ipairs(objects) do
        local props = { Size = object.Size, Position = object.Position }
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            props.TextSize = object.TextSize
            props.TextWrapped = object.TextWrapped
            props.TextTruncate = object.TextTruncate
            props.TextXAlignment = object.TextXAlignment
        end
        if object:IsA("ScrollingFrame") then
            props.CanvasSize = object.CanvasSize
        end
        saved[object] = props
    end
    return saved
end

function UI.RestoreLayout(saved)
    for object, props in pairs(saved) do
        if object.Parent then
            for name, value in pairs(props) do
                object[name] = value
            end
        end
    end
end

return UI
