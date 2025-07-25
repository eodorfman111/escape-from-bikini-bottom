--[[
    Checkpoint.server.lua
    This script handles the checkpoint mechanic for Stage1 (SpongeBob's Street).
    When a player touches a checkpoint part (inside SpongeBob's pineapple), their respawn location is set to that part.
    If they die later in the obby, they will respawn at this checkpoint rather than the start.

    Usage:
    • Place a SpawnLocation or Part in Stage1 to act as the checkpoint. Give it a name containing "checkpoint"
      (case‑insensitive), set a boolean attribute "IsCheckpoint" to true, or tag it with "Checkpoint" via CollectionService.
    • The script will automatically connect to it and assign players' RespawnLocation when touched.
    • Optionally, you can set the part's transparency or appearance in Studio; the script does not modify visuals.

    Note: Roblox's SpawnLocation objects have built‑in spawn behaviour. This script overrides the player's
    RespawnLocation property to force respawning at the checkpoint.
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Stage = script.Parent

-- Connect a single checkpoint part
local function connectCheckpoint(part: BasePart)
    if part:GetAttribute("CheckpointConnected") then
        return
    end
    part:SetAttribute("CheckpointConnected", true)
    part.Touched:Connect(function(other)
        local character = other and other.Parent
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                -- Set the player's respawn point to this part
                player.RespawnLocation = part
            end
        end
    end)
end

-- Determine if a part is a checkpoint candidate
local function isCheckpoint(obj: Instance)
    if not obj:IsA("BasePart") then
        return false
    end
    if obj:GetAttribute("IsCheckpoint") then
        return true
    end
    local name = obj.Name:lower()
    if name:find("checkpoint") then
        return true
    end
    return false
end

-- Connect checkpoints tagged via CollectionService
for _, inst in ipairs(CollectionService:GetTagged("Checkpoint")) do
    if inst:IsA("BasePart") then
        connectCheckpoint(inst)
    end
end

-- Listen for new parts tagged as "Checkpoint"
CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(function(inst)
    if inst:IsA("BasePart") then
        connectCheckpoint(inst)
    end
end)

-- Scan Stage1 for existing checkpoint parts
for _, obj in ipairs(Stage:GetDescendants()) do
    if isCheckpoint(obj) then
        connectCheckpoint(obj)
    end
end

-- Watch for new parts added to Stage1
Stage.DescendantAdded:Connect(function(obj)
    if isCheckpoint(obj) then
        connectCheckpoint(obj)
    end
end)
