local Routing = {}

function Routing.IsUpper(area)
    return area == "UpperLeft" or area == "UpperRight"
end

function Routing.Destination(counters, kind, preferred, upstairs)
    if upstairs and kind == "Angry" then
        return counters:ChooseArea("Upper")
    end
    if preferred and not Routing.IsUpper(preferred) and counters:CanAccept(preferred) then
        return preferred
    end
    if kind == "Rich" then
        local lower = counters:ChooseArea()
        if lower then
            return lower
        end
        if upstairs then
            return counters:ChooseArea("Upper")
        end
    elseif not preferred then
        return counters:ChooseArea()
    end
    return nil
end

return Routing

