--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Conch").Config)
local lid = workspace:WaitForChild("ConchWorld"):WaitForChild("street"):WaitForChild("PatrickLid")
assert(lid:IsA("Model"), "Patrick's rock lid must be a Model")
local point = Config.exteriorPoint("rock", Config.RockHinge)
local hinge = CFrame.new(point[1], point[2], point[3])
	* CFrame.Angles(0, math.rad(Config.Exteriors.rock.yaw), 0)
local closed = hinge:ToObjectSpace(lid:GetPivot())
local origin = Config.Exteriors.rock.origin
local center = Vector3.new(origin[1], origin[2], origin[3])
local amount, target, poll = 0, 0, 0

RunService.RenderStepped:Connect(function(dt: number)
	poll -= dt
	if poll <= 0 then
		poll, target = 0.15, 0
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if root and root:IsA("BasePart") and (root.Position - center).Magnitude < 27 then
				target = 1
				break
			end
		end
	end
	if amount == target then
		return
	end
	local step = math.min(dt / 0.8, math.abs(target - amount))
	amount += if target > amount then step else -step
	local eased = amount * amount * (3 - 2 * amount)
	lid:PivotTo(hinge * CFrame.Angles(-math.rad(78) * eased, 0, 0) * closed)
end)
