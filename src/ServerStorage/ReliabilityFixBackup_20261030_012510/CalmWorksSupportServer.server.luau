local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")
local FRQHelpContext = require(ServerStorage:WaitForChild("FRQHelpContext"))
local getActiveFRQContext = ServerStorage:WaitForChild("GetActiveFRQContext")
local getSupportState = ServerStorage:WaitForChild("GetSupportState")
local Grounding = require(ServerStorage:WaitForChild("SupportGrounding"))
local SupportMemory = require(ServerStorage:WaitForChild("SupportMemory"))

local Config = require(ReplicatedStorage:WaitForChild("CalmWorksShared"):WaitForChild("Config"))
local generator = ServerStorage:FindFirstChild("CalmWorksSupportGenerator")
if not generator then
    generator = Instance.new("TextGenerator")
    generator.Name = "CalmWorksSupportGenerator"
    generator.SystemPrompt = require(ServerStorage:WaitForChild("SupportSystemPrompt"))
    generator.Temperature = 0.5
    generator.TopP = 0.75
    generator.Parent = ServerStorage
end
assert(generator:IsA("TextGenerator"), "CalmWorksSupportGenerator must be a TextGenerator")

local remotes = ReplicatedStorage:FindFirstChild("CalmWorksRemotes") or Instance.new("Folder")
remotes.Name = "CalmWorksRemotes"
remotes.Parent = ReplicatedStorage
local requestEvent = remotes:FindFirstChild("SupportChatRequest") or Instance.new("RemoteEvent")
requestEvent.Name = "SupportChatRequest"
requestEvent.Parent = remotes
local responseEvent = remotes:FindFirstChild("SupportChatResponse") or Instance.new("RemoteEvent")
responseEvent.Name = "SupportChatResponse"
responseEvent.Parent = remotes
local supportStore = DataStoreService:GetDataStore(Config.SupportChatDataStoreName)
local dataStoreEnabled = not RunService:IsStudio() or Config.SaveInStudio
local sessions = {}

local SAFE_FALLBACK = UI.T("Support", "SafeFallback")

local function trim(text)
    return string.match(text, "^%s*(.-)%s*$") or ""
end

local function sanitizeHistory(rawHistory)
    local history = {}
    if type(rawHistory) ~= "table" then
        return history
    end
    local first = math.max(1, #rawHistory - Config.SupportChatMaxHistoryMessages + 1)
    for index = first, #rawHistory do
        local item = rawHistory[index]
        if
            type(item) == "table"
            and (item.Role == "user" or item.Role == "assistant")
            and type(item.Text) == "string"
        then
            table.insert(history, {
                Role = item.Role,
                Text = string.sub(item.Text, 1, Config.SupportChatMaxSavedMessageCharacters),
                Timestamp = type(item.Timestamp) == "number" and math.floor(item.Timestamp) or 0,
            })
        end
    end
    return history
end

local function defaultSession()
    return {
        History = {},
        Memory = SupportMemory.New(),
        Revision = 0,
        Busy = false,
        LastRequestAt = -math.huge,
        CanSave = false,
        Dirty = false,
        Saving = false,
    }
end

local function loadSession(player)
    local session = defaultSession()
    if dataStoreEnabled then
        local success, data = pcall(function()
            return supportStore:GetAsync("Player_" .. player.UserId)
        end)
        if success then
            session.CanSave = true
            if type(data) == "table" then
                session.History = sanitizeHistory(data.History)
                -- Old opaque AI context is intentionally not restored; displayed chat still saves.
            end
        else
            warn("CalmWorks support history load failed for " .. player.Name .. ": " .. tostring(data))
        end
    end
    if player.Parent then
        sessions[player] = session
        player:SetAttribute("SupportChatReady", true)
    end
end

local function saveSession(player, forceSave)
    local session = sessions[player]
    if not session or not session.CanSave or (not forceSave and not session.Dirty) then
        return false
    end
    if forceSave and session.Saving then
        local deadline = os.clock() + 10
        while session.Saving and os.clock() < deadline do
            task.wait(0.1)
        end
    end
    if session.Saving then
        return false
    end
    session.Saving = true
    local history = sanitizeHistory(session.History)
    local revision = session.Revision
    local success, errorMessage = pcall(function()
        supportStore:UpdateAsync("Player_" .. player.UserId, function()
            return {
                Version = 1,
                History = history,

                UpdatedAt = os.time(),
            }
        end)
    end)
    session.Saving = false
    if success then
        if session.Revision == revision then
            session.Dirty = false
        end
    else
        warn("CalmWorks support history save failed for " .. player.Name .. ": " .. tostring(errorMessage))
    end
    return success
end

local function addMessage(session, role, text)
    table.insert(session.History, { Role = role, Text = text, Timestamp = os.time() })
    while #session.History > Config.SupportChatMaxHistoryMessages do
        table.remove(session.History, 1)
    end
    session.Dirty = true
    session.Revision += 1
end

local function filterForPlayer(text, player)
    local success, result = pcall(function()
        local filtered =
            TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PrivateChat)
        return filtered:GetNonChatStringForUserAsync(player.UserId)
    end)
    if not success or type(result) ~= "string" then
        return nil
    end
    return trim(result)
end

local function upgradeSummary(player)
    local tycoon = workspace:FindFirstChild("CalmWorksTycoon")
    local building = tycoon and tycoon:FindFirstChild("Building")
    local stage = player:GetAttribute("CompletedExpansions") or 0
    local area = stage == 0 and building or building and building:FindFirstChild("ExpansionVisit" .. stage)
    local pads = area and area:FindFirstChild("UpgradePads")
    if not pads then
        return "This stage's upgrade details are unavailable."
    end
    local items = {}
    for _, pad in ipairs(pads:GetChildren()) do
        local name = pad:GetAttribute("DisplayName") or pad.Name
        local price = tonumber(pad:GetAttribute("Price")) or 0
        local prompt = pad:FindFirstChild("PurchasePrompt", true)
        local status = prompt and prompt.Enabled and "available" or "purchased or not active"
        table.insert(items, string.format("%s ($%d, %s)", tostring(name), price, status))
    end
    table.sort(items)
    return table.concat(items, ", ")
end

local function currentState(player)
    local measurements
    if getSupportState:GetAttribute("Ready") then
        local ok, value = pcall(function()
            return getSupportState:Invoke(player)
        end)
        if ok and type(value) == "table" then
            measurements = value
        end
    end
    return Grounding.State(player, Config, measurements, upgradeSummary(player))
end

local function rememberedState(player, session)
    local interval = math.clamp(tonumber(Config.SupportChatMemoryRefreshSeconds) or 120, 10, 600)
    return session.Memory:Get(os.clock(), interval, player:GetAttribute("DataLoaded") == true, function()
        local state = currentState(player)
        state.ProgressRefreshSeconds = interval
        return state
    end)
end

task.spawn(function()
    while task.wait(1) do
        for player, session in pairs(sessions) do
            if player.Parent and player:GetAttribute("DataLoaded") == true then
                rememberedState(player, session)
            end
        end
    end
end)

local function sendError(player, message, code)
    responseEvent:FireClient(player, { Action = "Error", Message = message, Code = code })
end

local function currentFRQ(player, id)
    if type(id) ~= "string" or #id > 100 or not getActiveFRQContext:GetAttribute("Ready") then
        return nil
    end
    local ok, context = pcall(function()
        return getActiveFRQContext:Invoke(player)
    end)
    return ok and context and context.Id == id and context or nil
end

local function handleSend(player, rawText, frqId, rawDraft)
    local session = sessions[player]
    if not session then
        sendError(player, UI.T("Support", "Loading"), "HistoryLoading")
        return
    end
    if not Config.SupportChatEnabled then
        sendError(player, UI.T("Support", "Disabled"))
        return
    end
    if session.Busy then
        sendError(player, UI.T("Support", "Busy"))
        return
    end
    local now = os.clock()
    local remaining = Config.SupportChatCooldownSeconds - (now - session.LastRequestAt)
    if remaining > 0 then
        sendError(player, UI.T("Support", "Cooldown", math.ceil(remaining), remaining > 1 and "s" or ""))
        return
    end
    if type(rawText) ~= "string" then
        sendError(player, UI.T("Support", "Unreadable"))
        return
    end
    if #rawText > Config.SupportChatMaxInputCharacters * 4 then
        sendError(player, UI.T("Support", "CharacterLimit", Config.SupportChatMaxInputCharacters))
        return
    end
    rawText = trim(rawText)
    local inputCharacters = utf8.len(rawText)
    if not inputCharacters or inputCharacters > Config.SupportChatMaxInputCharacters then
        sendError(player, UI.T("Support", "CharacterLimit", Config.SupportChatMaxInputCharacters))
        return
    end
    if rawText == "" then
        sendError(player, UI.T("Support", "EmptyServer"))
        return
    end
    local context = frqId ~= nil and currentFRQ(player, frqId) or nil
    if frqId ~= nil and not context then
        sendError(player, UI.T("FRQHelp", "Expired"), "FRQExpired")
        return
    end
    local draft = ""
    if context then
        draft = FRQHelpContext.ValidDraft(rawDraft, Config.FRQMaxCharacters)
    end
    if draft == nil then
        sendError(player, UI.T("FRQHelp", "DraftLimit", Config.FRQMaxCharacters))
        return
    end

    session.Busy = true
    session.LastRequestAt = now
    responseEvent:FireClient(player, { Action = "Status", Message = UI.T("Support", "Filtering") })
    local filteredUser = filterForPlayer(rawText, player)
    if not filteredUser or filteredUser == "" then
        session.Busy = false
        sendError(player, UI.T("Support", "FilterRejected"))
        return
    end

    if not player.Parent or sessions[player] ~= session then
        session.Busy = false
        return
    end
    local filteredDraft = ""
    if draft ~= "" then
        filteredDraft = filterForPlayer(draft, player)
    end
    if filteredDraft == nil then
        session.Busy = false
        sendError(player, UI.T("Support", "FilterRejected"))
        return
    end
    if context and not currentFRQ(player, frqId) then
        session.Busy = false
        sendError(player, UI.T("FRQHelp", "Expired"), "FRQExpired")
        return
    end
    addMessage(session, "user", filteredUser)
    responseEvent:FireClient(player, {
        Action = "Messages",
        Complete = false,
        Messages = { { Role = "user", Text = filteredUser, Timestamp = os.time() } },
    })
    responseEvent:FireClient(player, { Action = "Status", Message = UI.T("Support", "Thinking") })
    local state = rememberedState(player, session)
    if not state then
        session.Busy = false
        sendError(player, UI.T("Support", "Loading"))
        return
    end
    local userPrompt = Grounding.Prompt(state, session.History, filteredUser, Config)
    if context then
        userPrompt ..= FRQHelpContext.Prompt(context, filteredDraft)
    end
    local answer
    if not context then
        answer = Grounding.DirectAnswer(state, filteredUser, function(key, ...)
            return UI.T("Support", key, ...)
        end)
    end
    if not answer then
        -- Keep this snapshot for the whole reply, even if the next refresh occurs.
        local request = { UserPrompt = userPrompt, MaxTokens = Config.SupportChatMaxResponseTokens }
        local generatedOkay, generated = pcall(function()
            return generator:GenerateTextAsync(request)
        end)
        answer = generatedOkay and type(generated) == "table" and generated.GeneratedText or nil
        if type(answer) ~= "string" or trim(answer) == "" then
            warn("CalmWorks support generation unavailable; using the editable fallback.")
            answer = SAFE_FALLBACK
        end
    end
    local filteredAnswer =
        filterForPlayer(string.sub(answer, 1, Config.SupportChatMaxSavedMessageCharacters), player)
    if not filteredAnswer or filteredAnswer == "" then
        filteredAnswer = SAFE_FALLBACK
    end
    if not player.Parent or sessions[player] ~= session then
        session.Busy = false
        return
    end
    if context and not currentFRQ(player, frqId) then
        session.Busy = false
        sendError(player, UI.T("FRQHelp", "Expired"), "FRQExpired")
        task.spawn(saveSession, player, false)
        return
    end
    addMessage(session, "assistant", filteredAnswer)
    session.Busy = false
    responseEvent:FireClient(player, {
        Action = "Messages",
        Complete = true,
        Messages = { { Role = "assistant", Text = filteredAnswer, Timestamp = os.time() } },
    })
    task.spawn(saveSession, player, false)
end

requestEvent.OnServerEvent:Connect(function(player, payload)
    if type(payload) ~= "table" then
        return
    end
    if payload.Action == "History" then
        local session = sessions[player]
        if session then
            responseEvent:FireClient(player, { Action = "History", Messages = session.History })
        else
            sendError(player, UI.T("Support", "HistoryLoading"), "HistoryLoading")
        end
    elseif payload.Action == "Send" then
        task.spawn(handleSend, player, payload.Text, payload.FRQContextId, payload.Draft)
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.spawn(loadSession, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(loadSession, player)
end
Players.PlayerRemoving:Connect(function(player)
    saveSession(player, true)
    sessions[player] = nil
end)

task.spawn(function()
    while task.wait(Config.SupportChatAutosaveSeconds) do
        for player in pairs(sessions) do
            task.spawn(saveSession, player, false)
        end
    end
end)

game:BindToClose(function()
    local pending = 0
    for player, session in pairs(sessions) do
        if session.CanSave and session.Dirty then
            pending += 1
            task.spawn(function()
                saveSession(player, true)
                pending -= 1
            end)
        end
    end
    local deadline = os.clock() + 20
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)
