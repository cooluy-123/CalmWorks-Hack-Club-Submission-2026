local Progress = {}
Progress.ExpansionCount = 4

function Progress.Clean(saved)
    local completed = type(saved) == "table" and tonumber(saved.CompletedExpansions) or 0
    if not completed or completed ~= completed then
        completed = 0
    end
    completed = math.clamp(math.floor(completed), 0, Progress.ExpansionCount)
    return {
        CompletedExpansions = completed,
        FinalVisitCompleted = completed == Progress.ExpansionCount and type(saved) == "table" and saved.FinalVisitCompleted == true,
        Won = completed == Progress.ExpansionCount and type(saved) == "table" and saved.Won == true,
        CeremonyClosingSeen = completed == Progress.ExpansionCount and type(saved) == "table"
            and saved.Won == true and saved.CeremonyClosingSeen ~= false,
    }
end

function Progress.Stars(state)
    return state.Won and 5 or state.CompletedExpansions
end

function Progress.FindItem(items, id)
    if not items or type(id) ~= "string" or id == "" then
        return nil
    end

    local item = items:FindFirstChild(id)
    for _, group in ipairs(items:GetChildren()) do
        if group:IsA("Folder") and group:GetAttribute("UpgradeGroup") == true then
            local candidate = group:FindFirstChild(id)
            if candidate then
                -- Ambiguous IDs must not unlock the wrong model.
                if item then
                    return nil
                end
                item = candidate
            end
        end
    end
    return item
end

function Progress.Catalog(items, pads)
    if not items or not pads then
        return nil, "Missing upgrade templates"
    end
    local catalog = {}
    local required = {}
    for _, pad in ipairs(pads:GetChildren()) do
        local id = pad:GetAttribute("UpgradeId")
        local price = pad:GetAttribute("Price")
        local prompt = pad:FindFirstChild("PurchasePrompt", true)
        if type(id) ~= "string" or id == "" or catalog[id] then
            return nil, "Each pad needs a unique UpgradeId"
        end
        local item = Progress.FindItem(items, id)
        if not item or not prompt or not prompt:IsA("ProximityPrompt") then
            return nil, "Each pad needs a matching upgrade and PurchasePrompt"
        end
        if type(price) ~= "number" or price ~= price or price < 0 or price == math.huge then
            return nil, "Each pad needs a valid non-negative Price"
        end
        catalog[id] = pad
        if pad:GetAttribute("RequiredForProgression") ~= false then
            table.insert(required, id)
        end
    end
    -- Empty or unfinished stages must not grant stars automatically.
    if #required == 0 then
        return nil, "Add at least one required upgrade"
    end
    table.sort(required)
    return catalog, required
end

function Progress.Templates(settings)
    local items = settings and settings:FindFirstChild("ItemsTemplate")
    local pads = settings and settings:FindFirstChild("PadsTemplate")
    return items and items.Value, pads and pads.Value
end

function Progress.ExpansionReady(settings)
    if not settings or settings:GetAttribute("ExpansionReady") ~= true then
        return false
    end
    local items, pads = Progress.Templates(settings)
    if settings:GetAttribute("FeatureOnly") == true and items and pads and #pads:GetChildren() == 0 then
        return true
    end
    return Progress.Catalog(items, pads) ~= nil
end

function Progress.IsMaxed(state, purchases, expansionPurchases, baseItems, basePads, settings)
    local index = state.CompletedExpansions
    local items, pads = baseItems, basePads
    local owned = purchases
    if index > 0 then
        if not Progress.ExpansionReady(settings[index]) then
            return false
        end
        items, pads = Progress.Templates(settings[index])
        owned = expansionPurchases[tostring(index)] or {}
    end
    local catalog, required = Progress.Catalog(items, pads)
    if not catalog then
        return false
    end
    for _, id in ipairs(required) do
        if owned[id] ~= true then
            return false
        end
    end
    return true
end

return Progress
