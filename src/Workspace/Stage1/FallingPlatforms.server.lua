--[[ 
    FallingPlatforms.server.lua
    This script powers the "falling mailboxes" obstacles in Stage1 (SpongeBob's Street).
    When a player steps on a mailbox (or any part tagged/named appropriately), it will unanchor and fall,
    then reset back to its original position after a short delay.

    Usage:
    • Tag any part with the CollectionService tag "FallingPlatform" to make it fall when touched.
    • Alternatively, name the part so that it contains "mailbox" or set a boolean attribute "IsFallingPlatform" to true.

    The script records the original CFrame and Anchored state of each falling platform.
    When a player touches the platform, it becomes unanchored and falls. After a delay, it resets to its original CFrame
    and re-anchors. A debounce prevents multiple triggers in quick succession.
--]]

local CollectionService = game:GetService("CollectionService")
local Stage = script.Parent
local TweenService = game:GetService("TweenService")

-- Table to store per‑platform state
local platformData: {[Instance]: {cframe: CFrame, anchored: boolean, busy: boolean}} = {}

-- Reset a platform back to its original state
local function resetPlatform(part: BasePart)
    local data = platformData[part]
    if not data then
        return
    end
    -- Reset CFrame and anchor state
    part.Anchored = false
    -- Use a tween for a smooth reset, optional but nicer
    local tween = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {CFrame = data.cframe})
    tween:Play()
    tween.Completed:Wait()
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
    part.CFrame = data.cframe
    part.Anchored = data.anchored
    data.busy = false
end

-- Trigger the falling behaviour for a platform when touched
local function triggerPlatform(part: BasePart)
    local data = platformData[part]
    if not data or data.busy then
        return
    end
    data.busy = true
    -- Unanchor to make it fall
    part.Anchored = false
    -- Wait before resetting; adjust delay for difficulty
    task.delay(3, function()
        resetPlatform(part)
    end)
end

-- Connect a falling behaviour to a single part
local function connectFallingPlatform(part: BasePart)
    if platformData[part] then
        return
    end
    platformData[part] = {
        cframe = part.CFrame,
        anchored = part.Anchored,
        busy = false
    }
    part.Touched:Connect(function(other)
        local character = other and other.Parent
        if not character then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            triggerPlatform(part)
        end
    end)
end

-- Determine whether an object should be treated as a falling platform
local function shouldBeFalling(obj: Instance)
    if not obj:IsA("BasePart") then
        return false
    end
    if obj:GetAttribute("IsFallingPlatform") then
        return true
    end
    local name = obj.Name:lower()
    if name:find("mailbox") or name:find("falling") then
        return true
    end
    return false
end

-- Scan all tagged platforms
for _, part in ipairs(CollectionService:GetTagged("FallingPlatform")) do
    if part:IsA("BasePart") then
        connectFallingPlatform(part)
    end
end

-- Listen for new tags
CollectionService:GetInstanceAddedSignal("FallingPlatform"):Connect(function(obj)
    if obj:IsA("BasePart") then
        connectFallingPlatform(obj)
    end
end)

-- Scan Stage for named or attributed platforms
local function scanForFalling(container: Instance)
    for _, obj in ipairs(container:GetDescendants()) do
        if shouldBeFalling(obj) then
            connectFallingPlatform(obj)
        end
    end
end

scanForFalling(Stage)

-- Watch for new parts added to Stage
Stage.DescendantAdded:Connect(function(obj)
    if shouldBeFalling(obj) then
        connectFallingPlatform(obj)
    end
end)
