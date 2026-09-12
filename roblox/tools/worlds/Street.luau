--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../../src/shared/Config")

local sand, asphalt, water = { 236, 219, 167 }, { 67, 104, 110 }, { 49, 174, 195 }

local function flower(
	kit: WorldKit.Kit,
	x: number,
	y: number,
	z: number,
	radius: number,
	color: WorldKit.Triple
)
	for i = 0, 59 do
		local a, b = i * math.pi / 30, (i + 1) * math.pi / 30
		local ar, br = radius * (0.7 + 0.3 * math.cos(5 * a)), radius * (0.7 + 0.3 * math.cos(5 * b))
		local ax, ay = x + math.cos(a) * ar, y + math.sin(a) * ar
		local bx, by = x + math.cos(b) * br, y + math.sin(b) * br
		local dx, dy = bx - ax, by - ay
		local line = kit:cylinder(
			"Distant flower outline",
			{ (ax + bx) / 2, (ay + by) / 2, z },
			{ math.sqrt(dx * dx + dy * dy), 0.55, 0.55 },
			color,
			{ 0, 0, math.deg(math.atan2(dy, dx)) }
		)
		line.collide = false
	end
end

return function(): { WorldKit.Part }
	local kit = WorldKit.new("street", { 0, 0, 0 })
	local zone = Config.Zones.street
	local cx, cz, width, depth = zone.origin[1], zone.origin[3], zone.size[1], zone.size[3]
	kit:part("Sea floor", { cx, -2, cz }, { width + 320, 4, depth + 300 }, sand, nil, "Sand")
	kit:part(
		"Conch Street",
		{ cx, 0.02, Config.RoadZ },
		{ width + 280, 0.08, Config.RoadWidth },
		asphalt,
		nil,
		"Concrete"
	).collide =
		false
	for _, id in { "rock", "moai", "pineapple" } do
		local x = Config.Exteriors[id].origin[1]
		local start, finish = 10, Config.RoadZ - Config.RoadWidth / 2
		if id == "moai" then
			for z = 15, finish, 6 do
				kit:part(
					"Squidward's wooden stepping plank",
					{ x, 0.1, z },
					{ 7.5, 0.2, 1.8 },
					{ 101, 88, 75 },
					nil,
					"WoodPlanks"
				)
			end
		else
			kit:part(
				"House footpath",
				{ x, 0.07, (start + finish) / 2 },
				{ 7, 0.1, finish - start },
				asphalt,
				nil,
				"Concrete"
			).collide =
				false
			if id == "pineapple" then
				for z = 14, finish - 1, 4 do
					for _, side in { -1, 1 } do
						kit:ball(
							"Pineapple stepping stone",
							{ x + side * 1.7, 0.15, z + side * 0.4 },
							{ 2.3, 0.14, 1.6 },
							{ 145, 159, 87 }
						).collide =
							false
					end
				end
			end
		end
		if id ~= "pineapple" then
			local mx = x + 12
			kit:cylinder("Mailbox post", { mx, 1.7, 29 }, { 3.4, 0.35, 0.35 }, { 112, 107, 80 })
			kit:ball(
				"Rounded mailbox",
				{ mx, 3.6, 29 },
				{ 2.5, 1.8, 2.6 },
				if id == "rock" then { 205, 131, 136 } else { 104, 137, 157 }
			)
			kit:part("Mailbox opening", { mx, 3.5, 30.3 }, { 1.5, 0.6, 0.08 }, { 37, 67, 80 })
		end
	end
	for _, id in { "krab", "bucket" } do
		local door = Config.exteriorPoint(id, { 0, 0, 10 })
		local direction = if door[3] < Config.RoadZ then 1 else -1
		local curb = Config.RoadZ - direction * Config.RoadWidth / 2
		kit:part(
			"Restaurant footpath",
			{ door[1], 0.07, (door[3] + curb) / 2 },
			{ 10, 0.1, math.abs(door[3] - curb) },
			asphalt,
			nil,
			"Concrete"
		).collide =
			false
	end
	for i = 0, 15 do
		local x = -190 + i * 34
		local z = -88 - i % 3 * 12
		local height = 16 + i * 7 % 23
		local color = { 89 + i % 4 * 9, 157 + i % 3 * 8, 171 }
		kit:cylinder("Distant Bikini Bottom tube building", { x, height / 2, z }, { height, 9, 9 }, color)
		kit:ball("Tube building rounded cap", { x, height, z }, { 9, 3, 9 }, color)
		for y = 5, height - 4, 6 do
			kit:cylinder(
				"Distant building porthole",
				{ x, y, z + 4.6 },
				{ 0.15, 2, 2 },
				{ 65, 126, 145 },
				{ 0, 90, 0 }
			).collide =
				false
		end
	end
	for i = 0, 23 do
		local x, z = -164 + i * 20, 145 + i % 3 * 9
		for j = 0, 2 do
			kit:ball(
				"Coral",
				{ x + j * 1.2, 1.5 + j, z },
				{ 0.8, 3 + j * 2, 0.8 },
				{ 174 + i % 4 * 15, 108 + i % 5 * 12, 169 }
			).collide =
				false
		end
	end
	for i = 0, 6 do
		flower(
			kit,
			-190 + i * 87,
			65 + i % 3 * 23,
			-174,
			21 + i % 2 * 9,
			if i % 2 == 0 then { 92, 189, 166 } else { 100, 159, 197 }
		)
	end
	for _, panel in
		{
			{ { cx, 120, -240 }, { 862, 240, 2 } },
			{ { cx, 120, 380 }, { 862, 240, 2 } },
			{ { cx - 430, 120, 70 }, { 2, 240, 620 } },
			{ { cx + 430, 120, 70 }, { 2, 240, 620 } },
			{ { cx, 240, 70 }, { 862, 2, 620 } },
		}
	do
		local backdrop = kit:part("Underwater backdrop", panel[1], panel[2], water, nil, "Neon")
		backdrop.collide, backdrop.castShadow = false, false
	end
	kit:cylinder("Conch Street signpost", { 57, 4, 32 }, { 8, 0.45, 0.45 }, { 128, 96, 65 })
	kit:part("Conch Street signboard", { 57, 7.5, 32 }, { 10, 2.4, 0.4 }, { 51, 117, 123 }, nil, "WoodPlanks")
	kit:label("CONCH STREET\nRestaurants →", { 57, 8.5, 32 })
	kit:part("Lifeguard supply stand", { 70, 2.5, 72 }, { 8, 5, 4 }, { 38, 133, 142 }, nil, "WoodPlanks")
	kit:supply({ 69, 2, 67 })
	for _, wall in
		{
			{ { cx - width / 2, 35, cz }, { 2, 70, depth } },
			{ { cx + width / 2, 35, cz }, { 2, 70, depth } },
			{ { cx, 35, cz - depth / 2 }, { width, 70, 2 } },
			{ { cx, 35, cz + depth / 2 }, { width, 70, 2 } },
		}
	do
		kit:part("Reef boundary", wall[1], wall[2], { 60, 135, 146 }).transparency = 1
	end
	return kit.parts
end
