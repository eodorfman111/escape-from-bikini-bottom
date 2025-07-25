--[[ 
    KillParts.server.lua
    This script controls all kill parts in Stage1 (SpongeBob's Street) of the "Escape from Bikini Bottom" obby.
    Kill parts represent Gary’s slime trails — if a player touches one, they die.

    Usage:
    • Tag any part you want to behave as a kill part with the CollectionService tag "KillPart".
      You can do this in Roblox Studio via the Tag Editor (Home > CollectionService > Add Tag).
    • Alternatively, set the part's name to include "slime" (case‑insensitive) or set a boolean attribute "IsKillPart" to true.
    • When a player's character touches a tagged/marked part, their humanoid's health is set to 0.

    The script watches for new parts added to Stage1 so you can build in Studio and see changes live.
--]]

local CollectionService = game:GetService("CollectionService")
local Stage = script.Parent

-- Connect a kill behaviour to a single part
local function connectKillPart(part: BasePart)
    -- Guard against connecting twice
    if part:GetAttribute("KillConnected") then
        return
    end
    part:SetAttribute("KillConnected", true)
    part.Touched:Connect(function(other)
        local character = other and other.Parent
        if not character then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
        end
    end)
end

-- Scan existing descendants for killable parts
local function scanForKillParts(container: Instance)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if obj:GetAttribute("IsKillPart") or name:find("slime") then
                connectKillPart(obj)
            end
        end
    end
end

-- Connect kill parts tagged via CollectionService
for _, part in ipairs(CollectionService:GetTagged("KillPart")) do
    if part:IsA("BasePart") then
        connectKillPart(part)
    end
end

-- Listen for new parts being tagged "KillPart"
CollectionService:GetInstanceAddedSignal("KillPart"):Connect(function(inst)
    if inst:IsA("BasePart") then
        connectKillPart(inst)
    end
end)

-- Fallback scanning: any new parts added to Stage1
Stage.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") then
        local name = obj.Name:lower()
        if obj:GetAttribute("IsKillPart") or name:find("slime") then
            connectKillPart(obj)
        end
    end
end)

-- Initial scan for parts named like "slime"
scanForKillParts(Stage)