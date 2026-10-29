local Shared = game.ReplicatedStorage.CalmWorksShared
local AttentionPolicy = require(Shared.AttentionPolicy)
local settings = Shared.NPCAttention
local Interaction = {}

function Interaction.CanStart(player, owner, model, data, active, first)
    if not player or not owner or player ~= owner then
        return false, "NotBusinessOwner"
    end
    if not first then
        return false, "CustomerNotFirstInLine"
    end
    if
        not data
        or data.Kind ~= "BusinessMan"
        or not data.ArrivedAt
        or active
        or not data.Prompt
        or not data.Prompt.Enabled
    then
        return false, "CustomerAlreadyActive"
    end
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not humanoid or humanoid.Health <= 0 or not root then
        return false, "CustomerAlreadyActive"
    end
    if (playerRoot.Position - root.Position).Magnitude > data.Prompt.MaxActivationDistance + 2 then
        return false, "CustomerAlreadyActive"
    end
    local rooms = settings.Rooms.Value
    if AttentionPolicy.RoomAt(rooms, playerRoot.Position) ~= data.Area then
        return false, "CustomerAlreadyActive"
    end
    -- Check walls only when interacting, not every frame.
    local head = character:FindFirstChild("Head") or playerRoot
    local target = model:FindFirstChild("Head") or root
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = { character, model }
    parameters.RespectCanCollide = true
    if workspace:Raycast(head.Position, target.Position - head.Position, parameters) then
        return false, "CustomerAlreadyActive"
    end
    return true
end

return Interaction
