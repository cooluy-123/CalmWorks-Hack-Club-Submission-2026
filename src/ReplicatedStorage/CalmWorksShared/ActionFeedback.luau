-- One cached client module shares a cooldown across prompts, quiz UI and support UI.
-- The editable sound remains in Workspace > CalmWorksTycoon > Error Sound Effect.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Feedback = {}
local lastErrorAt = -math.huge
local warnedMissing = false

function Feedback.Error()
    if not RunService:IsClient() then
        return false
    end
    local tycoon = workspace:FindFirstChild("CalmWorksTycoon")
    local sound = tycoon and tycoon:FindFirstChild("Error Sound Effect")
    if not sound or not sound:IsA("Sound") then
        if not warnedMissing then
            warnedMissing = true
            warn("CalmWorks error feedback: restore the editable Error Sound Effect sound.")
        end
        return false
    end
    if sound:GetAttribute("FeedbackEnabled") == false then
        return false
    end
    local cooldown = sound:GetAttribute("FeedbackCooldownSeconds")
    if type(cooldown) ~= "number" or cooldown ~= cooldown then
        cooldown = 0.65
    end
    cooldown = math.clamp(cooldown, 0.1, 5)
    local now = os.clock()
    if now - lastErrorAt < cooldown then
        return false
    end
    lastErrorAt = now
    -- Client playback only: another player's rejected action cannot play this sound here.
    sound.TimePosition = 0
    sound:Play()
    return true
end

function Feedback.AcceptedClick()
    if not RunService:IsClient() then
        return
    end
    local tycoon = workspace:FindFirstChild("CalmWorksTycoon")
    local sound = tycoon and tycoon:FindFirstChild("ui-simple-button-click")
    if sound and sound:IsA("Sound") then
        sound.TimePosition = 0
        sound:Play()
    end
end

if RunService:IsClient() then
    ReplicatedStorage:WaitForChild("CalmWorksRemotes")
        :WaitForChild("ActionRejected").OnClientEvent
        :Connect(function()
            Feedback.Error()
        end)
end

return Feedback
