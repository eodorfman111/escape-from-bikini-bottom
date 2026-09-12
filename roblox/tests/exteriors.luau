--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../tools/WorldKit")
-- selene: allow(incorrect_standard_library_use)
local World = require("../tools/World")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")
-- selene: allow(incorrect_standard_library_use)
local roblox = require("../tools/Roblox")
-- selene: allow(incorrect_standard_library_use)
local fs = require("@lune/fs")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame

local function vector(value: WorldKit.Triple): Vector3
	return Vector3.new(value[1], value[2], value[3])
end
local function frame(part: WorldKit.Part): CFrame
	return CFrame.new(vector(part.position))
		* CFrame.Angles(math.rad(part.rotation[1]), math.rad(part.rotation[2]), math.rad(part.rotation[3]))
end
local function corners(part: WorldKit.Part): { Vector3 }
	local result = {}
	local cf, half = frame(part), vector(part.size) / 2
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				table.insert(result, cf * Vector3.new(x * half.X, y * half.Y, z * half.Z))
			end
		end
	end
	return result
end

for _, triangle in
	{
		{ { 0, 1, 0 }, { -1, 0, 0 }, { 1, 0, 0 } },
		{ { 1, 2, 3 }, { -4, 5, 9 }, { 10, -7, 2 } },
		{ { 10, -7, 2 }, { 1, 2, 3 }, { -4, 5, 9 } },
	}
do
	local kit = WorldKit.new("street", { 0, 0, 0 })
	kit:triangle("Test surface", triangle[1], triangle[2], triangle[3], { 100, 100, 100 })
	local a, b, c = vector(triangle[1]), vector(triangle[2]), vector(triangle[3])
	local normal = (b - a):Cross(c - a)
	local area = 0
	for _, part in kit.parts do
		area += part.size[2] * part.size[3] / 2
		local cf, half = frame(part), vector(part.size) / 2
		for _, corner in
			{
				Vector3.new(0, half.Y, half.Z),
				Vector3.new(0, -half.Y, half.Z),
				Vector3.new(0, -half.Y, -half.Z),
			}
		do
			local p = cf * corner
			assert(math.abs((p - a):Dot(normal.Unit)) < 0.0001, "Wedge face stays in the triangle plane")
			local sum = (
				(a - p):Cross(b - p).Magnitude
				+ (b - p):Cross(c - p).Magnitude
				+ (c - p):Cross(a - p).Magnitude
			) / 2
			assert(math.abs(sum - normal.Magnitude / 2) < 0.001, "Wedge vertices stay inside the triangle")
		end
	end
	assert(
		math.abs(area - normal.Magnitude / 2) < 0.001,
		"Wedges cover the triangle without gaps or overlaps"
	)
end

type Bounds = { min: Vector3, max: Vector3 }
local bounds: { [string]: Bounds } = {}
local specs, balls = World(), 0
local hinge = CFrame.new(vector(Config.exteriorPoint("rock", Config.RockHinge)))
local opening = hinge * CFrame.Angles(-math.rad(78), 0, 0) * hinge:Inverse()
for _, part in specs do
	if part.shape == "Ball" then
		balls += 1
	end
	for _, id in { "rock", "moai", "pineapple" } do
		if part.group ~= id .. "-exterior" and not (id == "rock" and part.group == "PatrickLid") then
			continue
		end
		if not bounds[id] then
			bounds[id] = {
				min = Vector3.new(math.huge, math.huge, math.huge),
				max = Vector3.new(-math.huge, -math.huge, -math.huge),
			}
		end
		for _, point in corners(part) do
			bounds[id].min = bounds[id].min:Min(point)
			bounds[id].max = bounds[id].max:Max(point)
			if part.group == "PatrickLid" then
				assert(
					(opening * point).Z < Config.Exteriors.rock.origin[3],
					"Open rock clears the entire approach"
				)
			end
		end
	end
end
assert(bounds.rock.max.Y < bounds.moai.max.Y * 0.5, "Patrick's closed rock stays below half Moai height")
assert(bounds.moai.max.Y > 35 and bounds.moai.max.Y < 46, "Moai height fits the player-scale neighborhood")
assert(
	bounds.pineapple.max.Y > 30 and bounds.pineapple.max.Y < 46,
	"Pineapple and Moai have comparable height"
)
assert(bounds.rock.max.X + 8 < bounds.moai.min.X, "Rock and Moai have separate lots")
assert(bounds.moai.max.X + 8 < bounds.pineapple.min.X, "Moai and pineapple have separate lots")
for _, portal in Config.Portals do
	if portal.zone == "street" then
		local towardRoad = Vector3.new(0, 0, Config.RoadZ - portal.position[3])
		assert(towardRoad:Dot(vector(portal.normal)) > Config.RoadWidth / 2, "Street entrances face the road")
		assert(portal.width >= 6, "Street doorways accommodate a standard avatar")
	end
end

local place = roblox.deserializePlace(fs.readFile("build/ConchStreetSurvival.rbxl"))
local meshes, lidParts = 0, 0
local scenery = false
for _, instance in place:GetDescendants() do
	if instance:IsA("SpecialMesh") then
		meshes += 1
		local parent = instance.Parent
		assert(
			parent and parent:IsA("Part") and parent.Shape == roblox.Enum.PartType.Block,
			"Ellipsoids use block-backed meshes"
		)
		assert(
			instance.MeshType == roblox.Enum.MeshType.Sphere and instance.Scale == Vector3.one,
			"Ellipsoid proportions follow parent size"
		)
	elseif instance:IsA("Model") and instance.Name == "PatrickLid" then
		for _, part in instance:GetChildren() do
			assert(
				part:IsA("BasePart") and part.Anchored and not part.CanCollide,
				"Animated rock lid is cosmetic"
			)
			lidParts += 1
		end
	elseif instance:IsA("LocalScript") and instance.Name == "Scenery" then
		scenery = true
	end
end
assert(meshes == balls and meshes > 100, "Every sphere spec survives serialization with its explicit mesh")
assert(scenery and lidParts > 500, "Rock animation and editable lid are embedded")
print(
	"PASS triangle coverage, landmark proportions, clear opening arc, road alignment and serialized sphere meshes"
)
