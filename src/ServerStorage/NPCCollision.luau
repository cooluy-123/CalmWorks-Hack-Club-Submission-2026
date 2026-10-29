local PhysicsService = game:GetService("PhysicsService")
local Collision = {}
local furnitureGroup = "CalmWorksFurniture"

function Collision.IsFurniture(part)
    local current = part
    while current and current ~= game do
        local setting = current:GetAttribute("NPCPassThrough")
        if setting ~= nil then
            return setting == true
        end
        current = current.Parent
    end
    return false
end

function Collision.Configure()
    for _, name in ipairs({ "CalmWorksCustomers", "CalmWorksPlayers", furnitureGroup }) do
        if not PhysicsService:IsCollisionGroupRegistered(name) then
            PhysicsService:RegisterCollisionGroup(name)
        end
    end
    PhysicsService:CollisionGroupSetCollidable("CalmWorksCustomers", furnitureGroup, false)
    PhysicsService:CollisionGroupSetCollidable("CalmWorksPlayers", furnitureGroup, true)
    PhysicsService:CollisionGroupSetCollidable("Default", furnitureGroup, true)
end

function Collision.Apply(part)
    if not part:IsA("BasePart") or not Collision.IsFurniture(part) then
        return
    end
    part.CollisionGroup = furnitureGroup
    local modifier = part:FindFirstChild("CalmWorksNPCPassThrough")
    if not modifier then
        modifier = Instance.new("PathfindingModifier")
        modifier.Name = "CalmWorksNPCPassThrough"
        modifier.Parent = part
    end
    modifier.PassThrough = true
end

function Collision.Start(building)
    Collision.Configure()
    for _, object in ipairs(building:GetDescendants()) do
        Collision.Apply(object)
    end
    -- Purchased and restored furniture inherits the editable template attribute.
    return building.DescendantAdded:Connect(function(object)
        Collision.Apply(object)
    end)
end

return Collision
