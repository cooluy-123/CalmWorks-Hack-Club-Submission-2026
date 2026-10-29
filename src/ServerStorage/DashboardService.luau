local Policy = require(script.Parent.DashboardPolicy)
local Scenarios = require(script.Parent.DashboardScenarios)
local UI = require(game.ReplicatedStorage.CalmWorksShared.EditableUI)
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.CalmWorksShared.Config)
local GradePolicy = require(script.Parent.FRQGradePolicy)
local HelpContext = require(script.Parent.FRQHelpContext)
local CustomerBehavior = require(script.Parent.CustomerBehavior)
local Service = {}

function Service.New(settings, callbacks)
    local self = {
        Active = nil,
        Model = nil,
        Connection = nil,
        Samples = {},
        LastSample = 0,
        LastMeterTick = 0,
    }
    local rng = Random.new()
    local remoteRequests = setmetatable({}, {__mode = "k"})

    local function state(player)
        local session = callbacks.Session(player)
        return session and session.Dashboard
    end

    local function owned(player)
        local session = callbacks.Session(player)
        if not player or not session then
            return false
        end
        local purchases = session and session.ExpansionPurchases["3"]
        return player == callbacks.Owner()
            and session.TycoonProgress.CompletedExpansions >= 3
            and purchases
            and purchases.CentralDashboard == true
    end

    function self:Context(player)
        local context = callbacks.Context(player)
        context.QueueSamples = #self.Samples
        context.LongestAverage, context.QueueGap = 0, 0
        context.LongestArea = "Main"
        local minimum = math.huge
        for _, area in ipairs({ "Main", "Left", "Right", "UpperLeft", "UpperRight" }) do
            local total = 0
            for _, sample in ipairs(self.Samples) do
                total += sample[area] or 0
            end
            local average = #self.Samples > 0 and total / #self.Samples or 0
            minimum = math.min(minimum, average)
            if average > context.LongestAverage then
                context.LongestAverage, context.LongestArea = average, area
            end
        end
        context.QueueGap = context.LongestAverage - (minimum == math.huge and 0 or minimum)
        context.RecentAngry = 0
        local saved = state(player)
        for _, angry in ipairs(saved and saved.RecentArrivals or {}) do
            if angry then
                context.RecentAngry += 1
            end
        end
        return context
    end

    function self:Multiplier(key)
        local player = callbacks.Owner()
        if not player or not owned(player) then
            return 1
        end
        return Policy.Multiplier(state(player), settings, key)
    end

    function self:Event(player, unit, angry)
        local saved = state(player)
        if not saved then
            return
        end
        if unit == "Arrival" then
            Policy.Arrival(saved, angry)
        end
        if unit == "Arrival" then
            callbacks.Changed(player)
        end
    end

    function self:IsActive(player)
        return self.Active ~= nil and self.Active.Player == player
    end

    function self:CanUse(player, model, remoteAccess)
        if not model or not model.Parent or not owned(player) then
            return false
        end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local part = model:FindFirstChild("Screen")
        local prompt = part and part:FindFirstChild("DashboardPrompt")
        if not root or not humanoid or humanoid.Health <= 0 or not prompt then
            return false
        end
        -- Remote sessions still require the owner, purchased panel and a living character.
        if remoteAccess == true then
            return true
        end
        if (root.Position - part.Position).Magnitude > math.min(prompt.MaxActivationDistance + 3, 16) then
            return false
        end
        -- Only the front of the wall-mounted panel is usable.
        if part.CFrame:PointToObjectSpace(root.Position).Z >= -0.25 then
            return false
        end
        local from = player.Character:FindFirstChild("Head") or root
        local filter = RaycastParams.new()
        filter.FilterType = Enum.RaycastFilterType.Exclude
        filter.FilterDescendantsInstances = { player.Character, model }
        local hit = workspace:Raycast(from.Position, part.Position - from.Position, filter)
        return hit == nil
    end

    local function save(player)
        callbacks.Changed(player)
        callbacks.Save(player)
    end

    function self:Prepare(player)
        local saved = state(player)
        if not saved or saved.Pending then
            return saved and saved.Pending
        end
        local okay, scenario, ticket = pcall(callbacks.Create, player)
        if not okay or not scenario then
            warn("CalmWorks online consultation could not prepare a customer.")
            return nil
        end
        local pending = Scenarios.NewPending(scenario, settings, rng)
        if not pending then
            callbacks.Cancel(ticket)
            return nil
        end
        saved.Pending = pending
        self.Prepared = {Player = player, Pending = pending, Ticket = ticket}
        save(player)
        return pending
    end

    function self:Payload(active)
        local pending = active.Pending
        local scenario = pending.Scenario
        local stage = scenario.Stages[pending.StageIndex]
        return {
            CustomerName = UI.T("Dashboard", "CustomerName", pending.Name),
            IsDashboard = true,
            IsOnlineConsultation = true,
            RemoteAccess = active.RemoteAccess == true,
            ContextToken = active.Token,
            IsAIGenerated = scenario.SourceKind == "AI",
            Mode = scenario.Mode,
            Prompt = stage.Prompt,
            Choices = scenario.Mode == "MCQ" and stage.Choices or nil,
            FRQContextId = scenario.Mode == "FRQ" and (active.Token .. ":" .. pending.StageIndex) or nil,
            FRQPrompt = scenario.Mode == "FRQ" and GradePolicy.Task(scenario, Config.FRQDefaultPrompt) or nil,
            MaxCharacters = Config.FRQMaxCharacters,
            CategoryCode = scenario.CategoryCode,
            Difficulty = scenario.Difficulty,
            StageIndex = pending.StageIndex,
            StageCount = #scenario.Stages,
        }
    end

    function self:Help(player)
        local active = self.Active
        if not active or active.Player ~= player or active.Completed then
            return nil
        end
        return HelpContext.Build({
            Scenario = active.Pending.Scenario,
            StageIndex = active.Pending.StageIndex,
            HelpContextId = active.Token,
            Opening = active.Opening,
            Grading = active.Submitting,
        }, self:CanUse(player, active.Model, active.RemoteAccess))
    end

    function self:Close(player, token)
        local active = self.Active
        if not active or active.Player ~= player or type(token) ~= "string" then
            return
        end
        -- A Close sent during the next-customer transition must still cancel it.
        if active.Token ~= token and active.PreviousToken ~= token then
            return
        end
        if self.Prepared and self.Prepared.Pending == active.Pending then
            callbacks.Cancel(self.Prepared.Ticket)
            self.Prepared = nil
        end
        self.Active = nil
        callbacks.Release(active.Model)
        callbacks.Open(player, {Closed = true, ContextToken = active.Token})
    end

    function self:OpenRemote(player)
        local now = os.clock()
        if now - (remoteRequests[player] or -math.huge) < 1 then
            return
        end
        remoteRequests[player] = now
        self:Open(player, true)
    end

    function self:Open(player, remoteAccess)
        if not self:CanUse(player, self.Model, remoteAccess) then
            callbacks.Reject(player, "NotBusinessOwner")
            return
        end
        if self.Active or callbacks.Busy() then
            callbacks.Reject(player, "CustomerAlreadyActive")
            return
        end
        local pending = self:Prepare(player)
        if not pending then
            callbacks.Notice(player, "DashboardUnavailable")
            return
        end
        local active = {
            Player = player, Model = self.Model, Pending = pending,
            Token = HttpService:GenerateGUID(false), LastSubmit = -math.huge,
            Opening = true,
            RemoteAccess = remoteAccess == true,
        }
        self.Active = active
        callbacks.Hold(self.Model)
        self:Connect(active)
    end

    function self:Continue(player, token)
        local active = self.Active
        if not active or active.Player ~= player or active.Token ~= token then
            return
        end
        if not active.Completed or active.Opening or active.Submitting then
            return
        end
        if not self:CanUse(player, active.Model, active.RemoteAccess) then
            self:Close(player, token)
            return
        end
        active.Opening = true
        local pending = self:Prepare(player)
        if self.Active ~= active then
            return
        end
        if not pending then
            callbacks.Notice(player, "DashboardUnavailable")
            self:Close(player, token)
            return
        end
        active.PreviousToken = token
        active.Token = HttpService:GenerateGUID(false)
        active.Pending = pending
        active.Completed = false
        active.LastSubmit = -math.huge
        self:Connect(active)
    end

    function self:Connect(active)
        local player = active.Player
        local pending = active.Pending
        local prepared = self.Prepared
        if prepared and prepared.Pending == pending then
            local loading = self:Payload(active)
            loading.Loading = true
            callbacks.Open(player, loading)
            local okay, scenario = pcall(callbacks.Resolve, prepared.Ticket)
            if self.Active ~= active then
                return
            end
            self.Prepared = nil
            if okay and scenario then
                pending.Scenario = Scenarios.CleanScenario(scenario) or pending.Scenario
            else
                callbacks.Cancel(prepared.Ticket)
            end
            save(player)
        end
        active.Opening = false
        if not self:CanUse(player, active.Model, active.RemoteAccess) then
            self:Close(player, active.Token)
            return
        end
        callbacks.Open(player, self:Payload(active))
    end

    local function reaction(pending, outcome)
        local scenario = pending.Scenario
        if not scenario.CustomerProfile then
            return nil
        end
        local sensitive = scenario.ContentFlag ~= nil or scenario.Severity > Config.AIScenarioMaximumSeverity
        return CustomerBehavior.React(nil, scenario.CustomerProfile, outcome, sensitive)
    end

    function self:FinishStage(player, active)
        local pending = active.Pending
        local saved = state(player)
        if pending.StageIndex < #pending.Scenario.Stages then
            pending.StageIndex += 1
            save(player)
            return {Correct = true, Continue = true, IsDashboard = true, NextStage = self:Payload(active)}
        end
        -- Award only once, after every linked stage is resolved.
        active.Completed = true
        saved.Pending = nil
        local gain = Policy.Award(saved, settings, callbacks.Upgraded(player))
        saved.Completed += 1
        if pending.FirstCorrect then
            saved.FirstTryCorrect += 1
        end
        table.insert(saved.Recent, pending.Scenario.TemplateId)
        while #saved.Recent > 6 do
            table.remove(saved.Recent, 1)
        end
        saved.NextAt = 0
        callbacks.Completed(player)
        save(player)
        local benefit = UI.T("Dashboard", "ReviewBenefit", gain, saved.Review, Policy.Multiplier(saved, settings, "Service"))
        return {Correct = true, IsDashboard = true, Reward = 0, Success = pending.Scenario.Feedback .. " " .. benefit}
    end

    function self:Submit(player, answer, token)
        local active = self.Active
        if not active or active.Player ~= player or active.Token ~= token or active.Completed then
            return {Error = UI.T("Dashboard", "Expired")}
        end
        if not self:CanUse(player, active.Model, active.RemoteAccess) then
            self:Close(player, token)
            return {Error = UI.T("Dashboard", "ReturnToPanel")}
        end
        local pending = active.Pending
        local saved = state(player)
        if active.Opening or active.Submitting or saved.Pending ~= pending then
            return {Error = UI.T("Dashboard", "Retry")}
        end
        local scenario = pending.Scenario
        local index = pending.StageIndex
        local stage = scenario.Stages[index]
        local correct, grade
        local now = os.clock()
        local cooldown = scenario.Mode == "FRQ" and Config.FRQGradingCooldownSeconds or 0.6
        if now - active.LastSubmit < cooldown then
            return {Error = UI.T("Dashboard", "Retry")}
        end

        if scenario.Mode == "FRQ" then
            if type(answer) ~= "string" then
                return {Error = UI.T("ServerErrors", "WriteAResponseBeforeSubmitting")}
            end
            local response = string.match(answer, "^%s*(.-)%s*$") or ""
            local length = utf8.len(response)
            if not length or #response > 2000 then
                return {Error = UI.T("ServerErrors", "ThatResponseCouldNotBeProcessedSafely")}
            end
            if length < Config.FRQMinCharacters then
                return {Error = UI.T("ServerErrors", "WriteALittleMoreSoTheAI")}
            end
            if length > Config.FRQMaxCharacters then
                return {Error = UI.T("Dialogue", "CharacterLimit", Config.FRQMaxCharacters)}
            end
            active.LastSubmit = now
            active.Submitting = true
            local okay, result, problem = pcall(callbacks.Grade, player, scenario, index, response)
            active.Submitting = false
            if self.Active ~= active or pending.StageIndex ~= index or saved.Pending ~= pending then
                return {Error = UI.T("Dashboard", "Expired")}
            end
            if not self:CanUse(player, active.Model, active.RemoteAccess) then
                self:Close(player, token)
                return {Error = UI.T("Dashboard", "ReturnToPanel")}
            end
            if not okay or not result then
                scenario.Mode = "MCQ"
                save(player)
                return {SwitchToMCQ = true, NextStage = self:Payload(active),
                    Error = (okay and problem or UI.T("ServerNotices", "GradingUnavailable"))
                        .. UI.T("ServerNotices", "MCQFallback")}
            end
            grade = result
            correct = grade.Passed
        else
            if type(answer) ~= "number" or answer % 1 ~= 0 or not stage.Choices[answer] then
                return {Error = UI.T("Dialogue", "EmptyMCQ")}
            end
            active.LastSubmit = now
            correct = answer == stage.BestIndex
        end

        -- Keep the separate first-try completion statistic, but count every graded attempt.
        if not pending.RecordedStages[index] then
            pending.RecordedStages[index] = true
            pending.FirstCorrect = pending.FirstCorrect and correct
        end
        callbacks.Record(player, scenario, correct)
        local outcome = correct and "Optimal" or "Mixed"
        if not correct and grade then
            if grade.Scores.EscalationRisk >= Config.FRQMaximumEscalationRisk then
                outcome = "Risky"
            end
        elseif not correct then
            outcome = stage.ChoiceOutcomes[answer] or "Mixed"
        end
        local response = reaction(pending, outcome)
        local result
        if correct then
            result = self:FinishStage(player, active)
        else
            save(player)
            local hint = not grade and stage.ChoiceFeedback[answer] or nil
            if hint == "" then
                hint = scenario.Feedback
            end
            result = {Correct = false, Hint = hint, Outcome = outcome}
        end
        result.CustomerReaction = response
        if grade then
            result.Mode = "FRQ"
            result.Analysis = grade
        end
        return result
    end

    function self:Snapshot(player)
        local saved = state(player)
        if not saved then
            return nil
        end
        local result = Policy.Clean(saved)
        result.Purchased = owned(player) == true
        result.CooldownRemaining = math.max(0, result.NextAt - os.time())
        result.Pending = nil
        result.Boost = nil
        result.Upgraded = callbacks.Upgraded(player)
        result.Multiplier = Policy.Multiplier(saved, settings, "Service")
        result.PassiveMoraleMultiplier = Policy.Multiplier(saved, settings, "Decay")
        if player == callbacks.Owner() then
            result.Context = self:Context(player)
        end
        return result
    end

    function self:Tick()
        local player = callbacks.Owner()
        local model = player and owned(player) and callbacks.Panel() or nil
        if self.AccessPlayer ~= player then
            if self.AccessPlayer and callbacks.Access then
                callbacks.Access(self.AccessPlayer, false)
            end
            self.AccessPlayer = player
        end
        if player and callbacks.Access then
            callbacks.Access(player, model ~= nil)
        end
        if model ~= self.Model then
            if self.Connection then
                self.Connection:Disconnect()
                self.Connection = nil
            end
            if self.Active then
                self:Close(self.Active.Player, self.Active.Token)
            end
            self.Model = model
            self.LastMeterTick = os.clock()
            self.Samples = {}
            if model then
                local prompt = model.Screen.DashboardPrompt
                self.Connection = prompt.Triggered:Connect(function(who)
                    self:Open(who)
                end)
            end
        end
        if not player or not model then
            return
        end
        local now = os.clock()
        local elapsed = math.clamp(now - self.LastMeterTick, 0, 10)
        self.LastMeterTick = now
        local meter = state(player)
        if elapsed > 0 then
            Policy.Advance(meter, settings, callbacks.Upgraded(player), elapsed)
            callbacks.Changed(player)
        end
        if now - self.LastSample >= 5 then
            self.LastSample = now
            table.insert(self.Samples, callbacks.Context(player).Queues)
            if #self.Samples > 12 then
                table.remove(self.Samples, 1)
            end
        end
        if not self.Active and not callbacks.Busy() and not state(player).Pending then
            if now >= (self.NextPrepare or 0) then
                self.NextPrepare = now + 10
                self:Prepare(player)
            end
        end
        if self.Active then
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                self:Close(player, self.Active.Token)
            end
        end
        local saved = state(player)
        local context = self:Context(player)
        local screen = model.Screen.DashboardSurface
        screen.Morale.Text = UI.T("Dashboard", "PanelMorale", math.floor(context.AverageMorale + 0.5))
        screen.Decisions.Text = UI.T("Dashboard", "PanelDecisions", saved.Completed)
        screen.Status.Text =
            UI.T("Dashboard", "PanelReview", saved.Review, Policy.Multiplier(saved, settings, "Service"))
        local bar = screen:FindFirstChild("ReviewBar")
        local fill = bar and bar:FindFirstChild("Fill")
        if fill then
            fill.Size = UDim2.fromScale(saved.Review / 100, 1)
        end
    end

    function self:Reset()
        if self.AccessPlayer and callbacks.Access then
            callbacks.Access(self.AccessPlayer, false)
        end
        self.AccessPlayer = nil
        table.clear(remoteRequests)
        if self.Prepared then
            callbacks.Cancel(self.Prepared.Ticket)
            self.Prepared = nil
        end
        self.NextPrepare = 0
        if self.Active then
            self:Close(self.Active.Player, self.Active.Token)
        end
        if self.Connection then
            self.Connection:Disconnect()
        end
        self.Connection = nil
        self.Model = nil
        self.Samples = {}
        self.LastSample = 0
    end
    return self
end

return Service
