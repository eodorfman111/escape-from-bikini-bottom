--!strict
-- selene: allow(incorrect_standard_library_use)
local World = require("../tools/World")
-- selene: allow(incorrect_standard_library_use)
local Roblox = require("../tools/Roblox")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")
local Vector3, CFrame = Roblox.Vector3, Roblox.CFrame
type Obstacle = { zone: string, name: string, frame: CFrame, half: Vector3, radius: number }
local parts = World()
local obstacles: { Obstacle } = {}
for _, part in parts do
	if part.collide and part.transparency < 1 then
		table.insert(obstacles, {
			zone = part.zone,
			name = part.name,
			frame = CFrame.new(unpack(part.position)) * CFrame.Angles(
				math.rad(part.rotation[1]),
				math.rad(part.rotation[2]),
				math.rad(part.rotation[3])
			),
			half = Vector3.new(unpack(part.size)) / 2,
			radius = Vector3.new(unpack(part.size)).Magnitude / 2,
		})
	end
end
local function inside(point: Vector3, obstacle: Obstacle): boolean
	local p = obstacle.frame:PointToObjectSpace(point)
	local half = obstacle.half
	return math.abs(p.X) < half.X - 0.01 and math.abs(p.Y) < half.Y - 0.01 and math.abs(p.Z) < half.Z - 0.01
end
local samples = 0
local function route(zone: string, points: { { number } })
	for index = 1, #points - 1 do
		local start, finish = Vector3.new(unpack(points[index])), Vector3.new(unpack(points[index + 1]))
		local steps = math.ceil((finish - start).Magnitude)
		for step = 0, steps do
			local center = start:Lerp(finish, step / steps)
			local supported = false
			for _, obstacle in obstacles do
				if
					obstacle.zone ~= zone
					or (center - obstacle.frame.Position).Magnitude > obstacle.radius + 6
				then
					continue
				end
				if inside(center - Vector3.new(0, 0.3, 0), obstacle) then
					supported = true
				end
				for _, x in { -1.5, 0, 1.5 } do
					for _, z in { -1.5, 0, 1.5 } do
						for _, y in { 1, 3, 5.5 } do
							assert(
								not inside(center + Vector3.new(x, y, z), obstacle),
								string.format(
									"%s route blocked at %.1f, %.1f by %s",
									zone,
									center.X,
									center.Z,
									obstacle.name
								)
							)
						end
					end
				end
			end
			assert(supported, zone .. " route has a floor gap at " .. tostring(center))
			samples += 1
		end
	end
end
route("sponge", {
	{ 0, 0, 684 },
	{ 42, 0, 684 },
	{ 42, 0, 650 },
	{ 76, 0, 650 },
	{ 108, 0, 650 },
	{ 108, 0, 704 },
	{ 108, 0, 754 },
	{ 78, 0, 754 },
	{ 78, 0, 774 },
})
route("sponge", { { 0, 0, 684 }, { 0, 0, 666 }, { -13, 0, 666 }, { -13, 0, 624 } })
route("krusty", {
	{ 600, 0, 690 },
	{ 600, 0, 666 },
	{ 619, 0, 666 },
	{ 619, 0, 645 },
	{ 635, 0, 645 },
	{ 635, 0, 622 },
	{ 635, 0, 575 },
	{ 635, 0, 556 },
})
route("krusty", { { 635, 0, 575 }, { 580, 0, 575 }, { 565, 0, 575 } })
route("krusty", { { 635, 0, 625 }, { 664, 0, 625 }, { 664, 0, 629 }, { 688, 0, 629 } })
route("krusty", { { 664, 0, 625 }, { 664, 0, 609 }, { 688, 0, 609 } })
route("street", { { 390, 0, 41 }, { 390, 0, 10 }, { 390, 0, -21 } })
route("street", { { 390, 0, -19.2 }, { 357, 0, -19.2 }, { 357, 0, -28 } })
route("street", { { 390, 0, -19.2 }, { 424, 0, -19.2 }, { 424, 0, -26 } })
route("street", { { 80, 0, 83 }, { 80, 0, 170 } })
route("krusty", { { 600, 0, 666 }, { 581, 0, 666 }, { 581, 0, 645 }, { 562, 0, 645 }, { 562, 0, 629 } })
local entrances = 0
for _, portal in Config.Portals do
	if portal.zone == "sponge" then
		entrances += 1
		assert(portal.id == "pineapple-in", "Pineapple rooms must connect without internal portals")
	end
end
assert(entrances == 1, "One street doorway serves the connected pineapple")
assert(
	not Config.Zones.spongeLibrary and not Config.Zones.spongeBedroom,
	"Pineapple shares one navigation zone"
)
print("PASS", samples, "player-width route samples with continuous floors and headroom")
