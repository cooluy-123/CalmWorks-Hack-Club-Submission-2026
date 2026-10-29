local PathfindingService = game:GetService("PathfindingService")
local Navigation = {}
local computing = 0

local function reached(root, position)
    local flat = Vector3.new(root.Position.X, position.Y, root.Position.Z)
    return (flat - position).Magnitude < 1.6 and math.abs(root.Position.Y - position.Y) < 4.5
end

function Navigation.Walk(model, target, valid)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return false
    end
    if reached(root, target) then
        return true
    end

    for attempt = 1, 3 do
        local deadline = os.clock() + 20
        while computing >= 4 and valid() and os.clock() < deadline do
            task.wait(0.1)
        end
        if not valid() or os.clock() >= deadline then
            return false
        end
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4,
        })
        computing += 1
        local okay = pcall(function()
            path:ComputeAsync(root.Position, target)
        end)
        computing -= 1
        if not valid() then
            path:Destroy()
            return false
        end

        local finished = false
        if okay and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            local current = 1
            local blocked = false
            local connection = path.Blocked:Connect(function(index)
                if index >= current then
                    blocked = true
                end
            end)
            finished = true
            for i, waypoint in ipairs(waypoints) do
                current = i
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end
                if not reached(root, waypoint.Position) then
                    local untilTime = os.clock() + 8
                    local nextMove = 0
                    while valid() and not blocked and os.clock() < untilTime do
                        if reached(root, waypoint.Position) then
                            break
                        end
                        if os.clock() >= nextMove then
                            if waypoint.Action == Enum.PathWaypointAction.Jump then
                                humanoid.Jump = true
                            end
                            humanoid:MoveTo(waypoint.Position)
                            nextMove = os.clock() + 2
                        end
                        task.wait(0.1)
                    end
                    if not valid() or blocked or not reached(root, waypoint.Position) then
                        finished = false
                        break
                    end
                end
            end
            connection:Disconnect()
        end
        path:Destroy()
        if finished and reached(root, target) then
            return true
        end
        if not valid() then
            return false
        end
        task.wait(0.2 * attempt)
    end
    return false
end

function Navigation.Route(model, folder, reverse, data, valid)
    local markers = folder and folder:GetChildren() or {}
    table.sort(markers, function(a, b)
        if reverse then
            return a.Name > b.Name
        end
        return a.Name < b.Name
    end)
    local first = data and data.RouteIndex or 1
    for i = first, #markers do
        if not Navigation.Walk(model, markers[i].Position, valid) then
            return false
        end
        if data then
            data.RouteIndex = i + 1
        end
    end
    return #markers > 0
end

return Navigation

