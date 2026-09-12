--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../../src/shared/Config")

type Triple = WorldKit.Triple
type Kit = WorldKit.Kit

local steel = { 146, 166, 170 }
local silver = { 202, 217, 214 }
local dark = { 42, 62, 68 }
local ink = { 17, 35, 40 }
local red = { 172, 57, 55 }
local cream = { 233, 222, 177 }
local blue = { 78, 129, 188 }
local green = { 122, 199, 91 }
local cyan = { 103, 236, 220 }
local chum = { 128, 72, 89 }
local gold = { 237, 174, 57 }

local function rod(
	kit: Kit,
	name: string,
	a: Triple,
	b: Triple,
	diameter: number,
	color: Triple
): WorldKit.Part
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local horizontal = math.sqrt(dx * dx + dz * dz)
	return kit:cylinder(
		name,
		{ (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		{ math.sqrt(dx * dx + dy * dy + dz * dz), diameter, diameter },
		color,
		{ 0, -math.deg(math.atan2(dz, dx)), math.deg(math.atan2(dy, horizontal)) }
	)
end

local function capsule(kit: Kit, name: string, a: Triple, b: Triple, diameter: number, color: Triple)
	rod(kit, name, a, b, diameter, color)
	kit:ball(name .. " rounded end", a, { diameter, diameter, diameter }, color)
	kit:ball(name .. " rounded end", b, { diameter, diameter, diameter }, color)
end

local function disc(
	kit: Kit,
	name: string,
	p: Triple,
	diameter: number,
	thickness: number,
	color: Triple
): WorldKit.Part
	return kit:cylinder(name, p, { thickness, diameter, diameter }, color, { 0, 90, 0 })
end

local function bolts(kit: Kit, x: number, y: number, z: number, count: number, spacing: number)
	for i = 0, count - 1 do
		kit:ball("Round rivet", { x + i * spacing, y, z }, { 0.45, 0.45, 0.3 }, silver)
	end
end

local function porthole(kit: Kit, x: number, y: number, z: number, diameter: number)
	disc(kit, "Cast porthole rim", { x, y, z }, diameter, 0.65, dark)
	disc(kit, "Polished porthole lip", { x, y, z + 0.4 }, diameter - 0.6, 0.3, silver)
	disc(kit, "Deep teal porthole glass", { x, y, z + 0.6 }, diameter - 1.3, 0.15, { 43, 101, 109 })
	for i = 0, 7 do
		local angle = i * math.pi / 4
		kit:ball("Porthole fastening", {
			x + math.cos(angle) * (diameter / 2 - 0.3),
			y + math.sin(angle) * (diameter / 2 - 0.3),
			z + 0.45,
		}, { 0.3, 0.3, 0.3 }, gold)
	end
	rod(kit, "Glass glint", { x - 0.6, y + 0.8, z + 0.72 }, { x + 0.4, y + 1.4, z + 0.72 }, 0.2, cyan)
end

local function chumTin(kit: Kit, x: number, y: number, z: number, diameter: number)
	local height = diameter * 1.1
	kit:cylinder("Chum tin", { x, y + height / 2, z }, { height, diameter, diameter }, steel)
	for _, level in { 0.1, height - 0.1 } do
		kit:cylinder("Rolled tin edge", { x, y + level, z }, { 0.25, diameter + 0.3, diameter + 0.3 }, silver)
	end
	kit:cylinder(
		"Chum tin red band",
		{ x, y + height * 0.5, z },
		{ height * 0.35, diameter + 0.05, diameter + 0.05 },
		red
	)
	kit:cylinder("Unappetizing chum", { x, y + height, z }, { 0.12, diameter - 0.3, diameter - 0.3 }, chum)
	for i = 0, 2 do
		local angle = i * 2 * math.pi / 3
		kit:ball("Chum morsel", {
			x + math.cos(angle) * diameter * 0.22,
			y + height + 0.12,
			z + math.sin(angle) * diameter * 0.22,
		}, { diameter * 0.28, 0.35, diameter * 0.3 }, { 157, 98, 109 })
	end
end

local function stool(kit: Kit, x: number, z: number)
	kit:cylinder("Stool weighted foot", { x, 0.3, z }, { 0.6, 3.8, 3.8 }, dark)
	kit:cylinder("Stool chrome stem", { x, 2.3, z }, { 4, 0.8, 0.8 }, silver)
	kit:cylinder("Stool foot ring", { x, 1.5, z }, { 0.25, 2.6, 2.6 }, steel)
	kit:cylinder("Stool cushion piping", { x, 4.2, z }, { 0.7, 4.2, 4.2 }, cream)
	kit:ball("Round vinyl stool seat", { x, 4.65, z }, { 4.3, 1.1, 4.3 }, red)
end

local function burger(kit: Kit, x: number, y: number, z: number)
	kit:cylinder("Cafeteria plate", { x, y + 0.12, z }, { 0.22, 3.6, 3.6 }, cream)
	kit:ball("Chumwich bottom bun", { x, y + 0.4, z }, { 2.8, 0.6, 2.8 }, gold)
	kit:cylinder("Purple chum patty", { x, y + 0.8, z }, { 0.6, 2.65, 2.65 }, chum)
	kit:part("Crooked pickle slice", { x, y + 1.1, z }, { 2.8, 0.15, 2.8 }, green, nil, nil, { 0, 20, 0 })
	kit:ball("Chumwich dome bun", { x, y + 1.45, z }, { 2.9, 1, 2.9 }, { 209, 143, 57 })
	for i = -1, 1 do
		kit:ball("Bun sesame seed", { x + i * 0.6, y + 1.9, z + i % 2 * 0.3 }, { 0.18, 0.12, 0.4 }, cream)
	end
end

local function diningTable(kit: Kit, x: number, z: number)
	kit:cylinder("Cafeteria table foot", { x, 0.35, z }, { 0.7, 5, 5 }, dark)
	kit:cylinder("Cafeteria table pedestal", { x, 2.8, z }, { 5, 1.1, 1.1 }, silver)
	kit:cylinder("Rolled table edge", { x, 5.3, z }, { 0.65, 11, 11 }, silver)
	kit:cylinder("Cream enamel tabletop", { x, 5.65, z }, { 0.2, 10.4, 10.4 }, cream)
	for _, side in { -1, 1 } do
		stool(kit, x + side * 8.2, z)
	end
	burger(kit, x - 1.5, 5.75, z + 1)
	chumTin(kit, x + 2.4, 5.75, z - 1.4, 1)
	kit:part("Napkin dispenser", { x, 6.4, z - 2.5 }, { 1.8, 1.3, 1.4 }, steel)
	kit:part("Folded paper napkin", { x, 7.1, z - 2.5 }, { 1.3, 0.15, 1.1 }, cream)
end

local function exterior(kit: Kit)
	kit:cylinder("Flush bucket foundation", { 0, -0.5, -9 }, { 1, 60, 60 }, { 117, 139, 132 })
	for row = 0, 5 do
		local bottom = if row < 3 then row * 17 / 3 else 17 + (row - 3) * 6
		local height = if row < 3 then 17 / 3 else 6
		local y = bottom + height / 2
		local radius = 20 + y * 5 / 35
		for i = 0, 39 do
			local angle = i * math.pi / 20
			local x, z = math.sin(angle) * radius, -10 + math.cos(angle) * radius
			if bottom >= 17 or z < 3 or math.abs(x) > 11 then
				kit:part(
					"Tapered bucket steel panel",
					{ x, y, z },
					{ 2 * radius * math.tan(math.pi / 40) + 0.1, height, 1.2 },
					if i % 4 == 0 then silver else steel,
					nil,
					"Metal",
					{ 0, math.deg(angle), 0 }
				)
				if row == 0 or row == 5 then
					kit:ball(
						"Bucket shell rivet",
						{ x + math.sin(angle) * 0.65, y, z + math.cos(angle) * 0.65 },
						{ 0.55, 0.55, 0.55 },
						dark
					)
				end
			end
		end
	end
	for _, y in { 0.7, 23, 29, 35 } do
		local radius = 20 + y * 5 / 35 + 0.6
		for i = 0, 47 do
			local a, b = i * math.pi / 24, (i + 1) * math.pi / 24
			local mid = (a + b) / 2
			if y > 17 or math.cos(mid) < 0 or math.abs(math.sin(mid) * radius) > 12 then
				rod(
					kit,
					if y == 23 or y == 29 then "Painted bucket stripe" else "Rolled bucket rim",
					{ math.sin(a) * radius, y, -10 + math.cos(a) * radius },
					{ math.sin(b) * radius, y, -10 + math.cos(b) * radius },
					if y == 23 or y == 29 then 0.7 else 1.4,
					if y == 23 or y == 29 then red else silver
				)
			end
		end
	end
	kit:cylinder("Bucket top inset", { 0, 34.7, -10 }, { 0.5, 48, 48 }, dark)
	for _, side in { -1, 1 } do
		capsule(kit, "Entrance rolled jamb", { side * 8.3, 0.5, 10 }, { side * 8.3, 17.6, 10 }, 1.2, dark)
		kit:part("Open double door leaf", { side * 10, 7.7, 7.4 }, { 0.75, 15.4, 5.5 }, blue, nil, "Metal")
		kit:cylinder(
			"Open door porthole rim",
			{ side * 10.5, 10.5, 7.4 },
			{ 0.3, 3.3, 3.3 },
			silver,
			{ 0, 0, 0 }
		)
		kit:cylinder(
			"Open door porthole glass",
			{ side * 10.7, 10.5, 7.4 },
			{ 0.15, 2.5, 2.5 },
			cyan,
			{ 0, 0, 0 }
		)
		capsule(kit, "Open door pull", { side * 10.7, 5.8, 9.1 }, { side * 10.7, 8, 9.1 }, 0.3, cream)
		for _, y in { 3, 12 } do
			kit:cylinder("Door hinge", { side * 9.6, y, 10 }, { 1.7, 0.6, 0.6 }, silver)
		end
		disc(kit, "Bucket handle pivot", { side * 23.5, 26, -8 }, 4, 3, dark)
		disc(kit, "Handle pivot cap", { side * 23.5, 26, -6.4 }, 2.8, 0.35, gold)
	end
	capsule(kit, "Open entrance lintel", { -8.3, 18.3, 10 }, { 8.3, 18.3, 10 }, 1.2, silver)
	for i = 0, 23 do
		local a, b = i * math.pi / 24, (i + 1) * math.pi / 24
		rod(
			kit,
			"Arched bucket handle",
			{ math.cos(a) * 24, 26 + math.sin(a) * 28, -8 },
			{ math.cos(b) * 24, 26 + math.sin(b) * 28, -8 },
			1.7,
			dark
		)
	end
	kit:ball("Giant blue glove palm", { 0, 59, -8 }, { 14, 13, 10 }, blue)
	kit:cylinder("Glove wrist", { 0, 67, -10 }, { 8, 8, 8 }, blue)
	kit:cylinder("Rolled glove cuff", { 0, 70.5, -10 }, { 2.2, 11, 11 }, { 102, 155, 211 })
	kit:cylinder("Dark glove cuff opening", { 0, 71.7, -10 }, { 0.2, 7.8, 7.8 }, dark)
	for finger = 0, 3 do
		local x = -4.8 + finger * 3.1
		capsule(kit, "Glove curled finger", { x, 59, -3.8 }, { x, 53.5, -3.2 }, 3.1, blue)
		kit:ball("Glove curled fingertip", { x, 52.8, -5.3 }, { 3.1, 3.4, 5 }, blue)
		rod(
			kit,
			"Glove finger crease",
			{ x - 0.6, 55.6, -1.5 },
			{ x + 0.6, 55.6, -1.5 },
			0.18,
			{ 49, 93, 152 }
		)
	end
	capsule(kit, "Glove embracing thumb", { 6, 59, -8 }, { 8.4, 55.6, -5.5 }, 4.3, blue)
	kit:part("Bucket nameplate", { 0, 26, 15.4 }, { 22, 4.5, 0.8 }, red)
	for _, y in { 23.7, 28.3 } do
		capsule(kit, "Nameplate cream piping", { -10.6, y, 16 }, { 10.6, y, 16 }, 0.35, cream)
	end
	kit:label("CHUM BUCKET", { 0, 26, 16.1 }, cream)
	for _, side in { -1, 1 } do
		kit:light({ side * 9, 19.8, 11 }, cyan, 22)
		chumTin(kit, side * 29, 0, -1, 4.3)
		chumTin(kit, side * 32.5, 0, -6, 3.2)
		for i = 0, 3 do
			kit:ball(
				"Courtyard rounded cobble",
				{ side * (16 + i * 5), 0.4, 23 + i % 2 * 2 },
				{ 3, 0.8, 2.6 },
				steel
			)
			capsule(
				kit,
				"Crooked seaweed stalk",
				{ side * (28 + i), 0, -24 },
				{ side * (28 + i * 1.3), 2.3 + i * 0.6, -24.5 },
				0.55,
				{ 91, 141, 102 }
			)
		end
	end
	kit:part("Drive through speaker pedestal", { 32, 3.5, -16 }, { 1.7, 7, 2 }, dark)
	kit:part("Drive through speaker case", { 32, 8, -16 }, { 5, 5, 3 }, blue)
	disc(kit, "Drive through speaker", { 32, 8, -14.35 }, 3.2, 0.3, ink)
	for i = -2, 2 do
		rod(kit, "Speaker grille", { 31, 8 + i * 0.4, -14.1 }, { 33, 8 + i * 0.4, -14.1 }, 0.12, silver)
	end
end

local function restaurantShell(kit: Kit)
	kit:room(116, 100, 30, { 101, 130, 132 }, { 149, 170, 164 }, false)
	kit.parts[1].material = "SmoothPlastic"
	kit:part(
		"Laboratory flush floor inlay",
		{ 0, 0.035, -29 },
		{ 114, 0.07, 40 },
		{ 72, 104, 105 },
		nil,
		"Metal"
	)
	for _, x in { -56.9, 56.9 } do
		for z = -42, 42, 14 do
			kit:part("Stamped side wall panel", { x, 13, z }, { 0.2, 22, 12.5 }, steel, nil, "Metal")
			for _, y in { 3, 24 } do
				kit:ball("Wall panel bolt", { x * 0.994, y, z - 5 }, { 0.4, 0.5, 0.5 }, dark)
				kit:ball("Wall panel bolt", { x * 0.994, y, z + 5 }, { 0.4, 0.5, 0.5 }, dark)
			end
		end
		capsule(kit, "Wall base pipe", { x * 0.99, 0.8, -48 }, { x * 0.99, 0.8, 48 }, 0.9, dark)
		capsule(kit, "Wall crown pipe", { x * 0.99, 27.5, -48 }, { x * 0.99, 27.5, 48 }, 1.3, silver)
	end
	for x = -48, 48, 16 do
		kit:part("Rear steel wall seam", { x, 14, -49.25 }, { 0.25, 27, 0.25 }, dark)
		bolts(kit, x - 5, 27, -49.1, 3, 5)
	end
	for _, side in { -1, 1 } do
		kit:part("Entrance skirting", { side * 32.3, 1, 49.2 }, { 50.4, 1.8, 0.35 }, dark)
		kit:part("Inside doorway trim", { side * 6.65, 8.5, 49.2 }, { 1, 17, 0.4 }, silver)
		capsule(kit, "Upper dining wall rail", { side * 8, 24, 49.2 }, { side * 55, 24, 49.2 }, 0.8, dark)
	end
	kit:part("Inside doorway lintel", { 0, 17.7, 49.2 }, { 14.3, 1.2, 0.5 }, silver)
	for _, x in { -35, 35 } do
		kit:part("Floor border stripe", { x, 0.045, 21 }, { 39, 0.09, 1 }, red)
		for z = 0, 42, 6 do
			kit:part("Cafeteria checker inset", { x, 0.04, z }, { 4, 0.08, 4 }, cream)
			kit:part("Cafeteria checker inset", { x + 6, 0.04, z + 3 }, { 4, 0.08, 4 }, { 115, 142, 142 })
		end
	end
	kit:part("Laboratory divider left", { -35, 10, -8 }, { 46, 20, 1 }, steel, nil, "Metal")
	kit:part("Laboratory divider right pier", { 17, 10, -8 }, { 10, 20, 1 }, steel, nil, "Metal")
	kit:part("Laboratory divider end pier", { 53.5, 10, -8 }, { 9, 20, 1 }, steel, nil, "Metal")
	kit:part("Serving hatch apron", { 35.5, 3, -8 }, { 27, 6, 1 }, steel, nil, "Metal")
	kit:part("Serving hatch header", { 35.5, 17, -8 }, { 27, 6, 1 }, steel, nil, "Metal")
	kit:part("Wide laboratory doorway header", { 0, 22, -8 }, { 116, 4, 1.5 }, dark)
	for _, side in { -1, 1 } do
		capsule(
			kit,
			"Laboratory door rounded jamb",
			{ side * 12.8, 0.6, -7.2 },
			{ side * 12.8, 19.3, -7.2 },
			1,
			dark
		)
		for y = 2, 16, 3 do
			kit:part("Door jamb caution tab", { side * 12.8, y, -6.55 }, { 0.8, 1, 0.2 }, gold)
		end
	end
	capsule(kit, "Laboratory door crown", { -12.8, 20, -7.2 }, { 12.8, 20, -7.2 }, 1, silver)
	kit:label("LABORATORY", { 0, 22, -6.8 }, cyan)
	for _, x in { -34, 34 } do
		for _, z in { 28, -28 } do
			kit:cylinder("Hanging lamp stem", { x, 27, z }, { 5, 0.4, 0.4 }, dark)
			kit:ball("Domed industrial lampshade", { x, 24.9, z }, { 6, 2.5, 6 }, if z > 0 then red else dark)
			kit:cylinder("Lamp diffuser", { x, 23.9, z }, { 0.2, 5, 5 }, cream)
			kit:light({ x, 23.5, z }, if z > 0 then { 255, 213, 141 } else cyan, 32)
		end
	end
end

local function wallArt(kit: Kit)
	disc(kit, "Round chum menu medallion", { -46, 12, -7.1 }, 9, 0.6, dark)
	disc(kit, "Menu enamel field", { -46, 12, -6.7 }, 8, 0.25, cream)
	kit:part("Relief bucket body", { -46, 11.4, -6.35 }, { 3.7, 3.6, 0.4 }, red)
	capsule(kit, "Relief bucket rim", { -48, 13.4, -6.2 }, { -44, 13.4, -6.2 }, 0.4, silver)
	for i = 0, 7 do
		local a, b = i * math.pi / 8, (i + 1) * math.pi / 8
		rod(
			kit,
			"Relief bucket handle",
			{ -46 + math.cos(a) * 2, 13 + math.sin(a) * 2, -6.2 },
			{ -46 + math.cos(b) * 2, 13 + math.sin(b) * 2, -6.2 },
			0.3,
			dark
		)
	end
	kit:part("Chumwich diamond frame", { -32, 12, -7.1 }, { 7.5, 7.5, 0.5 }, gold, nil, nil, { 0, 0, 45 })
	kit:part("Chumwich diamond enamel", { -32, 12, -6.8 }, { 6.6, 6.6, 0.15 }, red, nil, nil, { 0, 0, 45 })
	kit:ball("Relief burger crown", { -32, 13.4, -6.3 }, { 5.7, 2.5, 0.8 }, gold)
	capsule(kit, "Relief burger filling", { -34.4, 11.8, -6.25 }, { -29.6, 11.8, -6.25 }, 0.8, chum)
	capsule(kit, "Relief burger base", { -34.2, 10.5, -6.3 }, { -29.8, 10.5, -6.3 }, 1, cream)
	for i = -1, 1 do
		kit:ball("Relief sesame seed", { -32 + i * 1.3, 13.8, -5.86 }, { 0.3, 0.6, 0.15 }, cream)
	end
	kit:part("Failure exhibit frame", { -18, 12.5, -7.1 }, { 9, 10, 0.7 }, dark)
	kit:part("Failure exhibit backing", { -18, 12.5, -6.65 }, { 8, 9, 0.2 }, { 63, 117, 127 })
	kit:part("Relief failed robot body", { -18, 12.5, -6.35 }, { 3.3, 3.2, 0.4 }, silver)
	kit:ball("Relief robot dome", { -18, 15, -6.3 }, { 3.9, 2.5, 0.55 }, steel)
	disc(kit, "Relief robot cyclops eye", { -18, 15, -5.95 }, 1.2, 0.25, red)
	for _, side in { -1, 1 } do
		rod(
			kit,
			"Relief robot crooked leg",
			{ -18 + side, 11, -6.2 },
			{ -18 + side * 2.2, 9, -6.2 },
			0.6,
			silver
		)
		rod(
			kit,
			"Relief robot drooping arm",
			{ -18 + side * 1.8, 13.5, -6.2 },
			{ -18 + side * 3.2, 12, -6.2 },
			0.55,
			silver
		)
	end
	kit:part("Spatula exhibit shelf", { -18, 3.5, -5.7 }, { 8, 0.5, 3 }, dark)
	rod(kit, "Golden spatula handle", { -19, 3.9, -4.7 }, { -17.5, 5.3, -4.7 }, 0.45, gold)
	local spatula = kit:part(
		"Golden failed-plan spatula",
		{ -17, 5.8, -4.7 },
		{ 1.9, 1.8, 0.35 },
		gold,
		nil,
		"Metal",
		{ 0, 0, -30 }
	)
	spatula.secret = "chum-golden-spatula"
	for i = -1, 1 do
		kit:part(
			"Spatula blade slot",
			{ -17 + i * 0.4, 5.8, -4.49 },
			{ 0.12, 0.8, 0.08 },
			dark,
			nil,
			nil,
			{ 0, 0, -30 }
		)
	end
end

local function restaurant(kit: Kit)
	diningTable(kit, -33, 30)
	diningTable(kit, -33, 8)
	diningTable(kit, 33, 32)
	kit:part("Rounded service counter core", { 35, 3.1, 0 }, { 31, 6.2, 6 }, red)
	for _, x in { 19.5, 50.5 } do
		kit:cylinder("Service counter rounded end", { x, 3.1, 0 }, { 6.2, 6, 6 }, red)
		kit:cylinder("Service counter rolled end cap", { x, 6.35, 0 }, { 0.5, 6.8, 6.8 }, silver)
	end
	kit:part("Service counter top", { 35, 6.35, 0 }, { 31, 0.5, 6.8 }, silver)
	capsule(kit, "Counter cream edge", { 19.5, 5.6, 3.1 }, { 50.5, 5.6, 3.1 }, 0.45, cream)
	capsule(kit, "Counter foot rail", { 20, 1.4, 4.8 }, { 50, 1.4, 4.8 }, 0.45, silver)
	for x = 22, 48, 13 do
		stool(kit, x, 9)
		rod(kit, "Counter foot rail bracket", { x, 1.4, 3 }, { x, 1.4, 4.8 }, 0.35, dark)
		burger(kit, x, 6.6, 1)
	end
	kit:part("Register base", { 43, 7.1, -0.8 }, { 4.5, 1, 3 }, dark)
	kit:part("Old cash register", { 43, 8.1, -1 }, { 4, 1.5, 2.8 }, steel, "Wedge")
	kit:part("Register display", { 43, 9.6, -1.6 }, { 3.3, 1.5, 0.5 }, dark)
	kit:part("Register empty total", { 43, 9.6, -1.3 }, { 2.6, 0.7, 0.1 }, cyan, nil, "Neon")
	for x = 0, 3 do
		for z = 0, 1 do
			kit:ball("Register key", { 41.8 + x * 0.8, 8.9, -0.9 + z * 0.75 }, { 0.45, 0.25, 0.45 }, cream)
		end
	end
	kit:cylinder("Counter bell foot", { 48, 6.8, -0.5 }, { 0.3, 1.5, 1.5 }, dark)
	kit:ball("Counter service bell", { 48, 7.2, -0.5 }, { 1.3, 0.8, 1.3 }, gold)
	kit:ball("Bell button", { 48, 7.7, -0.5 }, { 0.3, 0.3, 0.3 }, dark)
	kit:part("Serving hatch sill", { 35.5, 6.2, -7 }, { 29, 0.5, 4 }, dark)
	for x = 25, 45, 5 do
		chumTin(kit, x, 6.5, -6.5, 1.7)
	end
	for _, x in { 27, 44 } do
		porthole(kit, x, 23.5, -6.9, 5)
	end
	wallArt(kit)
	kit:supply({ -47, 2, 41 })
	for _, x in { -49, -45 } do
		kit:part("Supply chest steel band", { x, 2.1, 41 }, { 0.45, 4.2, 4.1 }, silver)
	end
	kit:part("Supply chest latch", { -47, 2.8, 43.15 }, { 0.9, 1.3, 0.35 }, gold)
	kit:part("Supply chest lid trim", { -47, 4.1, 41 }, { 5.3, 0.35, 4.3 }, dark)
	kit:part("Supply chest cross horizontal", { -47, 2, 43.35 }, { 2, 0.4, 0.15 }, cream)
	kit:part("Supply chest cross vertical", { -47, 2, 43.35 }, { 0.4, 2, 0.15 }, cream)
end

local function vat(kit: Kit, x: number, z: number)
	kit:cylinder("Experiment vat base", { x, 0.65, z }, { 1.3, 12, 12 }, dark)
	kit:cylinder("Vat lower pressure shell", { x, 2.2, z }, { 3, 11, 11 }, steel)
	local glass = kit:cylinder("Cylindrical specimen glass", { x, 10, z }, { 13, 10, 10 }, cyan)
	glass.transparency = 0.65
	kit:cylinder("Glowing vat culture", { x, 6.4, z }, { 6.8, 8.5, 8.5 }, { 87, 163, 92 }).transparency = 0.18
	for i = 0, 5 do
		local angle = i * 2.4
		kit:ball(
			"Suspended culture bubble",
			{ x + math.cos(angle) * 2.8, 5 + i * 1.7, z + math.sin(angle) * 2.8 },
			{ 0.7, 0.7, 0.7 },
			green
		).material =
			"Neon"
	end
	for _, y in { 3.7, 16.5 } do
		kit:cylinder("Pressure vessel sealing ring", { x, y, z }, { 0.8, 11.2, 11.2 }, silver)
	end
	kit:ball("Vat domed lid", { x, 17.5, z }, { 11, 3, 11 }, dark)
	for _, side in { -1, 1 } do
		capsule(kit, "Vat tie rod", { x + side * 5, 3, z }, { x + side * 5, 17, z }, 0.5, silver)
	end
	disc(kit, "Vat pressure gauge", { x, 3, z + 5.5 }, 2.5, 0.6, dark)
	disc(kit, "Pressure gauge dial", { x, 3, z + 5.85 }, 1.9, 0.1, cream)
	rod(kit, "Pressure gauge needle", { x, 3, z + 5.96 }, { x + 0.6, 3.5, z + 5.96 }, 0.13, red)
	capsule(kit, "Vat outlet riser", { x, 18, z }, { x, 24, z }, 1.8, steel)
	kit:light({ x, 12, z }, green, 20)
end

local function karen(kit: Kit)
	kit:part("Karen wall computer cabinet", { 0, 15.5, -47.7 }, { 24, 15, 2.5 }, dark, nil, "Metal")
	kit:part("Karen silver monitor bezel", { 0, 15.5, -46.2 }, { 22, 13, 0.7 }, silver)
	kit:part("Karen dark monitor face", { 0, 15.5, -45.75 }, { 19.5, 10.5, 0.3 }, ink)
	for _, x in { -10.8, 10.8 } do
		capsule(kit, "Karen rounded monitor edge", { x, 10, -46.2 }, { x, 21, -46.2 }, 1, silver)
	end
	local waveform = {
		{ -8, 15.5 },
		{ -5, 15.5 },
		{ -3.6, 17.5 },
		{ -1.8, 13.6 },
		{ 0, 16.6 },
		{ 1.5, 14.5 },
		{ 3.5, 15.5 },
		{ 8, 15.5 },
	}
	for i = 1, #waveform - 1 do
		local a, b = waveform[i], waveform[i + 1]
		local segment = rod(
			kit,
			"Karen luminous waveform",
			{ a[1], a[2], -45.5 },
			{ b[1], b[2], -45.5 },
			0.3,
			cyan
		)
		segment.material = "Neon"
	end
	for x = -8, 8, 2 do
		kit:part("Karen bottom ventilation slot", { x, 9.4, -45.7 }, { 0.6, 0.8, 0.1 }, ink)
	end
	kit:part("Karen console pedestal", { 0, 3, -39.5 }, { 17, 6, 6 }, dark, nil, "Metal")
	kit:part("Karen console silver lip", { 0, 6.3, -39 }, { 21, 0.6, 8 }, silver)
	kit:part("Karen console control surface", { 0, 6.7, -39 }, { 19, 0.25, 6.5 }, blue)
	for x = -7, 7, 2 do
		for row = 0, 2 do
			kit:part(
				"Karen console key",
				{ x, 6.95, -40.5 + row * 1.2 },
				{ 1.1, 0.3, 0.8 },
				if row == 2 then cream else steel
			)
		end
	end
	for _, x in { -8, 8 } do
		kit:ball("Karen console indicator", { x, 7.1, -36.8 }, { 0.6, 0.4, 0.6 }, green).material = "Neon"
	end
	kit:light({ 0, 20, -44.8 }, cyan, 28)
	kit:part("Memory cart lower tray", { 23, 1, -38 }, { 7, 0.6, 5 }, dark)
	kit:part("Memory cart upper tray", { 23, 4.2, -38 }, { 7, 0.4, 5 }, silver)
	for _, side in { -1, 1 } do
		capsule(
			kit,
			"Memory cart frame",
			{ 23 + side * 3, 0.8, -38 },
			{ 23 + side * 3, 4.2, -38 },
			0.5,
			steel
		)
		for _, dz in { -1.8, 1.8 } do
			kit:ball("Memory cart caster", { 23 + side * 2.7, 0.4, -38 + dz }, { 0.9, 0.8, 0.9 }, ink)
		end
	end
	local memory = kit:part("Karen removable backup cartridge", { 23, 5, -37.4 }, { 3, 1.2, 2.3 }, blue)
	memory.secret = "chum-karen-backup"
	kit:part("Backup cartridge label", { 23, 5.66, -37.4 }, { 2.5, 0.12, 1.4 }, cream)
	for i = -1, 1 do
		kit:part("Backup cartridge gold contact", { 23 + i * 0.7, 4.8, -36.15 }, { 0.3, 0.5, 0.2 }, gold)
	end
	kit:part("Backup archive cabinet", { 23, 2.6, -38 }, { 5.5, 2.4, 3.5 }, steel)
	for _, y in { 2, 3 } do
		kit:part("Archive drawer pull", { 23, y, -36.15 }, { 2.2, 0.3, 0.3 }, dark)
	end
end

local function laboratory(kit: Kit)
	vat(kit, -43, -42)
	vat(kit, 43, -42)
	for _, side in { -1, 1 } do
		capsule(kit, "Vat ceiling elbow", { side * 43, 24, -42 }, { side * 27, 24, -42 }, 1.8, steel)
		capsule(kit, "Ceiling process pipe", { side * 27, 24, -42 }, { side * 27, 24, -13 }, 1.8, steel)
		capsule(kit, "Process pipe downspout", { side * 27, 24, -13 }, { side * 27, 17, -13 }, 1.8, steel)
		for z = -39, -15, 6 do
			kit:cylinder("Pipe coupling", { side * 27, 24, z }, { 0.55, 2.4, 2.4 }, dark, { 0, 90, 0 })
			kit:part("Ceiling pipe hanger", { side * 27, 27, z }, { 0.45, 6, 0.45 }, dark)
		end
	end
	karen(kit)
	kit:part("Experiment bench cabinet", { 37, 3, -22 }, { 24, 6, 8 }, steel, nil, "Metal")
	kit:part("Experiment bench black top", { 37, 6.3, -22 }, { 25, 0.6, 9 }, dark)
	for x = 29, 45, 8 do
		kit:part("Bench cabinet door inset", { x, 3, -17.85 }, { 7, 4.8, 0.15 }, blue)
		kit:part("Bench cabinet pull", { x + 2, 3.7, -17.6 }, { 0.4, 1.5, 0.3 }, silver)
	end
	kit:cylinder("Formula decoy saucer", { 30, 6.75, -20 }, { 0.3, 4, 4 }, silver)
	local bottle = kit:cylinder(
		"Empty secret formula decoy bottle",
		{ 30, 8.3, -20 },
		{ 2.8, 2.3, 2.3 },
		{ 118, 190, 162 }
	)
	bottle.secret = "chum-decoy-formula"
	bottle.transparency = 0.25
	kit:ball("Formula bottle shoulder", { 30, 9.5, -20 }, { 2.3, 1.3, 2.3 }, { 118, 190, 162 }).transparency =
		0.25
	kit:cylinder("Formula bottle neck", { 30, 10.2, -20 }, { 1.2, 0.9, 0.9 }, { 118, 190, 162 })
	kit:cylinder("Formula bottle cork", { 30, 10.9, -20 }, { 0.5, 1, 1 }, gold)
	kit:part("Blank decoy recipe scroll", { 30, 8.2, -18.8 }, { 1.3, 1.7, 0.12 }, cream)
	kit:part("Microscope weighted base", { 40, 6.9, -21 }, { 3.5, 0.6, 3 }, blue)
	capsule(kit, "Microscope curved upright", { 40.7, 7.1, -21.5 }, { 40.7, 10.8, -22 }, 0.7, silver)
	rod(kit, "Microscope angled tube", { 40.7, 10.8, -22 }, { 39.4, 12, -21 }, 1, blue)
	kit:part("Microscope specimen stage", { 39.7, 8.7, -20.8 }, { 2.4, 0.2, 2 }, dark)
	kit:part("Microscope glass slide", { 39.7, 8.85, -20.8 }, { 1.2, 0.1, 0.7 }, cyan)
	kit:cylinder("Microscope focus wheel", { 41.25, 9.4, -21.5 }, { 0.5, 1.1, 1.1 }, dark, { 0, 0, 0 })
	for i = 0, 3 do
		local x = 44 + i
		kit:cylinder(
			"Culture test tube",
			{ x, 8, -23.8 },
			{ 2.6, 0.65, 0.65 },
			if i % 2 == 0 then cyan else green
		).transparency =
			0.3
		kit:ball("Test tube rounded bottom", { x, 6.9, -23.8 }, { 0.65, 0.65, 0.65 }, blue)
	end
	kit:part("Test tube rack", { 45.5, 7.3, -23.8 }, { 5, 0.4, 1.5 }, gold)
	chumTin(kit, 35, 6.6, -24, 2)
	kit:cylinder("Invention assembly plinth", { -35, 0.5, -24 }, { 1, 14, 14 }, dark)
	kit:cylinder("Invention plinth caution ring", { -35, 1.1, -24 }, { 0.3, 13.4, 13.4 }, gold)
	kit:cylinder("Invention plinth top", { -35, 1.35, -24 }, { 0.3, 12.2, 12.2 }, steel)
	for _, side in { -1, 1 } do
		kit:ball("Prototype robot boot", { -35 + side * 2.5, 2.2, -23 }, { 4, 1.5, 5 }, dark)
		capsule(
			kit,
			"Prototype robot shin",
			{ -35 + side * 2.5, 2.5, -24 },
			{ -35 + side * 2.5, 6, -24 },
			1.4,
			silver
		)
		kit:ball("Prototype robot shoulder", { -35 + side * 4.3, 10, -24 }, { 2.5, 2.5, 2.5 }, blue)
		capsule(
			kit,
			"Prototype bent arm",
			{ -35 + side * 4.8, 9.8, -24 },
			{ -35 + side * 6, 7, -23 },
			1.2,
			steel
		)
		kit:ball("Prototype robot mitten", { -35 + side * 6, 6.5, -23 }, { 2.2, 2.2, 2.2 }, dark)
	end
	kit:part("Prototype robot torso", { -35, 8.5, -24 }, { 7, 6, 5 }, blue)
	porthole(kit, -35, 8.7, -21.1, 4)
	kit:ball("Prototype robot dome", { -35, 13.2, -24 }, { 7.5, 5, 5.5 }, silver)
	disc(kit, "Prototype cyclops black socket", { -35, 13.5, -21.3 }, 3, 0.45, dark)
	disc(kit, "Prototype cyclops amber eye", { -35, 13.5, -20.95 }, 2, 0.2, gold)
	disc(kit, "Prototype cyclops pupil", { -35, 13.5, -20.78 }, 0.65, 0.1, red)
	capsule(kit, "Prototype antenna", { -35, 15.2, -24 }, { -36.5, 17, -24 }, 0.4, dark)
	kit:ball("Prototype antenna bulb", { -36.5, 17.2, -24 }, { 1, 1, 1 }, red)
	kit:part("Plankton drafting desk", { -18, 4, -43 }, { 12, 0.7, 8 }, dark)
	for _, x in { -23, -13 } do
		for _, z in { -46, -40 } do
			kit:cylinder("Drafting desk leg", { x, 2, z }, { 4, 0.7, 0.7 }, steel)
		end
	end
	kit:part("Original robot blueprint", { -18, 4.42, -42.5 }, { 8, 0.12, 5 }, blue)
	kit:part("Blueprint robot body", { -18, 4.51, -42.5 }, { 2.5, 0.08, 2 }, cream)
	kit:cylinder("Blueprint robot head", { -18, 4.52, -44.1 }, { 0.1, 1.7, 1.7 }, cream)
	for _, side in { -1, 1 } do
		rod(
			kit,
			"Blueprint robot leg",
			{ -18 + side * 0.8, 4.54, -41.5 },
			{ -18 + side * 1.4, 4.54, -40.8 },
			0.16,
			cream
		)
	end
	kit:part("Desk tiny podium", { -22, 4.8, -45 }, { 2, 0.7, 2 }, silver)
	local model = kit:ball("Pocket-sized failed robot model", { -22, 5.8, -45 }, { 1.5, 1.8, 1.2 }, green)
	model.secret = "chum-pocket-prototype"
	disc(kit, "Pocket prototype eye", { -22, 6.1, -44.3 }, 0.65, 0.2, gold)
	disc(kit, "Pocket prototype pupil", { -22, 6.1, -44.15 }, 0.25, 0.1, red)
	for _, side in { -1, 1 } do
		rod(
			kit,
			"Pocket prototype antenna",
			{ -22 + side * 0.35, 6.5, -45 },
			{ -22 + side * 0.7, 7.5, -45 },
			0.12,
			dark
		)
	end
	kit:part("Drafting pencil", { -14.4, 4.65, -43.2 }, { 0.2, 0.2, 3 }, gold, nil, nil, { 0, -18, 0 })
end

return function(): { WorldKit.Part }
	local outside = WorldKit.new("street", { 175, 0, 0 })
	local inside = WorldKit.new("chum", Config.Zones.chum.origin)
	exterior(outside)
	restaurantShell(inside)
	restaurant(inside)
	laboratory(inside)
	local result: { WorldKit.Part } = {}
	for _, kit in { outside, inside } do
		for _, part in kit.parts do
			table.insert(result, part)
		end
	end
	return result
end
