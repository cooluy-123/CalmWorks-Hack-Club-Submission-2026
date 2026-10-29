local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage:WaitForChild("CalmWorksShared")
local UI = require(Shared.EditableUI)
local GuidePolicy = require(Shared.ObjectiveGuidePolicy)

local player = Players.LocalPlayer
local gui = script.Parent
local root = gui:WaitForChild("ObjectiveBanner")
local banner = root:WaitForChild("Content")
local objectiveText = banner:WaitForChild("ObjectiveText")
local mentorText = banner:WaitForChild("TalkToBusinessManText")
local ceremonyText = banner:WaitForChild("CeremonyObjectiveText")
local completeText = banner:WaitForChild("CompleteText")
local notificationText = banner:WaitForChild("NotificationText")
local noticeTexts = ReplicatedStorage.CalmWorksShared.UIText:WaitForChild("Notifications")
local remotes = ReplicatedStorage:WaitForChild("CalmWorksRemotes")
local noticeEvent = remotes:WaitForChild("MilestoneNotice")
local noticeReceipt = remotes:WaitForChild("MilestoneNoticeReceipt")
local getNotices = remotes:WaitForChild("GetMilestoneNotices")
local noticeRelevant = remotes:WaitForChild("IsNotificationRelevant")
local checkingNotice = false
local soundReference = gui:WaitForChild("NotificationSound")
local hud = player.PlayerGui:WaitForChild("CalmWorksUI"):WaitForChild("HUD")

local shownPosition = banner.Position
local shownTransparency = banner.GroupTransparency
local state = "Hidden"
local currentObjective
local shownObjectives = {}
local previousOwnership
local animationId = 0
local activeTween
local warnedSound = false
local connections = {}
local noticeQueue = {}
local seenNotices = {}
local noticeSounds = {}
local eventNoticeHistory = {}
local currentNotice
local pumpNotifications
local currentGuide
local shownGuides = {}
local nextGuideAt = os.clock() + 20

local function connect(signal, callback)
    table.insert(connections, signal:Connect(callback))
end

local function numberSetting(name, fallback, minimum, maximum)
    local value = root:GetAttribute(name)
    if type(value) ~= "number" or value ~= value then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

local function loadingFinished()
    local loader = ReplicatedFirst:FindFirstChild("LoadingScreen")
    if not loader or loader.Disabled then
        return true
    end
    return player:GetAttribute("CalmWorksLoadingComplete") == true
end

local function setState(value)
    state = value
    root:SetAttribute("CurrentState", value)
end

local function placeBelowHUD()
    if root:GetAttribute("AutoPositionBelowHUD") == false then
        return
    end
    local bottom = hud.AbsolutePosition.Y + hud.AbsoluteSize.Y
    for _, object in ipairs(hud:GetDescendants()) do
        if object:IsA("GuiObject") and object.Visible then
            bottom = math.max(bottom, object.AbsolutePosition.Y + object.AbsoluteSize.Y)
        end
    end
    local y = bottom - gui.AbsolutePosition.Y + numberSetting("GapBelowHUD", 8, 0, 300)
    root.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset, 0, math.max(0, y))
end

local function hiddenPosition()
    local distance = root.AbsolutePosition.Y + banner.AbsoluteSize.Y
    distance += numberSetting("ExtraTopOffset", 12, 0, 500)
    return shownPosition - UDim2.fromOffset(0, distance)
end

local function cancelAnimation()
    animationId += 1
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
    return animationId
end

local function animate(position, transparency, seconds, ticket, onFinished)
    activeTween =
        TweenService:Create(banner, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = position,
            GroupTransparency = transparency,
        })
    activeTween.Completed:Once(function(playbackState)
        if ticket ~= animationId or not root.Parent or playbackState ~= Enum.PlaybackState.Completed then
            return
        end
        activeTween = nil
        if onFinished then
            onFinished()
        end
    end)
    activeTween:Play()
end

local function playNotification(setting)
    if root:GetAttribute(setting) == false then
        return
    end
    local sound = soundReference.Value
    if not sound or not sound:IsA("Sound") then
        if not warnedSound then
            warnedSound = true
            warn("CalmWorks objectives: set NotificationSound.Value to your notification Sound.")
        end
        return
    end
    -- Local playback prevents another player's objective from making a sound here.
    sound:Stop()
    sound.TimePosition = 0
    sound:Play()
end

local function dismissNotice()
    if currentNotice then
        -- A displayed milestone is consumed, even if a dialogue interrupts it.
        currentNotice = nil
        root:SetAttribute("CurrentNotification", nil)
        root:SetAttribute("PendingNotifications", #noticeQueue)
    end
end

local function hideObjective()
    currentGuide = nil
    root:SetAttribute("CurrentGuide", nil)
    currentObjective = nil
    root:SetAttribute("CurrentObjective", nil)
    dismissNotice()
    cancelAnimation()
    root.Visible = false
    setState("Hidden")
end

local function showObjective(kind)
    if state == "Active" and currentObjective == kind then
        return
    end
    dismissNotice()
    local ticket = cancelAnimation()
    placeBelowHUD()
    currentObjective = kind
    root:SetAttribute("CurrentObjective", kind)
    notificationText.Visible = false
    ceremonyText.Visible = kind == "Ceremony"
    mentorText.Visible = kind == "Mentor"
    objectiveText.Visible = kind == "Claim"
    completeText.Visible = false
    root.Visible = true
    banner.Position = hiddenPosition()
    banner.GroupTransparency = 1
    setState("Active")
    if not shownObjectives[kind] then
        shownObjectives[kind] = true
        playNotification("SoundOnShow")
    end
    animate(shownPosition, shownTransparency, numberSetting("EnterSeconds", 0.45, 0, 10), ticket)
end

local function completeObjective()
    currentObjective = nil
    root:SetAttribute("CurrentObjective", nil)
    if state == "Completing" or state == "Complete" then
        return
    end
    dismissNotice()
    local ticket = cancelAnimation()
    placeBelowHUD()
    notificationText.Visible = false
    ceremonyText.Visible = false
    mentorText.Visible = false
    objectiveText.Visible = false
    completeText.Visible = true
    if not root.Visible then
        banner.Position = hiddenPosition()
        banner.GroupTransparency = 1
    end
    root.Visible = true
    setState("Completing")
    playNotification("SoundOnComplete")
    animate(shownPosition, shownTransparency, numberSetting("EnterSeconds", 0.45, 0, 10), ticket, function()
        task.delay(numberSetting("CompleteHoldSeconds", 1.8, 0, 30), function()
            -- A newer objective or a removed GUI must cancel an old delayed exit.
            if ticket ~= animationId or not root.Parent then
                return
            end
            animate(hiddenPosition(), 1, numberSetting("ExitSeconds", 0.4, 0, 10), ticket, function()
                root.Visible = false
                setState("Complete")
            end)
        end)
    end)
end

local function blockedByDialogue()
    if player:GetAttribute("CeremonyActive") == true then
        return true
    end
    local playerGui = player.PlayerGui
    local effects = playerGui:FindFirstChild("CalmWorksFullScreenEffects")
    if effects then
        for _, name in ipairs({
            "TutorialOverlay",
            "FeedbackOverlay",
            "FRQFeedbackOverlay",
            "BusinessVisitOverlay",
        }) do
            local frame = effects:FindFirstChild(name)
            if frame and frame.Visible then
                return true
            end
        end
    end
    local main = playerGui:FindFirstChild("CalmWorksUI")
    if main and (main.Dialogue.Visible or main.AccuracyPanel.Visible) then
        return true
    end
    local support = playerGui:FindFirstChild("CalmWorksSupportUI")
    return support and support.SupportPanel.Visible == true
end

local function eventTemplate(id)
    return id:match("^Event:([%w_]+):[%x%-]+$")
end

local function noticeText(id)
    local template = eventTemplate(id) or id:match("^(M[35])_[1-4]$") or id
    return noticeTexts:FindFirstChild(template)
end

pumpNotifications = function()
    if
        currentNotice
        or checkingNotice
        or #noticeQueue == 0
        or root:GetAttribute("Enabled") == false
        or not loadingFinished()
    then
        return
    end
    if player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("OwnsBusiness") ~= true then
        return
    end
    if state == "Active" or state == "Completing" or blockedByDialogue() then
        return
    end
    local id = table.remove(noticeQueue, 1)
    root:SetAttribute("PendingNotifications", #noticeQueue)
    if eventTemplate(id) then
        checkingNotice = true
        local okay, relevant = pcall(function()
            return noticeRelevant:InvokeServer(id)
        end)
        checkingNotice = false
        if not okay or not relevant then
            noticeReceipt:FireServer(id)
            return
        end
        if blockedByDialogue() then
            table.insert(noticeQueue, 1, id)
            root:SetAttribute("PendingNotifications", #noticeQueue)
            return
        end
    end
    local shownAttribute = "MilestoneNoticeShown_" .. id
    if not eventTemplate(id) and player:GetAttribute(shownAttribute) == true then
        noticeReceipt:FireServer(id)
        return
    end
    local text = noticeText(id)
    if not text or not text:IsA("StringValue") or text:GetAttribute("Enabled") == false then
        noticeReceipt:FireServer(id)
        return
    end
    if not eventTemplate(id) then
        player:SetAttribute(shownAttribute, true)
    end
    currentGuide = nil
    root:SetAttribute("CurrentGuide", nil)
    nextGuideAt = os.clock() + numberSetting("ContextHintGapSeconds", 60, 15, 600)
    currentNotice = id
    root:SetAttribute("CurrentNotification", id)
    local ticket = cancelAnimation()
    placeBelowHUD()
    ceremonyText.Visible = false
    mentorText.Visible = false
    objectiveText.Visible = false
    completeText.Visible = false
    notificationText.Text = text.Value
    notificationText.Visible = true
    root.Visible = true
    banner.Position = hiddenPosition()
    banner.GroupTransparency = 1
    setState("Notifying")
    if not noticeSounds[id] and text:GetAttribute("PlaySound") ~= false then
        playNotification("SoundOnNotice")
        noticeSounds[id] = true
    end
    noticeReceipt:FireServer(id)
    local hold = text:GetAttribute("HoldSeconds")
    if type(hold) ~= "number" or hold ~= hold then
        hold = numberSetting("NotificationHoldSeconds", 6, 0.25, 60)
    end
    hold = math.clamp(hold, 0.25, 60)
    animate(shownPosition, shownTransparency, numberSetting("EnterSeconds", 0.45, 0, 10), ticket, function()
        task.delay(hold, function()
            if ticket ~= animationId or not root.Parent then
                return
            end
            animate(hiddenPosition(), 1, numberSetting("ExitSeconds", 0.4, 0, 10), ticket, function()
                currentNotice = nil
                root:SetAttribute("CurrentNotification", nil)
                root.Visible = false
                setState("Complete")
                pumpNotifications()
            end)
        end)
    end)
end

local function enqueueNotice(id)
    if type(id) ~= "string" or #id > 160 or seenNotices[id] or not noticeText(id) then
        return
    end
    if not eventTemplate(id) and player:GetAttribute("MilestoneNoticeShown_" .. id) == true then
        noticeReceipt:FireServer(id)
        return
    end
    if eventTemplate(id) then
        if #noticeQueue >= 64 then
            noticeReceipt:FireServer(id)
            return
        end
        table.insert(eventNoticeHistory, id)
        if #eventNoticeHistory > 128 then
            local oldest = table.remove(eventNoticeHistory, 1)
            seenNotices[oldest] = nil
            noticeSounds[oldest] = nil
        end
    end
    seenNotices[id] = true
    table.insert(noticeQueue, id)
    root:SetAttribute("PendingNotifications", #noticeQueue)
    pumpNotifications()
end

local function refreshObjective()
    if player:GetAttribute("DataLoaded") ~= true then
        previousOwnership = nil
        hideObjective()
        return
    end
    local ownsBusiness = player:GetAttribute("OwnsBusiness") == true
    local justClaimed = previousOwnership == false and ownsBusiness
    previousOwnership = ownsBusiness

    if root:GetAttribute("Enabled") == false or not loadingFinished() then
        hideObjective()
        return
    end
    if justClaimed then
        completeObjective()
    elseif ownsBusiness then
        if blockedByDialogue() then
            if state == "Active" then
                hideObjective()
            end
        elseif player:GetAttribute("CeremonyReady") == true then
            showObjective("Ceremony")
        elseif currentObjective == "Ceremony" and player:GetAttribute("GameCompleted") == true then
            completeObjective()
        elseif state == "Active" then
            hideObjective()
        end
    elseif blockedByDialogue() then
        hideObjective()
    elseif
        player:GetAttribute("TutorialCompleted") == true
        or root:GetAttribute("ShowAfterTutorial") == false
    then
        showObjective("Claim")
    elseif root:GetAttribute("ShowBeforeTutorial") ~= false then
        showObjective("Mentor")
    else
        hideObjective()
    end
end

local function chooseGuide()
    local characterRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local main = player.PlayerGui:FindFirstChild("CalmWorksUI")
    local visitors = {}
    if characterRoot then
        for _, model in ipairs(CollectionService:GetTagged("CalmWorksHelpVisitor")) do
            local head = model:FindFirstChild("Head")
            if head and model:IsDescendantOf(workspace)
                and model:GetAttribute("AttentionOwnerId") == player.UserId
                and model:GetAttribute("AttentionActive") == true then
                table.insert(visitors, {
                    Ready = model:GetAttribute("AttentionNeeded") == true
                        and model:GetAttribute("CounselorServing") ~= true,
                    Kind = model:GetAttribute("VisitorKind"),
                    Staff = model:GetAttribute("OnConsultation") == true,
                    Private = model:GetAttribute("PrivateSession") == true,
                    Room = model:GetAttribute("CounterArea") or "Main",
                    Distance = (head.Position - characterRoot.Position).Magnitude,
                })
            end
        end
    end
    return GuidePolicy.Choose({
        Ready = player:GetAttribute("DataLoaded") == true and loadingFinished(),
        Owns = player:GetAttribute("OwnsBusiness") == true,
        Blocked = blockedByDialogue() or not humanoid or humanoid.Health <= 0
            or root:GetAttribute("Enabled") == false or root:GetAttribute("ContextHintsEnabled") == false,
        Banner = state == "Active" or state == "Completing" or currentNotice ~= nil or checkingNotice or #noticeQueue > 0,
        Ceremony = player:GetAttribute("CeremonyReady") == true or player:GetAttribute("CeremonyActive") == true,
        Helped = player:GetAttribute("CustomersHelped") or 0,
        Reviewed = main and main.AccuracyPanel:GetAttribute("ProgressReviewed") == true,
        ExpansionReady = player:GetAttribute("NextExpansionReady") == true or player:GetAttribute("FinalVisitReady") == true,
        Online = player:GetAttribute("OnlineConsultationsUnlocked") == true,
        Won = player:GetAttribute("GameCompleted") == true,
    }, visitors)
end

local function updateGuide()
    local choice = chooseGuide()
    if currentGuide and (not choice or choice.Key ~= currentGuide) then
        hideObjective()
    end
    if not choice or currentGuide or root.Visible or os.clock() < nextGuideAt or shownGuides[choice.Key] then
        return
    end
    local template = Shared.UIText.ObjectiveGuide:FindFirstChild(choice.Key)
    if not template or template:GetAttribute("Enabled") == false then
        return
    end
    local room = choice.Room and UI.T("ObjectiveGuide", "Room" .. choice.Room) or ""
    notificationText.Text = UI.T("ObjectiveGuide", choice.Key, room)
    notificationText.Visible = true
    objectiveText.Visible, mentorText.Visible, ceremonyText.Visible, completeText.Visible = false, false, false, false
    currentGuide = choice.Key
    shownGuides[choice.Key] = true
    root:SetAttribute("CurrentGuide", currentGuide)
    nextGuideAt = os.clock() + numberSetting("ContextHintGapSeconds", 60, 15, 600)
    local ticket = cancelAnimation()
    placeBelowHUD()
    root.Visible = true
    banner.Position = hiddenPosition()
    banner.GroupTransparency = 1
    setState("Guiding")
    -- Hints reuse the existing banner silently and never replace a real notification.
    animate(shownPosition, shownTransparency, numberSetting("EnterSeconds", 0.45, 0, 10), ticket, function()
        task.delay(numberSetting("ContextHintHoldSeconds", 5, 2, 20), function()
            if ticket ~= animationId or not root.Parent then
                return
            end
            animate(hiddenPosition(), 1, numberSetting("ExitSeconds", 0.4, 0, 10), ticket, function()
                currentGuide = nil
                root:SetAttribute("CurrentGuide", nil)
                root.Visible = false
                setState("Complete")
            end)
        end)
    end)
end

root.Visible = false
setState("Hidden")
for _, name in ipairs({ "DataLoaded", "OwnsBusiness", "TutorialCompleted", "CalmWorksLoadingComplete", "CeremonyReady", "CeremonyActive", "GameCompleted" }) do
    connect(player:GetAttributeChangedSignal(name), refreshObjective)
end
connect(root:GetAttributeChangedSignal("Enabled"), refreshObjective)
connect(root:GetAttributeChangedSignal("ShowAfterTutorial"), refreshObjective)
connect(root:GetAttributeChangedSignal("ShowBeforeTutorial"), refreshObjective)
connect(root:GetAttributeChangedSignal("AutoPositionBelowHUD"), placeBelowHUD)
connect(root:GetAttributeChangedSignal("GapBelowHUD"), placeBelowHUD)
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), placeBelowHUD)
connect(gui:GetPropertyChangedSignal("AbsolutePosition"), placeBelowHUD)
connect(hud:GetPropertyChangedSignal("AbsolutePosition"), placeBelowHUD)
connect(hud:GetPropertyChangedSignal("AbsoluteSize"), placeBelowHUD)
for _, object in ipairs(hud:GetDescendants()) do
    if object:IsA("GuiObject") then
        connect(object:GetPropertyChangedSignal("AbsolutePosition"), placeBelowHUD)
        connect(object:GetPropertyChangedSignal("AbsoluteSize"), placeBelowHUD)
        connect(object:GetPropertyChangedSignal("Visible"), placeBelowHUD)
    end
end
gui.Destroying:Connect(function()
    cancelAnimation()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end)

connect(noticeEvent.OnClientEvent, enqueueNotice)
placeBelowHUD()
refreshObjective()
task.spawn(function()
    local ok, pending = pcall(function()
        return getNotices:InvokeServer()
    end)
    if ok and type(pending) == "table" then
        for _, id in ipairs(pending) do
            enqueueNotice(id)
        end
    end
end)
task.spawn(function()
    while gui.Parent do
        refreshObjective()
        if currentNotice and blockedByDialogue() then
            dismissNotice()
            cancelAnimation()
            root.Visible = false
            setState("Complete")
        end
        pumpNotifications()
        updateGuide()
        task.wait(0.15)
    end
end)