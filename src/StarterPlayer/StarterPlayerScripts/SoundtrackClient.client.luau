local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local config = require(ReplicatedStorage:WaitForChild("SoundtrackConfig"))
local folder = SoundService:WaitForChild("CalmWorksSoundtrack")
local sound = folder:WaitForChild("Track")
local music = folder:WaitForChild("Music")

if folder:GetAttribute("ControllerRunning") then
    return
end
folder:SetAttribute("ControllerRunning", true)

local running = true
script.Destroying:Connect(function()
    running = false
    sound:Stop()
    folder:SetAttribute("ControllerRunning", false)
end)

local function numberSetting(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

local function readSongs(entries, defaultVolume)
    local songs = {}
    local used = {}
    if type(entries) ~= "table" then
        return songs
    end

    for i, entry in ipairs(entries) do
        local id = entry
        local volume = defaultVolume
        if type(entry) == "table" then
            id = entry.SoundId
            volume = numberSetting(entry.Volume, defaultVolume, 0, 10)
        end
        if type(id) == "number" then
            id = tostring(id)
        end
        if type(id) == "string" then
            local digits = string.match(id, "^rbxassetid://(%d+)$") or string.match(id, "^(%d+)$")
            if digits and tonumber(digits) and tonumber(digits) > 0 then
                id = "rbxassetid://" .. digits
                if not used[id] then
                    used[id] = true
                    table.insert(songs, { SoundId = id, Volume = volume, Index = i })
                end
            else
                warn("[CalmWorks Soundtrack] Invalid song entry " .. i .. "; skipping.")
            end
        else
            warn("[CalmWorks Soundtrack] Missing SoundId at entry " .. i .. "; skipping.")
        end
    end
    return songs
end

local function makeOrder(songs, shuffle, previousId, random)
    local order = table.clone(songs)
    if shuffle then
        for i = #order, 2, -1 do
            local j = random:NextInteger(1, i)
            order[i], order[j] = order[j], order[i]
        end
        -- Avoid repeating the last song when a new shuffle starts.
        if #order > 1 and order[1].SoundId == previousId then
            local j = random:NextInteger(2, #order)
            order[1], order[j] = order[j], order[1]
        end
    end
    return order
end

local volume = numberSetting(config.Volume, 0.5, 0, 10)
local fadeTime = numberSetting(config.FadeTime, 1.25, 0, 30)
local gap = numberSetting(config.DelayBetweenSongs, 1, 0, 60)
local loadTimeout = numberSetting(config.LoadTimeout, 10, 1, 30)
local songs = readSongs(config.Songs, volume)
local random = Random.new()
local previousId

sound:Stop()
sound.Looped = false
sound.PlayOnRemove = false
sound.PlaybackRegionsEnabled = false
sound.SoundGroup = music
sound.Volume = 0

if config.Enabled == false or #songs == 0 then
    folder:SetAttribute("State", "Disabled")
    folder:SetAttribute("ControllerRunning", false)
    if #songs == 0 then
        warn("[CalmWorks Soundtrack] No valid songs in SoundtrackConfig.")
    end
    return
end

local function playSong(song)
    sound:Stop()
    sound.Volume = 0
    sound.TimePosition = 0
    sound.SoundId = song.SoundId
    folder:SetAttribute("SongIndex", song.Index)
    folder:SetAttribute("State", "Loading")

    -- An unavailable/private asset must not stall the whole playlist.
    local deadline = os.clock() + loadTimeout
    while running and not sound.IsLoaded and os.clock() < deadline do
        task.wait(0.1)
    end
    if not running then
        return false
    end
    if not sound.IsLoaded or sound.TimeLength <= 0 then
        warn("[CalmWorks Soundtrack] Could not load " .. song.SoundId .. "; skipping.")
        return false
    end

    sound:Play()
    folder:SetAttribute("State", "Playing")
    previousId = song.SoundId
    local startedAt = os.clock()

    while running and sound.Playing do
        local speed = math.max(sound.PlaybackSpeed, 0.01)
        local duration = sound.TimeLength / speed
        local fade = math.min(fadeTime, duration / 2)
        local amount = 1
        if fade > 0 then
            local elapsed = os.clock() - startedAt
            local remaining = math.max(0, sound.TimeLength - sound.TimePosition) / speed
            amount = math.clamp(math.min(elapsed / fade, remaining / fade), 0, 1)
        end
        sound.Volume = song.Volume * amount
        task.wait(0.05)
    end

    sound:Stop()
    sound.Volume = 0
    folder:SetAttribute("State", "BetweenSongs")
    return true
end

while running do
    local played = 0
    local order = makeOrder(songs, config.Shuffle == true, previousId, random)
    for _, song in ipairs(order) do
        if not running then
            break
        end
        if playSong(song) then
            played += 1
            task.wait(gap)
        end
    end

    if running and played == 0 then
        folder:SetAttribute("State", "Retrying")
        -- Back off if every track fails instead of repeatedly flooding requests.
        task.wait(loadTimeout)
    end
end
