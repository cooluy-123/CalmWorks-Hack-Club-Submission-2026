local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local Policy = require(script.Parent.CeremonyPolicy)
local UI = require(game.ReplicatedStorage.CalmWorksShared.EditableUI)
local Service = {}

function Service.New(settings, callbacks)
    local self = {Scene = nil, Active = nil, Owner = nil, Tweens = {}, NextReadyAt = 0}
    local template = settings.Template.Value
    local actors = settings.AudienceTemplates.Value
    local templates = Instance.new("Folder")
    templates.Name = "CalmWorksCeremonyTemplates"
    templates.Parent = ServerStorage
    template.Parent = templates
    actors.Parent = templates

    local function alive(player)
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        return root and humanoid and humanoid.Health > 0, root, humanoid
    end

    local function setAttribute(player, name, value)
        if player and player.Parent and player:GetAttribute(name) ~= value then
            player:SetAttribute(name, value)
        end
    end

    function self:IsPlaying()
        return self.Active ~= nil and self.Active.Phase == "Playing"
    end

    function self:ClearScene()
        if self.PromptConnection then
            self.PromptConnection:Disconnect()
            self.PromptConnection = nil
        end
        for _, tween in ipairs(self.Tweens) do
            tween:Cancel()
        end
        table.clear(self.Tweens)
        if self.Scene then
            self.Scene:Destroy()
            self.Scene = nil
        end
    end

    local function releaseCharacter(active)
        if active and active.Root and active.Root.Parent then
            active.Root.Anchored = active.WasAnchored
        end
        if active and active.Humanoid and active.Humanoid.Parent then
            active.Humanoid.AutoRotate = active.AutoRotate
        end
    end

    function self:Reset()
        local active = self.Active
        self.Active = nil
        if active then
            releaseCharacter(active)
            callbacks.Send(active.Player, {Kind = "Cancel", Token = active.Token})
            callbacks.CloseSpeech(active.Player, active.Token)
            callbacks.Release(settings)
        end
        setAttribute(self.Owner, "CeremonyActive", false)
        setAttribute(self.Owner, "CeremonyReady", false)
        self:ClearScene()
        self.Owner = nil
        self.NextReadyAt = os.clock() + 2
    end

    function self:Abort(player, token)
        local active = self.Active
        if not active or active.Player ~= player or active.Token ~= token then
            return
        end
        self:Reset()
    end

    function self:Spawn(player)
        if self.Scene then
            return
        end
        local scene = template:Clone()
        scene.Name = "CalmWorksCeremony"
        scene.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
        scene:SetAttribute("OwnerUserId", player.UserId)
        if settings:GetAttribute("AutoPlaceBetweenSpawns") ~= false then
            local a = settings.PlayerSpawn.Value
            local b = settings.CustomerSpawn.Value
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local middle = (a.Position + b.Position) / 2
                local old = template:GetPivot()
                local y = Policy.Number(settings:GetAttribute("GroundY"), old.Y, -500, 500)
                scene:PivotTo(CFrame.new(middle.X, y, middle.Z) * old.Rotation)
            end
        end
        local guests = Instance.new("Folder")
        guests.Name = "Audience"
        guests.Parent = scene
        local count = 0
        for _, marker in ipairs(scene.AudienceMarkers:GetChildren()) do
            local reference = marker:FindFirstChild("ActorTemplate")
            local actorTemplate = reference and reference.Value
            if marker:IsA("BasePart") and actorTemplate and actorTemplate:IsDescendantOf(actors) and count < 24 then
                count += 1
                local actor = actorTemplate:Clone()
                actor.Name = marker.Name .. "_" .. actorTemplate.Name
                -- Audience copies never run imported scripts or join gameplay queues.
                for _, item in ipairs(actor:GetDescendants()) do
                    if item:IsA("LuaSourceContainer") or item:IsA("ProximityPrompt") then
                        item:Destroy()
                    elseif item:IsA("BasePart") then
                        item.CanCollide = false
                        item.CanTouch = false
                        item.CanQuery = false
                    end
                end
                local root = actor:FindFirstChild("HumanoidRootPart")
                if root then
                    actor.PrimaryPart = root
                    root.Anchored = true
                    local height = Policy.Number(marker:GetAttribute("HeightOffset"), 2.5, 0, 10)
                    actor:PivotTo(marker.CFrame + Vector3.new(0, height, 0))
                    actor.Parent = guests
                else
                    actor:Destroy()
                end
            end
        end
        scene.Parent = workspace
        self.Scene = scene
        self.PromptConnection = scene.CutPoint.CutRibbonPrompt.Triggered:Connect(function(who)
            self:Begin(who)
        end)
    end

    function self:CanCut(player)
        if player ~= callbacks.Owner() or not self.Scene or self.Active or callbacks.Busy() then
            return false
        end
        if not Policy.Eligible(callbacks.Progress(player), callbacks.Maxed(player)) then
            return false
        end
        local okay, root = alive(player)
        if not okay then
            return false
        end
        local point = self.Scene.CutPoint
        local prompt = point.CutRibbonPrompt
        if (root.Position - point.Position).Magnitude > math.min(prompt.MaxActivationDistance + 2, 14) then
            return false
        end
        local head = player.Character:FindFirstChild("Head") or root
        local parameters = RaycastParams.new()
        parameters.FilterType = Enum.RaycastFilterType.Exclude
        parameters.FilterDescendantsInstances = {player.Character, self.Scene}
        return workspace:Raycast(head.Position, point.Position - head.Position, parameters) == nil
    end

    function self:Fall(active)
        if self.Active ~= active or active.Phase ~= "Playing" or not self.Scene then
            return
        end
        local ribbon = self.Scene.Ribbon
        local duration = active.Timeline.Reveal - active.Timeline.Cut
        for _, name in ipairs({"LeftHalf", "RightHalf"}) do
            local half = ribbon[name]
            local hinge = half.Hinge.CFrame
            local degrees = Policy.Number(half:GetAttribute("FallAngleDegrees"), name == "LeftHalf" and -16 or 16, -30, 30)
            local movement = hinge * CFrame.Angles(0, 0, math.rad(degrees)) * hinge:Inverse()
            for _, piece in ipairs(half:GetChildren()) do
                if piece:IsA("BasePart") and piece.Name ~= "Hinge" then
                    local tween = TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = movement * piece.CFrame})
                    table.insert(self.Tweens, tween)
                    tween:Play()
                end
            end
        end
        local target = self.Scene:GetPivot() * CFrame.new(0, 1.12, 0.8) * CFrame.Angles(math.rad(75), 0, math.rad(15))
        local tween = TweenService:Create(ribbon.CenterBow, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = target})
        table.insert(self.Tweens, tween)
        tween:Play()
    end

    function self:Begin(player)
        if settings:GetAttribute("Enabled") == false or not self:CanCut(player) then
            callbacks.Reject(player, "CeremonyNotReady")
            return false
        end
        local _, root, humanoid = alive(player)
        local active = {
            Player = player, Character = player.Character, Root = root, Humanoid = humanoid,
            WasAnchored = root.Anchored, AutoRotate = humanoid.AutoRotate,
            Token = HttpService:GenerateGUID(false), Phase = "Playing", Timeline = Policy.Timeline(settings),
            StartAt = workspace:GetServerTimeNow() + Policy.Number(settings:GetAttribute("StartDelaySeconds"), 0.5, 0.2, 3),
        }
        self.Active = active
        self.Scene.CutPoint.CutRibbonPrompt.Enabled = false
        root.Anchored = true
        humanoid.AutoRotate = false
        callbacks.Hold(settings)
        setAttribute(player, "CeremonyActive", true)
        local cameras = self.Scene.Cameras
        local closeBounds = cameras:FindFirstChild("CloseupBounds")
        local wideBounds = cameras:FindFirstChild("OverviewBounds")
        callbacks.Send(player, {
            Kind = "Begin", Token = active.Token, StartAt = active.StartAt, Timeline = active.Timeline,
            Closeup = cameras.Closeup.CFrame, Overview = cameras.Overview.CFrame,
            CloseupFOV = Policy.Number(cameras.Closeup:GetAttribute("FieldOfView"), 52, 35, 90),
            OverviewFOV = Policy.Number(cameras.Overview:GetAttribute("FieldOfView"), 55, 35, 90),
            CloseupBounds = closeBounds and closeBounds.CFrame,
            CloseupSize = closeBounds and closeBounds.Size,
            OverviewBounds = wideBounds and wideBounds.CFrame,
            OverviewSize = wideBounds and wideBounds.Size,
        })
        task.delay(math.max(0, active.StartAt + active.Timeline.Cut - workspace:GetServerTimeNow()), function()
            self:Fall(active)
        end)
        return true
    end

    function self:Speak(active)
        local lines = UI.Sequence("CeremonyClosing")
        active.Lines = lines
        callbacks.Speak(active.Player, {Token = active.Token, Index = active.Index, Count = #lines,
            Text = lines[active.Index], VisitNumber = 6, CeremonyClosing = true})
        active.LastSpokeAt = os.clock()
    end

    function self:StartClosing(player, active)
        active = active or {Player = player, Token = HttpService:GenerateGUID(false)}
        active.Phase = "Closing"
        active.Index = 1
        active.LastAdvanceAt = -math.huge
        self.Active = active
        callbacks.Hold(settings)
        setAttribute(player, "CeremonyActive", false)
        setAttribute(player, "CeremonyReady", false)
        self:Speak(active)
    end

    function self:Finish(player, token)
        local active = self.Active
        if not Policy.CanFinish(active, player, token, workspace:GetServerTimeNow()) then
            return false
        end
        if player.Character ~= active.Character or not alive(player)
            or not Policy.Eligible(callbacks.Progress(player), callbacks.Maxed(player)) then
            self:Abort(player, token)
            return false
        end
        -- The server grants completion once, only after a valid cut and full timeline.
        callbacks.Complete(player)
        releaseCharacter(active)
        self:StartClosing(player, active)
        return true
    end

    function self:Advance(player, token, index)
        local active = self.Active
        if not active or active.Phase ~= "Closing" or active.Player ~= player
            or active.Token ~= token or active.Index ~= index then
            return {Error = UI.T("BusinessVisitStatus", "Unavailable"), Closed = true}
        end
        if os.clock() - active.LastAdvanceAt < 0.2 then
            return {Error = UI.T("BusinessVisitStatus", "Retry")}
        end
        active.LastAdvanceAt = os.clock()
        if active.Index < #active.Lines then
            active.Index += 1
            return {Token = active.Token, Index = active.Index, Count = #active.Lines,
                Text = active.Lines[active.Index], VisitNumber = 6, CeremonyClosing = true}
        end
        callbacks.Seen(player)
        self:Reset()
        return {Complete = true}
    end

    function self:Tick()
        local player = callbacks.Owner()
        if self.Owner ~= player then
            self:Reset()
            self.Owner = player
        end
        if not player then
            return
        end
        local progress = callbacks.Progress(player)
        local active = self.Active
        if active then
            if not alive(player) or (active.Character and player.Character ~= active.Character) then
                self:Abort(player, active.Token)
                return
            end
            if active.Phase == "Playing" then
                local grace = Policy.Number(settings:GetAttribute("TimeoutGraceSeconds"), 15, 5, 30)
                if workspace:GetServerTimeNow() > active.StartAt + active.Timeline.Finish + grace then
                    self:Abort(player, active.Token)
                end
            elseif os.clock() - active.LastSpokeAt > 8 then
                self:Speak(active)
            end
            return
        end
        if os.clock() < self.NextReadyAt then
            return
        end
        if Policy.ClosingNeeded(progress) and not callbacks.Busy() and alive(player) then
            self:StartClosing(player)
            return
        end
        local ready = settings:GetAttribute("Enabled") ~= false
            and Policy.Eligible(progress, callbacks.Maxed(player))
        if ready then
            self:Spawn(player)
            self.Scene.CutPoint.CutRibbonPrompt.Enabled = not callbacks.Busy() and alive(player) == true
        elseif self.Scene then
            self:ClearScene()
        end
        setAttribute(player, "CeremonyReady", ready == true)
    end
    return self
end

return Service

