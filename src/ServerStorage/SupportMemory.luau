local Memory = {}

function Memory.New()
    local self = { Snapshot = nil, CapturedAt = -math.huge, Refreshing = false }

    function self:Get(now, interval, ready, capture)
        local loaded = self.Snapshot and self.Snapshot.DataLoaded == true
        local due = not self.Snapshot or now - self.CapturedAt >= interval or (ready and not loaded)
        if due and not self.Refreshing then
            self.Refreshing = true
            local okay, state = pcall(capture)
            self.Refreshing = false
            if okay and type(state) == "table" then
                self.Snapshot = state
                self.CapturedAt = now
            end
        end
        return self.Snapshot
    end

    return self
end

return Memory
