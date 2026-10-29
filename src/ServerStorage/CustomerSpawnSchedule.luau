local Schedule = {}
local areas = { "Main", "Left", "Right" }

local function number(value, fallback, minimum, maximum)
    value = tonumber(value)
    if not value or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

local function baseRange(config)
    local minimum = config.SpawnTimeMin
    local maximum = config.SpawnTimeMax
    if config.TestMode then
        minimum = config.TestSpawnTimeMin
        maximum = config.TestSpawnTimeMax
    end
    minimum = number(minimum, 30, 0.25, 300)
    maximum = number(maximum, math.max(60, minimum), minimum, 300)
    return minimum, maximum
end

local function factor(config, stars, expanded, staffed)
    if expanded and not staffed then
        return 1
    end
    local maximum = number(config.MaxStars, 5, 0, 20)
    stars = math.floor(number(stars, 0, 0, maximum))
    local rate = number(config.SpawnRatePerStar, 1, 0.1, 5)
    return rate ^ stars
end

function Schedule.Range(config, stars, expanded, staffed, multiplier)
    local minimum, maximum = baseRange(config)
    local speed = factor(config, stars, expanded, staffed) * number(multiplier, 1, 0.5, 5)
    return math.clamp(minimum / speed, 0.25, 300), math.clamp(maximum / speed, 0.25, 300)
end

function Schedule.New(config, rng)
    rng = rng or Random.new()
    local self = { Lines = {}, Expanded = nil, LastAt = nil }

    local function newLine(now, speed, minimum, maximum)
        local base = rng:NextNumber(minimum, maximum)
        local interval = math.clamp(base / speed, 0.25, 300)
        return {
            BaseInterval = base,
            Interval = interval,
            NextAt = now + interval,
            Speed = speed,
            Minimum = minimum,
            Maximum = maximum,
        }
    end

    function self:Step(now, state)
        local expanded = state.Expanded == true
        local initial = self.LastAt == nil
        local elapsed = self.LastAt and math.max(0, now - self.LastAt) or 0
        local minimum, maximum = baseRange(config)
        local enabled = expanded and 3 or 1
        local due = {}
        if expanded and self.Expanded == false then
            -- Opening three lines starts fresh base intervals, not old star-rate deadlines.
            table.clear(self.Lines)
        end
        self.Expanded = expanded

        for i, area in ipairs(areas) do
            if i > enabled then
                self.Lines[area] = nil
            else
                local staffed = state.Staffed and state.Staffed[area] == true
                local multiplier = state.Multipliers and state.Multipliers[area]
                local speed = factor(config, state.Stars, expanded, staffed) * number(multiplier, 1, 0.5, 5)
                local line = self.Lines[area]
                if not line then
                    line = newLine(now, speed, minimum, maximum)
                    if initial then
                        if area == "Main" then
                            line.NextAt = math.max(now, state.FirstAt or now)
                            line.FirstArrival = true
                        else
                            line.NextAt = math.max(line.NextAt, state.FirstAt or now)
                        end
                    end
                    self.Lines[area] = line
                else
                    if state.Blocked then
                        line.NextAt += elapsed
                    end
                    if line.Speed ~= speed or line.Minimum ~= minimum or line.Maximum ~= maximum then
                        local fraction = math.clamp((line.NextAt - now) / line.Interval, 0, 1)
                        if line.Minimum ~= minimum or line.Maximum ~= maximum then
                            line.BaseInterval = rng:NextNumber(minimum, maximum)
                        end
                        line.Interval = math.clamp(line.BaseInterval / speed, 0.25, 300)
                        line.Speed, line.Minimum, line.Maximum = speed, minimum, maximum
                        if not line.FirstArrival then
                            -- Keep elapsed progress, and change only this line's remaining wait.
                            line.NextAt = now + fraction * line.Interval
                        end
                    end
                end
                if not state.Blocked and now >= line.NextAt then
                    table.insert(due, area)
                    -- Missed/full-queue arrivals never accumulate into catch-up bursts.
                    self.Lines[area] = newLine(now, speed, minimum, maximum)
                end
            end
        end
        self.LastAt = now
        return due
    end

    return self
end

return Schedule
