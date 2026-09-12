--!strict
-- selene: allow(incorrect_standard_library_use)
local fs = require("@lune/fs")
-- selene: allow(incorrect_standard_library_use)
local roblox = require("./Roblox")
-- selene: allow(incorrect_standard_library_use)
local process = require("@lune/process")
-- selene: allow(incorrect_standard_library_use)
local World = require("./World")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")

local Instance = roblox.Instance
local Color3 = roblox.Color3
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Enum = roblox.Enum
local UDim2 = roblox.UDim2
local materials: { [string]: Enum.Material } = {}
local shapes: { [string]: Enum.PartType } = {}
for _, material in Enum.Material:GetEnumItems() do
	materials[material.Name] = material :: Enum.Material
end
for _, shape in Enum.PartType:GetEnumItems() do
	shapes[shape.Name] = shape :: Enum.PartType
end

local function vector(t: { number })
	return Vector3.new(t[1], t[2], t[3])
end
local function color(t: { number })
	return Color3.fromRGB(t[1], t[2], t[3])
end
local world = Instance.new("Model")
world.Name = "ConchWorld"
local zones: { [string]: Folder } = {}
local zoneCount = 0
for id in Config.Zones do
	zoneCount += 1
	local folder = Instance.new("Folder")
	folder.Name = id
	folder.Parent = world
	zones[id] = folder
end
local parts = World()
for _, spec in parts do
	local part: BasePart = if spec.shape == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
	part.Name = spec.name
	part.Size = vector(spec.size)
	part.CFrame = CFrame.new(vector(spec.position))
		* CFrame.Angles(math.rad(spec.rotation[1]), math.rad(spec.rotation[2]), math.rad(spec.rotation[3]))
	part.Color = color(spec.color)
	part.Material = assert(materials[spec.material], "Unknown material " .. spec.material)
	if part:IsA("Part") then
		part.Shape = assert(shapes[spec.shape], "Unknown shape " .. spec.shape)
	end
	part.Anchored = true
	part.CanCollide = spec.collide
	part.CanTouch = false
	part.CanQuery = spec.collide
	part.Transparency = spec.transparency
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("Zone", spec.zone)
	if spec.secret then
		part:SetAttribute("Discovery", spec.secret)
	end
	if spec.secret or spec.supply then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = if spec.secret then "Discover • +80 coins" else "Heal & refill"
		prompt.ObjectText = spec.name
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
		part:SetAttribute("Supply", spec.supply == true)
	end
	if spec.label then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(220, 70)
		gui.MaxDistance = 90
		gui.StudsOffset = Vector3.new(0, 1, 0)
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.fromRGB(255, 242, 211)
		text.TextStrokeTransparency = 0.3
		text.TextSize = 18
		text.TextWrapped = true
		text.Text = spec.label
		text.Parent = gui
		gui.Parent = part
	end
	if spec.light > 0 then
		local light = Instance.new("PointLight")
		light.Color = color(spec.color)
		light.Range = math.min(60, spec.light)
		light.Brightness = 1.3
		light.Shadows = false
		light.Parent = part
	end
	part.Parent = zones[spec.zone]
end
for _, portal in Config.Portals do
	local part = Instance.new("Part")
	part.Name = portal.id
	part.Size = Vector3.new(portal.width, 16, 0.2)
	local position, normal = vector(portal.position), vector(portal.normal)
	part.CFrame = CFrame.lookAt(position + Vector3.new(0, 8, 0), position + Vector3.new(0, 8, 0) - normal)
	part.Color = Color3.fromRGB(100, 230, 231)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.92
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part:SetAttribute("Portal", portal.id)
	part:SetAttribute("Zone", portal.zone)
	part.Parent = zones[portal.zone]
	local canBarricade = portal.barricade
	for _, paired in Config.Portals do
		if paired.id == portal.target and paired.barricade then
			canBarricade = true
		end
	end
	if canBarricade then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Barricade • 40 coins / 15 seconds"
		prompt.ObjectText = portal.label
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end
end
local spawn = Instance.new("SpawnLocation")
spawn.Name = "ConchSpawn"
spawn.Size = Vector3.new(10, 0.2, 10)
spawn.Position = Vector3.new(Config.Spawn[1], 0.15, Config.Spawn[3])
spawn.Anchored = true
spawn.Transparency = 1
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = world
fs.writeDir("build")
fs.writeFile("build/World.rbxm", roblox.serializeModel({ world }))
local result =
	process.exec("rojo", { "build", "default.project.json", "-o", "build/ConchStreetSurvival.rbxl" })
assert(result.ok, result.stderr)
print(result.stdout)
local place = roblox.deserializePlace(fs.readFile("build/ConchStreetSurvival.rbxl"))
assert(place:GetService("Workspace"):FindFirstChild("ConchWorld"), "World missing from place")
print(
	string.format(
		"Built editable place with %d modeled parts, %d doors, %d zones",
		#parts,
		#Config.Portals,
		zoneCount
	)
)
