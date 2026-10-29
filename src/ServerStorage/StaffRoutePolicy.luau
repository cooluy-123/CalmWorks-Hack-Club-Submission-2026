local Policy = {}

local function route(points, area, first, last)
    local room = points:FindFirstChild(area)
    local inbound = room and room:FindFirstChild("Inbound")
    if not inbound then
        return nil
    end
    local steps = {}
    for i = first, last do
        local marker = inbound:FindFirstChild(string.format("%02d", i))
        if not marker or not marker:IsA("BasePart") then
            return nil
        end
        steps[i] = marker.Position
    end
    return steps
end

local function distance(a, b)
    local offset = Vector3.new(a.X - b.X, 0, a.Z - b.Z)
    return offset.Magnitude
end

function Policy.Build(points, position, destination, nearest)
    local target = route(points, destination, 7, 8)
    if not target then
        return nil
    end
    local selected
    local steps
    local closest = math.huge
    local choices = {destination}
    if nearest ~= false then
        table.insert(choices, destination == "UpperLeft" and "UpperRight" or "UpperLeft")
    end
    for _, area in ipairs(choices) do
        local candidate = route(points, area, 3, 7)
        if candidate then
            local length = distance(position, candidate[3])
            if length < closest then
                selected = area
                steps = candidate
                closest = length
            end
        end
    end
    if not selected then
        return nil
    end

    local result = {}
    for i = 3, 7 do
        table.insert(result, steps[i])
    end
    -- Cross the lobby after the stairs, not diagonally across the stairwell opening.
    if selected ~= destination then
        table.insert(result, target[7])
    end
    table.insert(result, target[8])
    return {Stairway = selected, Points = result}
end

return Policy