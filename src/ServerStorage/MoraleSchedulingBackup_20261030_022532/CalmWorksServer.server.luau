-- Use the template references so moving editor folders does not duplicate live upgrades.
do
    local storage = game:GetService("ReplicatedStorage")
    local shared = storage:WaitForChild("CalmWorksShared")
    for i = 1, 4 do
        local settings = shared:FindFirstChild("BusinessVisit" .. i)
        if settings then
            for _, name in ipairs({ "PadsTemplate", "ItemsTemplate" }) do
                local reference = settings:FindFirstChild(name)
                local template = reference and reference.Value
                if template and template:IsDescendantOf(workspace) then
                    template.Parent = storage
                end
            end
        end
    end
end

local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local FRQHelpContext = require(ServerStorage:WaitForChild("FRQHelpContext"))
local FRQGradePolicy = require(ServerStorage:WaitForChild("FRQGradePolicy"))
local AnswerSubmission = require(ServerStorage:WaitForChild("AnswerSubmission"))

local Shared = ReplicatedStorage:WaitForChild("CalmWorksShared")
local Config = require(Shared:WaitForChild("Config"))
local ScenarioLibrary = require(ServerStorage:WaitForChild("ScenarioLibrary"))
local DialogueGenerator = require(ServerStorage:WaitForChild("DialogueGenerator"))
local AdaptiveSkills = require(ServerStorage:WaitForChild("AdaptiveSkills"))
local FRQGrader = require(ServerStorage:WaitForChild("FRQGrader"))
local ScenarioAI = require(ServerStorage:WaitForChild("ScenarioAIService"))
local CustomerBehavior = require(ServerStorage:WaitForChild("CustomerBehavior"))
local PracticeRecommendations = require(ServerStorage:WaitForChild("PracticeRecommendations"))
local ProgressCalendar = require(Shared:WaitForChild("ProgressCalendar"))
local ProgressHistory = require(ServerStorage:WaitForChild("ProgressHistory"))
local SupportGrounding = require(ServerStorage:WaitForChild("SupportGrounding"))
local PracticePolicy = require(ServerStorage:WaitForChild("PracticeModePolicy"))
local MilestoneProgress = require(ServerStorage:WaitForChild("MilestoneProgress"))
local BusinessExpansion = require(ServerStorage:WaitForChild("BusinessExpansion"))
local TycoonProgression = require(ServerStorage:WaitForChild("TycoonProgression"))
local CustomerValues = require(ServerStorage:WaitForChild("CustomerValues"))
local PersonalConsultationPolicy = require(ServerStorage:WaitForChild("PersonalConsultationPolicy"))
local personalSettings = Shared:WaitForChild("PersonalConsultations")
local PlayerHelpPacing = require(ServerStorage:WaitForChild("PlayerHelpPacing"))
local helpPacing = PlayerHelpPacing.New(Shared:WaitForChild("PlayerHelpPacing"))
local CustomerCounters = require(ServerStorage:WaitForChild("CustomerCounters"))
local MentorInteraction = require(ServerStorage:WaitForChild("MentorInteraction"))
local CustomerRouting = require(ServerStorage:WaitForChild("CustomerRouting"))
local CustomerSpawnSchedule = require(ServerStorage:WaitForChild("CustomerSpawnSchedule"))
local BusinessRates = require(ServerStorage:WaitForChild("BusinessRates"))
local StaffConcernPolicy = require(ServerStorage:WaitForChild("StaffConcernPolicy"))
local StaffConsultations = require(ServerStorage:WaitForChild("StaffConsultations"))
local StaffMoralePolicy = require(ServerStorage:WaitForChild("StaffMoralePolicy"))
local StaffMoraleService = require(ServerStorage:WaitForChild("StaffMoraleService"))
local DashboardPolicy = require(ServerStorage:WaitForChild("DashboardPolicy"))
local DashboardService = require(ServerStorage:WaitForChild("DashboardService"))
local PrivateSessions = require(ServerStorage:WaitForChild("PrivateSessions"))
local PrivateSessionPolicy = require(ServerStorage:WaitForChild("PrivateSessionPolicy"))
local CustomerNoticePolicy = require(ServerStorage:WaitForChild("CustomerNoticePolicy"))
local noticeSettings = Shared:WaitForChild("CustomerNotifications")
local lastSpecialNoticeAt = -math.huge
local StaffRoutePolicy = require(ServerStorage:WaitForChild("StaffRoutePolicy"))
local NPCCollision = require(ServerStorage:WaitForChild("NPCCollision"))
local finalVisitSettings = Shared:WaitForChild("FinalBusinessVisit")
local privateSettings = Shared:WaitForChild("PrivateSessions")
local dashboardSettings = Shared:WaitForChild("Dashboard")
local moraleSettings = Shared:WaitForChild("EmployeeMorale")
local staffSettings = Shared:WaitForChild("StaffConsultations")
local valueSettings = Shared:WaitForChild("CustomerValues")
local visitSettings = {}
for i = 1, TycoonProgression.ExpansionCount do
    visitSettings[i] = Shared:WaitForChild("BusinessVisit" .. i)
end

-- Every building part below this model is an editable Studio object.
local tycoon = workspace:WaitForChild("CalmWorksTycoon")
local claimPad = tycoon:WaitForChild("ClaimPad")
local building = tycoon:WaitForChild("Building")
local baseItems = building:WaitForChild("BaseItems")
local upgradePads = building:WaitForChild("UpgradePads")
local upgradeItems = building:WaitForChild("UpgradeItems")
local customerPoints = ServerStorage:WaitForChild("CustomerPoints")
local customersFolder = tycoon:FindFirstChild("Customers") or Instance.new("Folder")
customersFolder.Name = "Customers"
customersFolder.Parent = tycoon
local noobTemplate = ServerStorage:WaitForChild("CalmWorksNoobTemplate")
local hairTemplate = ServerStorage:WaitForChild("CalmWorksHairTemplate")

local remotes = ReplicatedStorage:FindFirstChild("CalmWorksRemotes") or Instance.new("Folder")
remotes.Name = "CalmWorksRemotes"
remotes.Parent = ReplicatedStorage
local openDialogue = remotes:FindFirstChild("OpenDialogue") or Instance.new("RemoteEvent")
openDialogue.Name = "OpenDialogue"
openDialogue.Parent = remotes
local submitAnswer = remotes:FindFirstChild("SubmitAnswer") or Instance.new("RemoteFunction")
submitAnswer.Name = "SubmitAnswer"
submitAnswer.Parent = remotes
local completeTutorial = remotes:FindFirstChild("CompleteTutorial") or Instance.new("RemoteEvent")
completeTutorial.Name = "CompleteTutorial"
completeTutorial.Parent = remotes
local getAccuracyData = remotes:FindFirstChild("GetAccuracyData") or Instance.new("RemoteFunction")
getAccuracyData.Name = "GetAccuracyData"
getAccuracyData.Parent = remotes
local accuracyUpdated = remotes:FindFirstChild("AccuracyUpdated") or Instance.new("RemoteEvent")
accuracyUpdated.Name = "AccuracyUpdated"
accuracyUpdated.Parent = remotes

local cashBalanceChanged = remotes:WaitForChild("CashBalanceChanged")
local actionRejected = remotes:WaitForChild("ActionRejected")
local getProgressView = remotes:WaitForChild("GetProgressView")
local setPracticeMode = remotes:WaitForChild("SetPracticeMode")
local milestoneNotice = remotes:WaitForChild("MilestoneNotice")
local noticeReceipt = remotes:WaitForChild("MilestoneNoticeReceipt")
local getMilestoneNotices = remotes:WaitForChild("GetMilestoneNotices")
local openBusinessVisit = remotes:WaitForChild("OpenBusinessVisit")
local closeBusinessVisit = remotes:WaitForChild("CloseBusinessVisit")
local advanceBusinessVisit = remotes:WaitForChild("AdvanceBusinessVisit")
local lastActionRejectionAt = {}
local function rejectAction(player, reason)
    if not player or player.Parent ~= Players then
        return
    end
    local now = os.clock()
    -- Throttle server notifications as well as local playback; no broadcast or client relay.
    if now - (lastActionRejectionAt[player] or -math.huge) < 0.5 then
        return
    end
    lastActionRejectionAt[player] = now
    actionRejected:FireClient(player, reason)
end

local owner
local firstCustomerAt = 0
local generation = 0
local customerQueue = {}
local customerData = {}
local counters
local staffVisits
local staffMorale
local dashboard
local privateSessions
local ceremony
local tryStaffVisit
local stageMaxed
local activeCustomer
local function setActiveCustomer(model)
    if typeof(activeCustomer) == "Instance" and activeCustomer:IsA("Model") then
        activeCustomer:SetAttribute("ConversationOwnerId", nil)
    end
    activeCustomer = model
    if typeof(model) == "Instance" and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
        model:SetAttribute("ConversationOwnerId", owner and owner.UserId or nil)
    end
end
local businessVisitor
local expansions = {}
local checkStageProgress
local ensureBusinessVisit
local openMentorConversation
local function isActionableCustomer(model)
    local data = customerData[model]
    if data and data.Private then
        return privateSessions and privateSessions:IsReady(model)
    end
    return counters:IsFront(model)
end

local getActiveFRQContext = ServerStorage:WaitForChild("GetActiveFRQContext")
getActiveFRQContext.OnInvoke = function(player)
    if dashboard and dashboard:IsActive(player) then
        return dashboard:Help(player)
    end
    local data = activeCustomer and customerData[activeCustomer]
    if data and data.Kind == "BusinessMan" then
        return nil
    end
    return FRQHelpContext.Build(
        activeCustomer and customerData[activeCustomer],
        player == owner and activeCustomer ~= nil and isActionableCustomer(activeCustomer)
    )
end
getActiveFRQContext:SetAttribute("Ready", true)
local purchasedUpgrades = {}
local playerSessions = {}
local function hasExpandedLines()
    return owner ~= nil and owner:GetAttribute("Expansion1Active") == true
end

local function hasUpstairs()
    return owner ~= nil and owner:GetAttribute("Expansion2Active") == true
end

local function hasCounterStaff(area)
    local session = owner and playerSessions[owner]
    local index, id = "1", area .. "Counselor"
    if CustomerRouting.IsUpper(area) then
        index, id = "2", area .. "ExecutiveConsulter"
    end
    local purchases = session and session.ExpansionPurchases[index]
    local expansion = expansions[tonumber(index)]
    local items = expansion and expansion.Container and expansion.Container:FindFirstChild("Items")
    local model = items and items:FindFirstChild(id)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    return purchases ~= nil and purchases[id] == true and humanoid ~= nil and humanoid.Health > 0
end
local function isCounterStaffed(area)
    local role = CustomerRouting.IsUpper(area) and "Executive" or "Counselor"
    if staffVisits and staffVisits:Away(area, role) then
        return false
    end
    return hasCounterStaff(area)
end

local function executiveAvailable(area)
    return staffSettings:GetAttribute("ExecutiveAutoHelpEnabled") ~= false
        and CustomerRouting.IsUpper(area) and isCounterStaffed(area)
end

local function canExecutiveHelp(data, area)
    return data ~= nil and data.Kind == "Staff" and data.Angry ~= true
        and data.PersonalHelp ~= true and data.StaffHomeRoom ~= area
        and executiveAvailable(area)
end

local function hasAutomaticStaffRoom(home)
    for _, area in ipairs({"UpperLeft", "UpperRight"}) do
        if area ~= home and executiveAvailable(area) and counters:CanAccept(area, true) then
            return true
        end
    end
    return false
end

local function helpContext(exclude)
    local result = {Count = 0, Rooms = {}, Busy = activeCustomer ~= nil, StaffPriority = false}
    for model, data in pairs(customerData) do
        if model ~= exclude and model.Parent then
            local staffed = hasCounterStaff(data.Area)
            if data.Private then
                staffed = privateSessions and privateSessions:IsStaffed(data.PrivateStation) or false
            end
            if PlayerHelpPacing.RequiresPlayer(data, staffed, canExecutiveHelp(data, data.Area)) then
                result.Count += 1
                result.Rooms[data.Area] = (result.Rooms[data.Area] or 0) + 1
            end
        end
    end
    local session = owner and playerSessions[owner]
    if session and session.TycoonProgress.CompletedExpansions >= 3 and staffVisits
        and not staffVisits.Active and os.clock() >= staffVisits.NextVisitAt then
        local candidate = staffMorale:Candidate(function(staff)
            if not staffVisits:CanTake(staff) or (staff.Private and privateSessions:Busy(staff.Area)) then
                return false
            end
            local room = staff.Room or staff.Area
            if hasAutomaticStaffRoom(room) then
                return false
            end
            if CustomerRouting.IsUpper(room) then
                local other = room == "UpperLeft" and "UpperRight" or "UpperLeft"
                return counters:CanAccept(other, true) and (result.Rooms[other] or 0) == 0
            end
            for _, area in ipairs({"UpperLeft", "UpperRight"}) do
                if counters:CanAccept(area, true) and (result.Rooms[area] or 0) == 0 then
                    return true
                end
            end
            return false
        end)
        result.StaffPriority = candidate ~= nil
        if not result.StaffPriority and session.StaffConcerns.Pending then
            for _, staff in ipairs(StaffMoralePolicy.Roster) do
                if staffVisits:CanTake(staff) and not (staff.Private and privateSessions:Busy(staff.Area)) then
                    local room = staff.Room or staff.Area
                    for _, destination in ipairs({"UpperLeft", "UpperRight"}) do
                        if not hasAutomaticStaffRoom(room) and destination ~= room
                            and counters:CanAccept(destination, true)
                            and (result.Rooms[destination] or 0) == 0 then
                            result.StaffPriority = true
                            break
                        end
                    end
                end
                if result.StaffPriority then
                    break
                end
            end
        end
    end
    return result
end

local function allowPlayerRequest(kind, area, exclude)
    return helpPacing:CanRequest(helpContext(exclude), kind, area)
end

local function roomUpgrades(area)
    local session = owner and playerSessions[owner]
    local result = BusinessRates.Upgrades(session and session.ExpansionPurchases or {}, visitSettings, area)
    if staffVisits and staffVisits:Away(area, "Manager") then
        result.Managed = false
    end
    return result
end

local function roomArrivalMultiplier(area)
    local boost = dashboard and dashboard:Multiplier("Arrival") or 1
    return roomUpgrades(area).PaintingMultiplier * boost
end

local function counselorServiceSeconds(area)
    local stars = owner and owner:GetAttribute("Stars") or 0
    local seconds = BusinessRates.ServiceSeconds(
        Config,
        valueSettings,
        stars,
        roomUpgrades(area).Managed,
        CustomerRouting.IsUpper(area)
    )
    local multiplier = staffMorale and staffMorale:Multiplier(area) or 1
    local boost = dashboard and dashboard:Multiplier("Service") or 1
    return math.clamp(seconds / multiplier / boost, 0.25, 240)
end
local dataStore = DataStoreService:GetDataStore(Config.DataStoreName)
local dataStoreEnabled = not RunService:IsStudio() or Config.SaveInStudio
local SessionStore = require(ServerStorage:WaitForChild("SessionStore"))
local playerStore = SessionStore.New(dataStore, Config, 9)

local GIRL_CUSTOMER_NAMES =
    { "Ava", "Chloe", "Emma", "Isabella", "Lily", "Maya", "Mia", "Olivia", "Sophia", "Zoe" }
local BOY_CUSTOMER_NAMES =
    { "Caleb", "Ethan", "Henry", "Jack", "Leo", "Liam", "Lucas", "Mason", "Noah", "Owen" }
local TORSO_COLORS = {
    Color3.fromRGB(13, 105, 172),
    Color3.fromRGB(196, 40, 28),
    Color3.fromRGB(75, 151, 75),
    Color3.fromRGB(123, 47, 123),
    Color3.fromRGB(218, 133, 65),
}

local PLAYER_COLLISION_GROUP = "CalmWorksPlayers"
local CUSTOMER_COLLISION_GROUP = "CalmWorksCustomers"

local CATEGORY_DEFINITIONS = assert(
    ScenarioLibrary.Metadata and ScenarioLibrary.Metadata.Categories,
    "ScenarioLibrary.Metadata.Categories is required for accuracy tracking"
)
local recommendationTemplates = ServerStorage:WaitForChild("RecommendationTemplates")
local function recommendationTemplate(name, fallback)
    local item = recommendationTemplates:FindFirstChild(name)
    return item and item:IsA("StringValue") and item.Value ~= "" and item.Value or fallback
end
local CATEGORY_BY_CODE = {}
for _, category in ipairs(CATEGORY_DEFINITIONS) do
    CATEGORY_BY_CODE[category.Code] = category
end

local function defaultCategoryAccuracy()
    local accuracy = {}
    for _, category in ipairs(CATEGORY_DEFINITIONS) do
        accuracy[category.Code] = AdaptiveSkills.NewStats()
    end
    return accuracy
end

local function sanitizeAnswerCount(value)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return 0
    end
    return math.max(0, math.floor(value))
end

-- Register once on the server. pcall also makes this safe when the groups were
-- already added through Studio's Collision Groups editor.
pcall(function()
    PhysicsService:RegisterCollisionGroup(PLAYER_COLLISION_GROUP)
end)
pcall(function()
    PhysicsService:RegisterCollisionGroup(CUSTOMER_COLLISION_GROUP)
end)
PhysicsService:CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP, CUSTOMER_COLLISION_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CUSTOMER_COLLISION_GROUP, CUSTOMER_COLLISION_GROUP, false)
NPCCollision.Start(building)

local function assignCollisionGroup(root, groupName)
    if root:IsA("BasePart") then
        root.CollisionGroup = groupName
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = groupName
        end
    end
end

local function configurePlayerCharacter(player)
    local function onCharacter(character)
        assignCollisionGroup(character, PLAYER_COLLISION_GROUP)
        character.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("BasePart") then
                descendant.CollisionGroup = PLAYER_COLLISION_GROUP
            end
        end)
    end
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        onCharacter(player.Character)
    end
end

local function rememberVisual(instance)
    if instance:IsA("Decal") or instance:IsA("Texture") then
        if instance:GetAttribute("CalmWorksTransparency") == nil then
            instance:SetAttribute("CalmWorksTransparency", instance.Transparency)
        end
    elseif instance:IsA("BasePart") then
        if instance:GetAttribute("CalmWorksTransparency") == nil then
            instance:SetAttribute("CalmWorksTransparency", instance.Transparency)
            instance:SetAttribute("CalmWorksCanCollide", instance.CanCollide)
        end
        if instance:GetAttribute("CalmWorksCanTouch") == nil then
            instance:SetAttribute("CalmWorksCanTouch", instance.CanTouch)
            instance:SetAttribute("CalmWorksCanQuery", instance.CanQuery)
        end
    elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("Light") then
        if instance:GetAttribute("CalmWorksEnabled") == nil then
            instance:SetAttribute("CalmWorksEnabled", instance.Enabled)
        end
    elseif instance:IsA("ProximityPrompt") then
        if instance:GetAttribute("CalmWorksEnabled") == nil then
            instance:SetAttribute("CalmWorksEnabled", instance.Enabled)
        end
    end
end

local function setVisible(root, visible)
    rememberVisual(root)
    for _, instance in ipairs(root:GetDescendants()) do
        rememberVisual(instance)
        if instance:IsA("Decal") or instance:IsA("Texture") then
            instance.Transparency = visible and instance:GetAttribute("CalmWorksTransparency") or 1
        elseif instance:IsA("BasePart") then
            instance.Transparency = visible and instance:GetAttribute("CalmWorksTransparency") or 1
            instance.CanCollide = visible and instance:GetAttribute("CalmWorksCanCollide") or false
            instance.CanTouch = visible and instance:GetAttribute("CalmWorksCanTouch") or false
            instance.CanQuery = visible and instance:GetAttribute("CalmWorksCanQuery") or false
        elseif
            instance:IsA("BillboardGui")
            or instance:IsA("SurfaceGui")
            or instance:IsA("Light")
            or instance:IsA("ProximityPrompt")
        then
            instance.Enabled = visible and instance:GetAttribute("CalmWorksEnabled") or false
        end
    end
    if root:IsA("BasePart") then
        root.Transparency = visible and root:GetAttribute("CalmWorksTransparency") or 1
        root.CanCollide = visible and root:GetAttribute("CalmWorksCanCollide") or false
        root.CanTouch = visible and root:GetAttribute("CalmWorksCanTouch") or false
        root.CanQuery = visible and root:GetAttribute("CalmWorksCanQuery") or false
    end
end

local function hideEditorMarkers()
    for _, instance in ipairs(customerPoints:GetDescendants()) do
        if instance:IsA("BasePart") then
            instance.Transparency = 1
            instance.CanCollide = false
            instance.CanTouch = false
            instance.CanQuery = false
        elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
            instance.Enabled = false
        end
    end
end

local function defaultPlayerData()
    return {
        Version = 9,
        ProgressHistory = {},
        Money = Config.StartingCash,
        CustomersHelped = 0,
        Purchases = {},
        CategoryAccuracy = defaultCategoryAccuracy(),
        AnswerHistory = {},
        RecentScenarioIds = {},
        RecentCustomerProfiles = {},
        TutorialCompleted = false,
        Milestones = MilestoneProgress.Restore(nil),
        TycoonProgress = TycoonProgression.Clean(nil),
        ExpansionPurchases = {},
        CustomerValues = CustomerValues.Clean(nil, 100),
        StaffConcerns = StaffConcernPolicy.Clean(nil),
        StaffMorale = StaffMoralePolicy.Clean(nil),
        Dashboard = DashboardPolicy.Clean(nil),
    }
end

local function sanitizePlayerData(rawData)
    local data = defaultPlayerData()
    if type(rawData) ~= "table" or rawData.Version ~= 9 then
        return data
    end
    data.ProgressHistory =
        ProgressHistory.Clean(rawData.ProgressHistory, CATEGORY_DEFINITIONS, Config, os.time())
    if type(rawData.Money) == "number" then
        data.Money = math.max(0, math.floor(rawData.Money))
    end
    if type(rawData.CustomersHelped) == "number" then
        data.CustomersHelped = math.max(0, math.floor(rawData.CustomersHelped))
    end
    data.CustomerValues = CustomerValues.Clean(rawData.CustomerValues, 100)
    data.StaffConcerns = StaffConcernPolicy.Clean(rawData.StaffConcerns)
    data.StaffMorale = StaffMoralePolicy.Clean(rawData.StaffMorale)
    data.Dashboard = DashboardPolicy.Clean(rawData.Dashboard)
    data.RecentScenarioIds = DialogueGenerator.CleanRecentIds(rawData.RecentScenarioIds)
    data.RecentCustomerProfiles = CustomerBehavior.CleanRecentProfiles(
        rawData.RecentCustomerProfiles,
        math.clamp(Config.CustomerRecentProfileWindow or 6, 1, 30)
    )
    data.Milestones = MilestoneProgress.Restore(rawData.Milestones)
    data.TycoonProgress = TycoonProgression.Clean(rawData.TycoonProgress)
    local savedPurchases = type(rawData.ExpansionPurchases) == "table" and rawData.ExpansionPurchases or {}
    for i = 1, data.TycoonProgress.CompletedExpansions do
        local key = tostring(i)
        data.ExpansionPurchases[key] = BusinessExpansion.ValidPurchases(savedPurchases[key], visitSettings[i])
    end
    if type(rawData.Purchases) == "table" then
        -- The original $50 Couches purchase was split into two $25 sofa sets.
        -- Existing owners keep everything they already paid for.
        if rawData.Purchases.Couches == true then
            data.Purchases.LeftSofas = true
            data.Purchases.RightSofas = true
        end
        for id, purchased in pairs(rawData.Purchases) do
            if type(id) == "string" and purchased == true and upgradeItems:FindFirstChild(id) then
                data.Purchases[id] = true
            end
        end
    end
    if type(rawData.CategoryAccuracy) == "table" then
        for _, category in ipairs(CATEGORY_DEFINITIONS) do
            local saved = rawData.CategoryAccuracy[category.Code]
            if type(saved) == "table" then
                data.CategoryAccuracy[category.Code] = AdaptiveSkills.RestoreStats(saved, Config)
            end
        end
    end
    if type(rawData.AnswerHistory) == "table" then
        for _, entry in ipairs(rawData.AnswerHistory) do
            local clean = AdaptiveSkills.CleanHistoryEntry(entry, CATEGORY_BY_CODE)
            if clean then
                table.insert(data.AnswerHistory, clean)
                if #data.AnswerHistory > Config.AccuracyWindowSize then
                    table.remove(data.AnswerHistory, 1)
                end
            end
        end
    end
    if type(rawData.TutorialCompleted) == "boolean" then
        data.TutorialCompleted = rawData.TutorialCompleted
    elseif data.CustomersHelped > 0 or next(data.Purchases) ~= nil then
        -- Players with legacy progress are not treated as brand-new players.
        data.TutorialCompleted = true
    end
    return data
end

local function markDirty(player)
    local session = playerSessions[player]
    if session then
        session.Dirty = true
        session.Revision += 1
    end
end

local savePlayerData

local function sendMilestone(player, id)
    local session = playerSessions[player]
    if not session or not MilestoneProgress.Notice(session.Milestones, id) then
        return
    end
    table.insert(session.PendingNotices, id)
    markDirty(player)
    milestoneNotice:FireClient(player, id)
    task.spawn(savePlayerData, player, true)
end

local function customerNeedsNotice(model, ready)
    local data = model and customerData[model]
    if not data or not model.Parent then
        return false
    end
    local staffed = hasCounterStaff(data.Area)
    if data.Private then
        staffed = privateSessions and privateSessions:IsStaffed(data.PrivateStation) or false
    end
    if ready then
        return CustomerNoticePolicy.Ready(data, staffed, activeCustomer ~= nil, isActionableCustomer(model), noticeSettings, canExecutiveHelp(data, data.Area))
    end
    return CustomerNoticePolicy.NeedsHelp(data, staffed, activeCustomer == model, canExecutiveHelp(data, data.Area))
end

local function sendEventNotice(player, templateName, model)
    local session = playerSessions[player]
    local text = Shared.UIText.Notifications:FindFirstChild(templateName)
    if not session or player ~= owner or not text or not text:IsA("StringValue") then
        return
    end
    if text:GetAttribute("Enabled") == false then
        return
    end

    local data = model and customerData[model]
    if model then
        if not data or data.NoticeSent or not customerNeedsNotice(model) or noticeSettings:GetAttribute("Enabled") == false then
            if data then
                data.PendingNotice = nil
                -- Recheck staff requests if their executive becomes unavailable.
                if data.Kind == "Staff" and not data.NoticeSent then
                    data.PendingNotice = templateName
                end
            end
            return
        end
        data.PendingNotice = templateName
        if not customerNeedsNotice(model, true) or not CustomerNoticePolicy.GapReady(noticeSettings, lastSpecialNoticeAt, os.clock()) then
            return
        end
    end

    -- Arrival notices are once per event, not saved once-ever milestones.
    local pending = session.PendingNotices
    local eventCount = 0
    local oldestEvent
    for i, id in ipairs(pending) do
        if string.sub(id, 1, 6) == "Event:" then
            eventCount += 1
            oldestEvent = oldestEvent or i
        end
    end
    if eventCount >= 32 then
        local expired = table.remove(pending, oldestEvent)
        if session.NoticeTargets then
            session.NoticeTargets[expired] = nil
        end
    end
    local id = "Event:" .. templateName .. ":" .. HttpService:GenerateGUID(false)
    session.NoticeTargets = session.NoticeTargets or {}
    if model then
        session.NoticeTargets[id] = { Model = model, ExpiresAt = os.clock() + 120 }
    end
    table.insert(pending, id)
    if data then
        data.NoticeSent = true
        data.PendingNotice = nil
        lastSpecialNoticeAt = os.clock()
    end
    milestoneNotice:FireClient(player, id)
    return id
end

local noticeRelevant = remotes:WaitForChild("IsNotificationRelevant")
noticeRelevant.OnServerInvoke = function(player, id)
    local session = playerSessions[player]
    if not session or type(id) ~= "string" or #id > 160 then
        return false
    end
    local target = session.NoticeTargets and session.NoticeTargets[id]
    if target then
        return player == owner and os.clock() < target.ExpiresAt and customerNeedsNotice(target.Model, true)
    end
    return table.find(session.PendingNotices, id) ~= nil
end

getMilestoneNotices.OnServerInvoke = function(player)
    local session = playerSessions[player]
    return session and table.clone(session.PendingNotices) or {}
end
noticeReceipt.OnServerEvent:Connect(function(player, id)
    local session = playerSessions[player]
    if not session or type(id) ~= "string" then
        return
    end
    if session.NoticeTargets then
        session.NoticeTargets[id] = nil
    end
    local index = table.find(session.PendingNotices, id)
    if index then
        table.remove(session.PendingNotices, index)
    end
end)

local retargetWaitingCustomers
local function currentPracticeTargets(session)
    return PracticePolicy.Targets(
        session and session.AnswerHistory or {},
        CATEGORY_DEFINITIONS,
        Config,
        session and session.PracticeEnabled and session.PracticeTargets or nil
    )
end
local function makeAccuracySnapshot(player)
    local session = playerSessions[player]
    local counts = {}
    for _, category in ipairs(CATEGORY_DEFINITIONS) do
        counts[category.Code] = { Correct = 0, Incorrect = 0 }
    end
    for _, entry in ipairs(session and session.AnswerHistory or {}) do
        local count = counts[entry.Code]
        if count then
            if entry.Correct then
                count.Correct += 1
            else
                count.Incorrect += 1
            end
        end
    end
    local categories = {}
    local totalCorrect, totalIncorrect = 0, 0
    for _, category in ipairs(CATEGORY_DEFINITIONS) do
        local stats = session and session.CategoryAccuracy[category.Code]
        local count = counts[category.Code]
        local correct, incorrect = count.Correct, count.Incorrect
        local total = correct + incorrect
        totalCorrect += correct
        totalIncorrect += incorrect
        table.insert(categories, {
            Code = category.Code,
            Name = category.Name,
            Correct = correct,
            Incorrect = incorrect,
            Total = total,
            Accuracy = total > 0 and correct / total or nil,
            FocusActive = stats and stats.FocusActive == true or false,
            FocusCorrect = stats and AdaptiveSkills.FocusProgress(stats) or 0,
            FocusMistakes = stats and select(2, AdaptiveSkills.FocusProgress(stats)) or 0,
        })
    end
    local templates = {}
    for _, item in ipairs(recommendationTemplates:GetChildren()) do
        if item:IsA("StringValue") then
            templates[item.Name] = item.Value
        end
    end
    local recommendation = PracticeRecommendations.Build(categories, Config, templates)
    local totalAnswers = totalCorrect + totalIncorrect
    return {
        Ready = session ~= nil,
        Categories = categories,
        TotalCorrect = totalCorrect,
        TotalIncorrect = totalIncorrect,
        TotalAnswers = totalAnswers,
        WindowSize = Config.AccuracyWindowSize,
        OverallAccuracy = totalAnswers > 0 and totalCorrect / totalAnswers or nil,
        TargetAccuracy = Config.AdaptiveGoalAccuracy,
        MasteryCorrect = Config.AdaptiveMasteryCorrect,
        MasteryMistakes = Config.AdaptiveMasteryMistakes,
        Recommendation = recommendation.Text,
        RecommendationCategoryCode = recommendation.PrimaryCode,
        RecommendationCategoryCodes = recommendation.Codes,
        RecommendationDetails = recommendation.Weak,
        RecommendationsAllAtGoal = recommendation.AllAtGoal,
        Progress = ProgressHistory.Meta(session and session.ProgressHistory or {}, os.time()),
        Practice = {
            Enabled = session and session.PracticeEnabled == true or false,
            Targets = currentPracticeTargets(session),
            OwnsBusiness = player == owner,
            Note = session and session.PracticeNote or UI.T("ServerNotices", "Current"),
        },
    }
end

local getSupportState = ServerStorage:FindFirstChild("GetSupportState") or Instance.new("BindableFunction")
getSupportState.Name = "GetSupportState"
getSupportState.Parent = ServerStorage
getSupportState.OnInvoke = function(player)
    local session = playerSessions[player]
    if not session or player.Parent ~= Players then
        return { Ready = false }
    end
    local data = SupportGrounding.Measurements(makeAccuracySnapshot(player), session.ProgressHistory, Config)
    data.Formats = {}
    for _, mode in ipairs({ "MCQ", "FRQ" }) do
        local metric =
            AdaptiveSkills.WindowMetrics(session.AnswerHistory, nil, mode, nil, Config.AccuracyWindowSize)
        data.Formats[mode] = {
            Samples = metric.Samples,
            Correct = metric.Correct,
            AccuracyPercent = metric.Accuracy and math.floor(metric.Accuracy * 1000 + 0.5) / 10 or nil,
        }
    end
    local record = player == owner and staffVisits and staffVisits.Active
    local renovationItems, renovationPads = TycoonProgression.Templates(visitSettings[3])
    local renovationCatalog = TycoonProgression.Catalog(renovationItems, renovationPads)
    data.StaffConsultations = {
        Completed = session.StaffConcerns.Completed,
        RequiredDuringExpansion3 = staffSettings:GetAttribute("MinimumCompleted"),
        ChancePerArrival = staffSettings:GetAttribute("ChancePerArrival"),
        GuaranteeEveryArrivals = staffSettings:GetAttribute("GuaranteeEveryArrivals"),
        Pending = session.StaffConcerns.Pending,
        VisitingRole = record and record.Role or "None",
        Station = record and record.Area or "None",
        Returning = record and record.Returning == true or false,
        ExecutiveAutoHelpEnabled = staffSettings:GetAttribute("ExecutiveAutoHelpEnabled") ~= false,
        ExecutiveHandling = record and customerData[record.Model] ~= nil
            and customerData[record.Model].Serving == true or false,
        RenovationsInstalled = renovationCatalog ~= nil,
    }
    data.StaffMorale = StaffMoralePolicy.Clean(session.StaffMorale)
    data.Dashboard = dashboard and dashboard:Snapshot(player)
    data.PrivateSessions = privateSessions and privateSessions:Snapshot()
    data.PersonalConsultations = {
        Enabled = personalSettings:GetAttribute("Enabled") ~= false,
        AutomaticSinceHelp = session.CustomerValues.AutomaticSinceHelp,
        AfterAutomatic = PersonalConsultationPolicy.Threshold(
            personalSettings,
            session.TycoonProgress.CompletedExpansions
        ),
        StaggerSeconds = personalSettings:GetAttribute("StaggerSeconds"),
    }
    data.CustomerLines = {}
    if player == owner then
        local expanded = hasExpandedLines()
        local areas = expanded and { "Main", "Left", "Right" } or { "Main" }
        if hasUpstairs() then
            table.insert(areas, "UpperLeft")
            table.insert(areas, "UpperRight")
        end
        for _, area in ipairs(areas) do
            local staffed = isCounterStaffed(area)
            local minimum, maximum = CustomerSpawnSchedule.Range(
                Config,
                player:GetAttribute("Stars"),
                expanded,
                staffed,
                roomArrivalMultiplier(area)
            )
            local upstairs = CustomerRouting.IsUpper(area)
            if upstairs then
                minimum, maximum = nil, nil
            end
            local angryWaiting, waitingForPlayer = counters:PlayerOnlyStatus(area)
            table.insert(data.CustomerLines, {
                Area = area,
                Staffed = staffed,
                StarScaled = not upstairs and (not expanded or staffed),
                Upstairs = upstairs,
                OverflowOnly = upstairs,
                MinimumSeconds = minimum,
                MaximumSeconds = maximum,
                Managed = roomUpgrades(area).Managed,
                PaintingMultiplier = roomUpgrades(area).PaintingMultiplier,
                AngryMultiplier = 1,
                AngryCustomersWaiting = angryWaiting,
                WaitingForPlayer = waitingForPlayer,
                CounselorServiceSeconds = counselorServiceSeconds(area),
            })
        end
    end
    return data
end
getSupportState:SetAttribute("Ready", true)

local function captureProgress(player, timestamp)
    local session = playerSessions[player]
    if not session then
        return
    end
    local record = ProgressHistory.Record(makeAccuracySnapshot(player), timestamp)
    session.ProgressHistory =
        ProgressHistory.Merge(session.ProgressHistory, { record }, CATEGORY_DEFINITIONS, Config, os.time())
    session.LastProgressCaptureAt = os.time()
    markDirty(player)
end

local function rollProgressDay(player, timestamp)
    local session = playerSessions[player]
    if not session then
        return
    end
    local today = ProgressCalendar.Day(timestamp)
    if session.ProgressDay and today > session.ProgressDay then
        -- Called before recording the first answer on a new day, so it cannot
        -- contaminate yesterday's 11:59 PM snapshot with tomorrow's answers.
        captureProgress(player, ProgressCalendar.EndOfDay(session.ProgressDay))
    end
    session.ProgressDay = today
end

local function reconcilePractice(player)
    local session = playerSessions[player]
    if not session or not session.PracticeEnabled then
        return
    end
    local targets = currentPracticeTargets(session)
    session.PracticeTargets = targets
    local signature = PracticePolicy.Signature(targets)
    if #targets == 0 then
        session.PracticeEnabled = false
        session.PracticeNote = UI.T("ServerNotices", "Complete")
    end
    if signature ~= session.PracticeSignature then
        session.PracticeSignature = signature
        session.PracticeRevision += 1
        if retargetWaitingCustomers then
            retargetWaitingCustomers(player)
        end
    end
end

getAccuracyData.OnServerInvoke = function(player)
    return makeAccuracySnapshot(player)
end

getProgressView.OnServerInvoke = function(player, request)
    local session = playerSessions[player]
    if not session then
        return { Error = UI.T("ServerErrors", "ProgressIsStillLoading") }
    end
    if type(request) ~= "table" or (request.Mode ~= "Daily" and request.Mode ~= "Weekly") then
        return { Error = UI.T("ServerErrors", "InvalidProgressView") }
    end
    if os.clock() - (session.LastProgressRequestAt or -math.huge) < 0.1 then
        return { Error = UI.T("ServerErrors", "PleaseWaitAMomentBeforeMovingAgain") }
    end
    session.LastProgressRequestAt = os.clock()
    if request.Mode == "Daily" and request.Day == ProgressCalendar.Day(os.time()) then
        return makeAccuracySnapshot(player)
    end
    local templates = {}
    for _, v in ipairs(recommendationTemplates:GetChildren()) do
        if v:IsA("StringValue") then
            templates[v.Name] = v.Value
        end
    end
    local view, why = ProgressHistory.View(
        session.ProgressHistory,
        CATEGORY_DEFINITIONS,
        Config,
        templates,
        request.Day,
        request.Mode == "Weekly",
        os.time()
    )
    if not view then
        return { Error = why }
    end
    view.Practice = makeAccuracySnapshot(player).Practice
    return view
end

setPracticeMode.OnServerInvoke = function(player, enabled)
    local session = playerSessions[player]
    if not session or not player:GetAttribute("DataLoaded") then
        return { Error = UI.T("ServerErrors", "YourDataIsStillLoading") }
    end
    if type(enabled) ~= "boolean" then
        return { Error = UI.T("ServerErrors", "InvalidPracticeSetting") }
    end
    if os.clock() - (session.LastPracticeToggleAt or -math.huge) < 0.5 then
        return { Error = UI.T("ServerErrors", "PleaseWaitAMomentBeforeSwitchingPractice") }
    end
    session.LastPracticeToggleAt = os.clock()
    local targets = currentPracticeTargets(session)
    if enabled and player ~= owner then
        return { Error = UI.T("ServerErrors", "ClaimYourBusinessBeforeStartingPractice") }
    end
    if enabled and #targets == 0 then
        return { Error = UI.T("ServerErrors", "NoMeasuredCategoryIsBelow85Answer") }
    end
    session.PracticeEnabled = enabled
    session.PracticeTargets = enabled and targets or nil
    session.PracticeSignature = PracticePolicy.Signature(targets)
    session.PracticeRevision += 1
    session.PracticeNote = enabled and UI.T("ServerNotices", "Started") or UI.T("ServerNotices", "Stopped")
    if retargetWaitingCustomers then
        retargetWaitingCustomers(player)
    end
    local snapshot = makeAccuracySnapshot(player)
    accuracyUpdated:FireClient(player, snapshot)
    return snapshot
end

local function recordCategoryAnswer(player, scenario, correct)
    local session = playerSessions[player]
    local code = scenario and scenario.CategoryCode
    if not session or type(code) ~= "string" or not CATEGORY_BY_CODE[code] then
        return
    end
    rollProgressDay(player, os.time())
    local stats = session.CategoryAccuracy[code]
    if not stats then
        stats = AdaptiveSkills.NewStats()
        session.CategoryAccuracy[code] = stats
    end
    AdaptiveSkills.Record(stats, correct, Config)
    session.AnswerHistory = session.AnswerHistory or {}
    table.insert(session.AnswerHistory, {
        Code = code,
        Correct = correct == true,
        Mode = scenario.Mode,
        Difficulty = scenario.Difficulty,
        TargetSkill = scenario.TargetSkill,
    })
    if #session.AnswerHistory > Config.AccuracyWindowSize then
        table.remove(session.AnswerHistory, 1)
    end
    markDirty(player)
    reconcilePractice(player)
    accuracyUpdated:FireClient(player, makeAccuracySnapshot(player))
end

local moneySync = {}
local MAX_SAFE_CASH = 9007199254740991

local function cleanMoney(amount)
    if type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then
        return nil
    end
    return math.clamp(math.floor(amount), 0, MAX_SAFE_CASH)
end

local function disconnectMoneySync(player)
    local state = moneySync[player]
    if state then
        if state.CashConnection then
            state.CashConnection:Disconnect()
        end
        if state.MoneyConnection then
            state.MoneyConnection:Disconnect()
        end
        moneySync[player] = nil
    end
end

local function setMoney(player, amount, suppressDirty)
    local state = moneySync[player]
    local previous = state and state.Balance or cleanMoney(player:GetAttribute("Money")) or 0
    amount = cleanMoney(amount) or previous
    if state then
        -- Record own writes before firing signals, including deferred Roblox signals.
        state.Balance = amount
    end
    if player:GetAttribute("Money") ~= amount then
        player:SetAttribute("Money", amount)
    end
    local stats = player:FindFirstChild("leaderstats")
    local cash = state and state.Cash or stats and stats:FindFirstChild("Cash")
    if cash and cash.Value ~= amount then
        cash.Value = amount
    end
    if not suppressDirty and amount ~= previous then
        markDirty(player)
        if player:GetAttribute("DataLoaded") and player.Parent == Players then
            local sequence = (player:GetAttribute("CashFeedbackSequence") or 0) + 1
            player:SetAttribute("CashFeedbackSequence", sequence)
            cashBalanceChanged:FireClient(player, {
                Balance = amount,
                Gain = math.max(0, amount - previous),
                Sequence = sequence,
            })
        end
    end
end

local function syncPendingMoney(player)
    local state = moneySync[player]
    if not state then
        return
    end
    if state.Cash.Value ~= state.Balance then
        setMoney(player, state.Cash.Value)
    elseif player:GetAttribute("Money") ~= state.Balance then
        setMoney(player, player:GetAttribute("Money"))
    end
end

local function bindMoneySync(player, cash, initialMoney)
    disconnectMoneySync(player)
    local state = { Cash = cash }
    moneySync[player] = state
    setMoney(player, initialMoney, true)
    -- Server-only listeners: client-side Value edits cannot grant spendable cash.
    state.CashConnection = cash:GetPropertyChangedSignal("Value"):Connect(function()
        if moneySync[player] == state and cash.Value ~= state.Balance then
            setMoney(player, cash.Value)
        end
    end)
    state.MoneyConnection = player:GetAttributeChangedSignal("Money"):Connect(function()
        local amount = player:GetAttribute("Money")
        if moneySync[player] == state and amount ~= state.Balance then
            setMoney(player, amount)
        end
    end)
end

local function setRating(player, progress)
    player:SetAttribute("Stars", TycoonProgression.Stars(progress))
    player:SetAttribute("CompletedExpansions", progress.CompletedExpansions)
    player:SetAttribute("TycoonStage", progress.CompletedExpansions + 1)
    player:SetAttribute("GameCompleted", progress.Won)
    player:SetAttribute("FinalVisitCompleted", progress.FinalVisitCompleted == true)
    player:SetAttribute("AwaitingCeremony", progress.FinalVisitCompleted == true and not progress.Won)
    for i = 1, TycoonProgression.ExpansionCount do
        local completed = progress.CompletedExpansions >= i
        player:SetAttribute("Visit" .. i .. "Completed", completed)
        player:SetAttribute("Expansion" .. i .. "Unlocked", completed)
    end
end

local function setProgress(player, helped, suppressDirty)
    player:SetAttribute("CustomersHelped", helped)
    if not suppressDirty then
        markDirty(player)
    end
end

local function createLeaderstats(player, loadedData)
    local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player
    local cash = stats:FindFirstChild("Cash") or Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Parent = stats
    bindMoneySync(player, cash, loadedData.Money)
    setProgress(player, loadedData.CustomersHelped, true)
    player:SetAttribute("TutorialCompleted", loadedData.TutorialCompleted)
    player:SetAttribute("OwnsBusiness", false)
    setRating(player, loadedData.TycoonProgress)
    player:SetAttribute("CurrentStageMaxed", false)
    player:SetAttribute("NextExpansionReady", false)
    for i = 1, TycoonProgression.ExpansionCount do
        player:SetAttribute("Expansion" .. i .. "Active", false)
    end
end

local function loadPlayerData(player)
    player:SetAttribute("DataLoaded", false)
    player:SetAttribute("SaveStatus", "Loading")
    local loadedData = defaultPlayerData()
    local canSave = false
    local lease

    if dataStoreEnabled then
        local result
        lease, result = playerStore:Acquire("Player_" .. player.UserId, function()
            return player.Parent == Players
        end)
        if not lease then
            player:SetAttribute("SaveStatus", "Load unavailable - existing progress protected")
            if player.Parent == Players then
                player:Kick(UI.T("ServerErrors", "SaveLoadUnavailable"))
            end
            return
        end
        if player.Parent ~= Players then
            playerStore:Save(lease, nil, true)
            return
        end
        loadedData = sanitizePlayerData(result)
        canSave = true
        player:SetAttribute("SaveStatus", "Loaded")
    else
        player:SetAttribute("SaveStatus", "Studio saving disabled")
    end

    if player.Parent ~= Players then
        return
    end
    playerSessions[player] = {
        Purchases = loadedData.Purchases,
        Milestones = loadedData.Milestones,
        TycoonProgress = loadedData.TycoonProgress,
        ExpansionPurchases = loadedData.ExpansionPurchases,
        CustomerValues = loadedData.CustomerValues,
        StaffConcerns = loadedData.StaffConcerns,
        StaffMorale = loadedData.StaffMorale,
        Dashboard = loadedData.Dashboard,
        PendingNotices = {},
        WarnedStage = nil,
        CategoryAccuracy = loadedData.CategoryAccuracy,
        AnswerHistory = loadedData.AnswerHistory,
        ProgressHistory = loadedData.ProgressHistory,
        ProgressDay = ProgressCalendar.Day(os.time()),
        LastProgressCaptureAt = os.time(),
        PracticeEnabled = false,
        PracticeRevision = 0,
        PracticeSignature = "",
        RecentScenarioIds = loadedData.RecentScenarioIds,
        RecentCustomerProfiles = loadedData.RecentCustomerProfiles,
        Dirty = false,
        Revision = 0,
        CanSave = canSave,
        SaveLease = lease,
        Saving = false,
    }
    createLeaderstats(player, loadedData)
    player:SetAttribute("DataLoaded", true)
    captureProgress(player, os.time())
end

local function makeSaveSnapshot(player, session)
    syncPendingMoney(player)
    local expansionPurchases = {}
    for key, owned in pairs(session.ExpansionPurchases) do
        expansionPurchases[key] = table.clone(owned)
    end
    local purchases = {}
    for id, purchased in pairs(session.Purchases) do
        if purchased then
            purchases[id] = true
        end
    end
    local categoryAccuracy = {}
    for _, category in ipairs(CATEGORY_DEFINITIONS) do
        local stats = session.CategoryAccuracy[category.Code] or AdaptiveSkills.NewStats()
        categoryAccuracy[category.Code] = AdaptiveSkills.SnapshotStats(stats, Config)
    end
    return {
        Version = 9,
        Money = player:GetAttribute("Money") or Config.StartingCash,
        CustomersHelped = player:GetAttribute("CustomersHelped") or 0,
        Purchases = purchases,
        Milestones = MilestoneProgress.Snapshot(session.Milestones),
        ExpansionPurchases = expansionPurchases,
        CustomerValues = CustomerValues.Clean(session.CustomerValues, 100),
        StaffConcerns = StaffConcernPolicy.Clean(session.StaffConcerns),
        StaffMorale = StaffMoralePolicy.Clean(session.StaffMorale),
        Dashboard = DashboardPolicy.Clean(session.Dashboard),
        TycoonProgress = TycoonProgression.Clean(session.TycoonProgress),
        CategoryAccuracy = categoryAccuracy,
        AnswerHistory = table.clone(session.AnswerHistory),
        RecentScenarioIds = DialogueGenerator.CleanRecentIds(session.RecentScenarioIds),
        RecentCustomerProfiles = CustomerBehavior.CleanRecentProfiles(
            session.RecentCustomerProfiles,
            math.clamp(Config.CustomerRecentProfileWindow or 6, 1, 30)
        ),
        ProgressHistory = ProgressHistory.Clean(
            session.ProgressHistory,
            CATEGORY_DEFINITIONS,
            Config,
            os.time()
        ),
        TutorialCompleted = player:GetAttribute("TutorialCompleted") == true,
        UpdatedAt = os.time(),
    }
end

savePlayerData = function(player, forceSave, release)
    local session = playerSessions[player]
    if not session or not session.CanSave then
        return false
    end
    if release then
        session.ReleaseRequested = true
    end
    if session.SaveLease.Released then
        return true
    end
    if session.Saving then
        if forceSave then
            session.SaveAgain = true
            local deadline = os.clock() + 20
            while session.Saving and os.clock() < deadline do
                task.wait(0.1)
            end
        end
        return session.LastSaveOkay == true and not session.Saving
    end
    if not forceSave and not session.Dirty and not playerStore:NeedsRenewal(session.SaveLease) then
        return true
    end

    session.Saving = true
    local success = false
    repeat
        session.SaveAgain = false
        player:SetAttribute("SaveStatus", "Saving")
        local snapshot = makeSaveSnapshot(player, session)
        local savedRevision = session.Revision
        local persisted
        success, persisted = playerStore:Save(session.SaveLease, snapshot, session.ReleaseRequested)
        session.LastSaveOkay = success
        if success then
            if session.Revision == savedRevision then
                session.Dirty = false
            end
            if player.Parent == Players then
                player:SetAttribute("SaveStatus", "Saved")
            end
        elseif persisted == "Conflict" then
            session.CanSave = false
            player:SetAttribute("SaveStatus", "Session changed - stale save blocked")
            if player.Parent == Players then
                player:Kick(UI.T("ServerErrors", "SaveSessionChanged"))
            end
        else
            warn("CalmWorks player save unavailable for " .. player.Name .. ": " .. tostring(persisted))
            if player.Parent == Players then
                player:SetAttribute("SaveStatus", "Save failed - retrying later")
            end
        end
    until not success or session.SaveLease.Released
        or not (session.SaveAgain or session.ReleaseRequested)
    session.Saving = false
    return success
end

completeTutorial.OnServerEvent:Connect(function(player)
    if not player:GetAttribute("DataLoaded") or player:GetAttribute("TutorialCompleted") then
        return
    end
    player:SetAttribute("TutorialCompleted", true)
    markDirty(player)
    -- Completing onboarding saves immediately in published servers.
    task.spawn(savePlayerData, player, false)
end)

local function setNameLabel(head, text)
    -- The visual nameplate lives under the editable noob template's Head.
    -- Runtime code changes only the displayed customer name.
    local gui = head:FindFirstChild("CustomerNameGui")
    local label = gui and gui:FindFirstChild("NameLabel")
    assert(
        gui and gui:IsA("BillboardGui") and label and label:IsA("TextLabel"),
        "Add CustomerNameGui > NameLabel under CalmWorksNoobTemplate.Head"
    )
    label.Text = text
end

local function getPoint(name)
    return customerPoints:WaitForChild(name).Position
end

local function makeDialoguePayload(data)
    local scenario = data.Scenario
    local stageIndex = data.StageIndex
    local stage = scenario.Stages[stageIndex]
    return {
        CustomerName = data.Name,
        AnswerToken = AnswerSubmission.Token(data),
        IsAIGenerated = scenario.SourceKind == "AI",
        Prompt = stage.Prompt,
        FRQContextId = scenario.Mode == "FRQ" and (data.HelpContextId .. ":" .. stageIndex) or nil,
        FRQPrompt = scenario.Mode == "FRQ" and FRQGradePolicy.Task(scenario, Config.FRQDefaultPrompt) or nil,
        Mode = scenario.Mode,
        Choices = scenario.Mode == "MCQ" and stage.Choices or nil,
        MaxCharacters = Config.FRQMaxCharacters,
        Difficulty = scenario.Difficulty,
        CategoryCode = scenario.CategoryCode,
        StageIndex = stageIndex,
        StageCount = #scenario.Stages,
    }
end

local function startWalkAnimation(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
    animator.Parent = humanoid
    local walkAnimation = Instance.new("Animation")
    walkAnimation.Name = "ClassicR6Walk"
    walkAnimation.AnimationId = Config.R6WalkAnimationId
    walkAnimation.Parent = model
    local walkTrack
    local loaded, loadResult = pcall(function()
        return animator:LoadAnimation(walkAnimation)
    end)
    if loaded then
        walkTrack = loadResult
        walkTrack.Looped = true
        walkTrack.Priority = Enum.AnimationPriority.Movement
    else
        warn("Could not load the classic R6 walk animation: " .. tostring(loadResult))
    end
    humanoid.Running:Connect(function(speed)
        if not walkTrack then
            return
        end
        if speed > 0.1 then
            if not walkTrack.IsPlaying then
                walkTrack:Play(0.15)
            end
            walkTrack:AdjustSpeed(math.clamp(speed / 10, 0.5, 1.5))
        elseif walkTrack.IsPlaying then
            walkTrack:Stop(0.2)
        end
    end)

    return walkTrack
end

local function reservedScenarioIds(exceptModel)
    local ids = {}
    for model, data in pairs(customerData) do
        if model ~= exceptModel and model.Parent and data.Scenario and not data.Leaving then
            ids[data.Scenario.TemplateId or data.Scenario.Id] = true
        end
    end
    return ids
end

local function connectCustomerPrompt(model, root, prompt)
    return prompt.Triggered:Connect(function(player)
        if player ~= owner then
            rejectAction(player, "NotBusinessOwner")
            return
        end
        if not isActionableCustomer(model) then
            rejectAction(player, "CustomerNotFirstInLine")
            return
        end
        local entry = customerData[model]
        local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if
            not entry
            or not entry.ArrivedAt
            or (entry.Serving and not entry.Private)
            or not playerRoot
            or (playerRoot.Position - root.Position).Magnitude > prompt.MaxActivationDistance + 3
        then
            rejectAction(player, "CustomerAlreadyActive")
            return
        end
        if activeCustomer then
            rejectAction(player, "CustomerAlreadyActive")
            return
        end
        if entry.Private then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local from = player.Character:FindFirstChild("Head") or playerRoot
            local head = model:FindFirstChild("Head") or root
            local filter = RaycastParams.new()
            filter.FilterType = Enum.RaycastFilterType.Exclude
            filter.FilterDescendantsInstances = { player.Character, model }
            if
                not humanoid
                or humanoid.Health <= 0
                or workspace:Raycast(from.Position, head.Position - from.Position, filter)
            then
                rejectAction(player, "CustomerAlreadyActive")
                return
            end
        end
        setActiveCustomer(model)
        local data = customerData[model]
        data.Opening, prompt.Enabled = true, false
        counters:SetAttention(model, false)
        if data.GenerationTicket.State == "Pending" then
            openDialogue:FireClient(player, {
                Loading = true,
                CustomerName = data.Name,
                CategoryCode = data.Scenario.CategoryCode,
                Difficulty = data.Scenario.Difficulty,
            })
        end
        local okay, scenario = pcall(ScenarioAI.Resolve, data.GenerationTicket)
        if
            player ~= owner
            or not player.Parent
            or not model.Parent
            or activeCustomer ~= model
            or customerData[model] ~= data
        then
            return
        end
        if okay and scenario then
            data.Scenario = scenario
        else
            ScenarioAI.Cancel(data.GenerationTicket)
        end
        model:SetAttribute("ScenarioSource", data.Scenario.SourceKind or "Library")
        model:SetAttribute("ScenarioFallbackReason", data.GenerationTicket.Reason)
        model:SetAttribute("ScenarioTemplateId", data.Scenario.TemplateId or data.Scenario.Id)
        data.Opening = false
        openDialogue:FireClient(player, makeDialoguePayload(data))
    end)
end

local function createCustomer(area, kind, privateId)
    -- Clone sanitized templates; customer type is selected before choosing its queue.
    local session = owner and playerSessions[owner]
    local angry = kind == "Angry"
    local rich = kind == "Rich"
    local selectedScenario = DialogueGenerator.Generate(
        owner and owner:GetAttribute("Stars") or 0,
        session and session.CategoryAccuracy,
        session and session.RecentScenarioIds,
        session and session.AnswerHistory,
        session and session.PracticeEnabled and PracticePolicy.Codes(currentPracticeTargets(session)) or nil,
        session and session.RecentCustomerProfiles,
        reservedScenarioIds(),
        angry and "Angry" or nil
    )
    local profile = selectedScenario.CustomerProfile
    local hasHair = math.random() < Config.CustomerHairChance
    local appearance = hasHair and "Female" or "Male"
    local template = CustomerBehavior.GetTemplate(profile, appearance)
    if angry then
        template = ServerStorage:WaitForChild("CalmWorksAngryNoobTemplate")
        assert(
            CustomerBehavior.ValidTemplate(template),
            "Angry customer template must remain a valid R6 customer"
        )
    elseif rich then
        template = ServerStorage:WaitForChild("CalmWorksRichNoobTemplate")
        assert(
            CustomerBehavior.ValidTemplate(template),
            "Rich customer template must remain a valid R6 customer"
        )
        appearance = template:GetAttribute("Appearance") or "Male"
        hasHair = appearance == "Female"
    end
    local model = template:Clone()
    model:SetAttribute("CustomerValue", angry and "Angry" or rich and "Rich" or "Standard")
    model:SetAttribute("RewardMultiplier", rich and valueSettings:GetAttribute("RichRewardMultiplier") or 1)
    if privateId then
        model:SetAttribute(
            "RewardMultiplier",
            PrivateSessionPolicy.Reward(model:GetAttribute("RewardMultiplier"), privateSettings)
        )
    end
    model.Name = "Customer"
    -- Custom appearance templates supply geometry, not executable behavior.
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("LuaSourceContainer") then
            child:Destroy()
        elseif child:IsA("BasePart") then
            child.Anchored = false
        end
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    assert(humanoid and root and head, "CalmWorksNoobTemplate must remain a valid R6 rig")
    humanoid.WalkSpeed = 10
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    local spawnPosition = getPoint("Spawn")
    local torsoColor = TORSO_COLORS[math.random(#TORSO_COLORS)]
    if model:GetAttribute("RandomizeTorso") ~= false then
        model.Torso.Color = torsoColor
        local bodyColors = model:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            bodyColors.TorsoColor = BrickColor.new(torsoColor)
        end
    end
    local namePool = hasHair and GIRL_CUSTOMER_NAMES or BOY_CUSTOMER_NAMES
    local customerName = namePool[math.random(#namePool)]
    setNameLabel(head, customerName)
    CustomerBehavior.UpdateModel(model, profile)
    model:SetAttribute("PracticeTarget", selectedScenario.PracticeTarget == true)
    model:SetAttribute("PracticeCategory", selectedScenario.CategoryCode)
    model:SetAttribute("Appearance", appearance)
    -- HelpPrompt is part of the editable noob template in ServerStorage.
    local prompt = root:FindFirstChild("HelpPrompt")
    assert(
        prompt and prompt:IsA("ProximityPrompt"),
        "Add HelpPrompt under CalmWorksNoobTemplate.HumanoidRootPart"
    )
    prompt.ObjectText, prompt.Enabled = customerName, false
    if privateId then
        prompt.ActionText = UI.T("World", "PrivateSessionAction")
        prompt.RequiresLineOfSight = false
    end
    model.PrimaryPart, model.Parent = root, customersFolder
    model:PivotTo(CFrame.new(spawnPosition))
    local existingHair = false
    for _, item in ipairs(model:GetChildren()) do
        if
            item:IsA("Accoutrement")
            and (item:GetAttribute("IsCustomerHair") == true or string.lower(item.Name):find("hair", 1, true))
        then
            existingHair = true
        end
    end
    if hasHair and model:GetAttribute("UseDefaultHair") ~= false and not existingHair then
        humanoid:AddAccessory(hairTemplate:Clone())
    end
    assignCollisionGroup(model, CUSTOMER_COLLISION_GROUP)
    root:SetNetworkOwner(nil)

    local walkTrack = startWalkAnimation(model)

    local metrics = AdaptiveSkills.GenerationContext(
        session and session.AnswerHistory,
        selectedScenario,
        CATEGORY_DEFINITIONS,
        Config
    )
    selectedScenario.TargetSkill = metrics.TargetSkill
    metrics.PracticeMode = session and session.PracticeEnabled == true or false
    customerData[model] = {
        Name = customerName,
        HelpContextId = HttpService:GenerateGUID(false),
        CustomerProfile = profile,
        Scenario = selectedScenario,
        GenerationTicket = ScenarioAI.Start(owner, selectedScenario, metrics),
        PracticeRevision = session and session.PracticeRevision or 0,
        StageIndex = 1,
        RecordedStages = {},
        Prompt = prompt,
        WalkTrack = walkTrack,
        HasToolboxHair = hasHair,
        Rich = rich,
        Angry = angry,
        Private = privateId ~= nil,
        PrivateStation = privateId,
        Area = area or "Main",
    }
    connectCustomerPrompt(model, root, prompt)
    if rich then
        session.CustomerValues.RichSeen = true
    end
    if angry then
        CustomerValues.CommitAngry(session.CustomerValues)
    end
    if session then
        markDirty(owner)
        task.spawn(savePlayerData, owner, false)
    end
    model.Destroying:Connect(function()
        local data = customerData[model]
        if not data then
            return
        end
        ScenarioAI.Cancel(data.GenerationTicket)
        if data.Private then
            privateSessions:Remove(model)
        else
            counters:Remove(model)
        end
        customerData[model] = nil
        if activeCustomer == model then
            setActiveCustomer(nil)
        end
        task.defer(function()
            counters:Update()
        end)
    end)
    return model
end

retargetWaitingCustomers = function(player)
    if player ~= owner then
        return
    end
    local session = playerSessions[player]
    if not session then
        return
    end
    local forced = session.PracticeEnabled and PracticePolicy.Codes(currentPracticeTargets(session)) or nil
    for model, data in pairs(customerData) do
        if
            data
            and data.Kind ~= "BusinessMan"
            and data.Kind ~= "Staff"
            and model ~= activeCustomer
            and not data.Serving
            and model.Parent
            and data.PracticeRevision ~= session.PracticeRevision
        then
            ScenarioAI.Cancel(data.GenerationTicket)
            local scenario = DialogueGenerator.Generate(
                player:GetAttribute("Stars") or 0,
                session.CategoryAccuracy,
                session.RecentScenarioIds,
                session.AnswerHistory,
                forced,
                session.RecentCustomerProfiles,
                reservedScenarioIds(model),
                data.Angry and "Angry" or nil
            )
            local metrics = AdaptiveSkills.GenerationContext(
                session.AnswerHistory,
                scenario,
                CATEGORY_DEFINITIONS,
                Config
            )
            metrics.PracticeMode = session.PracticeEnabled
            scenario.TargetSkill = metrics.TargetSkill
            data.Scenario, data.CustomerProfile = scenario, scenario.CustomerProfile
            data.StageIndex, data.RecordedStages = 1, {}
            data.HelpContextId = HttpService:GenerateGUID(false)
            data.PracticeRevision = session.PracticeRevision
            CustomerBehavior.UpdateModel(model, data.CustomerProfile)
            model:SetAttribute("PracticeTarget", session.PracticeEnabled)
            model:SetAttribute("PracticeCategory", scenario.CategoryCode)
            model:SetAttribute("ScenarioSource", nil)
            model:SetAttribute("ScenarioFallbackReason", nil)
            model:SetAttribute("ScenarioTemplateId", scenario.TemplateId)
            data.GenerationTicket = ScenarioAI.Start(player, scenario, metrics)
        end
    end
end

local function updateQueue()
    counters:Update()
end

local function walkOut(model, area)
    counters:WalkOut(model, area or "Main")
end

stageMaxed = function(player)
    local session = playerSessions[player]
    return session
        and TycoonProgression.IsMaxed(
            session.TycoonProgress,
            session.Purchases,
            session.ExpansionPurchases,
            upgradeItems,
            upgradePads,
            visitSettings
        )
end

local function visitLines(index)
    local lines = {}
    local name = index == 5 and "FinalBusinessVisit" or "BusinessVisit" .. index
    for _, text in ipairs(UI.Sequence(name)) do
        if text:match("%S") and #text <= 4000 and #lines < 50 then
            table.insert(lines, text)
        end
    end
    return lines
end

local function nextVisit(player)
    local session = playerSessions[player]
    if not session or session.TycoonProgress.Won or not stageMaxed(player) then
        return nil
    end
    local index = session.TycoonProgress.CompletedExpansions + 1
    if index == 5 then
        if not session.TycoonProgress.FinalVisitCompleted
            and finalVisitSettings:GetAttribute("DialogueReady") == true
            and #visitLines(5) > 0
        then
            return 5
        end
        return nil
    end
    -- A fast buyer still gets the guaranteed Rich visitor before leaving expansion 1.
    if index == 2 and not session.CustomerValues.RichSeen then
        return nil
    end
    if
        index == 4
        and session.StaffConcerns.Completed < (staffSettings:GetAttribute("MinimumCompleted") or 3)
    then
        return nil
    end
    local settings = visitSettings[index]
    if
        not settings
        or settings:GetAttribute("DialogueReady") ~= true
        or not TycoonProgression.ExpansionReady(settings)
        or #visitLines(index) == 0
    then
        return nil
    end
    return index
end

local function visitPayload(data)
    return {
        Token = data.VisitToken,
        Index = data.VisitIndex,
        Count = #data.VisitLines,
        Text = data.VisitLines[data.VisitIndex],
        VisitNumber = data.VisitNumber,
    }
end

openMentorConversation = function(model, player)
    local data = customerData[model]
    local allowed, reason =
        MentorInteraction.CanStart(player, owner, model, data, activeCustomer, counters:IsFront(model))
    if not allowed then
        rejectAction(player, reason)
        return
    end
    if nextVisit(owner) ~= data.VisitNumber then
        model:Destroy()
        return
    end
    if not data.VisitToken then
        data.VisitLines = visitLines(data.VisitNumber)
        data.VisitToken = HttpService:GenerateGUID(false)
        data.VisitIndex = 1
    end
    setActiveCustomer(model)
    data.Prompt.Enabled = false
    counters:SetAttention(model, false)
    openBusinessVisit:FireClient(owner, visitPayload(data))
end

local function createBusinessMan(index)
    local template = ServerStorage:WaitForChild("CalmWorksBusinessManVisitTemplate")
    local model = template:Clone()
    model.Name = "BusinessMan"
    model:SetAttribute("VisitorKind", "BusinessMan")
    model:SetAttribute("VisitNumber", index)
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("LuaSourceContainer") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = false
        end
    end
    local root = model.HumanoidRootPart
    local humanoid = model.Humanoid
    local prompt = root.TalkPrompt
    prompt.Enabled = false
    humanoid.WalkSpeed = 10
    humanoid.AutoRotate = true
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    model.PrimaryPart = root
    local spawnPosition = getPoint("Spawn")
    local counterPosition = getPoint("Queue1")
    local facing = Vector3.new(counterPosition.X, spawnPosition.Y, counterPosition.Z)
    model:PivotTo(CFrame.lookAt(spawnPosition, facing))
    assignCollisionGroup(model, CUSTOMER_COLLISION_GROUP)
    model.Parent = customersFolder
    root:SetNetworkOwner(nil)
    customerData[model] =
        { Kind = "BusinessMan", VisitNumber = index, Prompt = prompt, WalkTrack = startWalkAnimation(model) }
    prompt.Triggered:Connect(function(player)
        if player ~= owner then
            rejectAction(player, "NotBusinessOwner")
            return
        end
        openMentorConversation(model, player)
    end)
    model.Destroying:Connect(function()
        local data = customerData[model]
        if not data then
            return
        end
        counters:Remove(model)
        customerData[model] = nil
        businessVisitor = nil
        if activeCustomer == model then
            setActiveCustomer(nil)
        end
        if owner and data.VisitToken then
            closeBusinessVisit:FireClient(owner, data.VisitToken)
        end
        task.defer(function()
            updateQueue()
            if ensureBusinessVisit then
                ensureBusinessVisit()
            end
        end)
    end)
    return model
end

ensureBusinessVisit = function()
    if not owner or os.clock() < firstCustomerAt or activeCustomer or businessVisitor then
        return false
    end
    local index = nextVisit(owner)
    if not index then
        return false
    end
    local area = "Main"
    if index >= 3 then
        area = counters:ChooseArea("Upper", true, function(room)
            return allowPlayerRequest("Mentor", room)
        end)
    elseif not counters:CanAccept(area) or not allowPlayerRequest("Mentor", area) then
        area = nil
    end
    if not area then
        return false
    end
    businessVisitor = createBusinessMan(index)
    counters:Add(businessVisitor, area)
    helpPacing:Requested()
    if index == 5 then
        sendMilestone(owner, "FinalBusinessManArrived")
    else
        sendMilestone(owner, "M5_" .. index)
    end
    updateQueue()
    return true
end

checkStageProgress = function(player)
    local session = playerSessions[player]
    if not session then
        return
    end
    local maxed = stageMaxed(player) == true
    local progress = session.TycoonProgress
    player:SetAttribute("CurrentStageMaxed", maxed)
    local pendingVisit = nextVisit(player)
    player:SetAttribute("NextExpansionReady", pendingVisit ~= nil and pendingVisit <= 4)
    player:SetAttribute("FinalVisitReady", pendingVisit == 5)
    if maxed and progress.CompletedExpansions == TycoonProgression.ExpansionCount and not progress.Won then
        if player == owner and not progress.FinalVisitCompleted then
            ensureBusinessVisit()
        end
    elseif maxed and progress.CompletedExpansions < TycoonProgression.ExpansionCount then
        if not nextVisit(player) and session.WarnedStage ~= progress.CompletedExpansions then
            session.WarnedStage = progress.CompletedExpansions
            warn(
                "CalmWorks: stage is maxed. Finish the next expansion pads and dialogue, then enable DialogueReady and ExpansionReady."
            )
        end
        if player == owner then
            ensureBusinessVisit()
        end
    end
end

advanceBusinessVisit.OnServerInvoke = function(player, token, index)
    local model = activeCustomer
    local data = model and customerData[model]
    if player ~= owner or not data or data.Kind ~= "BusinessMan" or not counters:IsFront(model) then
        return { Error = UI.T("BusinessVisitStatus", "Unavailable"), Closed = true }
    end
    if not MilestoneProgress.CanAdvance(data, token, index, os.clock()) then
        return { Error = UI.T("BusinessVisitStatus", "Retry") }
    end
    data.LastAdvanceAt = os.clock()
    if data.VisitIndex < #data.VisitLines then
        data.VisitIndex += 1
        return visitPayload(data)
    end
    local session = playerSessions[player]
    local index = data.VisitNumber
    if nextVisit(player) ~= index then
        model:Destroy()
        return { Error = UI.T("BusinessVisitStatus", "NotReady"), Closed = true }
    end
    if index == 5 then
        session.TycoonProgress.FinalVisitCompleted = true
        setRating(player, session.TycoonProgress)
        markDirty(player)
        setActiveCustomer(nil)
        businessVisitor = nil
        counters:Remove(model)
        customerData[model] = nil
        sendMilestone(player, "CeremonyPending")
        checkStageProgress(player)
        updateQueue()
        walkOut(model, data.Area)
        task.spawn(savePlayerData, player, true)
        return { Complete = true }
    end
    local okay, applied = pcall(function()
        return expansions[index]:Apply(player, session, true)
    end)
    if not okay or not applied then
        if not okay then
            warn("CalmWorks expansion could not be applied: " .. tostring(applied))
            expansions[index]:Reset()
        end
        return { Error = UI.T("BusinessVisitStatus", "NotReady") }
    end
    session.TycoonProgress.CompletedExpansions = index
    staffMorale:Sync(false)
    setRating(player, session.TycoonProgress)
    markDirty(player)
    setActiveCustomer(nil)
    businessVisitor = nil
    counters:Remove(model)
    customerData[model] = nil
    sendMilestone(player, "M3_" .. index)
    if index == 1 then
        sendEventNotice(player, "CounselorHiringTip")
    end
    checkStageProgress(player)
    updateQueue()
    walkOut(model, data.Area)
    return { Complete = true }
end

tryStaffVisit = function()
    local session = owner and playerSessions[owner]
    if
        not session
        or session.TycoonProgress.CompletedExpansions < 3
        or businessVisitor
        or staffVisits.Active
        or os.clock() < staffVisits.NextVisitAt
    then
        return false
    end
    local function allowedRoom(home, room)
        if home == room or not counters:CanAccept(room, true) then
            return false
        end
        return executiveAvailable(room) or allowPlayerRequest("Staff", room)
    end
    local function canVisit(staff)
        if not staffVisits:CanTake(staff) then
            return false
        end
        if staff.Private and privateSessions:Busy(staff.Area) then
            return false
        end
        local home = staff.Room or staff.Area
        return allowedRoom(home, "UpperLeft") or allowedRoom(home, "UpperRight")
    end
    local preferred = staffMorale:Candidate(canVisit)
    if not session.StaffConcerns.Pending and not preferred then
        return false
    end
    local record = staffVisits:Take(session.StaffConcerns, preferred, canVisit)
    if not record then
        return false
    end
    -- Prefer a working executive, without cutting ahead of their existing queue.
    local area = counters:ChooseArea("Upper", true, function(room)
        return record.HomeRoom ~= room and executiveAvailable(room)
    end)
    if not area then
        area = counters:ChooseArea("Upper", true, function(room)
            return allowedRoom(record.HomeRoom, room)
        end)
    end
    if not area then
        staffVisits:Recover(record.Model)
        return false
    end
    if record and CustomerRouting.IsUpper(record.HomeRoom) then
        area = record.HomeRoom == "UpperLeft" and "UpperRight" or "UpperLeft"
        if not counters:CanAccept(area, true) then
            staffVisits:Recover(record.Model)
            return false
        end
        local from = customerPoints[record.HomeRoom].Inbound:GetChildren()
        local to = customerPoints[area].Inbound:GetChildren()
        table.sort(from, function(a, b)
            return a.Name < b.Name
        end)
        table.sort(to, function(a, b)
            return a.Name < b.Name
        end)
        record.TransferPoints = { from[#from].Position, to[#to].Position }
    elseif record then
        local route = StaffRoutePolicy.Build(customerPoints, record.Home, area, staffSettings:GetAttribute("UseNearestStairway"))
        if not route then
            staffVisits:Recover(record.Model)
            warn("CalmWorks: staff stair markers are incomplete; visit remains pending.")
            return false
        end
        record.TransferPoints = route.Points
        record.Stairway = route.Stairway
        record.Model:SetAttribute("ConsultationStairway", route.Stairway)
    end
    if not record then
        return false
    end
    local model = record.Model
    if not executiveAvailable(area) then
        helpPacing:Requested()
    end
    local okay, reason = pcall(function()
        local scenario = DialogueGenerator.GenerateWorkplace(
            record.Role,
            owner:GetAttribute("Stars") or 3,
            session.CategoryAccuracy,
            session.StaffConcerns.RecentCases,
            session.AnswerHistory,
            record.HomeRoom,
            session.RecentCustomerProfiles
        )
        if record.MoraleDriven then
            scenario.WorkplaceContext.Morale = session.StaffMorale.Entries[record.StaffId].Morale
            scenario.WorkplaceContext.VisitReason =
                "Low morale: seek a workable workplace adjustment, clarification or support from the owner or an executive counselor."
        end
        local metrics =
            AdaptiveSkills.GenerationContext(session.AnswerHistory, scenario, CATEGORY_DEFINITIONS, Config)
        scenario.TargetSkill = metrics.TargetSkill
        local name = model:GetAttribute("ConsultationName") or (record.Area .. " " .. record.Role)
        record.Prompt.ObjectText = name
        CustomerBehavior.UpdateModel(model, scenario.CustomerProfile)
        customerData[model] = {
            Kind = "Staff",
            StaffId = record.StaffId,
            StaffHomeRoom = record.HomeRoom,
            Name = name,
            HelpContextId = HttpService:GenerateGUID(false),
            CustomerProfile = scenario.CustomerProfile,
            Scenario = scenario,
            GenerationTicket = ScenarioAI.Start(owner, scenario, metrics),
            StageIndex = 1,
            RecordedStages = {},
            Prompt = record.Prompt,
            Area = area,
            RouteIndex = 3,
            Entered = record.TransferPoints ~= nil,
            TransferPoints = record.TransferPoints,
            Rich = false,
            Angry = false,
        }
        table.insert(record.Connections, connectCustomerPrompt(model, record.Root, record.Prompt))
        table.insert(
            record.Connections,
            model.Destroying:Connect(function()
                local data = customerData[model]
                if data then
                    ScenarioAI.Cancel(data.GenerationTicket)
                    counters:Remove(model)
                    customerData[model] = nil
                    if activeCustomer == model then
                        setActiveCustomer(nil)
                    end
                end
                staffVisits:Recover(model)
                task.defer(function()
                    counters:Update()
                end)
            end)
        )
        counters:Add(model, area)
        local entry = customerData[model]
        local timeout =
            math.clamp(tonumber(staffSettings:GetAttribute("RouteTimeoutSeconds")) or 120, 30, 300)
        task.delay(timeout, function()
            if customerData[model] == entry and not entry.ArrivedAt then
                ScenarioAI.Cancel(entry.GenerationTicket)
                counters:Remove(model)
                customerData[model] = nil
                staffVisits:Recover(model)
                counters:Update()
                warn("CalmWorks: staff arrival timed out; workstation restored and visit remains pending.")
            end
        end)
        sendEventNotice(owner, "StaffConsultationArrived", model)
        markDirty(owner)
        counters:Update()
    end)
    if not okay then
        local data = customerData[model]
        if data then
            ScenarioAI.Cancel(data.GenerationTicket)
            counters:Remove(model)
            customerData[model] = nil
        end
        staffVisits:Recover(model)
        warn("CalmWorks: staff visit preparation failed: " .. tostring(reason))
        return false
    end
    return true
end

local function spawnCustomer(area)
    if ceremony and ceremony:IsPlaying() then
        return false
    end
    if not owner or os.clock() < firstCustomerAt then
        return false
    end
    if ensureBusinessVisit() or businessVisitor then
        return false
    end
    local session = playerSessions[owner]
    local slot
    if session.TycoonProgress.CompletedExpansions >= 4 then
        slot = privateSessions:Reserve()
    end
    if not slot and not counters:ChooseArea() and not counters:ChooseArea("Upper") then
        return false
    end
    local kind = CustomerValues.Kind(
        session.CustomerValues,
        session.TycoonProgress.CompletedExpansions,
        stageMaxed(owner) == true,
        valueSettings,
        Random.new()
    )
    if slot then
        area = slot.Room
    else
        if kind == "Angry" then
            area = counters:ChooseArea("Upper", false, function(room)
                return allowPlayerRequest("Angry", room)
            end)
            if not area then
                -- Defer this request; keep automatic business running with an ordinary visitor.
                kind = "Standard"
            end
        end
        if kind == "Rich" then
            local automatic = counters:ChooseArea(nil, false, function(room)
                return isCounterStaffed(room)
            end)
            area = automatic or CustomerRouting.Destination(counters, kind, area, hasUpstairs())
        elseif kind ~= "Angry" then
            area = CustomerRouting.Destination(counters, kind, area, hasUpstairs())
        end
    end
    if not area then
        privateSessions:Release(slot)
        return false
    end
    local needsPlayer = slot and not slot.WasStaffed
        or not slot and (kind == "Angry" or not hasCounterStaff(area))
    if needsPlayer then
        if not allowPlayerRequest(kind, area) then
            privateSessions:Release(slot)
            return false
        end
        helpPacing:Requested()
    end
    local spawnOwner, spawnGeneration = owner, generation
    local okay, model = pcall(createCustomer, area, kind, slot and slot.Id)
    if not okay then
        privateSessions:Release(slot)
        warn("CalmWorks customer could not spawn: " .. tostring(model))
        return false
    end
    if owner ~= spawnOwner or generation ~= spawnGeneration then
        privateSessions:Release(slot)
        model:Destroy()
        return false
    end
    if slot then
        privateSessions:Begin(slot, model)
    else
        counters:Add(model, area)
    end
    dashboard:Event(owner, "Arrival", kind == "Angry")
    if
        StaffConcernPolicy.Due(
            session.StaffConcerns,
            session.TycoonProgress.CompletedExpansions,
            staffSettings,
            Random.new()
        )
    then
        session.StaffConcerns.Pending = true
    end
    markDirty(owner)
    local data = customerData[model]
    if not data.Private then
        if data.Angry then
            sendEventNotice(owner, "AngryCustomerArrived", model)
        elseif data.Rich then
            sendEventNotice(owner, "RichCustomerArrived", model)
        end
    end
    if (owner:GetAttribute("CustomersHelped") or 0) == 0 then
        sendMilestone(owner, "M2")
    end
    updateQueue()
    return true
end

local function getFirstCustomerDelay()
    local minimum = tonumber(Config.FirstCustomerDelay)
    local maximum = tonumber(Config.FirstCustomerDelayMax)
    if not minimum or minimum ~= minimum then
        minimum = 10
    end
    if not maximum or maximum ~= maximum then
        maximum = 15
    end
    minimum = math.clamp(minimum, 10, 300)
    maximum = math.clamp(maximum, minimum, 300)
    return Random.new():NextNumber(minimum, maximum)
end

local function beginCustomerLoop(myGeneration)
    task.spawn(function()
        local schedule = CustomerSpawnSchedule.New(Config)
        while generation == myGeneration and owner do
            local blocked = ensureBusinessVisit() or businessVisitor ~= nil
            local due = schedule:Step(os.clock(), {
                Expanded = hasExpandedLines(),
                Stars = owner:GetAttribute("Stars") or 0,
                Staffed = {
                    Main = isCounterStaffed("Main"),
                    Left = isCounterStaffed("Left"),
                    Right = isCounterStaffed("Right"),
                },
                Multipliers = {
                    Main = roomArrivalMultiplier("Main"),
                    Left = roomArrivalMultiplier("Left"),
                    Right = roomArrivalMultiplier("Right"),
                },
                FirstAt = firstCustomerAt,
                Blocked = blocked,
            })
            for _, area in ipairs(due) do
                if generation ~= myGeneration or not owner then
                    break
                end
                spawnCustomer(area)
            end
            task.wait(0.25)
        end
    end)
end

local function resetTycoon()
    lastSpecialNoticeAt = -math.huge
    helpPacing:Reset()
    if ceremony then
        ceremony:Reset()
    end
    if privateSessions then
        privateSessions:Reset()
    end
    if dashboard then
        dashboard:Reset()
    end
    generation += 1
    firstCustomerAt = 0
    if staffVisits then
        staffVisits:Reset()
    end
    for _, expansion in ipairs(expansions) do
        expansion:Reset()
    end
    businessVisitor = nil
    for _, data in pairs(customerData) do
        ScenarioAI.Cancel(data.GenerationTicket)
    end
    setActiveCustomer(nil)
    owner = nil
    counters:Reset()
    table.clear(customerData)
    table.clear(purchasedUpgrades)
    customersFolder:ClearAllChildren()
    setVisible(claimPad, true)
    setVisible(baseItems, false)
    setVisible(upgradePads, false)
    for _, item in ipairs(upgradeItems:GetChildren()) do
        setVisible(item, false)
    end
    hideEditorMarkers()
    for _, settings in ipairs(visitSettings) do
        local items, pads = TycoonProgression.Templates(settings)
        for _, template in pairs({ items, pads }) do
            if template:IsDescendantOf(workspace) and not template:IsDescendantOf(building) then
                setVisible(template, false)
            end
        end
    end
end

local function playPurchaseSound(prompt)
    -- Use the pad's editable Sound, but only after the server commits the action.
    local holder = prompt.Parent and prompt.Parent:FindFirstChild("Script")
    local sound = holder and holder:FindFirstChild("Sound")
    if sound and sound:IsA("Sound") then
        sound.TimePosition = 0
        sound:Play()
    end
end

for _, pad in ipairs(upgradePads:GetChildren()) do
    local prompt = pad:FindFirstChild("PurchasePrompt", true)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Triggered:Connect(function(player)
            local id = pad:GetAttribute("UpgradeId")
            local price = pad:GetAttribute("Price") or 0
            if not player:GetAttribute("DataLoaded") then
                rejectAction(player, "DataStillLoading")
                return
            end
            if player ~= owner then
                rejectAction(player, "NotBusinessOwner")
                return
            end
            if
                type(id) ~= "string"
                or id == ""
                or type(price) ~= "number"
                or price ~= price
                or price < 0
                or price == math.huge
            then
                rejectAction(player, "UpgradeUnavailable")
                return
            end
            if purchasedUpgrades[id] then
                rejectAction(player, "AlreadyPurchased")
                return
            end
            if (player:GetAttribute("Money") or 0) < price then
                rejectAction(player, "InsufficientFunds")
                return
            end
            local item = upgradeItems:FindFirstChild(id)
            if not item then
                warn("Missing editable upgrade model: " .. tostring(id))
                rejectAction(player, "UpgradeUnavailable")
                return
            end
            purchasedUpgrades[id] = true
            local session = playerSessions[player]
            if session then
                session.Purchases[id] = true
                markDirty(player)
            end
            setMoney(player, player:GetAttribute("Money") - price)
            setVisible(item, true)
            setVisible(pad, false)
            for _, expansion in ipairs(expansions) do
                expansion:OpenPassages()
            end
            playPurchaseSound(prompt)
            checkStageProgress(player)
            -- Purchases save immediately instead of waiting for the next autosave.
            task.spawn(savePlayerData, player, false)
        end)
    end
end

local claimPrompt = claimPad:FindFirstChild("ClaimPrompt", true)
assert(
    claimPrompt and claimPrompt:IsA("ProximityPrompt"),
    "ClaimPad needs a descendant ProximityPrompt named ClaimPrompt"
)
claimPrompt.Triggered:Connect(function(player)
    if owner then
        rejectAction(player, "BusinessAlreadyClaimed")
        return
    end
    if not player:GetAttribute("DataLoaded") then
        rejectAction(player, "DataStillLoading")
        return
    end
    owner, generation = player, generation + 1
    firstCustomerAt = os.clock() + getFirstCustomerDelay()
    player:SetAttribute("OwnsBusiness", true)
    if not player:GetAttribute("TutorialCompleted") then
        -- Claiming proves the player found the business, so dismiss and persist the onboarding.
        player:SetAttribute("TutorialCompleted", true)
        markDirty(player)
        task.spawn(savePlayerData, player, false)
    end
    local nameLabel = baseItems:FindFirstChild("BusinessName", true)
    if nameLabel and nameLabel:IsA("TextLabel") then
        nameLabel.Text = UI.T("World", "BusinessTitle", player.DisplayName)
    end
    setVisible(claimPad, false)
    setVisible(baseItems, true)
    setVisible(upgradePads, true)
    for _, item in ipairs(upgradeItems:GetChildren()) do
        setVisible(item, false)
    end
    table.clear(purchasedUpgrades)
    local session = playerSessions[player]
    if session then
        for id, purchased in pairs(session.Purchases) do
            if purchased then
                local item = upgradeItems:FindFirstChild(id)
                local matchingPad
                for _, pad in ipairs(upgradePads:GetChildren()) do
                    if pad:GetAttribute("UpgradeId") == id then
                        matchingPad = pad
                        break
                    end
                end
                if item and matchingPad then
                    purchasedUpgrades[id] = true
                    setVisible(item, true)
                    setVisible(matchingPad, false)
                end
            end
        end
    end
    for _, expansion in ipairs(expansions) do
        expansion:Apply(player, session)
    end
    staffMorale:Sync(false)
    checkStageProgress(player)
    beginCustomerLoop(generation)
    playPurchaseSound(claimPrompt)
end)

local function customerReaction(data, outcome)
    if not data.CustomerProfile then
        return nil
    end
    local sensitive = data.Scenario.ContentFlag ~= nil
        or data.Scenario.Severity > Config.AIScenarioMaximumSeverity
    return CustomerBehavior.React(activeCustomer, data.CustomerProfile, outcome, sensitive)
end

local function finishAnsweredStage(player, data)
    local scenario = data.Scenario
    if data.StageIndex < #scenario.Stages then
        data.StageIndex += 1
        return { Correct = true, Continue = true, NextStage = makeDialoguePayload(data) }
    end
    local finishedCustomer = activeCustomer
    helpPacing:Helped()
    PersonalConsultationPolicy.Helped(playerSessions[player].CustomerValues)
    setActiveCustomer(nil)
    local stars = math.clamp(math.floor(tonumber(player:GetAttribute("Stars")) or 0), 0, Config.MaxStars)
    local reward = CustomerValues.Reward(scenario.Difficulty, stars, data.Rich, Config, valueSettings)
    if data.Private then
        reward = PrivateSessionPolicy.Reward(reward, privateSettings)
    end
    setMoney(player, (player:GetAttribute("Money") or 0) + reward)
    setProgress(player, (player:GetAttribute("CustomersHelped") or 0) + 1)
    counters:Remove(finishedCustomer)
    customerData[finishedCustomer] = nil
    if not ensureBusinessVisit() then
        updateQueue()
    end
    if data.Kind == "Staff" then
        local record = staffVisits.Active
        if record and record.Model == finishedCustomer then
            record.Helped = true
            staffMorale:Recover(record.StaffId)
        end
        StaffConcernPolicy.Complete(playerSessions[player].StaffConcerns)
        markDirty(player)
        staffVisits:Return(finishedCustomer, data.Area)
        checkStageProgress(player)
        task.spawn(savePlayerData, player, false)
    elseif data.Private then
        staffMorale:Customer(data.PrivateStation, scenario, data.Angry)
        privateSessions:Depart(finishedCustomer, data)
    else
        if data.Angry and not data.MoralePenaltyApplied then
            data.MoralePenaltyApplied = true
            staffMorale:Customer(data.Area, scenario, true)
        end
        walkOut(finishedCustomer, data.Area)
    end
    return { Correct = true, Reward = reward, Success = scenario.Feedback, Difficulty = scenario.Difficulty }
end

submitAnswer.OnServerInvoke = function(player, answer, contextToken, answerToken)
    if dashboard and dashboard:IsActive(player) then
        return dashboard:Submit(player, answer, contextToken)
    end
    if contextToken ~= nil then
        return { Error = UI.T("Dashboard", "Expired") }
    end
    if player ~= owner or not activeCustomer or not isActionableCustomer(activeCustomer) then
        return { Error = UI.T("ServerErrors", "ThereIsNoActiveCustomer") }
    end
    local currentCustomer = activeCustomer
    local data = customerData[currentCustomer]
    if not data or data.Kind == "BusinessMan" then
        return { Error = UI.T("ServerErrors", "ThereIsNoActiveScenario") }
    end
    if data.Opening then
        return { Error = UI.T("ServerErrors", "YourScenarioIsStillPreparing") }
    end
    local scenario = data.Scenario
    local stageIndex = data.StageIndex
    local stage = scenario.Stages[stageIndex]
    if not stage then
        return { Error = UI.T("ServerErrors", "ThereIsNoActiveQuestion") }
    end

    local status, previous = AnswerSubmission.Check(data, answerToken, answer)
    if status == "Repeat" then
        return previous
    elseif status == "Busy" then
        return { Error = UI.T("ServerErrors", "YourResponseIsStillBeingGraded") }
    elseif status ~= "Ready" then
        return { Error = UI.T("ServerErrors", "AnswerExpired"), CurrentStage = makeDialoguePayload(data) }
    end

    if scenario.Mode == "FRQ" then
        if type(answer) ~= "string" then
            return { Error = UI.T("ServerErrors", "WriteAResponseBeforeSubmitting") }
        end
        local response = string.match(answer, "^%s*(.-)%s*$") or ""
        local responseCharacters = utf8.len(response)
        if not responseCharacters or #response > 2000 then
            return { Error = UI.T("ServerErrors", "ThatResponseCouldNotBeProcessedSafely") }
        end
        if responseCharacters < Config.FRQMinCharacters then
            return { Error = UI.T("ServerErrors", "WriteALittleMoreSoTheAI") }
        end
        if responseCharacters > Config.FRQMaxCharacters then
            return { Error = UI.T("Dialogue", "CharacterLimit", Config.FRQMaxCharacters) }
        end
        if data.Grading then
            return { Error = UI.T("ServerErrors", "YourResponseIsStillBeingGraded") }
        end
        local now = os.clock()
        if now - (data.LastFRQSubmitAt or -math.huge) < Config.FRQGradingCooldownSeconds then
            return { Error = UI.T("ServerErrors", "PleaseWaitAMomentBeforeSubmittingAgain") }
        end
        AnswerSubmission.Begin(data, answerToken, answer)
        data.Grading, data.LastFRQSubmitAt = true, now
        local okay, grade, gradeError = pcall(FRQGrader.Grade, player, scenario, stageIndex, response)
        data.Grading = false
        if not okay then
            warn("CalmWorks FRQ grading error: " .. tostring(grade))
            grade, gradeError = nil, UI.T("ServerNotices", "GradingUnavailable")
        end
        if
            player ~= owner
            or activeCustomer ~= currentCustomer
            or customerData[currentCustomer] ~= data
            or data.StageIndex ~= stageIndex
        then
            return { Error = UI.T("ServerErrors", "ThisCustomerIsNoLongerActive") }
        end
        if not grade then
            -- The existing curated three-choice stage is a safe fallback. No score is recorded.
            scenario.Mode = "MCQ"
            return AnswerSubmission.Finish(data, {
                SwitchToMCQ = true,
                NextStage = makeDialoguePayload(data),
                Error = (gradeError or UI.T("ServerNotices", "GradingFailed"))
                    .. UI.T("ServerNotices", "MCQFallback"),
            })
        end
        -- Every valid graded attempt counts, including a corrected retry.
        data.RecordedStages[stageIndex] = true
        recordCategoryAnswer(player, scenario, grade.Passed)
        if not grade.Passed then
            local outcome = grade.Scores.EscalationRisk >= Config.FRQMaximumEscalationRisk and "Risky"
                or "Mixed"
            return AnswerSubmission.Finish(data, {
                Correct = false,
                Mode = "FRQ",
                Analysis = grade,
                CustomerReaction = customerReaction(data, outcome),
            })
        end
        local reaction = customerReaction(data, "Optimal")
        local result = finishAnsweredStage(player, data)
        result.Mode, result.Analysis = "FRQ", grade
        result.CustomerReaction = reaction
        return AnswerSubmission.Finish(data, result)
    end

    if type(answer) ~= "number" or answer % 1 ~= 0 or not stage.Choices[answer] then
        return { Error = UI.T("ServerErrors", "InvalidAnswer") }
    end
    AnswerSubmission.Begin(data, answerToken, answer)
    local isCorrect = answer == stage.BestIndex
    data.RecordedStages[stageIndex] = true
    recordCategoryAnswer(player, scenario, isCorrect)
    if not isCorrect then
        local specificFeedback = stage.ChoiceFeedback and stage.ChoiceFeedback[answer]
        if type(specificFeedback) ~= "string" or specificFeedback == "" then
            specificFeedback = scenario.Feedback
        end
        return AnswerSubmission.Finish(data, {
            Correct = false,
            CustomerReaction = customerReaction(
                data,
                stage.ChoiceOutcomes and stage.ChoiceOutcomes[answer] or "Mixed"
            ),
            Hint = specificFeedback,
            Outcome = stage.ChoiceOutcomes and stage.ChoiceOutcomes[answer] or "Incorrect",
        })
    end
    local reaction = customerReaction(data, "Optimal")
    local result = finishAnsweredStage(player, data)
    result.CustomerReaction = reaction
    return AnswerSubmission.Finish(data, result)
end

local function findWorkingStaff(area, role)
    local index = role == "Counselor" and 1 or 2
    if area:sub(1, 7) == "Private" then
        index = 4
    end
    local expansion = expansions[index]
    local items = expansion and expansion.Container and expansion.Container:FindFirstChild("Items")
    local id = area .. (role == "Executive" and "ExecutiveConsulter" or role)
    return items and items:FindFirstChild(id)
end

staffVisits = StaffConsultations.New(staffSettings, customerPoints, findWorkingStaff, moraleSettings)
staffMorale = StaffMoraleService.New(
    moraleSettings,
    function()
        return owner and playerSessions[owner]
    end,
    findWorkingStaff,
    function()
        if owner then
            markDirty(owner)
        end
    end,
    function()
        return dashboard and dashboard:Multiplier("Decay") or 1
    end,
    function()
        return activeCustomer ~= nil
    end
)

counters = CustomerCounters.New(customerQueue, customerData, customerPoints, valueSettings, {
    Owner = function()
        return owner
    end,
    Active = function()
        return activeCustomer
    end,
    Expanded = hasExpandedLines,
    Upstairs = hasUpstairs,
    Capacity = function(area)
        if CustomerRouting.IsUpper(area) then
            local count = tonumber(valueSettings:GetAttribute("UpperQueueCapacity")) or 4
            if count ~= count then
                count = 4
            end
            return math.clamp(math.floor(count), 1, 4)
        end
        return Config.MaxQueueSize
    end,
    Staffed = isCounterStaffed,
    HasStaff = hasCounterStaff,
    CanServeStaff = function(model, data, area)
        return canExecutiveHelp(data, area)
    end,
    ReservedUpperSlots = function()
        local session = owner and playerSessions[owner]
        return helpPacing:ReservedUpperSlots(session and session.TycoonProgress.CompletedExpansions or 0)
    end,
    ServiceSeconds = counselorServiceSeconds,
    RequestPersonalHelp = function(player, model, data, area)
        if
            activeCustomer ~= nil
            or businessVisitor
            or data.Kind == "BusinessMan"
            or data.Kind == "Staff"
            or CustomerCounters.RequiresPlayer(data)
            or not isCounterStaffed(area)
        then
            return
        end
        local session = playerSessions[player]
        if not session then
            return
        end
        local now = os.clock()
        if
            not PersonalConsultationPolicy.Due(
                session.CustomerValues,
                session.TycoonProgress.CompletedExpansions,
                personalSettings,
                session.LastPersonalHelpRequestAt,
                now
            )
        then
            return
        end
        if not allowPlayerRequest("Personal", area, model) then
            return
        end
        helpPacing:Requested()
        session.LastPersonalHelpRequestAt = now
        data.PersonalHelp = true
        model:SetAttribute("PersonalHelp", true)
        data.Prompt.ActionText = UI.T("World", "PersonalHelpAction")
        sendEventNotice(player, "PersonalConsultationReady", model)
    end,
    Stuck = function(model)
        local data = customerData[model]
        if data and data.Kind == "Staff" then
            ScenarioAI.Cancel(data.GenerationTicket)
            counters:Remove(model)
            customerData[model] = nil
            if activeCustomer == model then
                setActiveCustomer(nil)
            end
            staffVisits:Recover(model)
            counters:Update()
            warn("CalmWorks: staff route blocked; restored the workstation and kept the visit pending.")
            return
        end
        warn(
            "CalmWorks: customer route blocked at "
                .. tostring(model:GetAttribute("CounterArea"))
                .. "; removing stuck visitor."
        )
        model:Destroy()
    end,
    Served = function(player, model, data)
        local session = playerSessions[player]
        if player ~= owner or not session or customerData[model] ~= data or activeCustomer == model then
            return
        end
        if data.Kind == "Staff" then
            local record = staffVisits.Active
            if not canExecutiveHelp(data, data.Area) or not record or record.Model ~= model
                or record.Returning or record.Helped then
                return
            end
            -- A resolved staff concern restores morale, not money or player learning evidence.
            record.Helped = true
            ScenarioAI.Cancel(data.GenerationTicket)
            staffMorale:Customer(data.Area, data.Scenario, false)
            staffMorale:Recover(record.StaffId)
            StaffConcernPolicy.Complete(session.StaffConcerns)
            counters:Remove(model)
            customerData[model] = nil
            model:SetAttribute("CounselorServing", false)
            data.Prompt.Enabled = false
            markDirty(player)
            staffVisits:Return(model, data.Area)
            updateQueue()
            checkStageProgress(player)
            task.spawn(savePlayerData, player, false)
            return
        end
        if CustomerCounters.RequiresPlayer(data) then
            return
        end
        staffMorale:Customer(data.Area, data.Scenario, false)
        dashboard:Event(player, "Service")
        PersonalConsultationPolicy.Automatic(playerSessions[player].CustomerValues)
        -- Staff income must never fabricate answers, practice progress, or skill evidence.
        local stars = player:GetAttribute("Stars") or 0
        local reward =
            CustomerValues.Reward(data.Scenario.Difficulty, stars, data.Rich, Config, valueSettings)
        setMoney(player, (player:GetAttribute("Money") or 0) + reward)
        ScenarioAI.Cancel(data.GenerationTicket)
        counters:Remove(model)
        customerData[model] = nil
        model:SetAttribute("CounselorServing", false)
        walkOut(model, data.Area)
        updateQueue()
        checkStageProgress(player)
        task.spawn(savePlayerData, player, false)
    end,
})

for index, settings in ipairs(visitSettings) do
    expansions[index] = BusinessExpansion.New(settings, building, {
        SetVisible = setVisible,
        SetMoney = setMoney,
        IsOwner = function(player)
            return player == owner
        end,
        Reject = rejectAction,
        BusinessTitle = function(player)
            return UI.T("World", "BusinessTitle", player.DisplayName)
        end,
        ProgressChanged = function(player, id)
            staffMorale:Hire(id)
            staffMorale:Sync(false)
            markDirty(player)
            checkStageProgress(player)
            task.spawn(savePlayerData, player, false)
        end,
    }, index)
    for _, attribute in ipairs({ "ExpansionReady", "DialogueReady" }) do
        settings:GetAttributeChangedSignal(attribute):Connect(function()
            if owner then
                expansions[index]:Apply(owner, playerSessions[owner])
                checkStageProgress(owner)
            end
        end)
    end
end

privateSessions = PrivateSessions.New(privateSettings, customerPoints, {
    AllowPlayerRequest = function(room)
        return allowPlayerRequest("Private", room)
    end,
    Root = function()
        local container = expansions[4].Container
        local items = container and container:FindFirstChild("Items")
        return items and items:FindFirstChild("PrivateSessionBaseItems")
    end,
    Employee = function(id)
        return findWorkingStaff(id, "Counselor")
    end,
    Away = function(id)
        return staffVisits:Away(id, "Counselor")
    end,
    Data = function(model)
        return customerData[model]
    end,
    Owner = function()
        return owner
    end,
    Active = function()
        return activeCustomer
    end,
    Notice = sendEventNotice,
    Failed = function(model)
        local data = customerData[model]
        if data then
            ScenarioAI.Cancel(data.GenerationTicket)
            customerData[model] = nil
        end
        if activeCustomer == model then
            setActiveCustomer(nil)
        end
        model:Destroy()
    end,
    WalkOut = walkOut,
    ServiceSeconds = function(id)
        local seconds =
            PrivateSessionPolicy.Number(privateSettings:GetAttribute("ServiceSeconds"), 45, 5, 300)
        local morale = staffMorale:Multiplier(id)
        local boost = dashboard and dashboard:Multiplier("Service") or 1
        return seconds / morale / boost
    end,
    Completed = function(player, model, data)
        if player ~= owner or customerData[model] ~= data or activeCustomer == model then
            return
        end
        local normal = CustomerValues.Reward(
            data.Scenario.Difficulty,
            player:GetAttribute("Stars") or 0,
            data.Rich,
            Config,
            valueSettings
        )
        setMoney(
            player,
            (player:GetAttribute("Money") or 0) + PrivateSessionPolicy.Reward(normal, privateSettings)
        )
        staffMorale:Customer(data.PrivateStation, data.Scenario, data.Angry)
        PersonalConsultationPolicy.Automatic(playerSessions[player].CustomerValues)
        ScenarioAI.Cancel(data.GenerationTicket)
        privateSessions:Depart(model, data)
        customerData[model] = nil
        markDirty(player)
        task.spawn(savePlayerData, player, false)
    end,
})

dashboard = DashboardService.New(dashboardSettings, {
    Create = function(player)
        local session = playerSessions[player]
        local scenario = DialogueGenerator.Generate(
            player:GetAttribute("Stars") or 0,
            session.CategoryAccuracy,
            session.RecentScenarioIds,
            session.AnswerHistory,
            session.PracticeEnabled and PracticePolicy.Codes(currentPracticeTargets(session)) or nil,
            session.RecentCustomerProfiles,
            reservedScenarioIds()
        )
        local metrics = AdaptiveSkills.GenerationContext(session.AnswerHistory, scenario, CATEGORY_DEFINITIONS, Config)
        scenario.TargetSkill = metrics.TargetSkill
        metrics.PracticeMode = session.PracticeEnabled == true
        return scenario, ScenarioAI.Start(player, scenario, metrics)
    end,
    Resolve = ScenarioAI.Resolve,
    Cancel = ScenarioAI.Cancel,
    Grade = FRQGrader.Grade,
    Access = function(player, enabled)
        if player.Parent == Players and player:GetAttribute("OnlineConsultationsUnlocked") ~= enabled then
            player:SetAttribute("OnlineConsultationsUnlocked", enabled)
        end
    end,
    Upgraded = function(player)
        local session = player and playerSessions[player]
        local purchases = session and session.ExpansionPurchases["4"]
        return purchases ~= nil and purchases.DashboardUpgrade == true
    end,
    Session = function(player)
        return player and playerSessions[player]
    end,
    Owner = function()
        return owner
    end,
    Context = function(player)
        local session = playerSessions[player]
        local result = { StaffCount = 0, AverageMorale = 0, Queues = {}, AngryWaiting = 0 }
        local total = 0
        if session then
            for _, staff in ipairs(StaffMoralePolicy.Roster) do
                local index = staff.Stage
                local purchases = session.ExpansionPurchases[index] or {}
                if purchases[staff.Id] then
                    result.StaffCount += 1
                    total += session.StaffMorale.Entries[staff.Id].Morale
                end
            end
        end
        if result.StaffCount > 0 then
            result.AverageMorale = total / result.StaffCount
        end
        for _, area in ipairs({ "Main", "Left", "Right", "UpperLeft", "UpperRight" }) do
            result.Queues[area] = 0
        end
        for model, data in pairs(customerData) do
            if model.Parent and not data.Private and result.Queues[data.Area] ~= nil then
                result.Queues[data.Area] += 1
                if data.Angry then
                    result.AngryWaiting += 1
                end
            end
        end
        return result
    end,
    Panel = function()
        local container = expansions[3].Container
        local items = container and container:FindFirstChild("Items")
        return items and items:FindFirstChild("CentralDashboard")
    end,
    Busy = function()
        return activeCustomer ~= nil
    end,
    Hold = function(model)
        setActiveCustomer(model)
    end,
    Release = function(model)
        if activeCustomer == model then
            setActiveCustomer(nil)
        end
    end,
    Open = function(player, payload)
        if player.Parent == Players then
            openDialogue:FireClient(player, payload)
        end
    end,
    Reject = rejectAction,
    Notice = function(player, key)
        rejectAction(player, key)
        sendEventNotice(player, key)
    end,
    Record = recordCategoryAnswer,
    Changed = markDirty,
    Save = function(player)
        task.spawn(savePlayerData, player, false)
    end,
    Completed = function(player)
        PersonalConsultationPolicy.Helped(playerSessions[player].CustomerValues)
        helpPacing:Helped()
    end,
})
remotes:WaitForChild("OpenDashboard").OnServerEvent:Connect(function(player)
    if player:GetAttribute("DataLoaded") then
        dashboard:OpenRemote(player)
    end
end)
remotes:WaitForChild("CloseDashboard").OnServerEvent:Connect(function(player, token)
    dashboard:Close(player, token)
end)
remotes:WaitForChild("ContinueDashboard").OnServerEvent:Connect(function(player, token)
    if player:GetAttribute("DataLoaded") then
        dashboard:Continue(player, token)
    end
end)

ceremony = require(ServerStorage:WaitForChild("CeremonyService")).New(Shared.RibbonCeremony, {
    Owner = function()
        return owner
    end,
    Progress = function(player)
        local session = player and playerSessions[player]
        return session and session.TycoonProgress
    end,
    Maxed = function(player)
        return player == owner and stageMaxed(player) == true
    end,
    Busy = function()
        return activeCustomer ~= nil
    end,
    Hold = function(lock)
        setActiveCustomer(lock)
    end,
    Release = function(lock)
        if activeCustomer == lock then
            setActiveCustomer(nil)
        end
    end,
    Send = function(player, data)
        if player.Parent == Players then
            remotes.CeremonyEvent:FireClient(player, data)
        end
    end,
    Speak = function(player, data)
        if player.Parent == Players then
            openBusinessVisit:FireClient(player, data)
        end
    end,
    CloseSpeech = function(player, token)
        if player.Parent == Players then
            closeBusinessVisit:FireClient(player, token)
        end
    end,
    Reject = rejectAction,
    Complete = function(player)
        local session = playerSessions[player]
        session.TycoonProgress.Won = true
        session.TycoonProgress.CeremonyClosingSeen = false
        setRating(player, session.TycoonProgress)
        markDirty(player)
        task.spawn(savePlayerData, player, true)
    end,
    Seen = function(player)
        local session = playerSessions[player]
        session.TycoonProgress.CeremonyClosingSeen = true
        markDirty(player)
        sendMilestone(player, "GameComplete")
        task.spawn(savePlayerData, player, true)
    end,
})
remotes.CeremonyFinished.OnServerEvent:Connect(function(player, token)
    ceremony:Finish(player, token)
end)
remotes.CeremonyAbort.OnServerEvent:Connect(function(player, token)
    ceremony:Abort(player, token)
end)
remotes.AdvanceCeremony.OnServerInvoke = function(player, token, index)
    return ceremony:Advance(player, token, index)
end

local function onPlayerAdded(player)
    configurePlayerCharacter(player)
    loadPlayerData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(function(player)
    syncPendingMoney(player)
    lastActionRejectionAt[player] = nil
    ScenarioAI.CancelPlayer(player)
    rollProgressDay(player, os.time())
    captureProgress(player, os.time())
    savePlayerData(player, true, true)
    if player == owner then
        resetTycoon()
    end
    disconnectMoneySync(player)
    playerSessions[player] = nil
end)

task.spawn(function()
    while task.wait(1) do
        staffMorale:Sync(true)
        dashboard:Tick()
        privateSessions:Tick()
        ceremony:Tick()
        if owner then
            for model, data in pairs(customerData) do
                if data.PendingNotice then
                    sendEventNotice(owner, data.PendingNotice, model)
                end
            end
        end
        local okay, reason = pcall(tryStaffVisit)
        if not okay then
            warn("CalmWorks staff scheduling failed: " .. tostring(reason))
        end
        if owner then
            local count = helpContext().Count
            if owner:GetAttribute("PlayerHelpOutstanding") ~= count then
                owner:SetAttribute("PlayerHelpOutstanding", count)
            end
        end
        for player, session in pairs(playerSessions) do
            if player.Parent then
                local now = os.time()
                local dayChanged = session.ProgressDay ~= ProgressCalendar.Day(now)
                rollProgressDay(player, now)
                if
                    dayChanged
                    or now - (session.LastProgressCaptureAt or 0) >= Config.ProgressCheckpointSeconds
                then
                    captureProgress(player, now)
                    accuracyUpdated:FireClient(player, makeAccuracySnapshot(player))
                    task.spawn(savePlayerData, player, false)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.AutoSaveSeconds) do
        for player in pairs(playerSessions) do
            if player.Parent then
                task.spawn(savePlayerData, player, false)
            end
        end
    end
end)

game:BindToClose(function()
    local remaining = 0
    for player, session in pairs(playerSessions) do
        rollProgressDay(player, os.time())
        captureProgress(player, os.time())
        if session.CanSave then
            remaining += 1
            task.spawn(function()
                savePlayerData(player, true, true)
                remaining -= 1
            end)
        end
    end
    local deadline = os.clock() + 25
    while remaining > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)

resetTycoon()
