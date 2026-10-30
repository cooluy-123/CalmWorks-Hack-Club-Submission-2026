local HttpService = game:GetService("HttpService")
local SessionStore = {}

local function revision(value)
    local n = type(value) == "table" and value.SaveRevision or nil
    if type(n) ~= "number" or n ~= n or n < 0 or n == math.huge then
        return 0
    end
    return math.floor(n)
end

local function metadata(info)
    if info then
        return info:GetUserIds(), info:GetMetadata()
    end
    return {}, {}
end

function SessionStore.New(store, config, version)
    local self = {
        Store = store,
        Version = version,
        LeaseSeconds = math.clamp(tonumber(config.DataSessionLeaseSeconds) or 120, 60, 600),
        WaitSeconds = math.clamp(tonumber(config.DataSessionWaitSeconds) or 20, 0, 25),
        Retries = math.clamp(math.floor(tonumber(config.DataStoreRetries) or 3), 1, 5),
    }

    function self:Acquire(key, active)
        local id = HttpService:GenerateGUID(false)
        local deadline = os.clock() + self.WaitSeconds
        local failures = 0
        local reason = "Busy"

        repeat
            if active and not active() then
                return nil, "Cancelled"
            end
            local okay, saved = pcall(function()
                return self.Store:UpdateAsync(key, function(previous, info)
                    if previous ~= nil and type(previous) ~= "table" then
                        reason = "InvalidData"
                        return nil
                    end
                    if previous and type(previous.Version) == "number" and previous.Version > self.Version then
                        reason = "NewerVersion"
                        return nil
                    end
                    local lock = previous and previous.SaveSession
                    if type(lock) == "table" and lock.Id ~= id
                        and type(lock.ExpiresAt) == "number" and lock.ExpiresAt > os.time() then
                        reason = "Busy"
                        return nil
                    end

                    local result = table.clone(previous or {})
                    result.SaveSession = { Id = id, ExpiresAt = os.time() + self.LeaseSeconds }
                    result.SaveRevision = revision(previous)
                    local users, meta = metadata(info)
                    return result, users, meta
                end)
            end)
            if okay and type(saved) == "table" and saved.SaveSession and saved.SaveSession.Id == id then
                return {
                    Key = key,
                    Id = id,
                    Revision = revision(saved),
                    LastSavedAt = os.clock(),
                    Released = false,
                }, saved
            end
            if not okay then
                failures += 1
                reason = "Unavailable"
                if failures >= self.Retries then
                    return nil, reason
                end
            elseif reason ~= "Busy" then
                return nil, reason
            end
            if os.clock() >= deadline then
                break
            end
            task.wait(math.min(2, math.max(0, deadline - os.clock())))
        until false

        return nil, reason
    end

    function self:NeedsRenewal(lease)
        return not lease.Released and os.clock() - lease.LastSavedAt >= self.LeaseSeconds / 3
    end

    function self:Flush(lease)
        local operation = lease.Pending
        if not operation then
            return false, "NoPendingSave"
        end
        for attempt = 1, self.Retries do
            local observed
            local reason = "Conflict"
            local okay, saved = pcall(function()
                return self.Store:UpdateAsync(lease.Key, function(previous, info)
                    observed = nil
                    reason = "Conflict"
                    -- A timed-out request may already have committed. Never apply it twice.
                    if type(previous) == "table" and previous.SaveCommitId == operation.Id then
                        observed = previous
                        reason = "Committed"
                        return nil
                    end
                    local lock = type(previous) == "table" and previous.SaveSession
                    if type(lock) ~= "table" or lock.Id ~= lease.Id
                        or revision(previous) ~= operation.Revision then
                        return nil
                    end
                    local result = table.clone(previous)
                    if operation.Snapshot then
                        for key, value in pairs(operation.Snapshot) do
                            result[key] = value
                        end
                    end
                    result.SaveRevision = operation.Revision + 1
                    result.SaveCommitId = operation.Id
                    if operation.Release then
                        result.SaveSession = nil
                    else
                        result.SaveSession = { Id = lease.Id, ExpiresAt = os.time() + self.LeaseSeconds }
                    end
                    local users, meta = metadata(info)
                    return result, users, meta
                end)
            end)
            if okay then
                local committed = observed or saved
                if type(committed) == "table" and committed.SaveCommitId == operation.Id then
                    lease.Revision = revision(committed)
                    lease.LastSavedAt = os.clock()
                    lease.Released = operation.Release
                    lease.Pending = nil
                    return true, committed
                end
                return false, reason
            end
            if attempt < self.Retries then
                task.wait(attempt)
            end
        end
        return false, "Unavailable"
    end

    function self:Save(lease, snapshot, release)
        if lease.Released then
            return false, "Released"
        end
        if lease.Pending then
            local okay, saved = self:Flush(lease)
            if not okay or lease.Released then
                return okay, saved
            end
        end
        lease.Pending = {
            Id = HttpService:GenerateGUID(false),
            Revision = lease.Revision,
            Snapshot = snapshot,
            Release = release == true,
        }
        return self:Flush(lease)
    end

    return self
end

return SessionStore
