-- Server-only background generation. A closed ticket can NEVER replace a displayed question.
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Config = require(game:GetService("ReplicatedStorage").CalmWorksShared.Config)
local Validator = require(script.Parent.ScenarioAIValidator)
local CustomerBehavior = require(script.Parent.CustomerBehavior)
local Schema = require(script.Parent.ScenarioAISchema)
local Service = {}

local function contentOnly(source, useBasePrompt, labelChoices)
    local value = { Title = source.Title, Feedback = source.Feedback, Stages = {} }
    for _, stage in ipairs(source.Stages) do
        local feedback = table.clone(stage.ChoiceFeedback)
        for index, text in ipairs(feedback) do
            if text == "" then
                feedback[index] = source.Feedback
                    or "Explain why this response is appropriate under the stated facts."
            end
        end
        local choices = stage.Choices
        if labelChoices then
            choices = { A = stage.Choices[1], B = stage.Choices[2], C = stage.Choices[3] }
            feedback = { A = feedback[1], B = feedback[2], C = feedback[3] }
        end
        table.insert(value.Stages, {
            Prompt = not useBasePrompt and stage.Prompt or nil,
            Background = stage.Background or stage.BasePrompt or stage.Prompt,
            CustomerInsight = useBasePrompt and "" or stage.CustomerInsight,
            Choices = choices,
            ChoiceFeedback = feedback,
        })
    end
    return value
end

function Service.New(deps)
    deps = deps or {}
    local config = deps.Config or Config
    local tickets, activeJobs, failures, cooldownUntil = {}, 0, 0, 0
    local counts = { Started = 0, Accepted = 0, Library = 0, Reasons = {} }
    local lastTimings = {}
    local log = deps.Log or print
    local api = {}
    local function alive(ticket)
        return not ticket.Closed and ticket.Player.Parent ~= nil and os.clock() < ticket.PrepareDeadline
    end
    local function fail(ticket, reason)
        if ticket.Closed or ticket.State ~= "Pending" then
            return
        end
        ticket.State, ticket.Reason = "Fallback", reason
        counts.Reasons[reason] = (counts.Reasons[reason] or 0) + 1
        counts.LastFallback =
            { Reason = reason, Phase = ticket.Phase, Seconds = os.clock() - ticket.StartedAt }
        if config.AIScenarioLogFallbacks ~= false and not ticket.FallbackLogged then
            ticket.FallbackLogged = true
            local source = ticket.Source
            local profile = source.CustomerProfile or {}
            log(
                string.format(
                    "[CalmWorks AI fallback] reason=%s | preset=%s | category=%s | level=%s | format=%s | mood=%s | personality=%s | style=%s",
                    tostring(reason),
                    tostring(source.TemplateId or source.Id),
                    tostring(source.CategoryCode),
                    tostring(source.Difficulty),
                    tostring(source.Mode),
                    tostring(profile.Mood or "none"),
                    tostring(profile.Personality or "none"),
                    tostring(profile.CommunicationStyle or "none")
                )
            )
        end
    end
    local function native(name, prompt, tokens, schema)
        local generator = ServerStorage:FindFirstChild(name)
        assert(generator and generator:IsA("TextGenerator"), "Scenario TextGenerator is missing")
        local request = { UserPrompt = prompt, MaxTokens = tokens }
        if config.AIScenarioUseJsonSchema == true then
            request.JsonSchema = schema
        end
        local response = generator:GenerateTextAsync(request)
        assert(type(response) == "table" and type(response.GeneratedText) == "string", "Empty AI result")
        return response.GeneratedText
    end
    local writer = deps.Write
        or function(prompt, schema)
            return native("CalmWorksScenarioGenerator", prompt, config.AIScenarioMaxTokens, schema)
        end
    local reviewer = deps.Review
        or function(prompt, schema)
            return native("CalmWorksScenarioReviewer", prompt, config.AIScenarioReviewMaxTokens, schema)
        end
    local checker = deps.Check
        or function(prompt, schema)
            return native("CalmWorksScenarioAnswerChecker", prompt, 450, schema)
        end
    local filter = deps.Filter
        or function(player, text)
            -- Reject filtered changes rather than silently changing the meaning/answer key.
            local result =
                TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PrivateChat)
            return result:GetNonChatStringForUserAsync(player.UserId) == text
        end

    function api.Start(player, source, metrics)
        local ticket = {
            Player = player,
            Source = source,
            StartedAt = os.clock(),
            State = "Pending",
            Closed = false,
            PrepareDeadline = os.clock() + (config.AIScenarioPreparationSeconds or 45),
            Phase = "queued",
            Timings = {},
        }
        tickets[ticket] = true
        local reason
        if not player or player.Parent == nil then
            reason = "player_left"
        elseif not config.AIScenarioEnabled then
            reason = "disabled"
        elseif source.ContentFlag or source.Severity > (config.AIScenarioMaximumSeverity or 3) then
            reason = "reviewed_sensitive_case"
        elseif os.clock() < cooldownUntil then
            reason = "cooldown"
        elseif activeJobs >= (config.AIScenarioMaxConcurrent or 2) then
            reason = "busy"
        end
        if reason then
            fail(ticket, reason)
            return ticket
        end
        activeJobs += 1
        counts.Started += 1
        task.delay(config.AIScenarioPreparationSeconds or 45, function()
            fail(ticket, "preparation_timeout")
        end)
        task.spawn(function()
            local okay, apiError = pcall(function()
                local context = {
                    Constraints = {
                        Category = source.Category,
                        CategoryCode = source.CategoryCode,
                        Difficulty = source.Difficulty,
                        Mode = source.Mode,
                        MaximumSeverity = source.Severity,
                        TargetSkill = source.TargetSkill or source.Skill or source.Skills[1],
                        StageCount = #source.Stages,
                        CustomerPresentation = CustomerBehavior.Context(source.CustomerProfile),
                        WorkplaceContext = source.WorkplaceContext,
                        Speaker = {
                            Role = source.WorkplaceContext and source.WorkplaceContext.VisitorRole
                                or "Customer",
                            Listener = "CalmWorks business owner (the player)",
                            Perspective = "The NPC describes their own situation in first person. Learning metrics are not personal story facts.",
                        },
                    },
                    Performance = metrics or {},
                    Reference = contentOnly(source, true),
                    FRQRubric = source.FRQ,
                }
                context.Constraints.AnswerRoles = {}
                for _, stage in ipairs(source.Stages) do
                    table.insert(
                        context.Constraints.AnswerRoles,
                        { BestPosition = stage.BestIndex, Roles = stage.ChoiceOutcomes }
                    )
                end
                local answerInstructions = {}
                for index, stage in ipairs(source.Stages) do
                    table.insert(
                        answerInstructions,
                        string.format(
                            "Stage %d: put the best response at choice position %d; do not reorder the roles.",
                            index,
                            stage.BestIndex
                        )
                    )
                end
                context.OutputContract = {
                    RootFields = { "Title", "Feedback", "Stages" },
                    StageFields = { "Background", "CustomerInsight", "Choices", "ChoiceFeedback" },
                    Instruction = "Return one JSON object in this exact shape. Never copy Constraints, Performance, AnswerRoles, FRQRubric or Prompt into the output. Aim for 12-16 words in each choice while preserving the tradeoffs. Keep feedback concise so every stage fits.",
                }
                ticket.Phase = "writer"
                local writerStarted = os.clock()
                local raw = writer(
                    table.concat(answerInstructions, "\n")
                        .. "\nUse these constraints and reference:\n"
                        .. HttpService:JSONEncode(context),
                    Schema.Writer(source)
                )
                ticket.Timings.WriterSeconds = os.clock() - writerStarted
                if not alive(ticket) or ticket.State ~= "Pending" then
                    return
                end
                local candidate, validationError = Validator.DecodeCandidate(raw, source, config)
                if not candidate then
                    fail(ticket, validationError)
                    return
                end
                local reviewConstraints = table.clone(context.Constraints)
                reviewConstraints.AnswerRoles = nil -- reviewer must solve, not copy the answer key
                -- A separate blind solve prevents a reviewer merely copying the reference key
                -- or trusting the writer's feedback. Disagreement always uses the library.
                local blind = {
                    Difficulty = source.Difficulty,
                    CustomerPresentation = context.Constraints.CustomerPresentation,
                    WorkplaceContext = source.WorkplaceContext,
                    Stages = {},
                }
                for _, stage in ipairs(candidate.Stages) do
                    table.insert(blind.Stages, {
                        Prompt = stage.Prompt,
                        Choices = { A = stage.Choices[1], B = stage.Choices[2], C = stage.Choices[3] },
                    })
                end
                ticket.Phase = "quality_checks"
                local review, checked, reviewFailure, checkFailure
                local reviewDone, checkDone = false, false
                task.spawn(function()
                    local started = os.clock()
                    local success, result = pcall(
                        reviewer,
                        HttpService:JSONEncode({
                            Constraints = reviewConstraints,
                            Reference = contentOnly(source, true),
                            Candidate = contentOnly(candidate, false, true),
                            FRQRubric = source.FRQ,
                            OutputContract = {
                                RequiredChecks = HttpService:JSONDecode(Schema.Reviewer(source)).required,
                                Speaker = context.Constraints.Speaker,
                                StageCount = #source.Stages,
                                BestKeys = "Choose the provided letter A, B or C once for EACH stage. These letters label the displayed positions, not the reference answer roles.",
                                WorkplaceAligned = source.WorkplaceContext
                                        and "REQUIRED boolean: the supplied staff role remains the narrator."
                                    or nil,
                            },
                        }),
                        Schema.Reviewer(source)
                    )
                    ticket.Timings.ReviewSeconds = os.clock() - started
                    if success then
                        review = result
                    else
                        reviewFailure = result
                    end
                    reviewDone = true
                end)
                task.spawn(function()
                    local started = os.clock()
                    local success, result =
                        pcall(checker, HttpService:JSONEncode(blind), Schema.Checker(source))
                    ticket.Timings.CheckSeconds = os.clock() - started
                    if success then
                        checked = result
                    else
                        checkFailure = result
                    end
                    checkDone = true
                end)
                -- Retain capacity until BOTH native requests return, even after a timeout.
                while not reviewDone or not checkDone do
                    task.wait(0.025)
                end
                if reviewFailure or checkFailure then
                    error(tostring(reviewFailure or checkFailure))
                end
                if not alive(ticket) or ticket.State ~= "Pending" then
                    return
                end
                local valid, reviewError = Validator.ValidateReview(review, candidate)
                if not valid then
                    fail(ticket, reviewError)
                    return
                end
                local agreed, checkError = Validator.ValidateBlindCheck(checked, candidate)
                if not agreed then
                    fail(ticket, checkError)
                    return
                end
                ticket.Phase = "text_filter"
                if not filter(player, Validator.VisibleText(candidate)) then
                    fail(ticket, "text_filter_rejected")
                    return
                end
                if not alive(ticket) or ticket.State ~= "Pending" then
                    return
                end
                candidate.AIValidated = true
                ticket.Result, ticket.State = candidate, "Ready"
                failures = 0
                counts.Accepted += 1
            end)
            -- Do not release capacity on a timeout: Roblox cannot cancel an in-flight API call.
            activeJobs -= 1
            lastTimings = table.clone(ticket.Timings)
            if not okay then
                local message = string.lower(tostring(apiError))
                local reason = "api_unavailable"
                if message:find("moderation", 1, true) or message:find("blocked", 1, true) then
                    reason = "provider_rejected"
                elseif message:find("rate limit", 1, true) or message:find("throttl", 1, true) then
                    reason = "provider_rate_limit"
                end
                fail(ticket, reason)
                failures += 1
                if failures >= (config.AIScenarioFailureLimit or 3) then
                    cooldownUntil = os.clock() + (config.AIScenarioCooldownSeconds or 30)
                end
            elseif ticket.State == "Pending" then
                fail(ticket, "expired")
            end
        end)
        return ticket
    end

    function api.Resolve(ticket)
        assert(ticket and ticket.Source, "A scenario ticket is required")
        if ticket.Closed then
            return ticket.Resolved or ticket.Source
        end
        -- Hard cap is intentional even if an editable Config value is accidentally increased.
        local deadline = math.min(
            ticket.PrepareDeadline,
            os.clock() + math.clamp(config.AIScenarioLoadingSeconds or 2, 0, 2)
        )
        while
            ticket.State == "Pending"
            and not ticket.Closed
            and ticket.Player.Parent ~= nil
            and os.clock() < deadline
        do
            task.wait(math.min(0.025, math.max(0, deadline - os.clock())))
        end
        if ticket.State == "Pending" then
            fail(ticket, "loading_timeout")
        end
        local result = not ticket.Closed and ticket.State == "Ready" and ticket.Result or ticket.Source
        if result == ticket.Source then
            counts.Library += 1
        end
        ticket.Resolved, ticket.Closed = result, true
        tickets[ticket] = nil
        return result
    end

    function api.Cancel(ticket)
        if not ticket then
            return
        end
        ticket.Closed, ticket.Result = true, nil
        tickets[ticket] = nil
    end
    function api.CancelPlayer(player)
        for ticket in pairs(tickets) do
            if ticket.Player == player then
                api.Cancel(ticket)
            end
        end
    end
    function api.GetDiagnostics()
        local pending = 0
        for _ in pairs(tickets) do
            pending += 1
        end
        return {
            Started = counts.Started,
            Accepted = counts.Accepted,
            Library = counts.Library,
            Reasons = table.clone(counts.Reasons),
            ActiveJobs = activeJobs,
            Tickets = pending,
            CooldownSeconds = math.max(0, cooldownUntil - os.clock()),
            LastTimings = table.clone(lastTimings),
            LastFallback = counts.LastFallback and table.clone(counts.LastFallback) or nil,
            SchemaMode = config.AIScenarioUseJsonSchema == true and "provider_schema" or "validated_json",
        }
    end
    return api
end

local defaultService = Service.New()
for key, value in pairs(defaultService) do
    Service[key] = value
end
return Service
