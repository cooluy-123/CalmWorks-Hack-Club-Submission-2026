local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Shared = game.ReplicatedStorage:WaitForChild("CalmWorksShared")
local settings = Shared:WaitForChild("NPCAttention")
local policy = require(Shared:WaitForChild("AttentionPolicy"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local template = settings:WaitForChild("AttentionMarker")
local records = {}
local seen = {}
local tag = "CalmWorksHelpVisitor"

local function remove(model)
    local record = records[model]
    if not record then
        return
    end
    if record.Marker then
        record.Marker:Destroy()
    end
    if record.Id and model:GetAttribute("AttentionActive") == false then
        seen[record.Id] = nil
    end
    records[model] = nil
end

local function add(model)
    if model:IsA("Model") and not records[model] then
        records[model] = {}
    end
end

local added = CollectionService:GetInstanceAddedSignal(tag):Connect(add)
local removed = CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
for _, model in ipairs(CollectionService:GetTagged(tag)) do
    add(model)
end

while script.Parent do
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local alive = root and humanoid and humanoid.Health > 0
    local rooms = settings.Rooms.Value
    local room = alive and policy.RoomAt(rooms, root.Position)
    local owns = player:GetAttribute("OwnsBusiness") == true
    if not owns then
        table.clear(seen)
    end
    for model, record in pairs(records) do
        local id = model:GetAttribute("AttentionVisitId")
        local mine = model:GetAttribute("AttentionOwnerId") == player.UserId
        local active = model:GetAttribute("AttentionActive") == true
        local head = model:FindFirstChild("Head")
        if not model:IsDescendantOf(workspace) or not active or not mine or not owns or not id then
            if record.Marker then
                record.Marker.Enabled = false
            end
        else
            if record.Id ~= id then
                if record.Marker then
                    record.Marker:Destroy()
                end
                record.Marker = nil
                record.Id = id
            end
            local needed = model:GetAttribute("AttentionNeeded") == true
            local sameRoom = room ~= nil and room == model:GetAttribute("CounterArea")
            local acknowledged, visible = policy.Observe(seen[id] == true, needed, sameRoom)
            seen[id] = acknowledged
            if not record.Marker and head then
                record.Marker = template:Clone()
                record.Marker.Name = "NPCAttention_" .. id
                record.Marker.Adornee = head
                record.Marker.Enabled = false
                record.Marker.Parent = playerGui
            end
            if record.Marker then
                record.Marker.Adornee = head
                record.Marker.Enabled = visible
                    and alive ~= nil
                    and alive ~= false
                    and head ~= nil
                    and rooms ~= nil
                    and settings:GetAttribute("Enabled") ~= false
            end
        end
    end
    local interval = tonumber(settings:GetAttribute("CheckInterval")) or 0.2
    if interval ~= interval then
        interval = 0.2
    end
    task.wait(math.clamp(interval, 0.1, 1))
end

added:Disconnect()
removed:Disconnect()
for model in pairs(records) do
    remove(model)
end
