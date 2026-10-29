local Expansion = {}
local Progress = require(script.Parent.TycoonProgression)
local ServerStorage = game:GetService("ServerStorage")

local function setSpawnPosition(settings, expanded)
    local placement = settings:FindFirstChild("SpawnPlacement")
    if not placement then
        return
    end
    local reference = placement:FindFirstChild("Target")
    local normal = placement:FindFirstChild("NormalCFrame")
    local spawn = reference and reference:IsA("ObjectValue") and reference.Value
    if not spawn or not spawn:IsA("SpawnLocation") or not spawn:IsDescendantOf(workspace) then
        return
    end
    if not normal or not normal:IsA("CFrameValue") then
        return
    end

    local target = normal.Value
    if expanded then
        local offset = placement:GetAttribute("OffsetZ")
        if type(offset) == "number" and offset == offset and math.abs(offset) < math.huge then
            target += Vector3.new(0, 0, offset)
        end
    end
    -- Always start from the saved baseline so repeated restores cannot move it farther.
    spawn.CFrame = target
end

local function prepareCounselor(model)
    if not model:GetAttribute("CounselorArea") and not model:GetAttribute("ManagerArea") then
        return
    end
    -- Stationary staff must not let Humanoid physics turn collisions back on.
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.EvaluateStateMachine = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
            part:SetAttribute("CalmWorksCanCollide", false)
            part:SetAttribute("CalmWorksCanTouch", false)
            part:SetAttribute("CalmWorksCanQuery", false)
        end
    end
end

local function removePurchasedCovers(items, id)
    -- Only remove parts in this runtime expansion, never the editable templates.
    for _, part in ipairs(items:GetDescendants()) do
        if part:IsA("BasePart") and part:GetAttribute("RemoveWhenPurchased") == id then
            part:Destroy()
        end
    end
end

function Expansion.ValidPurchases(saved, settings)
    local result = {}
    local items, pads = Progress.Templates(settings)
    if type(saved) ~= "table" or not items or not pads then
        return result
    end
    for _, pad in ipairs(pads:GetChildren()) do
        local id = pad:GetAttribute("UpgradeId")
        local legacyId = pad:GetAttribute("LegacyPurchaseId")
        local purchased = saved[id] == true
        -- Previously purchased pairs keep both individual plants.
        if type(legacyId) == "string" and legacyId ~= "" and saved[legacyId] == true then
            purchased = true
        end
        if type(id) == "string" and purchased and Progress.FindItem(items, id) then
            result[id] = true
        end
    end
    return result
end

function Expansion.New(settings, building, callbacks, index)
    local self = {
        Container = nil,
        Pending = nil,
        Connections = {},
        RemovedPassages = {},
        PassagesFolder = nil,
        RemovedUpgradeCovers = {},
        UpgradeCoversFolder = nil,
    }

    function self:RemoveUpgradeCovers(items, id)
        removePurchasedCovers(items, id)
        -- Later upgrades can open explicitly tagged covers in earlier runtime stages.
        for _, container in ipairs(building:GetChildren()) do
            local stage = container:GetAttribute("CalmWorksExpansionIndex")
            local otherItems = container:FindFirstChild("Items")
            if type(stage) == "number" and stage < index and otherItems then
                for _, part in ipairs(otherItems:GetDescendants()) do
                    if part:IsA("BasePart") and part:GetAttribute("RemoveWhenPurchased") == id
                        and part:GetAttribute("RemoveWhenPurchasedStage") == index then
                        if not self.UpgradeCoversFolder then
                            self.UpgradeCoversFolder = Instance.new("Folder")
                            self.UpgradeCoversFolder.Name = "CalmWorksPurchasedCovers" .. index
                            self.UpgradeCoversFolder.Parent = ServerStorage
                        end
                        table.insert(self.RemovedUpgradeCovers, {Part = part, Parent = part.Parent})
                        part.Parent = self.UpgradeCoversFolder
                    end
                end
            end
        end
    end

    function self:OpenPassages()
        if not self.Container then
            return
        end
        for _, ref in ipairs(settings.HideOnExpand:GetChildren()) do
            if ref:IsA("ObjectValue") and ref.Value and ref.Value:IsDescendantOf(building) then
                local targets = { ref.Value }
                if index == 2 and not ref.Value:IsA("BasePart") then
                    targets = ref.Value:GetDescendants()
                end
                for _, target in ipairs(targets) do
                    local allowed = true
                    local removeFromWorld = ref:GetAttribute("RemoveFromWorld") == true
                    if index == 2 then
                        -- A group reference must never hide the whole back wall.
                        allowed = target:IsA("BasePart") and target.Name == "WallR"
                        removeFromWorld = true
                    end
                    if allowed and target:IsDescendantOf(building) then
                        callbacks.SetVisible(target, false)
                        if removeFromWorld and target:IsA("BasePart") then
                            if not self.PassagesFolder then
                                self.PassagesFolder = Instance.new("Folder")
                                self.PassagesFolder.Name = "CalmWorksRemovedPassages" .. index
                                self.PassagesFolder.Parent = ServerStorage
                            end
                            table.insert(self.RemovedPassages, { Part = target, Parent = target.Parent })
                            target.Parent = self.PassagesFolder
                        end
                    end
                end
            end
        end
    end

    function self:Reset()
        setSpawnPosition(settings, false)
        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end
        table.clear(self.Connections)
        for _, entry in ipairs(self.RemovedUpgradeCovers) do
            if entry.Parent.Parent and entry.Part.Parent == self.UpgradeCoversFolder then
                entry.Part.Parent = entry.Parent
            end
        end
        table.clear(self.RemovedUpgradeCovers)
        if self.UpgradeCoversFolder then
            self.UpgradeCoversFolder:Destroy()
            self.UpgradeCoversFolder = nil
        end
        -- Restore reusable base-building parts before clearing this owner's expansion.
        for _, entry in ipairs(self.RemovedPassages) do
            if entry.Parent.Parent and entry.Part.Parent == self.PassagesFolder then
                entry.Part.Parent = entry.Parent
            end
        end
        table.clear(self.RemovedPassages)
        if self.PassagesFolder then
            self.PassagesFolder:Destroy()
            self.PassagesFolder = nil
        end
        if self.Pending then
            self.Pending:Destroy()
            self.Pending = nil
        end
        if self.Container then
            self.Container:Destroy()
            self.Container = nil
        end
    end

    function self:Apply(player, session, unlocking)
        if self.Container then
            self:OpenPassages()
            setSpawnPosition(settings, true)
            return true
        end
        if not unlocking and session.TycoonProgress.CompletedExpansions < index then
            return false
        end
        if not Progress.ExpansionReady(settings) then
            return false
        end
        local itemTemplate, padTemplate = Progress.Templates(settings)
        local container = Instance.new("Folder")
        container.Name = "ExpansionVisit" .. index
        container:SetAttribute("CalmWorksExpansionIndex", index)
        local items = itemTemplate:Clone()
        local pads = padTemplate:Clone()
        items.Name, pads.Name = "Items", "UpgradePads"
        items.Parent, pads.Parent = container, container
        for _, object in ipairs(container:GetDescendants()) do
            if object:IsA("LuaSourceContainer") then
                for _, child in ipairs(object:GetChildren()) do
                    if not child:IsA("LuaSourceContainer") then
                        child.Parent = object.Parent
                    end
                end
                object:Destroy()
            end
        end
        local pending = Instance.new("Folder")
        pending.Name = "CalmWorksLockedUpgrades" .. index
        pending.Parent = ServerStorage
        self.Pending = pending
        for _, item in ipairs(items:GetChildren()) do
            prepareCounselor(item)
        end
        local key = tostring(index)
        local purchases = session.ExpansionPurchases[key] or {}
        session.ExpansionPurchases[key] = purchases
        callbacks.SetVisible(items, true)
        callbacks.SetVisible(pads, true)
        for _, object in ipairs(items:GetDescendants()) do
            if object:IsA("TextLabel") and object.Name == "BusinessName" then
                object.Text = callbacks.BusinessTitle(player)
            end
        end
        for _, pad in ipairs(pads:GetChildren()) do
            local id = pad:GetAttribute("UpgradeId")
            local item = Progress.FindItem(items, id)
            local itemParent = item.Parent
            local prompt = pad:FindFirstChild("PurchasePrompt", true)
            local purchased = purchases[id] == true
            if purchased then
                self:RemoveUpgradeCovers(items, id)
            else
                item.Parent = pending
            end
            callbacks.SetVisible(item, purchased)
            callbacks.SetVisible(pad, not purchased)
            local function refreshLabel()
                local display = tostring(pad:GetAttribute("DisplayName") or id)
                local price = tostring(pad:GetAttribute("Price") or 0)
                prompt.ActionText, prompt.ObjectText = "Purchase " .. display, "$" .. price
                local title = pad:FindFirstChild("Title", true)
                local pricing = pad:FindFirstChild("Pricing", true)
                if title and title:IsA("TextLabel") then
                    title.Text = display
                end
                if pricing and pricing:IsA("TextLabel") then
                    pricing.Text = "$" .. price
                end
            end
            refreshLabel()
            table.insert(self.Connections, pad:GetAttributeChangedSignal("Price"):Connect(refreshLabel))
            table.insert(self.Connections, pad:GetAttributeChangedSignal("DisplayName"):Connect(refreshLabel))
            table.insert(
                self.Connections,
                prompt.Triggered:Connect(function(who)
                    if who ~= player or not callbacks.IsOwner(who) then
                        callbacks.Reject(who, "NotBusinessOwner")
                        return
                    end
                    local price = pad:GetAttribute("Price")
                    local root = who.Character and who.Character:FindFirstChild("HumanoidRootPart")
                    local part = prompt:FindFirstAncestorWhichIsA("BasePart")
                    if
                        not root
                        or not part
                        or (root.Position - part.Position).Magnitude > prompt.MaxActivationDistance + 3
                    then
                        callbacks.Reject(who, "UpgradeUnavailable")
                        return
                    end
                    if type(price) ~= "number" or price ~= price or price < 0 or price == math.huge then
                        callbacks.Reject(who, "UpgradeUnavailable")
                        return
                    end
                    if purchases[id] then
                        callbacks.Reject(who, "AlreadyPurchased")
                        return
                    end
                    if (who:GetAttribute("Money") or 0) < price then
                        callbacks.Reject(who, "InsufficientFunds")
                        return
                    end
                    purchases[id] = true
                    callbacks.SetMoney(who, who:GetAttribute("Money") - price)
                    item.Parent = itemParent
                    self:RemoveUpgradeCovers(items, id)
                    callbacks.SetVisible(item, true)
                    prepareCounselor(item)
                    callbacks.SetVisible(pad, false)
                    local sound = pad:FindFirstChildWhichIsA("Sound", true)
                    if sound then
                        sound:Play()
                    end
                    callbacks.ProgressChanged(who)
                end)
            )
        end
        self.Container = container
        container.Parent = building
        -- Parenting an owned R15 rig into Workspace initializes torso collisions once.
        for _, item in ipairs(items:GetChildren()) do
            prepareCounselor(item)
        end
        self:OpenPassages()
        setSpawnPosition(settings, true)
        player:SetAttribute("Expansion" .. index .. "Active", true)
        return true
    end

    return self
end

return Expansion

