--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../../src/shared/Config")

type Triple = WorldKit.Triple
type Kit = WorldKit.Kit

local sand = { 222, 191, 137 }
local paleSand = { 243, 218, 168 }
local sandShadow = { 183, 142, 95 }
local rock = { 137, 76, 65 }
local brass = { 201, 151, 69 }
local pink = { 244, 154, 166 }
local purple = { 149, 107, 166 }
local green = { 168, 200, 108 }
local dark = { 62, 52, 49 }

local function rod(kit: Kit, name: string, a: Triple, b: Triple, radius: number, color: Triple): WorldKit.Part
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	return kit:cylinder(
		name,
		{ (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		{ length, radius * 2, radius * 2 },
		color,
		{ 0, math.deg(math.atan2(-dz, dx)), math.deg(math.asin(dy / length)) }
	)
end

local function ring(kit: Kit, name: string, p: Triple, rx: number, ry: number, radius: number, color: Triple)
	for i = 0, 23 do
		local a, b = i * math.pi / 12, (i + 1) * math.pi / 12
		rod(
			kit,
			name,
			{ p[1] + math.cos(a) * rx, p[2] + math.sin(a) * ry, p[3] },
			{ p[1] + math.cos(b) * rx, p[2] + math.sin(b) * ry, p[3] },
			radius,
			color
		).collide =
			false
	end
end

local function flower(kit: Kit, p: Triple, radius: number, color: Triple)
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		local petal = kit:ball(
			"Five-petal flower relief",
			{ p[1] + math.sin(angle) * radius * 0.65, p[2] + math.cos(angle) * radius * 0.65, p[3] },
			{ radius * 0.8, radius * 1.2, 0.3 },
			color
		)
		petal.rotation = { 0, 0, -math.deg(angle) }
		petal.collide = false
	end
	kit:ball(
		"Flower relief center",
		{ p[1], p[2], p[3] + 0.2 },
		{ radius * 0.6, radius * 0.6, 0.3 },
		paleSand
	).collide =
		false
end

local function lifted(p: Triple): Triple
	local angle = math.rad(62)
	return {
		p[1],
		1.5 + p[2] * math.cos(angle) + (p[3] + 18) * math.sin(angle),
		-18 - p[2] * math.sin(angle) + (p[3] + 18) * math.cos(angle),
	}
end

local function exterior(): Kit
	local kit = WorldKit.new("street", { -110, 0, 0 })
	kit:cylinder("Level excavated sand landing", { 0, -0.4, 0 }, { 0.8, 44, 44 }, sand).material = "Sand"
	for i = 0, 27 do
		local a = math.rad(25 + i * 310 / 28)
		local b = math.rad(25 + (i + 1) * 310 / 28)
		rod(
			kit,
			"Excavated pit lip",
			{ math.sin(a) * 22, 0.5, math.cos(a) * 19 },
			{ math.sin(b) * 22, 0.5, math.cos(b) * 19 },
			0.8,
			paleSand
		).material =
			"Sand"
		local rim = kit:ball(
			"Packed sand pit edge",
			{ math.sin(a) * 21, 1, math.cos(a) * 18 },
			{ 3, 2, 3 },
			sandShadow
		)
		rim.material = "Sand"
	end
	for i = -2, 2 do
		local breadth = math.sqrt(1 - (i / 2.8) ^ 2)
		local slab = kit:ball(
			"Lifted rounded rock lobe",
			lifted({ i * 8, 4.5, 0 }),
			{ 13, 13 * breadth, 38 * breadth },
			{ rock[1] + i * 3, rock[2] + i * 2, rock[3] + i * 2 }
		)
		slab.rotation = { -62, 0, 0 }
		slab.material = "Slate"
	end
	for i = 0, 39 do
		local a, b = i * math.pi / 20, (i + 1) * math.pi / 20
		rod(
			kit,
			"Brass lid rim",
			lifted({ math.sin(a) * 21, 0, math.cos(a) * 18 }),
			lifted({ math.sin(b) * 21, 0, math.cos(b) * 18 }),
			0.55,
			brass
		).material =
			"Metal"
		if i % 2 == 0 then
			local rivet = kit:ball(
				"Lid rim rivet",
				lifted({ math.sin(a) * 20.5, -0.4, math.cos(a) * 17.5 }),
				{ 0.65, 0.65, 0.65 },
				paleSand
			)
			rivet.material = "Metal"
		end
	end
	for i = 1, 18 do
		local x = (i * 13 % 31) - 15
		local z = (i * 7 % 23) - 11
		local patch = kit:ball(
			"Weathered rose stone patch",
			lifted({ x, 10.1 - math.abs(x) * 0.08, z }),
			{ 2 + i % 3, 0.35, 1.5 + i % 2 },
			{ 166 + i % 3 * 5, 100 + i % 4 * 4, 83 + i % 2 * 4 }
		)
		patch.rotation = { -62, 0, 0 }
		patch.collide = false
	end
	kit:cylinder("Continuous brass hinge barrel", { 0, 1.6, -18 }, { 23, 2.4, 2.4 }, brass, { 0, 0, 0 }).material =
		"Metal"
	for _, x in { -9, -3, 3, 9 } do
		kit:cylinder("Hinge knuckle", { x, 1.6, -18 }, { 2.2, 2.8, 2.8 }, sandShadow, { 0, 0, 0 }).material =
			"Metal"
	end
	for _, sign in { -1, 1 } do
		rod(kit, "Lid support stay", { sign * 17, 1.4, -6 }, lifted({ sign * 17, 0, 4 }), 0.45, brass).material =
			"Metal"
		kit:ball("Rock entrance cheek", { sign * 13, 4, 10 }, { 9, 8, 9 }, rock).material = "Slate"
		kit:light({ sign * 10, 5, 14 }, { 255, 214, 152 }, 18)
		for i = 1, 4 do
			kit:ball(
				"Scattered beach pebble",
				{ sign * (23 + i % 2 * 3), 0.4, -10 + i * 7 },
				{ 1.6 + i * 0.2, 0.8, 1.4 },
				{ 169 + i * 7, 124 + i * 6, 94 + i * 4 }
			)
		end
	end
	kit:cylinder("Driftwood mailbox post", { -27, 3, 18 }, { 6, 0.8, 0.8 }, sandShadow).material = "Wood"
	kit:part("Mailbox tray", { -27, 6.1, 18 }, { 4, 0.4, 5 }, dark)
	kit:ball("Rounded coral mailbox", { -27, 7, 18 }, { 4.3, 3, 5 }, pink)
	kit:part("Mailbox dark opening", { -27, 6.8, 20.45 }, { 2.8, 1.5, 0.12 }, dark)
	kit:part("Mailbox flag stalk", { -24.7, 8, 18 }, { 0.3, 3, 0.4 }, brass)
	kit:part("Mailbox flag", { -24, 9.2, 18 }, { 1.6, 0.9, 0.4 }, pink)
	flower(kit, { -27, 7, 20.6 }, 0.65, purple)
	kit:label("120 CONCH STREET", { -27, 10.7, 18 }, paleSand)
	return kit
end

local function sandRoom(): Kit
	local kit = WorldKit.new("patrick", Config.Zones.patrick.origin)
	kit:room(96, 88, 26, sand, paleSand, false)
	for _, part in kit.parts do
		if part.name == "Floor" or string.find(part.name, "wall") then
			part.material = "Sand"
		elseif part.name == "Ceiling" then
			part.material = "Slate"
			part.color = rock
		end
	end
	for level = 0, 4 do
		local y = 2.2 + level * 4.8
		local color = if level % 2 == 0 then paleSand else sandShadow
		rod(kit, "Back wall sand stratum", { -47, y, -43.1 }, { 47, y + 0.5, -43.1 }, 0.16, color)
		for _, sign in { -1, 1 } do
			rod(
				kit,
				"Side wall sand stratum",
				{ sign * 47.1, y, -43 },
				{ sign * 47.1, y + 0.4, 43 },
				0.18,
				color
			)
			rod(
				kit,
				"Split entrance sand stratum",
				{ sign * 7.5, y, 43.1 },
				{ sign * 47, y + 0.5, 43.1 },
				0.16,
				color
			)
		end
	end
	for _, sign in { -1, 1 } do
		kit:ball("Rounded entrance jamb", { sign * 8.5, 8, 43.1 }, { 3, 16, 2 }, paleSand)
		kit:light({ sign * 10, 17.5, 41 }, { 255, 218, 160 }, 22)
	end
	kit:ball("Sand entrance arch crown", { 0, 20.5, 43.3 }, { 20, 6, 2.3 }, paleSand)
	for i = 0, 8 do
		local x = -44 + i * 11
		rod(kit, "Overhead brass rock rib", { x, 25, -41 }, { x, 25, 41 }, 0.22, brass)
	end
	for i = 0, 7 do
		kit:part(
			"Right-hand descent wall relief",
			{ 11.5 + i * 2.3, 19.5 - i * 1.3, 42.8 },
			{ 2.2, 0.5, 0.35 },
			sandShadow
		).collide =
			false
	end
	rod(kit, "Descent motif handrail", { 10.5, 22, 42.5 }, { 30, 11, 42.5 }, 0.2, brass).collide = false
	return kit
end

local function livingRoom(kit: Kit)
	kit:sofa({ -28, 0, -4 }, sand)
	for _, x in { -33.3, -28, -22.7 } do
		kit:ball("Sculpted sand sofa cushion", { x, 4.2, -3 }, { 5, 1.8, 6.3 }, paleSand)
		kit:ball("Sofa back cushion", { x, 6.3, -6 }, { 5.1, 4.7, 1.6 }, paleSand)
		for i = 0, 2 do
			kit:ball(
				"Sofa pressed sand seam",
				{ x - 1.5 + i * 1.5, 4.9, 0 },
				{ 0.25, 0.18, 0.35 },
				sandShadow
			)
		end
	end
	local cushion = kit:ball("Sea-green pillow", { -33, 6.7, -4.6 }, { 3.7, 3.6, 1.4 }, green)
	cushion.rotation = { 0, 0, 12 }
	flower(kit, { -33, 6.8, -3.8 }, 1.1, purple)
	kit:table({ -28, 0, 9 }, sandShadow)
	kit:cylinder("Sand coffee table rolled edge", { -28, 5.1, 9 }, { 0.9, 10.6, 10.6 }, paleSand)
	kit:ball("Table pedestal sand foot", { -28, 0.9, 9 }, { 5.6, 1.8, 5.6 }, sand)
	kit:cylinder("Shell coaster", { -30, 5.65, 9 }, { 0.12, 2.4, 2.4 }, pink)
	kit:cylinder("Sand drink cup", { -30, 6.5, 9 }, { 1.6, 1.6, 1.6 }, sand)
	rod(kit, "Bent drinking straw", { -30, 7.2, 9 }, { -30.4, 8.1, 9 }, 0.09, purple)
	kit:ball("Rolled armchair seat", { -14, 2.2, -16 }, { 8, 4, 8 }, sand)
	kit:ball("Rolled armchair back", { -14, 5.8, -19 }, { 8, 7, 2.7 }, paleSand)
	for _, x in { -18.2, -9.8 } do
		kit:ball("Armchair scroll arm", { x, 4.5, -16 }, { 2.2, 3.5, 8 }, paleSand)
		kit:ball("Armchair spiral end", { x, 4.5, -11.9 }, { 1.2, 1.5, 0.2 }, sandShadow)
	end
	kit:part("Sand television pedestal", { -29, 2, 26 }, { 14, 4, 6 }, sand)
	kit:ball("Rounded CRT cabinet", { -29, 8, 26 }, { 14, 9, 6.5 }, sandShadow)
	kit:part("CRT face surround", { -29, 8, 22.8 }, { 12.4, 7.3, 0.6 }, paleSand)
	kit:ball("Bulging television glass", { -30.5, 8.3, 22.35 }, { 8.5, 5.4, 0.9 }, { 83, 136, 144 }).material =
		"Glass"
	kit:ball("CRT screen reflection", { -32.9, 9.5, 21.9 }, { 1.1, 1.8, 0.12 }, { 167, 207, 192 }).collide =
		false
	for i = 0, 1 do
		kit:cylinder(
			"CRT tuning knob",
			{ -24.5, 9.4 - i * 2.6, 22.05 },
			{ 0.7, 1.3, 1.3 },
			brass,
			{ 0, 90, 0 }
		)
		kit:part("Tuning knob notch", { -24.5, 9.7 - i * 2.6, 21.66 }, { 0.13, 0.6, 0.1 }, dark)
	end
	for i = 0, 4 do
		kit:part("CRT speaker slot", { -24.6 + i * 0.38, 5.9, 22.35 }, { 0.13, 0.9, 0.15 }, dark)
	end
	kit:ball("Rabbit ears antenna socket", { -29, 12.2, 26 }, { 2.5, 1.5, 2 }, brass)
	for _, sign in { -1, 1 } do
		rod(kit, "Rabbit ear antenna", { -29, 12.8, 26 }, { -29 + sign * 4, 17, 26 }, 0.12, dark)
		kit:ball("Antenna pearl", { -29 + sign * 4, 17, 26 }, { 0.65, 0.65, 0.65 }, paleSand)
	end
	kit:ball("TV sand fish silhouette", { -30.4, 8.2, 21.8 }, { 2.7, 1.5, 0.15 }, green).collide = false
	local tail = kit:part("TV fish tail", { -28.7, 8.2, 21.8 }, { 1.4, 1.4, 0.16 }, pink, "Wedge")
	tail.rotation = { 0, 90, 0 }
	tail.collide = false
	kit:ball("TV fish eye", { -31.2, 8.5, 21.65 }, { 0.22, 0.22, 0.12 }, dark).collide = false
	kit:cylinder("Telephone table top", { -41, 4.6, -8 }, { 0.7, 6.5, 6.5 }, paleSand)
	kit:cylinder("Telephone table stem", { -41, 2.2, -8 }, { 4.4, 2, 2 }, sand)
	kit:ball("Rotary phone base", { -41, 5.7, -8 }, { 4.8, 1.8, 3.3 }, sandShadow)
	kit:cylinder("Rotary dial plate", { -41, 6.5, -7.7 }, { 0.18, 2.1, 2.1 }, brass)
	for i = 0, 9 do
		local angle = i * math.pi / 5
		kit:cylinder(
			"Rotary dial finger hole",
			{ -41 + math.sin(angle) * 0.74, 6.61, -7.7 + math.cos(angle) * 0.74 },
			{ 0.08, 0.32, 0.32 },
			dark
		)
	end
	rod(kit, "Phone receiver bridge", { -43, 7.3, -9 }, { -39, 7.3, -9 }, 0.45, sand)
	for _, x in { -43, -39 } do
		kit:ball("Telephone receiver cup", { x, 7, -9 }, { 1.6, 1.4, 1.7 }, paleSand)
	end
	for i = 0, 17 do
		local a, b = i * math.pi / 2, (i + 1) * math.pi / 2
		rod(
			kit,
			"Coiled telephone cord",
			{ -43.4 + math.cos(a) * 0.25, 6.8 - i * 0.15, -8.6 + math.sin(a) * 0.25 },
			{ -43.4 + math.cos(b) * 0.25, 6.8 - (i + 1) * 0.15, -8.6 + math.sin(b) * 0.25 },
			0.08,
			dark
		).collide =
			false
	end
	kit:cylinder("Plant sand pot", { -41, 2, 32 }, { 4, 5, 5 }, sandShadow)
	kit:cylinder("Plant pot rolled rim", { -41, 4, 32 }, { 0.8, 5.5, 5.5 }, paleSand)
	for i = 0, 5 do
		local angle = i * math.pi / 3
		local x, z = -41 + math.cos(angle) * 2, 32 + math.sin(angle) * 2
		rod(kit, "Plant curved stem", { -41, 4, 32 }, { x, 8 + i % 2, z }, 0.16, green)
		local leaf = kit:ball("Rounded sea plant frond", { x, 9 + i % 2, z }, { 1.6, 4.5, 1 }, green)
		leaf.rotation = { math.sin(angle) * 30, 0, -math.cos(angle) * 30 }
	end
	ring(kit, "Jellyfishing net hoop", { -42, 10, 9 }, 3, 3.6, 0.18, brass)
	for i = -2, 2 do
		local halfHeight = 3.3 * math.sqrt(1 - (i / 3) ^ 2)
		rod(
			kit,
			"Net vertical mesh",
			{ -42 + i, 10 - halfHeight, 9.05 },
			{ -42 + i, 10 + halfHeight, 9.05 },
			0.035,
			paleSand
		).collide =
			false
		rod(kit, "Net cross mesh", { -44.3, 10 + i, 9.05 }, { -39.7, 10 + i, 9.05 }, 0.035, paleSand).collide =
			false
	end
	rod(kit, "Jellyfishing net handle", { -42, 1, 9 }, { -42, 6.5, 9 }, 0.23, sandShadow).secret =
		"patrick-pink-purloiner-net"
	for i = 0, 4 do
		kit:cylinder("Net handle binding", { -42, 2 + i * 0.4, 9 }, { 0.15, 0.6, 0.6 }, pink)
	end
end

local function kitchen(kit: Kit)
	for _, x in { 13, 43 } do
		kit:ball("Sand kitchen arch pier", { x, 7, -15 }, { 4, 14, 4 }, paleSand)
		kit:ball("Arch pier foot", { x, 1, -15 }, { 5, 2, 5 }, sandShadow)
	end
	for i = 0, 13 do
		local a, b = i * math.pi / 14, (i + 1) * math.pi / 14
		rod(
			kit,
			"Sculpted kitchen arch",
			{ 28 + math.cos(a) * 15, 14 + math.sin(a) * 8, -15 },
			{ 28 + math.cos(b) * 15, 14 + math.sin(b) * 8, -15 },
			1.5,
			paleSand
		).material =
			"Sand"
	end
	for _, x in { 17, 25, 33 } do
		kit:part("Sand kitchen cabinet", { x, 3.6, -38 }, { 7.7, 7.2, 8 }, sand)
		kit:part("Inset cupboard door", { x, 3.6, -33.85 }, { 6.6, 5.7, 0.35 }, sandShadow)
		kit:part("Cupboard raised panel", { x, 3.6, -33.6 }, { 5.6, 4.7, 0.3 }, paleSand)
		kit:ball("Cupboard shell pull", { x + 2, 4.8, -33.25 }, { 0.7, 0.9, 0.65 }, brass)
	end
	kit:part("Continuous sand countertop", { 25, 7.6, -38 }, { 25, 1, 8.7 }, paleSand)
	kit:ball("Countertop rounded front", { 25, 7.6, -33.6 }, { 25, 1, 1 }, paleSand)
	kit:part("Stove cooktop", { 17, 8.2, -38 }, { 6.8, 0.25, 6.5 }, sandShadow)
	for _, x in { 15.3, 18.7 } do
		for _, z in { -39.6, -36.4 } do
			kit:cylinder("Stove sand burner", { x, 8.4, z }, { 0.18, 2.3, 2.3 }, dark)
			kit:cylinder("Burner brass center", { x, 8.52, z }, { 0.12, 1.2, 1.2 }, brass)
		end
	end
	kit:part("Oven inset window", { 17, 3.8, -33.35 }, { 4.6, 2.8, 0.15 }, dark)
	rod(kit, "Oven handle", { 14.8, 5.7, -32.9 }, { 19.2, 5.7, -32.9 }, 0.2, brass)
	for i = 0, 3 do
		kit:cylinder("Stove control", { 14.9 + i * 1.4, 6.8, -33.35 }, { 0.3, 0.7, 0.7 }, brass, { 0, 90, 0 })
	end
	kit:ball("Sand kettle", { 15.3, 9.5, -39.6 }, { 2.7, 2.2, 2.7 }, paleSand)
	kit:cylinder("Kettle lid", { 15.3, 10.6, -39.6 }, { 0.2, 2, 2 }, brass)
	kit:ball("Kettle knob", { 15.3, 10.95, -39.6 }, { 0.55, 0.55, 0.55 }, dark)
	rod(kit, "Kettle spout", { 16.3, 9.6, -39.6 }, { 17.5, 10.6, -39.6 }, 0.3, paleSand)
	ring(kit, "Kettle handle", { 14.9, 10.5, -39.6 }, 1.2, 1.8, 0.12, dark)
	kit:part("Sink dark well", { 25, 8.18, -38 }, { 5.7, 0.1, 5.2 }, sandShadow)
	for _, x in { 22, 28 } do
		rod(kit, "Sink rolled side", { x, 8.3, -40.8 }, { x, 8.3, -35.2 }, 0.2, paleSand)
	end
	for _, z in { -40.8, -35.2 } do
		rod(kit, "Sink rolled edge", { 22, 8.3, z }, { 28, 8.3, z }, 0.2, paleSand)
	end
	rod(kit, "Faucet riser", { 25, 8.2, -41 }, { 25, 11.1, -41 }, 0.22, brass)
	rod(kit, "Faucet neck", { 25, 11.1, -41 }, { 25, 11.1, -38.8 }, 0.22, brass)
	rod(kit, "Faucet spout", { 25, 11.1, -38.8 }, { 25, 10.5, -38.8 }, 0.22, brass)
	for _, x in { 23.5, 26.5 } do
		kit:ball("Shell tap", { x, 8.8, -41 }, { 1.1, 0.7, 0.8 }, pink)
	end
	kit:part("Refrigerator sand body", { 41.5, 8, -35.5 }, { 9, 16, 12 }, paleSand)
	kit:ball("Rounded refrigerator crown", { 41.5, 15.7, -35.5 }, { 9, 2, 12 }, paleSand)
	kit:part("Open refrigerator cavity", { 41.5, 8, -29.35 }, { 7.8, 13.8, 0.35 }, sandShadow)
	for i = 0, 2 do
		kit:part("Refrigerator display shelf", { 41.5, 3 + i * 4, -28.5 }, { 7.5, 0.35, 1.9 }, paleSand)
		for j = 0, 2 do
			local food = kit:ball(
				"Refrigerated sand food",
				{ 39 + j * 2.4, 4.1 + i * 4, -28.35 },
				{ 1.7, 1.6 + j % 2 * 0.6, 1.4 },
				{ 216 + i * 5, 178 + j * 7, 122 + i * 8 }
			)
			food.material = "Sand"
		end
	end
	kit:part("Refrigerator open door", { 46, 8, -25.4 }, { 0.8, 15, 8 }, sand)
	rod(kit, "Fridge door handle", { 45.4, 7, -22.6 }, { 45.4, 11, -22.6 }, 0.24, brass)
	for _, y in { 4, 9 } do
		kit:part("Fridge door bottle rack", { 45.3, y, -25.3 }, { 1, 0.6, 5.6 }, paleSand)
		kit:cylinder("Sand bottle", { 44.8, y + 1.4, -25.3 }, { 2.5, 1.2, 1.2 }, sandShadow)
	end
	kit:table({ 30, 0, 0 }, sand)
	kit:cylinder("Sand feast tabletop rim", { 30, 5.3, 0 }, { 0.5, 10.7, 10.7 }, paleSand)
	kit:cylinder("Sand dinner plate", { 30, 5.65, 0 }, { 0.18, 4.3, 4.3 }, sandShadow)
	kit:ball("Sand burger lower bun", { 30, 6.1, 0 }, { 3.1, 0.8, 3 }, sand)
	kit:ball("Sand burger patty", { 30, 6.6, 0 }, { 3, 0.5, 2.9 }, sandShadow)
	kit:part("Sand burger cheese", { 30, 6.85, 0 }, { 3.2, 0.15, 3.2 }, paleSand, nil, "Sand", { 0, 16, 0 })
	local burger = kit:ball("Impossible sand feast", { 30, 7.4, 0 }, { 3.2, 1, 3.1 }, sand)
	burger.material = "Sand"
	burger.secret = "patrick-sand-feast"
	for i = 0, 6 do
		kit:ball(
			"Sand bun sesame seed",
			{ 29.2 + i % 3 * 0.7, 7.9, -0.7 + math.floor(i / 3) * 0.55 },
			{ 0.16, 0.1, 0.32 },
			paleSand
		)
	end
	kit:part("Sand sandwich slice", { 33, 6, -1 }, { 2, 0.5, 2 }, paleSand, "Wedge")
	for i = 0, 3 do
		kit:ball(
			"Fake fruit bowl fruit",
			{ 32 + i % 2, 8.7 + math.floor(i / 2) * 0.5, -38 + i % 3 },
			{ 1.3, 1.3, 1.3 },
			sand
		)
	end
	kit:cylinder("Fruit bowl rim", { 32.5, 8.3, -37.5 }, { 0.25, 4.4, 4.4 }, sandShadow)
	kit:light({ 28, 20, -25 }, { 255, 219, 159 }, 30)
end

local function sleepingNook(kit: Kit)
	kit:part("Sand bed plinth", { -30, 1.5, -32 }, { 17, 3, 19 }, sand)
	kit:ball("Soft sand mattress", { -30, 3.5, -32 }, { 18, 4, 20 }, paleSand)
	kit:ball("Scalloped sand headboard", { -30, 6, -41 }, { 19, 9, 3 }, sandShadow)
	kit:part("Green sleeping blanket", { -30, 5, -28 }, { 16.8, 0.35, 10 }, green)
	kit:part("Blanket foot drape", { -30, 3.6, -22.8 }, { 16.8, 3, 0.35 }, green)
	for _, x in { -35, -30, -25 } do
		flower(kit, { x, 3.8, -22.55 }, 0.9, purple)
	end
	for _, x in { -34, -26 } do
		kit:ball("Sand bed pillow", { x, 5.5, -37 }, { 7, 2, 4 }, paleSand)
	end
	kit:cylinder("Secret box bedside pedestal", { -42, 2.5, -23 }, { 5, 5.8, 5.8 }, sand)
	kit:part("Secret box", { -42, 6.2, -23 }, { 4, 2.5, 3 }, { 146, 110, 86 }, nil, "Wood")
	kit:part("Secret box lid", { -42, 7.65, -23 }, { 4.3, 0.5, 3.3 }, { 176, 135, 105 }, nil, "Wood")
	for _, x in { -43.2, -40.8 } do
		kit:part("Secret box brass band", { x, 6.3, -21.45 }, { 0.3, 2.6, 0.12 }, brass)
		kit:part("Secret box lid band", { x, 7.94, -23 }, { 0.3, 0.1, 3.3 }, brass)
	end
	local latch = kit:ball("Secret box clasp", { -42, 6.8, -21.2 }, { 0.7, 0.9, 0.35 }, brass)
	latch.secret = "patrick-secret-box"
	latch.collide = false
	rod(kit, "Secret box loose string", { -41.2, 7.8, -21.2 }, { -40, 5.6, -20.9 }, 0.07, paleSand).collide =
		false
	kit:cylinder("Nook lamp pedestal", { -18, 3, -36 }, { 6, 4, 4 }, sandShadow)
	kit:ball("Scallop bedside lampshade", { -18, 9.4, -36 }, { 6, 4.5, 3 }, pink)
	for i = 0, 4 do
		rod(
			kit,
			"Scallop lamp rib",
			{ -18, 7.8, -34.5 },
			{ -20 + i, 10.5 - math.abs(i - 2) * 0.45, -34.5 },
			0.1,
			paleSand
		)
	end
	kit:light({ -18, 8.5, -34.8 }, { 255, 186, 161 }, 24)
	kit:ball("Family portrait oval sand frame", { -29, 18.2, -42.5 }, { 19, 10.5, 1 }, sandShadow)
	kit:ball("Family portrait rose inset", { -29, 18.2, -41.9 }, { 17.5, 9.2, 0.4 }, { 211, 159, 143 })
	for i = 0, 2 do
		local x = -34.2 + i * 5.2
		local y = if i == 1 then 17.8 else 18.5
		local scale = if i == 1 then 0.8 else 1
		kit:ball("Family star torso relief", { x, y, -41.55 }, { 2.3 * scale, 3 * scale, 0.35 }, pink)
		for j = 0, 4 do
			local angle = j * math.pi * 2 / 5
			rod(
				kit,
				"Family star ray",
				{ x, y, -41.5 },
				{ x + math.sin(angle) * 1.9 * scale, y + math.cos(angle) * 2.3 * scale, -41.5 },
				0.5 * scale,
				pink
			).collide =
				false
		end
		for _, dx in { -0.4, 0.4 } do
			kit:ball("Portrait eye", { x + dx * scale, y + 0.7 * scale, -41.12 }, { 0.25, 0.4, 0.15 }, dark).collide =
				false
		end
		kit:ball("Portrait smile", { x, y - 0.15, -41.1 }, { 0.6, 0.2, 0.1 }, dark).collide = false
	end
	flower(kit, { -43, 17.5, -42.7 }, 2, paleSand)
	flower(kit, { -14, 19.5, -42.7 }, 2.8, sandShadow)
end

local function bathroom(kit: Kit)
	kit:part("Bathroom sand partition", { 33, 8.5, 15 }, { 29, 17, 1.2 }, sand)
	for _, z in { 18.5, 39.5 } do
		kit:part("Bathroom opening side", { 19, 8.5, z }, { 1.2, 17, 7 }, sand)
		kit:ball(
			"Bathroom doorway rolled edge",
			{ 19, 8, if z < 29 then 21.2 else 36.8 },
			{ 1.8, 16, 1.5 },
			paleSand
		)
	end
	kit:part("Bathroom opening lintel", { 19, 19, 29 }, { 1.2, 4, 14 }, sand)
	rod(kit, "Bathroom curtain rail", { 19, 20, 20.5 }, { 19, 20, 37.5 }, 0.2, brass)
	for _, side in { -1, 1 } do
		for i = 0, 3 do
			kit:cylinder(
				"Gathered pink curtain fold",
				{ 18.3, 12, 29 + side * (8.3 + i * 0.45) },
				{ 14, 0.65, 0.65 },
				if i % 2 == 0 then pink else { 218, 131, 150 }
			).collide =
				false
		end
	end
	kit:ball("Sand toilet pedestal", { 40, 1.9, 22 }, { 4.7, 3.8, 5.5 }, sand)
	kit:ball("Toilet rounded bowl", { 40, 4, 22.6 }, { 6.5, 3.6, 8 }, paleSand)
	kit:cylinder("Toilet seat shadow", { 40, 5.6, 22.6 }, { 0.15, 4.7, 4.7 }, sandShadow)
	kit:cylinder("Toilet seat inner basin", { 40, 5.71, 22.6 }, { 0.12, 3.3, 3.3 }, { 159, 184, 164 })
	kit:part("Toilet cistern", { 40, 6, 18.5 }, { 6.5, 7, 2.5 }, sand)
	kit:ball("Cistern lid", { 40, 9.4, 18.5 }, { 7, 0.9, 3 }, paleSand)
	kit:ball("Toilet raised lid", { 40, 8.6, 20 }, { 5.4, 5, 0.8 }, paleSand)
	rod(kit, "Toilet flush handle", { 43.3, 8.5, 18.5 }, { 43.3, 8.5, 20 }, 0.22, brass)
	kit:cylinder("Sand washstand", { 29, 3, 18.8 }, { 6, 3.5, 3.5 }, sand)
	kit:ball("Sand washbasin", { 29, 6.5, 18.8 }, { 8, 2.6, 5.4 }, paleSand)
	kit:ball("Washbasin hollow", { 29, 7.7, 19 }, { 5.5, 0.12, 3.5 }, sandShadow)
	rod(kit, "Washbasin faucet", { 29, 7.2, 17 }, { 29, 9, 17 }, 0.2, brass)
	rod(kit, "Washbasin spout", { 29, 9, 17 }, { 29, 9, 18.5 }, 0.2, brass)
	ring(kit, "Oval mirror shell frame", { 29, 12.6, 15.9 }, 3.6, 3.2, 0.3, pink)
	kit:ball("Polished shell mirror", { 29, 12.6, 16 }, { 6.6, 5.8, 0.25 }, { 175, 218, 215 }).material =
		"Glass"
	rod(kit, "Mirror glint", { 27, 12.6, 16.2 }, { 28.2, 14.2, 16.2 }, 0.13, paleSand).collide = false
	kit:part("Bathroom shell shelf", { 34, 9.7, 16.8 }, { 4, 0.5, 2.8 }, paleSand)
	for i = 0, 17 do
		local a, b = i * math.pi / 9, (i + 1) * math.pi / 9
		local segment = rod(
			kit,
			"Donut of Shame dough",
			{ 34 + math.cos(a), 11.3 + math.sin(a), 17.2 },
			{ 34 + math.cos(b), 11.3 + math.sin(b), 17.2 },
			0.5,
			{ 211, 149, 85 }
		)
		segment.collide = false
		if i == 0 then
			segment.secret = "patrick-donut-of-shame"
		end
		rod(
			kit,
			"Donut pink frosting",
			{ 34 + math.cos(a), 11.3 + math.sin(a), 17.55 },
			{ 34 + math.cos(b), 11.3 + math.sin(b), 17.55 },
			0.3,
			pink
		).collide =
			false
		if i % 2 == 0 then
			kit:part(
				"Donut sprinkle",
				{ 34 + math.cos(a), 11.3 + math.sin(a), 17.85 },
				{ 0.35, 0.1, 0.12 },
				if i % 4 == 0 then paleSand else green,
				nil,
				nil,
				{ 0, 0, i * 23 }
			).collide =
				false
		end
	end
	rod(kit, "Towel rail", { 43, 9, 37 }, { 46, 9, 37 }, 0.2, brass)
	kit:part("Folded sea-green towel", { 44.5, 7.2, 37 }, { 2.2, 3.6, 0.5 }, green)
	for i = 0, 2 do
		kit:part("Towel stripe", { 44.5, 5.8 + i * 0.3, 37.3 }, { 2.2, 0.12, 0.1 }, purple)
	end
	kit:light({ 34, 21, 28 }, { 255, 208, 186 }, 25)
end

return function(): { WorldKit.Part }
	local outside = exterior()
	local inside = sandRoom()
	livingRoom(inside)
	kitchen(inside)
	sleepingNook(inside)
	bathroom(inside)
	inside:supply({ -17, 2, 34 })
	inside:ball("Supply chest domed lid", { -17, 4, 34 }, { 5, 1.5, 4 }, { 111, 181, 148 })
	for _, x in { -18.6, -15.4 } do
		inside:part("Supply chest brass strap", { x, 2, 36.1 }, { 0.35, 3.7, 0.16 }, brass)
		inside:part("Supply lid brass strap", { x, 4.6, 34 }, { 0.35, 0.12, 3.7 }, brass)
	end
	inside:ball("Supply chest shell clasp", { -17, 2.9, 36.3 }, { 1, 1.2, 0.4 }, paleSand)
	local result: { WorldKit.Part } = {}
	for _, kit in { outside, inside } do
		for _, part in kit.parts do
			table.insert(result, part)
		end
	end
	return result
end
