local Policy = {}

function Policy.RoomAt(rooms, position)
    if not rooms or not position then
        return nil
    end
    for _, room in ipairs(rooms:GetChildren()) do
        if room:IsA("BasePart") and room:GetAttribute("Enabled") ~= false then
            local point = room.CFrame:PointToObjectSpace(position)
            local half = room.Size / 2
            if
                math.abs(point.X) <= half.X
                and math.abs(point.Y) <= half.Y
                and math.abs(point.Z) <= half.Z
            then
                return room:GetAttribute("RoomId") or room.Name
            end
        end
    end
    return nil
end

function Policy.NeedsHelp(data, first, staffed, active, executiveHelp)
    if not data or not first or not data.ArrivedAt or data.Serving or active then
        return false
    end
    if data.Kind == "BusinessMan" or data.Angry == true or data.PersonalHelp == true then
        return true
    end
    if data.Kind == "Staff" then
        return executiveHelp ~= true
    end
    return not staffed
end

function Policy.Observe(seen, needed, sameRoom)
    if seen or (needed and sameRoom) then
        return true, false
    end
    return false, needed
end

return Policy
