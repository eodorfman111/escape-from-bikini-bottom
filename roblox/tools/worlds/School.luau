--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
type Kit = WorldKit.Kit
local yellow, blue, white = { 241, 218, 111 }, { 68, 126, 172 }, { 249, 241, 210 }
local red, wood, green = { 210, 78, 70 }, { 174, 125, 75 }, { 55, 105, 93 }

local function boat(kit: Kit, x: number, z: number, color: WorldKit.Triple)
	kit:part("Training boat chassis", { x, 1.5, z }, { 7, 2, 13 }, blue)
	kit:ball("Training boat hull", { x, 3, z }, { 9, 3.5, 17 }, color)
	kit:part("Training boat open cockpit", { x, 4.8, z }, { 6, 0.5, 9 }, wood)
	kit:part("Training boat seat", { x, 5.5, z + 2 }, { 5, 1, 2.5 }, white)
	kit:part("Training boat seat back", { x, 7, z + 3 }, { 5, 3, 0.6 }, white)
	kit:cylinder("Training steering wheel", { x, 6.7, z - 2 }, { 0.3, 2.5, 2.5 }, blue, { 0, 90, 0 })
	for _, side in { -1, 1 } do
		for _, axle in { -4, 4 } do
			kit:cylinder(
				"Training boat wheel",
				{ x + side * 4.5, 1.6, z + axle },
				{ 1.1, 3.2, 3.2 },
				blue,
				{ 0, 0, 0 }
			)
		end
	end
end

local function classroom(): Kit
	local kit = WorldKit.new("street", { 390, 0, -15 })
	kit:room(80, 50, 24, yellow, { 185, 167, 129 }, false)
	for _, side in { -1, 1 } do
		kit:quad(
			"School sloping red roof",
			{ side * 44, 25, -29 },
			{ side * 44, 25, 29 },
			{ 0, 38, 29 },
			{ 0, 38, -29 },
			red
		)
		for _, x in { 16, 31 } do
			kit:part("School blue window frame", { side * x, 12, 25.8 }, { 10, 11, 0.6 }, blue)
			kit:part("School opaque window pane", { side * x, 12, 26.2 }, { 8, 9, 0.2 }, { 132, 203, 215 })
			kit:part("School white window mullion", { side * x, 12, 26.4 }, { 0.5, 9, 0.2 }, white)
			kit:part("School white window crossbar", { side * x, 12, 26.4 }, { 8, 0.5, 0.2 }, white)
		end
	end
	kit:triangle("School front gable", { -44, 25, 29 }, { 44, 25, 29 }, { 0, 38, 29 }, yellow)
	kit:triangle("School rear gable", { -44, 25, -29 }, { 44, 25, -29 }, { 0, 38, -29 }, yellow)
	kit:cylinder("School bell", { 0, 29.5, 29.8 }, { 3, 4, 4 }, wood)
	kit:ball("School bell clapper", { 0, 27.8, 29.8 }, { 1, 1, 1 }, blue)
	kit:part("Boating chalkboard frame", { 0, 12, -24 }, { 43, 12, 0.8 }, wood)
	kit:part("Boating chalkboard", { 0, 12, -23.5 }, { 41, 10, 0.2 }, green)
	for _, x in { -12, 0, 12 } do
		kit:part("Chalk boat diagram hull", { x, 11, -23.3 }, { 8, 0.25, 0.1 }, white).collide = false
		kit:part("Chalk boat diagram mast", { x, 13, -23.3 }, { 0.25, 4, 0.1 }, white).collide = false
		kit:triangle(
			"Chalk sail diagram",
			{ x + 0.2, 15, -23.2 },
			{ x + 3, 12, -23.2 },
			{ x + 0.2, 12, -23.2 },
			white
		)
	end
	kit:part("Mrs Puff teacher desk", { 0, 2.8, -14 }, { 18, 5.6, 7 }, wood, nil, "WoodPlanks")
	kit:part("Teacher desk blue trim", { 0, 5.8, -14 }, { 19, 0.4, 8 }, blue)
	kit:ball("Teacher apple", { -6, 6.7, -13 }, { 1.8, 1.8, 1.8 }, red)
	kit:part("Driving lesson book", { 3, 6.2, -14 }, { 4, 0.4, 3 }, green)
	for _, z in { -13, 0, 13 } do
		for _, x in { -24, -8, 8, 24 } do
			if z == -13 and math.abs(x) == 8 then
				continue
			end
			kit:part("Student desk writing top", { x, 4.8, z }, { 10, 0.6, 5 }, wood, nil, "WoodPlanks")
			for _, side in { -1, 1 } do
				kit:part("Student desk leg", { x + side * 4, 2.4, z }, { 0.5, 4.8, 0.5 }, blue)
			end
			kit:part("Student chair seat", { x, 2.5, z + 5 }, { 5, 0.6, 4 }, blue)
			kit:part("Student chair back", { x, 4.4, z + 6.8 }, { 5, 4, 0.5 }, blue)
			for _, side in { -1, 1 } do
				kit:part("Student chair foot", { x + side * 1.8, 1.2, z + 5 }, { 0.5, 2.4, 3 }, wood)
			end
			kit:part("Student blank workbook", { x, 5.2, z }, { 3, 0.2, 2.5 }, white)
		end
	end
	kit:part("Good Noodle Board frame", { -39, 12, -13 }, { 0.8, 12, 18 }, wood)
	kit:part("Good Noodle Board", { -38.5, 12, -13 }, { 0.2, 10, 16 }, { 40, 63, 61 })
	for row = 0, 6 do
		local y = 8 + row * 1.25
		kit:part("Good noodle chalk row", { -38.3, y - 0.6, -13 }, { 0.1, 0.08, 16 }, white).collide = false
		for col = 0, 3 do
			local z = -18 + col * 3.2
			kit:ball("Good noodle star center", { -38.1, y, z }, { 0.1, 0.5, 0.5 }, yellow).collide = false
			for tip = 0, 4 do
				local a = tip * math.pi * 2 / 5
				kit:triangle(
					"Golden good noodle star",
					{ -38.1, y + math.cos(a) * 0.5, z + math.sin(a) * 0.5 },
					{ -38.1, y + math.cos(a - math.pi / 5) * 0.25, z + math.sin(a - math.pi / 5) * 0.25 },
					{ -38.1, y + math.cos(a + math.pi / 5) * 0.25, z + math.sin(a + math.pi / 5) * 0.25 },
					yellow
				)
			end
		end
	end
	kit:secret("school-good-noodle-board", "Good noodle star", { -33, 5, -13 }, yellow)
	kit:part("Roger display pedestal", { 34, 3, -17 }, { 10, 6, 9 }, wood)
	local glass = kit:part("Roger glass case", { 34, 9, -17 }, { 9, 6, 8 }, { 146, 222, 224 }, nil, "Glass")
	glass.transparency, glass.collide = 0.7, false
	kit:ball("Roger classroom egg", { 34, 8.5, -17 }, { 3, 4, 3 }, white)
	kit:part("Roger case roof", { 34, 12.2, -17 }, { 10, 0.4, 9 }, blue)
	kit:secret("school-roger-case", "Roger's classroom keepsake", { 34, 5, -11 }, white)
	kit:bookshelf({ -34, 0, 16 }, 10, wood)
	kit:part("Supply closet blue door", { -39.3, 7, 5 }, { 0.4, 14, 7 }, blue)
	kit:ball("Supply closet handle", { -38.8, 7, 7 }, { 0.6, 0.6, 0.6 }, wood)
	for band = 0, 5 do
		kit:cylinder(
			"Lighthouse painted tower",
			{ 49, 4.5 + band * 9, 0 },
			{ 9, 17, 17 },
			if band % 2 == 0 then white else red
		)
	end
	kit:cylinder("Lighthouse balcony", { 49, 54.5, 0 }, { 1, 23, 23 }, blue)
	for i = 0, 11 do
		local a = i * math.pi / 6
		kit:cylinder(
			"Lighthouse balcony railing",
			{ 49 + math.cos(a) * 10.5, 56, math.sin(a) * 10.5 },
			{ 3, 0.4, 0.4 },
			white
		)
	end
	kit:ball("Lighthouse lantern", { 49, 59, 0 }, { 13, 8, 13 }, { 249, 218, 120 }).material = "Neon"
	kit:cylinder("Lighthouse lantern cap", { 49, 63.2, 0 }, { 1.5, 18, 18 }, red)
	kit:ball("Lighthouse domed roof", { 49, 64.5, 0 }, { 18, 4, 18 }, red)
	kit:light({ 49, 59, 0 }, yellow, 55)
	kit:part("School front path", { 0, 0.04, 41 }, { 14, 0.08, 32 }, { 166, 170, 137 }).collide = false
	kit:supply({ -48, 2, -32 })
	kit:cylinder("School anchor monument stem", { -48, 5, 23 }, { 10, 1, 1 }, blue)
	kit:part("School anchor crosspiece", { -48, 7, 23 }, { 8, 0.9, 1 }, blue)
	for _, side in { -1, 1 } do
		kit:part(
			"School anchor fluke",
			{ -48 + side * 3, 2, 23 },
			{ 6, 1.2, 1.2 },
			blue,
			nil,
			nil,
			{ 0, 0, side * 25 }
		)
	end
	kit:secret("school-anchor-marker", "Boating school anchor", { -48, 3, 28 }, blue)
	return kit
end

local function course(): Kit
	local kit = WorldKit.new("street", { 460, 0, -145 })
	local asphalt = { 98, 122, 125 }
	kit:part("Boating practice course", { 0, 0.04, 0 }, { 192, 0.08, 124 }, asphalt, nil, "Concrete").collide =
		false
	for i = 0, 63 do
		local a, b = i * math.pi / 32, (i + 1) * math.pi / 32
		for _, lane in { -7, 7 } do
			local ax, az = math.cos(a) * (78 + lane), math.sin(a) * (45 + lane)
			local bx, bz = math.cos(b) * (78 + lane), math.sin(b) * (45 + lane)
			kit:part(
				"Painted course lane",
				{ (ax + bx) / 2, 0.1, (az + bz) / 2 },
				{ math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2) + 0.1, 0.05, 0.5 },
				white,
				nil,
				nil,
				{ 0, -math.deg(math.atan2(bz - az, bx - ax)), 0 }
			).collide =
				false
		end
	end
	for i = 0, 17 do
		local a = i * math.pi / 9
		local x, z = math.cos(a) * 64, math.sin(a) * 30
		kit:part("Traffic cone foot", { x, 0.2, z }, { 3, 0.4, 3 }, blue)
		for tier = 0, 3 do
			kit:cylinder(
				"Traffic cone band",
				{ x, 0.7 + tier * 0.65, z },
				{ 0.65, 2.2 - tier * 0.5, 2.2 - tier * 0.5 },
				if tier == 2 then white else red
			)
		end
	end
	for _, x in { -20, 20 } do
		kit:part("Practice ramp", { x, 1.5, -45 }, { 11, 3, 18 }, wood, "Wedge")
	end
	for x = -9, 9, 3 do
		for z = 37, 52, 3 do
			kit:part(
				"Checkered finish stripe",
				{ x, 0.12, z },
				{ 3, 0.04, 3 },
				if (x + z) % 6 == 1 then white else blue
			).collide =
				false
		end
	end
	for _, x in { -13, 13 } do
		kit:cylinder("Finish flagpole", { x, 7, 55 }, { 14, 0.5, 0.5 }, white)
		kit:part("Finish pennant", { x + 2.5, 12, 55 }, { 5, 3, 0.2 }, red)
	end
	kit:secret("school-finish-keepsake", "Practice course ribbon", { 18, 3, 55 }, yellow)
	for tier = 0, 2 do
		kit:part(
			"Course bleacher step",
			{ 100 + tier * 3, 0.5 + tier * 0.75, 6 },
			{ 3, 1 + tier * 1.5, 46 },
			wood
		)
		kit:part("Course bleacher seat", { 100 + tier * 3, 3 + tier * 1.5, 6 }, { 2.4, 0.5, 46 }, blue)
	end
	for _, x in { -4, 18, 40 } do
		boat(kit, x, 95, if x == 18 then yellow else white)
		kit:part("Boat parking stripe", { x - 9, 0.1, 95 }, { 0.5, 0.1, 23 }, white).collide = false
	end
	boat(kit, -56, 8, red)
	return kit
end

return function(): { WorldKit.Part }
	local result = {}
	local school, practice = classroom(), course()
	for _, kit in { school, practice } do
		for _, part in kit.parts do
			part.group = if kit == school then "Mrs Puff's Boating School" else "Boating practice course"
			table.insert(result, part)
		end
	end
	return result
end
