local Policy = {}

function Policy.Overlaps(a, b, gap)
    return a.X < b.X + b.W + gap and a.X + a.W + gap > b.X
        and a.Y < b.Y + b.H + gap and a.Y + a.H + gap > b.Y
end

function Policy.Place(rect, occupied, step, attempts, gap, viewport)
    for i = 0, attempts do
        local shift = -i * step
        local nextRect = { X = rect.X, Y = rect.Y + shift, W = rect.W, H = rect.H }
        local clear = nextRect.Y >= 4 and nextRect.Y + nextRect.H <= viewport.Y - 4
        if clear then
            for _, other in ipairs(occupied) do
                if Policy.Overlaps(nextRect, other, gap) then
                    clear = false
                    break
                end
            end
        end
        if clear then
            return shift, nextRect
        end
    end
    return nil
end

return Policy
