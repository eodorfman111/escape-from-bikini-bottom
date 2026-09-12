--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../../src/shared/Config")

type Triple = WorldKit.Triple
type Kit = WorldKit.Kit

local C = {
	wood = { 153, 93, 49 },
	honey = { 193, 132, 67 },
	dark = { 83, 54, 38 },
	rope = { 220, 203, 158 },
	brass = { 230, 179, 62 },
	steel = { 113, 159, 174 },
	paleSteel = { 166, 201, 208 },
	navy = { 38, 70, 100 },
	red = { 203, 66, 58 },
	cream = { 255, 235, 192 },
	green = { 138, 183, 124 },
	teal = { 56, 130, 130 },
	glass = { 118, 209, 222 },
	pink = { 207, 146, 197 },
}

local function rod(kit: Kit, name: string, a: Triple, b: Triple, diameter: number, color: Triple)
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local horizontal = math.sqrt(dx * dx + dz * dz)
	local length = math.sqrt(horizontal * horizontal + dy * dy)
	local part = kit:cylinder(
		name,
		{ (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		{ length, diameter, diameter },
		color,
		{ 0, math.deg(math.atan2(-dz, dx)), math.deg(math.atan2(dy, horizontal)) }
	)
	part.collide = false
	return part
end

local function ring(
	kit: Kit,
	name: string,
	p: Triple,
	radius: number,
	thickness: number,
	color: Triple,
	axis: string
)
	local function point(angle: number): Triple
		local u, v = math.cos(angle) * radius, math.sin(angle) * radius
		if axis == "X" then
			return { p[1], p[2] + u, p[3] + v }
		elseif axis == "Y" then
			return { p[1] + u, p[2], p[3] + v }
		end
		return { p[1] + u, p[2] + v, p[3] }
	end
	for i = 0, 11 do
		rod(kit, name, point(i * math.pi / 6), point((i + 1) * math.pi / 6), thickness, color)
	end
end

local function rivets(kit: Kit, p: Triple, width: number, color: Triple)
	for x = -width / 2 + 1, width / 2 - 1, 3 do
		kit:ball("Round rivet", { p[1] + x, p[2], p[3] }, { 0.4, 0.4, 0.3 }, color).collide = false
	end
end

local function barrel(kit: Kit, x: number, z: number, cushion: Triple?)
	kit:cylinder("Barrel core", { x, 2.2, z }, { 4.4, 4.4, 4.4 }, C.wood)
	for i = 0, 7 do
		local a = i * math.pi / 4
		kit:ball(
			"Rounded barrel stave",
			{ x + math.cos(a) * 1.8, 2.2, z + math.sin(a) * 1.8 },
			{ 1.4, 4.3, 1.4 },
			C.honey
		)
	end
	for _, y in { 0.9, 3.5 } do
		kit:cylinder("Barrel iron hoop", { x, y, z }, { 0.35, 4.65, 4.65 }, C.navy)
	end
	kit:cylinder("Barrel seat", { x, 4.5, z }, { 0.4, 4.6, 4.6 }, cushion or C.honey)
end

local function burger(kit: Kit, x: number, y: number, z: number, scale: number)
	kit:cylinder("Patty bottom bun", { x, y, z }, { 0.4 * scale, 2.5 * scale, 2.5 * scale }, C.honey)
	kit:cylinder(
		"Grilled patty",
		{ x, y + 0.35 * scale, z },
		{ 0.4 * scale, 2.7 * scale, 2.7 * scale },
		C.dark
	)
	kit:part(
		"Cheese corners",
		{ x, y + 0.6 * scale, z },
		{ 2.6 * scale, 0.15 * scale, 2.6 * scale },
		C.brass,
		nil,
		nil,
		{ 0, 25, 0 }
	)
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		kit:ball(
			"Ruffled lettuce",
			{ x + math.cos(a) * scale, y + 0.75 * scale, z + math.sin(a) * scale },
			{ scale, 0.35 * scale, scale },
			C.green
		)
	end
	kit:ball(
		"Sesame crown bun",
		{ x, y + 1.15 * scale, z },
		{ 2.8 * scale, 1.1 * scale, 2.8 * scale },
		C.honey
	)
	for _, offset in { { -0.6, 0.1 }, { 0.3, 0.55 }, { 0.65, -0.25 }, { -0.15, -0.6 } } do
		kit:ball(
			"Sesame seed",
			{ x + offset[1] * scale, y + 1.65 * scale, z + offset[2] * scale },
			{ 0.18 * scale, 0.08 * scale, 0.35 * scale },
			C.cream
		)
	end
end

local function bottle(kit: Kit, name: string, p: Triple, color: Triple): WorldKit.Part
	local body = kit:ball(name, p, { 1.6, 2.3, 1.6 }, color)
	kit:cylinder(name .. " neck", { p[1], p[2] + 1.35, p[3] }, { 0.9, 0.65, 0.65 }, color)
	kit:cylinder(name .. " cork", { p[1], p[2] + 1.9, p[3] }, { 0.35, 0.75, 0.75 }, C.honey)
	return body
end

local function anchor(kit: Kit, x: number, y: number, z: number, scale: number, color: Triple)
	ring(kit, "Anchor eye", { x, y + 2.8 * scale, z }, 0.7 * scale, 0.3 * scale, color, "Z")
	rod(kit, "Anchor shank", { x, y - 2 * scale, z }, { x, y + 2.2 * scale, z }, 0.55 * scale, color)
	rod(
		kit,
		"Anchor stock",
		{ x - 1.7 * scale, y + scale, z },
		{ x + 1.7 * scale, y + scale, z },
		0.5 * scale,
		color
	)
	for _, sign in { -1, 1 } do
		rod(
			kit,
			"Anchor curved arm",
			{ x, y - 2 * scale, z },
			{ x + sign * 1.8 * scale, y - scale, z },
			0.6 * scale,
			color
		)
		rod(
			kit,
			"Anchor fluke",
			{ x + sign * 1.8 * scale, y - scale, z },
			{ x + sign * 2.3 * scale, y + 0.3 * scale, z },
			0.7 * scale,
			color
		)
	end
end

local function exterior(): Kit
	local kit = WorldKit.new("street", { 0, 0, 0 })
	kit:part("Flush sand apron", { 0, -0.35, 4 }, { 64, 0.7, 54 }, { 216, 197, 145 }, nil, "Sand")
	kit:part("Restaurant deck", { 0, -0.2, -11 }, { 57, 0.4, 44 }, C.honey, nil, "WoodPlanks")
	kit:part("Rear wooden wall", { 0, 8.5, -32 }, { 56, 17, 1.2 }, C.wood, nil, "WoodPlanks")
	for _, side in { -1, 1 } do
		local x = side * 28
		kit:part("Side lower hull", { x, 2, -11 }, { 1.2, 4, 42 }, C.wood, nil, "WoodPlanks")
		kit:part("Side upper hull", { x, 16, -11 }, { 1.2, 2, 42 }, C.honey, nil, "WoodPlanks")
		local glass = kit:part("Blue side window", { x, 9.5, -11 }, { 0.35, 11, 39 }, C.glass, nil, "Glass")
		glass.transparency = 0.4
		for z = -31, 9, 10 do
			rod(kit, "Rounded hull post", { x, 0, z }, { x, 17, z }, 1.1, C.dark).collide = true
		end
		for z = -28, 4, 8 do
			rod(
				kit,
				"Window diamond rope",
				{ x + side * 0.7, 4.5, z },
				{ x + side * 0.7, 14.5, z + 8 },
				0.22,
				C.rope
			)
			rod(
				kit,
				"Window diamond rope",
				{ x + side * 0.7, 14.5, z },
				{ x + side * 0.7, 4.5, z + 8 },
				0.22,
				C.rope
			)
		end
		kit:part("Front sill panel", { side * 18, 2, 10 }, { 20, 4, 1.2 }, C.wood, nil, "WoodPlanks")
		kit:part("Front upper panel", { side * 18, 16, 10 }, { 20, 2, 1.2 }, C.honey, nil, "WoodPlanks")
		local pane = kit:part(
			"Front display window",
			{ side * 18, 9.5, 10 },
			{ 16, 11, 0.35 },
			C.glass,
			nil,
			"Glass"
		)
		pane.transparency = 0.45
		for _, edge in { 8.5, 27.5 } do
			rod(kit, "Entrance jamb", { side * edge, 0, 10 }, { side * edge, 17, 10 }, 1, C.dark).collide =
				true
		end
		rod(kit, "Window mullion", { side * 18, 4, 10.5 }, { side * 18, 15, 10.5 }, 0.45, C.rope)
		for _, y in { 4, 15 } do
			rod(kit, "Window sill trim", { side * 9, y, 10.7 }, { side * 27, y, 10.7 }, 0.65, C.honey)
		end
		kit:part("Open door leaf", { side * 8.3, 7.5, 6.5 }, { 0.45, 15, 6.2 }, C.wood, nil, "WoodPlanks")
		kit:part("Open door inset", { side * 8.02, 9, 6.5 }, { 0.1, 8, 4.5 }, C.glass, nil, "Glass").transparency =
			0.3
		kit:ball("Door brass knob", { side * 7.75, 6.2, 4 }, { 0.65, 0.65, 0.65 }, C.brass)
	end
	kit:part("High entrance header", { 0, 18, 10 }, { 57, 2, 1.6 }, C.dark, nil, "Wood")
	for i = 0, 15 do
		local a, b = i * math.pi / 16, (i + 1) * math.pi / 16
		local x1, y1 = 28 * math.cos(a), 17 + 13 * math.sin(a)
		local x2, y2 = 28 * math.cos(b), 17 + 13 * math.sin(b)
		local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
		kit:part(
			"Curved roof stave",
			{ (x1 + x2) / 2, (y1 + y2) / 2, -11 },
			{ length + 0.15, 0.8, 44 },
			if i % 2 == 0 then C.wood else C.honey,
			nil,
			"WoodPlanks",
			{ 0, 0, math.deg(math.atan2(y2 - y1, x2 - x1)) }
		)
		for _, z in { -33, -19, -4, 11 } do
			rod(kit, "Barrel roof rib", { x1, y1 + 0.45, z }, { x2, y2 + 0.45, z }, 0.7, C.dark)
		end
	end
	for x = -26, 26, 4 do
		local height = 13 * math.sqrt(1 - (x / 28) ^ 2)
		for _, z in { -32, 10 } do
			kit:part(
				"Arched gable plank",
				{ x, 17 + height / 2, z },
				{ 4, height, 0.75 },
				C.wood,
				nil,
				"WoodPlanks"
			)
		end
	end
	rod(kit, "Flag halyard", { -23, 24, 12 }, { 23, 24, 12 }, 0.18, C.rope)
	local flagColors = { C.red, C.cream, C.navy, C.brass, C.cream }
	for i = 1, 5 do
		local x = -24 + i * 8
		kit:part("Maritime signal flag", { x, 22, 12 }, { 5.2, 3.5, 0.15 }, flagColors[i])
		if i == 1 then
			kit:part("Flag white cross", { x, 22, 12.12 }, { 0.9, 3.5, 0.08 }, C.cream)
			kit:part("Flag crossbar", { x, 22, 12.13 }, { 5.2, 0.9, 0.08 }, C.cream)
		elseif i == 2 then
			kit:ball("Flag red disc", { x, 22, 12.2 }, { 2.4, 2.4, 0.15 }, C.red)
		elseif i == 3 then
			kit:part("Flag white square", { x, 22, 12.15 }, { 2.4, 2.4, 0.1 }, C.cream)
		elseif i == 4 then
			kit:part(
				"Flag diagonal blue band",
				{ x, 22, 12.15 },
				{ 4.6, 1.1, 0.1 },
				C.navy,
				nil,
				nil,
				{ 0, 0, 29 }
			)
		else
			for _, offset in { -1.2, 1.2 } do
				kit:part("Flag blue stripe", { x + offset, 22, 12.15 }, { 1.1, 3.5, 0.1 }, C.navy)
			end
		end
	end
	kit:cylinder("Galley chimney", { 15, 30, -23 }, { 10, 3.5, 3.5 }, C.steel)
	kit:ball("Chimney elbow", { 15, 35, -23 }, { 4, 4, 4 }, C.steel)
	kit:cylinder("Chimney mouth", { 17.5, 35, -23 }, { 5, 4, 4 }, C.dark, { 0, 0, 0 })
	rod(kit, "Roof aerial", { -12, 28, -22 }, { -12, 36, -22 }, 0.3, C.navy)
	for i = 0, 3 do
		rod(kit, "Aerial crosspiece", { -15, 32 + i, -22 }, { -9, 32 + i, -22 }, 0.25, C.navy)
		kit:ball("Aerial tip", { -9, 32 + i, -22 }, { 0.65, 0.65, 0.65 }, C.navy)
	end
	kit:cylinder("Clam sign bamboo mast", { -37, 13, 17 }, { 26, 1.4, 1.4 }, C.honey)
	for y = 3, 23, 4 do
		kit:cylinder("Bamboo node", { -37, y, 17 }, { 0.4, 1.75, 1.75 }, C.dark)
	end
	kit:ball("Clam sign silhouette", { -37, 27, 17 }, { 18, 11, 2.3 }, C.pink)
	for i = -3, 3 do
		local a = math.rad(i * 17)
		local part = kit:ball(
			"Scalloped clam lobe",
			{ -37 + math.sin(a) * 5.2, 27 + math.cos(a) * 2, 17.25 },
			{ 4.6, 8, 1.9 },
			{ 230, 172 + math.abs(i) * 4, 213 }
		)
		part.rotation = { 0, 0, -i * 17 }
		rod(
			kit,
			"Clam radial ridge",
			{ -37 + i * 0.4, 23, 18.4 },
			{ -37 + math.sin(a) * 7, 27 + math.cos(a) * 5, 18.4 },
			0.22,
			C.cream
		)
	end
	kit:ball("Clam hinge", { -37, 22.5, 17.5 }, { 5, 2.5, 2.5 }, C.pink)
	kit:label("THE KRUSTY KRAB", { -37, 27, 19 })
	barrel(kit, 35, 3, nil)
	barrel(kit, 35, -5, nil)
	rod(kit, "Seahorse hitching post", { 35, 0, 17 }, { 35, 7, 17 }, 1.2, C.honey).collide = true
	ring(kit, "Hitching ring", { 35, 5.5, 17.9 }, 1.1, 0.25, C.brass, "Z")
	for _, side in { -1, 1 } do
		kit:part("Entrance lantern mount", { side * 11, 12, 11.5 }, { 2.5, 0.5, 2.5 }, C.navy)
		kit:light({ side * 11, 13.5, 11.7 }, C.cream, 17)
		kit:ball("Lantern cap", { side * 11, 14.7, 11.7 }, { 3, 1, 3 }, C.navy)
	end
	return kit
end

local function wheelTable(kit: Kit, x: number, z: number, color: Triple, meal: boolean)
	kit:cylinder("Table pedestal foot", { x, 0.5, z }, { 1, 5, 5 }, C.navy)
	kit:cylinder("Table pedestal", { x, 2.8, z }, { 5, 1.7, 1.7 }, C.honey)
	kit:cylinder("Ship wheel tabletop", { x, 5.2, z }, { 0.75, 11.8, 11.8 }, color)
	ring(kit, "Rounded wheel rim", { x, 5.5, z }, 5.9, 0.45, C.honey, "Y")
	for i = 0, 7 do
		local a = i * math.pi / 4
		rod(
			kit,
			"Wheel spoke",
			{ x, 5.65, z },
			{ x + math.cos(a) * 7, 5.65, z + math.sin(a) * 7 },
			0.32,
			C.honey
		)
		kit:ball(
			"Rounded wheel handle",
			{ x + math.cos(a) * 7, 5.65, z + math.sin(a) * 7 },
			{ 0.8, 0.8, 0.8 },
			C.honey
		)
	end
	kit:cylinder("Wheel central hub", { x, 5.65, z }, { 0.3, 1.1, 1.1 }, C.brass)
	barrel(kit, x - 10, z, color)
	barrel(kit, x + 10, z, color)
	kit:part("Napkin holder", { x + 2.5, 6.2, z - 2 }, { 1.8, 1.3, 1.1 }, C.steel)
	kit:part("Folded napkins", { x + 2.5, 6.8, z - 2 }, { 1.4, 0.7, 0.8 }, C.cream)
	if meal then
		kit:cylinder("Dinner plate", { x - 1.5, 5.8, z + 1 }, { 0.2, 4.6, 4.6 }, C.cream)
		burger(kit, x - 1.5, 6.1, z + 1, 0.9)
	else
		kit:cylinder("Striped soda cup", { x - 1, 6.6, z }, { 1.8, 1.5, 1.5 }, C.cream)
		kit:cylinder("Soda red band", { x - 1, 6.6, z }, { 0.55, 1.55, 1.55 }, C.red)
		rod(kit, "Bent soda straw", { x - 1, 7.5, z }, { x - 0.7, 9, z }, 0.15, C.red)
	end
end

local function porthole(kit: Kit, side: number, z: number)
	local x = side * 57.25
	kit:cylinder("Porthole blue inset", { x, 15, z }, { 0.25, 11, 11 }, C.glass, { 0, 0, 0 })
	ring(kit, "Brass porthole rim", { x - side * 0.25, 15, z }, 5.8, 0.6, C.brass, "X")
	for i = 0, 5 do
		local a = i * math.pi / 3
		kit:ball(
			"Porthole bolt",
			{ x - side * 0.6, 15 + math.cos(a) * 5.8, z + math.sin(a) * 5.8 },
			{ 0.5, 0.5, 0.5 },
			C.navy
		)
	end
	rod(kit, "Porthole glass shine", { x - side * 0.4, 15, z - 3 }, { x - side * 0.4, 18, z }, 0.3, C.cream)
end

local function diningRoom(kit: Kit)
	kit:room(116, 100, 30, C.wood, C.green, false)
	for x = -54, 54, 6 do
		kit:part("Flush floorboard seam", { x, 0.012, 0 }, { 0.07, 0.02, 98 }, { 101, 145, 94 }).collide =
			false
		for _, z in { -46, 45 } do
			kit:cylinder("Recessed deck nail", { x + 0.5, 0.018, z }, { 0.025, 0.24, 0.24 }, C.dark).collide =
				false
		end
	end
	for _, side in { -1, 1 } do
		for _, z in { -42, -18, 6, 30, 46 } do
			kit:cylinder("Dining hull rib", { side * 56.7, 15, z }, { 30, 1.4, 1.4 }, C.honey)
			for _, y in { 2, 22 } do
				kit:cylinder("Pillar iron collar", { side * 56.7, y, z }, { 0.55, 1.7, 1.7 }, C.navy)
			end
		end
		for _, y in { 1.1, 24.5 } do
			kit:part("Side hull trim", { side * 56.9, y, 0 }, { 1.3, 0.6, 98 }, C.honey, nil, "Wood")
		end
		for _, z in { 16, 39 } do
			porthole(kit, side, z)
		end
		kit:part("Entrance skirting", { side * 32, 1, 49.2 }, { 49, 1.3, 0.6 }, C.dark, nil, "Wood")
		kit:cylinder("Interior door jamb", { side * 7.2, 9, 49.3 }, { 18, 0.9, 0.9 }, C.honey)
	end
	kit:part("Interior door crown", { 0, 18, 49.3 }, { 16, 1.2, 1 }, C.honey, nil, "Wood")
	for _, z in { 1, 26, 45 } do
		kit:part("Ceiling crossbeam", { 0, 28.5, z }, { 114, 1.5, 2 }, C.dark, nil, "Wood")
		for _, x in { -28, 28 } do
			rod(kit, "Hanging lamp chain", { x, 28, z }, { x, 23, z }, 0.18, C.navy)
			kit:ball("Nautical lamp shade", { x, 23, z }, { 5, 1.6, 5 }, C.brass)
			kit:light({ x, 21.9, z }, C.cream, 29)
		end
	end
	wheelTable(kit, -32, 32, C.red, true)
	wheelTable(kit, 32, 32, C.brass, false)
	wheelTable(kit, -32, 8, C.brass, false)
	wheelTable(kit, 32, 8, C.red, true)
	kit:cylinder("Crow's nest mast", { -53, 15, 3 }, { 30, 2.4, 2.4 }, C.navy)
	kit:cylinder("Crow's nest basket", { -51, 25, 3 }, { 2, 9, 9 }, C.honey)
	ring(kit, "Crow's nest rail", { -51, 28, 3 }, 4.5, 0.4, C.rope, "Y")
	for i = 0, 7 do
		local a = i * math.pi / 4
		rod(
			kit,
			"Crow's nest upright",
			{ -51 + math.cos(a) * 4.5, 25, 3 + math.sin(a) * 4.5 },
			{ -51 + math.cos(a) * 4.5, 28, 3 + math.sin(a) * 4.5 },
			0.35,
			C.honey
		)
	end
	kit:part("Condiment island cabinet", { 52, 3, -3 }, { 8, 6, 10 }, C.teal, nil, "Wood")
	kit:ball("Rounded condiment counter", { 52, 6.2, -3 }, { 9, 1.1, 11 }, C.cream)
	bottle(kit, "Ketchup", { 51, 7.7, -1 }, C.red)
	bottle(kit, "Mustard", { 53, 7.7, -4 }, C.brass)
	kit:part("Condiment napkin stack", { 50, 7, -5 }, { 2, 0.6, 2.8 }, C.cream)
	local penny = kit:cylinder(
		"Doubloon under the barrel seat",
		{ -42, 0.18, 12.2 },
		{ 0.3, 1.8, 1.8 },
		C.brass
	)
	penny.secret = "krusty_dropped_doubloon"
	penny.collide = false
	kit:part("Doubloon embossed stroke", { -42, 0.36, 12.2 }, { 0.15, 0.08, 1.2 }, C.cream).collide = false
end

local function bulkheads(kit: Kit)
	for _, wall in
		{
			{ -52, 12 },
			{ -23, 14 },
			{ 23, 6 },
			{ 51, 14 },
		}
	do
		kit:part(
			"Riveted back-room bulkhead",
			{ wall[1], 12, -12 },
			{ wall[2], 24, 1 },
			C.steel,
			nil,
			"Metal"
		)
		rivets(kit, { wall[1], 2, -11.35 }, wall[2], C.paleSteel)
		rivets(kit, { wall[1], 22, -11.35 }, wall[2], C.paleSteel)
	end
	kit:part("Office passage lintel", { -38, 20.5, -12 }, { 16, 7, 1 }, C.steel, nil, "Metal")
	kit:part("Kitchen passage lintel", { 35, 20.5, -12 }, { 18, 7, 1 }, C.steel, nil, "Metal")
	kit:part("Serving hatch lower wall", { 2, 3, -12 }, { 36, 6, 1 }, C.steel, nil, "Metal")
	kit:part("Serving hatch upper wall", { 2, 20, -12 }, { 36, 8, 1 }, C.steel, nil, "Metal")
	kit:part("Serving hatch left post", { -13, 11, -12 }, { 6, 10, 1 }, C.steel, nil, "Metal")
	kit:part("Serving hatch counter", { 5, 6.2, -11.5 }, { 30, 0.7, 4 }, C.cream)
	for _, x in { -46, -30, 26, 44 } do
		kit:part("Passage edge trim", { x, 8.5, -11.3 }, { 0.5, 17, 0.5 }, C.brass)
	end
	kit:part("Office dividing wall", { -16, 15, -31 }, { 1, 30, 38 }, C.wood, nil, "WoodPlanks")
	kit:part("Bulkhead top rail", { 0, 24.5, -12 }, { 116, 1, 1.6 }, C.navy)
	anchor(kit, -38, 21.1, -11.1, 0.65, C.red)
	kit:part("Galley doorway plate", { 35, 21, -11.3 }, { 9, 3.5, 0.3 }, C.navy)
	rod(kit, "Galley spatula emblem handle", { 33.5, 19.8, -11 }, { 35, 21.5, -11 }, 0.35, C.cream)
	kit:part(
		"Galley spatula emblem head",
		{ 35.6, 22, -11 },
		{ 2.4, 1.5, 0.35 },
		C.cream,
		nil,
		nil,
		{ 0, 0, -40 }
	)
end

local function cashier(kit: Kit)
	kit:part("Boat keel", { 3, 1.3, -4 }, { 20, 2.6, 7 }, C.red)
	kit:ball("Rounded cashier hull", { 3, 3.1, -4 }, { 24, 5.5, 9 }, C.cream)
	kit:ball("Boat red waterline", { 3, 1.9, -4 }, { 23.5, 2.4, 8.8 }, C.red)
	kit:part("Boat counter deck", { 3, 5.6, -4 }, { 21, 0.7, 7.5 }, C.honey, nil, "Wood")
	for _, side in { -1, 1 } do
		rod(kit, "Boat gunwale", { -7, 5.4, -4 + side * 4 }, { 13, 5.4, -4 + side * 4 }, 0.6, C.cream)
	end
	for _, x in { -4, 3, 10 } do
		kit:cylinder("Boat brass porthole", { x, 3.7, 0.4 }, { 0.35, 1.9, 1.9 }, C.brass, { 0, 90, 0 })
		kit:cylinder("Boat blue porthole glass", { x, 3.7, 0.65 }, { 0.2, 1.3, 1.3 }, C.navy, { 0, 90, 0 })
	end
	kit:part("Register drawer", { 4, 6.3, -4 }, { 5.5, 1, 3.5 }, C.navy)
	kit:ball("Rounded cash register", { 4, 7.5, -4.3 }, { 5.2, 2.5, 3.1 }, C.steel)
	kit:part("Register display", { 4, 8.5, -3.3 }, { 3.4, 1, 0.25 }, C.navy)
	for i = 0, 2 do
		kit:part("Register amber digit", { 3 + i, 8.5, -3.12 }, { 0.45, 0.65, 0.08 }, C.brass)
		for j = 0, 2 do
			kit:ball(
				"Register round key",
				{ 2.8 + i * 1.1, 7 + j * 0.18, -2.6 - j * 0.4 },
				{ 0.55, 0.35, 0.55 },
				C.cream
			)
		end
	end
	kit:part("Receipt roll", { 6, 7.9, -4.5 }, { 0.8, 0.15, 2.4 }, C.cream)
	kit:cylinder("Order bell foot", { -5, 6.2, -3 }, { 0.3, 2.8, 2.8 }, C.navy)
	kit:ball("Brass order bell", { -5, 6.8, -3 }, { 2.5, 1.4, 2.5 }, C.brass)
	kit:ball("Bell button", { -5, 7.7, -3 }, { 0.5, 0.5, 0.5 }, C.navy)
	kit:part("Galley Grub frame", { 4, 23, -10.9 }, { 25, 6.6, 0.7 }, C.honey, nil, "Wood")
	kit:part("Galley Grub enamel panel", { 4, 23, -10.45 }, { 23.8, 5.4, 0.25 }, C.teal)
	kit:label("GALLEY GRUB", { 4, 27, -10 })
	kit:ball("Menu bun relief", { -3, 24.1, -10.1 }, { 5, 1.8, 0.4 }, C.honey)
	for _, row in
		{
			{ y = 23.2, color = C.green },
			{ y = 22.7, color = C.dark },
			{ y = 22.1, color = C.honey },
		}
	do
		kit:part("Menu patty layer", { -3, row.y, -10.1 }, { 5, 0.5, 0.4 }, row.color)
	end
	kit:part("Menu fries carton", { 4, 22.4, -10.1 }, { 3, 2, 0.4 }, C.red)
	for i = 0, 3 do
		kit:part("Menu golden fry", { 2.9 + i * 0.7, 24, -10.05 }, { 0.4, 2 + i % 2 * 0.6, 0.4 }, C.brass)
	end
	kit:part("Menu soda relief", { 10, 23, -10.1 }, { 2.5, 3, 0.4 }, C.cream)
	kit:part("Menu soda stripe", { 10, 23, -9.83 }, { 2.5, 0.6, 0.12 }, C.red)
	rod(kit, "Menu soda straw", { 10.3, 24.3, -10 }, { 10.8, 25.3, -10 }, 0.2, C.red)
end

local function grill(kit: Kit)
	kit:part("Galley flush tile inset", { 20, 0.04, -31 }, { 73, 0.08, 36 }, C.paleSteel).collide = false
	for x = -12, 52, 8 do
		for z = -46, -22, 8 do
			kit:part("Blue galley tile", { x, 0.085, z }, { 3.8, 0.01, 3.8 }, C.steel).collide = false
		end
	end
	kit:part("Grill enamel range", { 4, 3.4, -43 }, { 28, 6.8, 10 }, C.cream)
	kit:part("Grill iron cooktop", { 4, 7, -43 }, { 28, 0.6, 10 }, C.navy, nil, "Metal")
	kit:part("Grill backsplash", { 4, 9, -48.4 }, { 29, 5, 0.7 }, C.steel, nil, "Metal")
	for x = -8, 16, 2 do
		rod(kit, "Grill raised grate", { x, 7.5, -46 }, { x, 7.5, -39 }, 0.23, C.steel)
	end
	for _, x in { -5, 3, 11 } do
		kit:cylinder("Patty on the griddle", { x, 7.9, -43 }, { 0.55, 3, 3 }, C.dark)
		for offset = -0.7, 0.7, 0.7 do
			kit:part("Patty grill mark", { x + offset, 8.2, -43 }, { 0.13, 0.05, 1.8 }, { 47, 35, 28 })
		end
		kit:cylinder("Range control dial", { x, 5.4, -37.85 }, { 0.4, 1.1, 1.1 }, C.navy, { 0, 90, 0 })
		kit:part("Dial indicator", { x, 5.7, -37.6 }, { 0.12, 0.35, 0.1 }, C.cream)
	end
	kit:part("Oven window rim", { 4, 2.6, -37.8 }, { 10, 3, 0.4 }, C.steel)
	kit:part("Oven blue window", { 4, 2.6, -37.5 }, { 8.5, 2, 0.2 }, C.navy)
	rod(kit, "Oven handle", { 0, 4.1, -37.2 }, { 8, 4.1, -37.2 }, 0.35, C.brass)
	kit:part("Extraction hood", { 4, 18, -43 }, { 31, 3, 12 }, C.steel, nil, "Metal")
	kit:part("Hood rounded lip", { 4, 16.5, -36.9 }, { 32, 0.7, 0.8 }, C.paleSteel, nil, "Metal")
	kit:cylinder("Hood duct", { 4, 25, -44 }, { 12, 5, 5 }, C.steel)
	for x = -8, 16, 3 do
		kit:part("Hood vent slot", { x, 18, -36.9 }, { 1.3, 1.2, 0.1 }, C.navy)
	end
	kit:light({ 4, 15.6, -41 }, { 255, 199, 110 }, 26)
	kit:part("Cold storage cabinet", { 50, 7, -42 }, { 12, 14, 12 }, C.paleSteel, nil, "Metal")
	for _, x in { 47, 53 } do
		kit:part("Fridge inset door", { x, 7.2, -35.8 }, { 5.4, 12.6, 0.35 }, C.steel, nil, "Metal")
		rod(
			kit,
			"Fridge curved handle",
			{ x + if x < 50 then 1.5 else -1.5, 5.8, -35.3 },
			{ x + if x < 50 then 1.5 else -1.5, 9, -35.3 },
			0.35,
			C.cream
		)
	end
	kit:part("Sink cupboard", { 51, 3, -24 }, { 10, 6, 10 }, C.teal)
	kit:part("Dark sink basin", { 51, 6.2, -24 }, { 8, 0.5, 7 }, C.navy, nil, "Metal")
	for _, x in { 46.5, 55.5 } do
		kit:part("Sink side rim", { x, 6.5, -24 }, { 1, 0.6, 9 }, C.paleSteel, nil, "Metal")
	end
	for _, z in { -28, -20 } do
		kit:part("Sink end rim", { 51, 6.5, z }, { 10, 0.6, 1 }, C.paleSteel, nil, "Metal")
	end
	rod(kit, "Faucet riser", { 55, 6.5, -25 }, { 55, 10, -25 }, 0.45, C.steel)
	rod(kit, "Faucet spout", { 55, 10, -25 }, { 52, 10, -25 }, 0.45, C.steel)
	kit:ball("Faucet elbow", { 55, 10, -25 }, { 0.8, 0.8, 0.8 }, C.steel)
	kit:part("Sponge at sink", { 48, 7.1, -20 }, { 1.8, 0.7, 1.2 }, C.brass)
	kit:part("Prep shelf", { -11, 6.5, -27 }, { 8, 0.75, 14 }, C.cream)
	for _, z in { -32, -22 } do
		kit:cylinder("Prep counter leg", { -10, 3, z }, { 6, 0.7, 0.7 }, C.steel)
	end
	kit:part("Cutting board", { -10, 7.1, -27 }, { 5.5, 0.35, 5 }, C.honey)
	for i = 0, 3 do
		kit:cylinder("Pickle slices", { -11 + i * 0.75, 7.4, -27 }, { 0.2, 1.2, 1.2 }, C.green)
	end
	bottle(kit, "Pickle jar", { -11, 8.1, -31 }, C.green)
	rod(kit, "Spatula grip", { -8, 8, -39 }, { -8, 8.2, -42 }, 0.45, C.dark)
	local spatula = kit:part(
		"Golden spatula blade",
		{ -8, 8.25, -43 },
		{ 2.4, 0.2, 2 },
		C.brass,
		nil,
		"Metal"
	)
	spatula.secret = "krusty_golden_spatula"
	spatula.collide = false
	for _, x in { -8.7, -8, -7.3 } do
		kit:part("Spatula blade groove", { x, 8.37, -43 }, { 0.18, 0.03, 1.3 }, C.dark).collide = false
	end
	kit:supply({ 20, 2, -26 })
	kit:ball("Supply chest domed lid", { 20, 4.1, -26 }, { 5.2, 1.4, 4.2 }, C.teal)
	for _, x in { 18.4, 21.6 } do
		kit:part("Supply chest brass strap", { x, 2.2, -23.9 }, { 0.45, 4.2, 0.2 }, C.brass)
	end
	kit:part("Supply chest latch", { 20, 3, -23.7 }, { 0.8, 1.1, 0.35 }, C.brass)
end

local function office(kit: Kit)
	kit:part("Office flush wood floor", { -37, 0.04, -31 }, { 40, 0.08, 36 }, C.honey, nil, "WoodPlanks").collide =
		false
	kit:part("Sea trunk desk", { -37, 3, -35 }, { 19, 6, 9 }, C.wood, nil, "Wood")
	kit:ball("Rounded sea trunk desktop", { -37, 6.2, -35 }, { 21, 1.4, 10.5 }, C.honey)
	for _, x in { -44, -30 } do
		kit:part("Trunk brass strap", { x, 3, -30.35 }, { 0.65, 5.6, 0.25 }, C.brass)
		rivets(kit, { x, 5, -30.1 }, 2, C.cream)
	end
	kit:part("Trunk lock", { -37, 4, -30.05 }, { 1.8, 2, 0.5 }, C.brass)
	kit:part("Trunk keyhole", { -37, 4, -29.75 }, { 0.25, 0.8, 0.1 }, C.dark)
	barrel(kit, -37, -44, C.red)
	kit:ball("Captain chair back", { -37, 7.5, -46 }, { 5.3, 6, 1.7 }, C.red)
	kit:cylinder("Visitor barrel seat", { -49, 2.5, -23 }, { 5, 5, 5 }, C.honey)
	kit:cylinder("Visitor padded cushion", { -49, 5.2, -23 }, { 0.6, 5.2, 5.2 }, C.teal)
	kit:part("Desk ledger", { -39, 7.1, -34 }, { 4, 0.45, 3 }, C.navy)
	kit:part("Ledger open pages", { -39, 7.4, -34 }, { 3.6, 0.1, 2.6 }, C.cream)
	for i = 0, 3 do
		kit:part("Ledger ink tally", { -39, 7.47, -34.8 + i * 0.45 }, { 2.6, 0.03, 0.08 }, C.teal)
	end
	kit:ball("Desk telephone body", { -32, 7.4, -34 }, { 3.2, 1.3, 2.5 }, C.red)
	kit:cylinder("Telephone dial", { -32, 8.1, -33.7 }, { 0.2, 1.5, 1.5 }, C.cream)
	rod(kit, "Telephone receiver", { -33.4, 8.6, -34.5 }, { -30.6, 8.6, -34.5 }, 0.5, C.red)
	for _, x in { -33.4, -30.6 } do
		kit:ball("Telephone earpiece", { x, 8.4, -34.5 }, { 1, 1, 1.2 }, C.red)
	end
	kit:cylinder("Desk lamp base", { -44, 7.1, -37 }, { 0.4, 2.2, 2.2 }, C.brass)
	rod(kit, "Desk lamp crook", { -44, 7.3, -37 }, { -44, 11, -37 }, 0.25, C.brass)
	kit:ball("Desk lamp green shade", { -43.5, 11, -37 }, { 3, 1.1, 2.5 }, C.teal)
	kit:light({ -43.5, 10.2, -37 }, C.cream, 13)
	kit:part("Money safe body", { -22, 5, -44 }, { 9, 10, 9 }, C.navy, nil, "Metal")
	kit:part("Safe door brass surround", { -22, 5.2, -39.35 }, { 8, 8.5, 0.7 }, C.brass, nil, "Metal")
	kit:part("Safe recessed face", { -22, 5.2, -38.9 }, { 6.8, 7.3, 0.3 }, C.steel, nil, "Metal")
	ring(kit, "Safe wheel", { -22, 5, -38.25 }, 1.65, 0.3, C.navy, "Z")
	for i = 0, 2 do
		local a = i * math.pi * 2 / 3
		rod(
			kit,
			"Safe wheel spoke",
			{ -22, 5, -38.25 },
			{ -22 + math.cos(a) * 1.6, 5 + math.sin(a) * 1.6, -38.25 },
			0.25,
			C.navy
		)
	end
	for _, y in { 2, 8 } do
		kit:cylinder("Safe hinge", { -25.8, y, -38.7 }, { 1.5, 0.65, 0.65 }, C.brass)
	end
	kit:part("Formula display bracket", { -22, 8.7, -37.7 }, { 4, 0.4, 2.5 }, C.honey)
	local formula = bottle(kit, "Secret formula bottle", { -22, 10, -37.7 }, C.glass)
	formula.secret = "krusty_formula_bottle"
	formula.collide = false
	kit:part("Rolled formula parchment", { -22, 10, -36.9 }, { 0.75, 1.3, 0.15 }, C.cream)
	for i = 0, 2 do
		kit:cylinder(
			"Safe stacked coins",
			{ -25 + i * 2.7, 10.3 + i * 0.1, -45 },
			{ 0.6 + i * 0.2, 1.7, 1.7 },
			C.brass
		)
	end
	kit:part("First dollar walnut frame", { -45, 12, -49 }, { 13, 7, 0.8 }, C.dark, nil, "Wood")
	kit:part("First dollar inner gilt", { -45, 12, -48.5 }, { 11.7, 5.7, 0.3 }, C.brass)
	local dollar = kit:part(
		"Mr Krabs' first dollar",
		{ -45, 12, -48.25 },
		{ 10.5, 4.4, 0.2 },
		{ 139, 184, 119 }
	)
	dollar.secret = "krusty_first_dollar"
	dollar.collide = false
	kit:ball("Dollar oval medallion", { -45, 12, -48.04 }, { 2.8, 3.6, 0.2 }, C.cream)
	kit:ball("Dollar portrait head", { -45, 12.45, -47.86 }, { 1.3, 1.5, 0.15 }, C.teal)
	kit:ball("Dollar portrait shoulders", { -45, 11.35, -47.86 }, { 2, 1, 0.15 }, C.teal)
	for _, side in { -1, 1 } do
		kit:part("Dollar raised numeral", { -45 + side * 4, 12, -48.01 }, { 0.35, 2.2, 0.15 }, C.cream)
		for _, y in { 10.5, 13.5 } do
			rod(
				kit,
				"Dollar engraved flourish",
				{ -45 + side * 2.1, y, -48 },
				{ -45 + side * 4.7, y, -48 },
				0.12,
				C.teal
			)
		end
	end
	kit:part("Nautical relief backing", { -52, 13, -11.25 }, { 9, 10, 0.6 }, C.navy)
	anchor(kit, -52, 13, -10.65, 1.1, C.brass)
	ring(kit, "Relief rope border", { -52, 13, -10.6 }, 5, 0.35, C.rope, "Z")
	kit:light({ -37, 24, -32 }, { 255, 211, 134 }, 32)
end

return function(): { WorldKit.Part }
	local outside = exterior()
	local inside = WorldKit.new("krusty", Config.Zones.krusty.origin)
	diningRoom(inside)
	bulkheads(inside)
	cashier(inside)
	grill(inside)
	office(inside)
	local result: { WorldKit.Part } = {}
	for _, kit in { outside, inside } do
		for _, part in kit.parts do
			table.insert(result, part)
		end
	end
	return result
end
