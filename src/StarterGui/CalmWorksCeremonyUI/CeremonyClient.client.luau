local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local gui = script.Parent
local settings = game.ReplicatedStorage.CalmWorksShared:WaitForChild("RibbonCeremony")
local remotes = game.ReplicatedStorage.CalmWorksRemotes
local layer = gui:WaitForChild("ConfettiLayer")
local fade = gui:WaitForChild("Transition")
local active
local connection
local particles = {}

for _, item in ipairs(layer:GetChildren()) do
    if item:IsA("GuiObject") then
        table.insert(particles, {Object = item, Transparency = item.BackgroundTransparency})
    end
end
table.sort(particles, function(a, b)
    return a.Object.Name < b.Object.Name
end)

local function number(name, fallback, low, high)
    local value = settings:GetAttribute(name)
    if type(value) ~= "number" or value ~= value then
        return fallback
    end
    return math.clamp(value, low, high)
end

local function restore(data)
    if data.Restored then
        return
    end
    data.Restored = true
    ContextActionService:UnbindAction("CalmWorksCeremonyMovement")
    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = data.CameraCFrame
        camera.FieldOfViewMode = data.CameraFOVMode
        camera.FieldOfView = data.CameraFOV
        if data.CameraSubject and data.CameraSubject.Parent then
            camera.CameraSubject = data.CameraSubject
            camera.CameraType = data.CameraType
        else
            camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            camera.CameraType = Enum.CameraType.Custom
        end
    end
    for screen, enabled in pairs(data.Screens) do
        if screen.Parent then
            screen.Enabled = enabled
        end
    end
    for kind, enabled in pairs(data.Core) do
        pcall(function()
            StarterGui:SetCoreGuiEnabled(kind, enabled)
        end)
    end
end

local function clear(abort)
    local data = active
    active = nil
    if connection then
        connection:Disconnect()
        connection = nil
    end
    layer.Visible = false
    fade.Visible = false
    fade.BackgroundTransparency = 1
    for _, piece in ipairs(particles) do
        piece.Object.Visible = false
        piece.Object.BackgroundTransparency = piece.Transparency
    end
    if data then
        restore(data)
        if abort then
            remotes.CeremonyAbort:FireServer(data.Token)
        end
    end
end

local function play(name)
    local reference = settings:FindFirstChild(name)
    local sound = reference and reference.Value
    if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
        SoundService:PlayLocalSound(sound)
    end
end

local function smooth(value)
    value = math.clamp(value, 0, 1)
    return value * value * (3 - 2 * value)
end

local function fitCamera(cf, fov, size, bounds, viewport)
    if typeof(bounds) ~= "CFrame" or typeof(size) ~= "Vector3" then
        return cf
    end
    local vertical = math.tan(math.rad(fov / 2)) * 0.9
    local horizontal = vertical * math.max(0.25, viewport.X / math.max(1, viewport.Y))
    local extra = 0
    for _, x in ipairs({-0.5, 0.5}) do
        for _, y in ipairs({-0.5, 0.5}) do
            for _, z in ipairs({-0.5, 0.5}) do
                local corner = bounds:PointToWorldSpace(Vector3.new(size.X * x, size.Y * y, size.Z * z))
                local point = cf:PointToObjectSpace(corner)
                extra = math.max(extra, math.abs(point.X) / horizontal + point.Z,
                    math.abs(point.Y) / vertical + point.Z)
            end
        end
    end
    return cf - cf.LookVector * extra
end

local function confetti(elapsed)
    layer.Visible = settings:GetAttribute("ConfettiEnabled") ~= false
    local count = math.floor(number("ConfettiCount", 24, 0, #particles))
    local lifetime = number("ConfettiLifeSeconds", 2.8, 1, 8)
    local drift = number("ConfettiDrift", 0.08, 0, 0.4)
    for i, piece in ipairs(particles) do
        local object = piece.Object
        local age = elapsed - (i - 1) * lifetime / math.max(1, count)
        object.Visible = i <= count and age >= 0
        if object.Visible then
            local phase = (age % lifetime) / lifetime
            local x = ((i * 0.618034) % 1) + math.sin(phase * math.pi * 2 + i) * drift
            object.Position = UDim2.fromScale(x, -0.03 + phase * 1.1)
            object.Rotation = i * 31 + phase * (i % 2 == 0 and 180 or -180)
            object.BackgroundTransparency = math.max(piece.Transparency, math.clamp((phase - 0.8) / 0.2, 0, 1))
        end
    end
end

local function render()
    local data = active
    if not data then
        return
    end
    if player.Character ~= data.Character or not data.Humanoid.Parent or data.Humanoid.Health <= 0 then
        clear(true)
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then
        clear(true)
        return
    end
    local elapsed = math.max(0, workspace:GetServerTimeNow() - data.StartAt)
    local time = data.Timeline
    if data.Viewport ~= camera.ViewportSize then
        data.Viewport = camera.ViewportSize
        data.Closeup = fitCamera(data.AuthoredCloseup, data.CloseupFOV, data.CloseupSize, data.CloseupBounds, data.Viewport)
        data.Overview = fitCamera(data.AuthoredOverview, data.OverviewFOV, data.OverviewSize, data.OverviewBounds, data.Viewport)
    end
    if elapsed < time.Return then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
        if elapsed < time.Cut then
            local alpha = smooth(elapsed / time.Cut)
            camera.CFrame = data.CameraCFrame:Lerp(data.Closeup, alpha)
            camera.FieldOfView = data.CameraFOV + (data.CloseupFOV - data.CameraFOV) * alpha
        elseif elapsed < time.Reveal then
            camera.CFrame = data.Closeup
            camera.FieldOfView = data.CloseupFOV
        else
            local alpha = smooth((elapsed - time.Reveal) / (time.Overview - time.Reveal))
            camera.CFrame = data.Closeup:Lerp(data.Overview, alpha)
            camera.FieldOfView = data.CloseupFOV + (data.OverviewFOV - data.CloseupFOV) * alpha
        end
    end
    if elapsed >= time.Cut and not data.CutPlayed then
        data.CutPlayed = true
        play("ScissorsCut")
    end
    if elapsed >= time.Reveal and not data.PartyPlayed then
        data.PartyPlayed = true
        play("PartyCelebration")
    end
    if elapsed >= time.Reveal and elapsed < time.Return then
        confetti(elapsed - time.Reveal)
    end
    if elapsed >= time.Fade then
        fade.Visible = true
        if elapsed < time.Return then
            fade.BackgroundTransparency = 1 - math.clamp((elapsed - time.Fade) / (time.Return - time.Fade), 0, 1)
        else
            -- Restore the normal camera and controls while the screen is covered.
            restore(data)
            layer.Visible = false
            fade.BackgroundTransparency = math.clamp((elapsed - time.Return) / (time.Finish - time.Return), 0, 1)
        end
    end
    if elapsed >= time.Finish then
        local token = data.Token
        clear(false)
        remotes.CeremonyFinished:FireServer(token)
    end
end

local function begin(data)
    if type(data.Token) ~= "string" or type(data.Timeline) ~= "table"
        or typeof(data.Closeup) ~= "CFrame" or typeof(data.Overview) ~= "CFrame" then
        return
    end
    if active and active.Token == data.Token then
        return
    end
    clear(true)
    local camera = workspace.CurrentCamera
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not camera or not humanoid or humanoid.Health <= 0 then
        remotes.CeremonyAbort:FireServer(data.Token)
        return
    end
    data.Character = character
    data.Humanoid = humanoid
    data.CameraCFrame = camera.CFrame
    data.CameraFOV = camera.FieldOfView
    data.CameraFOVMode = camera.FieldOfViewMode
    data.AuthoredCloseup = data.Closeup
    data.AuthoredOverview = data.Overview
    data.CameraSubject = camera.CameraSubject
    data.CameraType = camera.CameraType
    data.Screens = {}
    data.Core = {}
    active = data
    for _, screen in ipairs(player.PlayerGui:GetChildren()) do
        if screen:IsA("ScreenGui") and screen ~= gui and screen.Name:match("^CalmWorks") then
            data.Screens[screen] = screen.Enabled
            screen.Enabled = false
        end
    end
    for _, kind in ipairs(Enum.CoreGuiType:GetEnumItems()) do
        if kind ~= Enum.CoreGuiType.All then
            pcall(function()
                data.Core[kind] = StarterGui:GetCoreGuiEnabled(kind)
                StarterGui:SetCoreGuiEnabled(kind, false)
            end)
        end
    end
    ContextActionService:BindActionAtPriority("CalmWorksCeremonyMovement", function()
        return Enum.ContextActionResult.Sink
    end, false, 3000, unpack(Enum.PlayerActions:GetEnumItems()))
    connection = RunService.RenderStepped:Connect(function()
        local okay, message = pcall(render)
        if not okay then
            warn("CalmWorks ceremony presentation stopped safely: " .. tostring(message))
            clear(true)
        end
    end)
end

remotes.CeremonyEvent.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then
        return
    end
    if data.Kind == "Begin" then
        local okay, message = pcall(begin, data)
        if not okay then
            warn("CalmWorks ceremony could not begin: " .. tostring(message))
            clear(true)
        end
    elseif data.Kind == "Cancel" and active and data.Token == active.Token then
        clear(false)
    end
end)
player.CharacterRemoving:Connect(function()
    clear(true)
end)
gui.Destroying:Connect(function()
    clear(true)
end)
layer.Visible = false
fade.Visible = false

