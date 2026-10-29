local Policy = {}

function Policy.Choose(state, visitors)
    if not state.Ready or not state.Owns or state.Blocked or state.Banner or state.Ceremony then
        return nil
    end
    local best
    for _, visitor in ipairs(visitors or {}) do
        if visitor.Ready then
            local priority = visitor.Kind == "BusinessMan" and 1
                or (visitor.Staff and 2 or (visitor.Private and 3 or 4))
            if not best or priority < best.Priority
                or (priority == best.Priority and visitor.Distance < best.Distance) then
                best = {
                    Priority = priority,
                    Distance = visitor.Distance,
                    Room = visitor.Room,
                    Key = visitor.Kind == "BusinessMan" and "Mentor"
                        or (visitor.Staff and "Staff" or (visitor.Private and "Private" or "Customer")),
                }
            end
        end
    end
    if best then
        return best
    end
    if state.Helped > 0 and not state.Reviewed then
        return { Key = "Review" }
    end
    if state.ExpansionReady then
        return { Key = "Expansion" }
    end
    if state.Online then
        return { Key = "Online" }
    end
    if state.Helped == 0 then
        return { Key = "Arrival" }
    end
    return { Key = state.Won and "Continue" or "Upgrade" }
end

return Policy
