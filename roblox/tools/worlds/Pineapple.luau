--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../../src/shared/Config")

type Triple = WorldKit.Triple
type Kit = WorldKit.Kit

local C = {
	cream = { 255, 238, 188 },
	brass = { 208, 158, 69 },
	wood = { 155, 100, 49 },
	dark = { 39, 65, 77 },
	blue = { 75, 147, 186 },
	cyan = { 91, 204, 216 },
	red = { 208, 77, 66 },
	green = { 119, 192, 49 },
	pink = { 239, 154, 188 },
}

local function rod(kit: Kit, name: string, a: Triple, b: Triple, diameter: number, color: Triple)
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	local part = kit:cylinder(
		name,
		{ (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		{ length, diameter, diameter },
		color,
		{ 0, math.deg(-math.atan2(dz, dx)), math.deg(math.asin(dy / length)) }
	)
	part.collide = false
	return part
end

local function hoop(
	kit: Kit,
	name: string,
	p: Triple,
	rx: number,
	ry: number,
	thickness: number,
	color: Triple,
	horizontal: boolean?,
	count: number?
)
	local segments = count or 16
	for i = 0, segments - 1 do
		local a, b = i * math.pi * 2 / segments, (i + 1) * math.pi * 2 / segments
		if horizontal then
			rod(
				kit,
				name,
				{ p[1] + math.cos(a) * rx, p[2], p[3] + math.sin(a) * ry },
				{ p[1] + math.cos(b) * rx, p[2], p[3] + math.sin(b) * ry },
				thickness,
				color
			)
		else
			rod(
				kit,
				name,
				{ p[1] + math.cos(a) * rx, p[2] + math.sin(a) * ry, p[3] },
				{ p[1] + math.cos(b) * rx, p[2] + math.sin(b) * ry, p[3] },
				thickness,
				color
			)
		end
	end
end

local function turn(kit: Kit, first: number, pivot: Triple, degrees: number)
	local angle = math.rad(degrees)
	for i = first, #kit.parts do
		local part = kit.parts[i]
		local x = part.position[1] - kit.origin[1] - pivot[1]
		local z = part.position[3] - kit.origin[3] - pivot[3]
		part.position[1] = kit.origin[1] + pivot[1] + x * math.cos(angle) + z * math.sin(angle)
		part.position[3] = kit.origin[3] + pivot[3] - x * math.sin(angle) + z * math.cos(angle)
		part.rotation[2] += degrees
	end
end

local function shell(kit: Kit, p: Triple, scale: number, color: Triple)
	for i = -3, 3 do
		local rib = kit:ball(
			"Scalloped shell rib",
			{ p[1] + i * scale * 0.55, p[2] - math.abs(i) * scale * 0.18, p[3] },
			{ scale * 0.9, scale * 3.2, scale * 0.85 },
			color
		)
		rib.rotation[3] = -i * 13
		rib.collide = false
	end
	kit:ball("Shell hinge", { p[1], p[2] - scale * 1.4, p[3] }, { scale * 2, scale, scale }, C.cream)
end

local function porthole(kit: Kit, p: Triple, radius: number)
	kit:cylinder("Porthole brass bezel", p, { 0.8, radius * 2.25, radius * 2.25 }, C.brass, { 0, 90, 0 })
	kit:cylinder(
		"Deep blue porthole",
		{ p[1], p[2], p[3] + 0.5 },
		{ 0.2, radius * 1.9, radius * 1.9 },
		C.dark,
		{ 0, 90, 0 }
	)
	kit:ball(
		"Turquoise window reflection",
		{ p[1] - radius * 0.2, p[2] + radius * 0.15, p[3] + 0.65 },
		{ radius * 1.2, radius * 1.35, 0.2 },
		{ 92, 209, 230 }
	)
	for i = 0, 7 do
		local a = i * math.pi / 4
		kit:ball(
			"Porthole bolt",
			{ p[1] + math.cos(a) * radius, p[2] + math.sin(a) * radius, p[3] + 0.6 },
			{ 0.4, 0.4, 0.3 },
			C.cream
		)
	end
end

local function doorTrim(kit: Kit, p: Triple, color: Triple, side: boolean?)
	local first = #kit.parts + 1
	for _, sign in { -1, 1 } do
		rod(
			kit,
			"Rounded portal jamb",
			{ p[1] + sign * 7.8, 0.4, p[3] },
			{ p[1] + sign * 7.8, 17.5, p[3] },
			1.1,
			color
		)
		kit:ball("Doorframe shoulder", { p[1] + sign * 7.8, 18.1, p[3] }, { 2, 2, 1.5 }, color)
	end
	rod(kit, "Overhead portal rail", { p[1] - 7.8, 18.5, p[3] }, { p[1] + 7.8, 18.5, p[3] }, 1.2, color)
	shell(kit, { p[1], 21.5, p[3] }, 0.85, C.cream)
	if side then
		turn(kit, first, p, -90)
	end
end

local function room(zone: string, wall: Triple, floor: Triple, side: boolean): Kit
	local kit = WorldKit.new(zone, Config.Zones[zone].origin)
	local height = Config.Zones[zone].size[2]
	kit:room(96, 88, height, wall, floor, side)
	doorTrim(kit, { 0, 0, 43.1 }, C.brass)
	if side then
		doorTrim(kit, { 47.1, 0, 0 }, zone == "sponge" and { 227, 141, 63 } or C.blue, true)
	end
	for _, y in { 1, height - 1.5 } do
		rod(kit, "Back wall molding", { -47, y, -43 }, { 47, y, -43 }, 0.6, C.brass)
		rod(kit, "Left wall molding", { -47, y, -43 }, { -47, y, 43 }, 0.6, C.brass)
		for _, sign in { -1, 1 } do
			rod(kit, "Front molding", { sign * 8.4, y, 43 }, { sign * 47, y, 43 }, 0.6, C.brass)
			if side then
				rod(kit, "Side molding", { 47, y, sign * 8.4 }, { 47, y, sign * 43 }, 0.6, C.brass)
			end
		end
		if not side then
			rod(kit, "Right wall molding", { 47, y, -43 }, { 47, y, 43 }, 0.6, C.brass)
		end
	end
	return kit
end

local function barrel(kit: Kit, p: Triple, height: number, diameter: number)
	kit:cylinder("Barrel cupboard", p, { height, diameter, diameter }, C.wood)
	for _, sign in { -1, 1 } do
		kit:cylinder(
			"Barrel iron hoop",
			{ p[1], p[2] + sign * height * 0.35, p[3] },
			{ 0.4, diameter + 0.2, diameter + 0.2 },
			C.dark
		)
	end
	kit:cylinder(
		"Barrel lid",
		{ p[1], p[2] + height / 2, p[3] },
		{ 0.35, diameter + 0.3, diameter + 0.3 },
		C.brass
	)
end

local function rug(kit: Kit, p: Triple, width: number, depth: number, color: Triple)
	local mat = kit:ball("Flat woven rug", { p[1], 0.08, p[3] }, { width, 0.14, depth }, color)
	mat.material = "Fabric"
	mat.collide = false
	hoop(kit, "Rug braided edging", { p[1], 0.12, p[3] }, width * 0.43, depth * 0.43, 0.1, C.cream, true, 20)
	for x = -3, 3 do
		rod(
			kit,
			"Rug woven stripe",
			{ p[1] + x * width / 10, 0.15, p[3] - depth * 0.3 },
			{ p[1] + x * width / 10, 0.15, p[3] + depth * 0.3 },
			0.06,
			C.brass
		)
	end
end

local function gary(kit: Kit, p: Triple, scale: number, portrait: boolean)
	kit:ball("Gary turquoise foot", p, { 5 * scale, 0.8 * scale, 2 * scale }, { 115, 214, 203 })
	kit:ball(
		"Gary pink shell",
		{ p[1], p[2] + 1.9 * scale, p[3] },
		{ 3.8 * scale, 3.8 * scale, 1.8 * scale },
		C.pink
	)
	for i = 0, 13 do
		local a, b = i * 0.5, (i + 1) * 0.5
		local ra, rb = (0.1 + i * 0.065) * scale, (0.1 + (i + 1) * 0.065) * scale
		rod(
			kit,
			"Gary shell spiral",
			{ p[1] + math.cos(a) * ra, p[2] + 1.9 * scale + math.sin(a) * ra, p[3] + scale },
			{ p[1] + math.cos(b) * rb, p[2] + 1.9 * scale + math.sin(b) * rb, p[3] + scale },
			0.16 * scale,
			{ 168, 60, 101 }
		)
	end
	for _, sign in { -1, 1 } do
		local x = p[1] + (2 + sign * 0.4) * scale
		rod(kit, "Gary eye stalk", { x, p[2], p[3] }, { x, p[2] + 3.5 * scale, p[3] }, 0.2 * scale, C.cyan)
		kit:ball("Gary golden eye", { x, p[2] + 3.5 * scale, p[3] }, { scale, scale, scale }, C.cream)
		kit:ball(
			"Gary ruby pupil",
			{ x, p[2] + 3.5 * scale, p[3] + 0.5 * scale },
			{ 0.45 * scale, 0.6 * scale, 0.18 * scale },
			C.red
		)
	end
	if not portrait then
		kit:cylinder("Gary food bowl", { p[1] + 5, 0.5, p[3] + 1 }, { 0.8, 3, 3 }, C.brass)
		kit:cylinder("Bowl hollow", { p[1] + 5, 0.94, p[3] + 1 }, { 0.08, 2.4, 2.4 }, C.dark)
		for i = 0, 4 do
			kit:ball(
				"Snail kibble",
				{ p[1] + 4.3 + i % 3 * 0.6, 1.05, p[3] + 0.5 + math.floor(i / 3) * 0.7 },
				{ 0.45, 0.3, 0.45 },
				C.wood
			)
		end
	end
end

local function exterior(): Kit
	local kit = WorldKit.new("street", { 0, 0, 0 })
	local bands = {
		{ y = 4.5, radius = 17.5, height = 9 },
		{ y = 13.5, radius = 20, height = 9 },
		{ y = 23, radius = 20.5, height = 10 },
		{ y = 32, radius = 18, height = 8 },
		{ y = 39, radius = 13, height = 6 },
	}
	for row, band in bands do
		for i = 0, 15 do
			if row > 2 or (i > 1 and i < 15) then
				local a = i * math.pi / 8
				local x, z = math.sin(a) * band.radius, math.cos(a) * band.radius
				local width = 2 * band.radius * math.tan(math.pi / 16) + 0.5
				kit:part(
					"Pineapple segmented rind",
					{ x, band.y, z },
					{ width, band.height + 0.1, 2.8 },
					{ 235 + (i + row) % 3 * 6, 139 + (i * 3 + row) % 4 * 9, 39 },
					nil,
					"SmoothPlastic",
					{ 0, math.deg(a), 0 }
				)
				local first = #kit.parts + 1
				for _, sign in { -1, 1 } do
					rod(
						kit,
						"Golden diamond rind seam",
						{ x - width * 0.47, band.y - sign * band.height * 0.43, z + 1.55 },
						{ x + width * 0.47, band.y + sign * band.height * 0.43, z + 1.55 },
						0.32,
						{ 189, 109, 29 }
					)
				end
				kit:ball("Raised pineapple eye", { x, band.y, z + 1.7 }, { 0.9, 1.4, 0.45 }, C.cream)
				turn(kit, first, { x, band.y, z }, math.deg(a))
			end
		end
	end
	kit:cylinder("Crown collar", { 0, 42.4, 0 }, { 2.7, 24, 24 }, { 146, 170, 46 })
	for i = 0, 8 do
		local a = i * math.pi * 2 / 9
		local reach = 12 + i % 3 * 2.5
		local tip = 56 + i % 3 * 3
		local rise, run = tip - 42, reach - 2
		local length = math.sqrt(rise * rise + run * run)
		local rotation = { 0, math.deg(a) - 90, math.deg(math.atan2(rise, run)) }
		local leaf = kit:ball(
			"Rounded pineapple leaf",
			{ math.sin(a) * (2 + run * 0.43), 42 + rise * 0.43, math.cos(a) * (2 + run * 0.43) },
			{ length * 0.85, 1.8, 5.5 },
			{ 74, 145 + i % 3 * 18, 50 }
		)
		leaf.rotation = { rotation[1], rotation[2], rotation[3] }
		local leafTip = kit:ball(
			"Tapered pineapple leaf tip",
			{ math.sin(a) * (2 + run * 0.83), 42 + rise * 0.83, math.cos(a) * (2 + run * 0.83) },
			{ length * 0.5, 0.9, 2.9 },
			{ 103, 185, 63 }
		)
		leafTip.rotation = { rotation[1], rotation[2], rotation[3] }
		rod(
			kit,
			"Leaf central vein",
			{ math.sin(a) * 2, 42.6, math.cos(a) * 2 },
			{ math.sin(a) * reach, tip + 0.6, math.cos(a) * reach },
			0.45,
			{ 151, 209, 74 }
		)
	end
	for _, sign in { -1, 1 } do
		kit:part("Recessed blue entrance pier", { sign * 9, 8.75, 16 }, { 3.2, 17.5, 5 }, C.blue)
		rod(
			kit,
			"Entrance silver edge",
			{ sign * 7.55, 0.3, 18.7 },
			{ sign * 7.55, 17.6, 18.7 },
			0.6,
			C.cream
		)
	end
	kit:part("Entrance blue overhead", { 0, 19.5, 17 }, { 21.2, 4, 5 }, C.blue)
	for i = 0, 7 do
		local a, b = i * math.pi / 8, (i + 1) * math.pi / 8
		rod(
			kit,
			"Arched nautical doorway crown",
			{ math.cos(a) * 9, 17.5 + math.sin(a) * 3.8, 19.7 },
			{ math.cos(b) * 9, 17.5 + math.sin(b) * 3.8, 19.7 },
			0.9,
			C.cream
		)
	end
	for _, window in
		{
			{ angle = -22.5, radius = 22.2, height = 23, size = 3.6 },
			{ angle = 22.5, radius = 19.7, height = 32, size = 3.3 },
		}
	do
		local angle = math.rad(window.angle)
		local p = { math.sin(angle) * window.radius, window.height, math.cos(angle) * window.radius }
		local first = #kit.parts + 1
		porthole(kit, p, window.size)
		turn(kit, first, p, window.angle)
	end
	rod(kit, "Side exhaust vertical", { 20, 18, -4 }, { 20, 27, -4 }, 2.2, C.blue)
	rod(kit, "Side exhaust elbow", { 20, 27, -4 }, { 24, 27, -4 }, 2.2, C.blue)
	kit:cylinder("Exhaust dark mouth", { 24.1, 27, -4 }, { 0.15, 1.65, 1.65 }, C.dark, { 0, 0, 0 })
	for _, sign in { -1, 1 } do
		for i = 0, 5 do
			kit:ball(
				"Path border sea pebble",
				{ sign * (9.5 + i % 2 * 0.7), 0.4, 23 + i * 2.2 },
				{ 1.5, 0.8, 1.6 },
				{ 185, 183 + i % 2 * 12, 149 }
			)
		end
	end
	rod(kit, "Mailbox coral post", { 17, 0, 29 }, { 17, 5, 29 }, 0.9, C.wood)
	kit:ball("Nautical mailbox", { 17, 5.5, 29 }, { 4.5, 3, 3.5 }, C.blue)
	kit:part("Mailbox letter slot", { 17, 5.7, 30.8 }, { 2.5, 0.2, 0.1 }, C.dark)
	rod(kit, "Mailbox flag stem", { 19, 5.5, 29 }, { 19, 8, 29 }, 0.25, C.brass)
	kit:part("Mailbox red flag", { 19.8, 7.7, 29 }, { 1.7, 0.9, 0.15 }, C.red)
	return kit
end

local function livingRoom(): Kit
	local kit = room("sponge", C.cyan, { 224, 209, 167 }, true)
	for x = -44, 44, 4 do
		rod(kit, "Cyan bamboo wall stalk", { x, 1, -42.9 }, { x, 25, -42.9 }, 0.55, { 59, 175, 190 })
		for _, y in { 7, 15, 23 } do
			kit:cylinder("Bamboo joint", { x, y, -42.9 }, { 0.23, 0.8, 0.8 }, { 144, 224, 215 })
		end
	end
	for z = -36, 36, 8 do
		rod(kit, "Left bamboo panel", { -46.8, 1, z }, { -46.8, 25, z }, 0.6, { 59, 175, 190 })
	end
	kit:part("Kitchen partition left", { -37, 13, -12 }, { 22, 26, 1.2 }, C.cyan)
	kit:part("Kitchen partition right", { 24, 13, -12 }, { 48, 26, 1.2 }, C.cyan)
	kit:part("Kitchen arch lintel", { -13, 23, -12 }, { 26, 6, 1.2 }, C.cyan)
	for _, x in { -26, 0 } do
		rod(kit, "Kitchen rounded arch column", { x, 0.5, -10.9 }, { x, 18, -10.9 }, 1.6, C.brass)
	end
	for i = 0, 9 do
		local a, b = i * math.pi / 10, (i + 1) * math.pi / 10
		rod(
			kit,
			"Kitchen broad arch",
			{ -13 + 13 * math.cos(a), 18 + 3 * math.sin(a), -10.9 },
			{ -13 + 13 * math.cos(b), 18 + 3 * math.sin(b), -10.9 },
			1.6,
			C.brass
		)
	end
	kit:part("Inflatable couch blue plinth", { 17, 1.3, -4 }, { 20, 2.2, 8 }, C.blue)
	for row = 0, 2 do
		kit:cylinder(
			"Green inflatable couch tube",
			{ 17, 3.3 + row * 2.1, -6 },
			{ 20, 2.5, 2.5 },
			C.green,
			{ 0, 0, 0 }
		)
		for _, sign in { -1, 1 } do
			kit:ball(
				"Inflatable couch rounded cap",
				{ 17 + sign * 10, 3.3 + row * 2.1, -6 },
				{ 2.5, 2.5, 2.5 },
				{ 145, 216, 70 }
			)
		end
	end
	for _, x in { 11.5, 22.5 } do
		kit:ball("Air-filled couch seat", { x, 3.3, -2.5 }, { 10.6, 2.8, 6.5 }, C.green)
	end
	for _, x in { 7, 27 } do
		kit:ball("Inflatable couch arm", { x, 5, -2.8 }, { 2.4, 2.7, 8 }, { 145, 216, 70 })
	end
	kit:cylinder("Couch air valve", { 28.1, 3.8, -2 }, { 0.6, 0.8, 0.8 }, C.brass, { 0, 0, 0 })
	rug(kit, { 17, 0, 13 }, 24, 18, { 184, 169, 113 })
	kit:table({ 17, 0, 12 }, C.wood)
	kit:cylinder("Tea saucer", { 17, 5.6, 12 }, { 0.15, 2, 2 }, C.cream)
	kit:cylinder("Tea cup", { 17, 6.2, 12 }, { 1, 1.3, 1.3 }, C.pink)
	hoop(kit, "Cup handle", { 17.8, 6.3, 12 }, 0.5, 0.45, 0.15, C.pink, false, 8)
	for _, x in { -33, -27 } do
		rod(kit, "Lifebuoy chair wooden foot", { x, 0.2, 8 }, { x, 3, 8 }, 0.8, C.wood)
	end
	kit:ball("Red lifebuoy chair back", { -30, 7, 5 }, { 9, 10, 2.8 }, C.red)
	kit:ball("Lifebuoy chair back cushion", { -30, 7, 6.5 }, { 7, 7.5, 1.2 }, { 228, 101, 74 })
	kit:ball("Lifebuoy chair seat", { -30, 3.3, 8 }, { 7, 1.7, 6 }, C.red)
	hoop(kit, "Chair white life ring", { -30, 4, 8 }, 4.2, 3.4, 1.5, C.cream, true, 16)
	for _, sign in { -1, 1 } do
		kit:ball("Red life ring binding", { -30 + sign * 4.2, 4, 8 }, { 1.6, 1.7, 2.5 }, C.red)
		kit:ball("Red chair arm", { -30 + sign * 4, 5.8, 8 }, { 1.8, 2, 6 }, C.red)
	end
	kit:cylinder("Diving helmet TV pedestal", { -22, 1.5, 29 }, { 3, 9, 9 }, C.wood)
	local first = #kit.parts + 1
	kit:ball("Brass diving helmet television", { -22, 6.5, 29 }, { 11, 10, 8.5 }, C.brass)
	porthole(kit, { -22, 7, 32.7 }, 3.3)
	for _, sign in { -1, 1 } do
		kit:cylinder(
			"Helmet side valve",
			{ -22 + sign * 5.8, 6.5, 29 },
			{ 1.7, 2.5, 2.5 },
			C.dark,
			{ 0, 0, 0 }
		)
	end
	rod(kit, "Television aerial", { -22, 11, 29 }, { -25, 15, 29 }, 0.25, C.dark)
	rod(kit, "Television aerial", { -22, 11, 29 }, { -19, 15, 29 }, 0.25, C.dark)
	turn(kit, first, { -22, 0, 29 }, 180)
	barrel(kit, { -38, 2.5, -3 }, 5, 4.8)
	shell(kit, { -38, 7, -3 }, 0.8, { 176, 136, 191 })
	kit:ball("Shell telephone receiver", { -38, 6, -1.8 }, { 3.7, 1, 1.4 }, { 125, 107, 164 })
	for i = 0, 7 do
		kit:ball("Telephone coiled cable", { -36.5, 5.9 - i * 0.45, -1.8 }, { 0.5, 0.5, 0.5 }, C.dark)
	end
	kit:part("Gary portrait wooden frame", { 11, 15.8, -10.8 }, { 9, 10, 0.7 }, C.wood)
	kit:part("Gary portrait blue inset", { 11, 15.8, -10.35 }, { 7.8, 8.8, 0.2 }, { 119, 185, 192 })
	gary(kit, { 10.4, 13.4, -9.9 }, 1.05, true)
	kit:ball("Striped fishing lure body", { 27, 17, -10.5 }, { 10, 2.5, 1.4 }, C.cream)
	for x = 24, 30, 2 do
		kit:ball("Fishing lure red stripe", { x, 17, -9.85 }, { 0.7, 2.1, 0.25 }, C.red)
	end
	for i = -2, 2 do
		rod(kit, "Lure feather tail", { 22.5, 17, -10 }, { 19.8, 17 + i * 0.65, -9.9 }, 0.16, C.dark)
	end
	hoop(kit, "Fishing lure hook", { 32.8, 16, -10.2 }, 1, 1, 0.18, C.dark, false, 10)
	kit:secret("pineapple-striped-lure", "The striped lure", { 32, 6, -8.5 }, C.cream)

	kit:part("Cream porthole refrigerator", { -37, 7.8, -35 }, { 9, 15.6, 9 }, C.cream)
	kit:ball("Refrigerator rounded top", { -37, 15.4, -35 }, { 9, 2, 9 }, C.cream)
	porthole(kit, { -37, 10, -30.2 }, 2.4)
	rod(kit, "Refrigerator brass handle", { -33.9, 4, -30.1 }, { -33.9, 7.3, -30.1 }, 0.5, C.brass)
	kit:ball("Potbelly stove", { -22, 4.7, -36 }, { 9, 8.5, 8 }, { 72, 102, 115 })
	kit:cylinder("Stove iron hotplate", { -22, 8.4, -36 }, { 0.6, 9, 9 }, C.dark)
	kit:ball("Stove firebox", { -22, 4.8, -31.9 }, { 5, 3.5, 0.3 }, C.dark)
	for _, x in { -23.5, -22, -20.5 } do
		rod(kit, "Stove door grille", { x, 3.5, -31.6 }, { x, 6, -31.6 }, 0.25, C.brass)
	end
	rod(kit, "Crooked stove pipe lower", { -22, 9, -38 }, { -22, 17, -38 }, 1.8, C.dark)
	rod(kit, "Crooked stove pipe elbow", { -22, 17, -38 }, { -18, 19, -38 }, 1.8, C.dark)
	rod(kit, "Crooked stove pipe upper", { -18, 19, -38 }, { -18, 25, -38 }, 1.8, C.dark)
	kit:ball("Stovetop kettle", { -24, 10, -34 }, { 3.4, 3, 3.4 }, C.red)
	hoop(kit, "Kettle handle", { -24, 11.7, -34 }, 1.2, 1, 0.25, C.dark, false, 10)
	rod(kit, "Kettle spout", { -22.5, 10, -34 }, { -21.3, 11.3, -34 }, 0.6, C.red)
	for _, x in { -7, 4, 15, 26 } do
		barrel(kit, { x, 3.7, -37 }, 7.4, 8)
		kit:ball("Cupboard knob", { x, 4, -32.9 }, { 0.7, 0.7, 0.7 }, C.cream)
	end
	kit:part("Kitchen continuous worktop", { 9.5, 7.8, -37 }, { 42, 0.8, 9 }, C.cream)
	kit:cylinder("Bucket sink rim", { 6, 8.3, -36 }, { 0.6, 6, 6 }, C.blue)
	kit:cylinder("Bucket sink hollow", { 6, 8.65, -36 }, { 0.1, 4.9, 4.9 }, C.dark)
	rod(kit, "Bucket sink tap", { 6, 8.2, -39 }, { 6, 12, -39 }, 0.5, C.brass)
	rod(kit, "Bucket sink tap spout", { 6, 12, -39 }, { 6, 12, -36.5 }, 0.5, C.brass)
	kit:part("Bread board", { 23, 8.4, -35.5 }, { 5, 0.35, 3 }, C.wood)
	kit:ball("Cartoon bread loaf", { 23, 9.2, -35.5 }, { 3.8, 1.6, 2.4 }, { 224, 163, 76 })
	for i = 0, 2 do
		rod(kit, "Bread score", { 22 + i, 10, -36 }, { 22.5 + i, 10, -35 }, 0.13, C.cream)
	end
	kit:table({ 21, 0, -21 }, C.brass)
	for _, x in { 14, 28 } do
		kit:ball("Shell dining chair cushion", { x, 2.9, -21 }, { 4.3, 1.2, 4.3 }, C.blue)
		shell(kit, { x, 6, -23 }, 1.2, { 227, 179, 149 })
		for _, sign in { -1, 1 } do
			rod(
				kit,
				"Bamboo dining chair leg",
				{ x + sign * 1.4, 0.2, -21 },
				{ x + sign * 1.4, 3, -21 },
				0.5,
				C.brass
			)
		end
	end
	shell(kit, { 37, 19, -41.8 }, 1.5, C.pink)
	kit:light({ 37, 17, -39.5 }, { 255, 211, 155 }, 22)
	kit:supply({ 34, 2, 27 })
	kit:ball("Supply chest domed lid", { 34, 4, 27 }, { 5, 1.3, 4 }, { 112, 191, 158 })
	for _, x in { 32.3, 35.7 } do
		kit:part("Supply chest brass strap", { x, 2.2, 29.05 }, { 0.45, 3.8, 0.2 }, C.brass)
	end
	kit:part("Supply chest latch", { 34, 3, 29.2 }, { 1, 1.4, 0.3 }, C.cream)
	return kit
end

local function library(): Kit
	local kit = room("spongeLibrary", { 86, 153, 159 }, { 97, 130, 57 }, true)
	for i = -3, 3 do
		local a = i * 0.34
		local x, z = math.sin(a) * 39, -math.cos(a) * 36
		local first = #kit.parts + 1
		kit:bookshelf({ x, 0.5, z }, 11.5, C.wood)
		for _, sign in { -1, 1 } do
			rod(
				kit,
				"Curved stack bamboo upright",
				{ x + sign * 6, 0.4, z + 2 },
				{ x + sign * 6, 23, z + 2 },
				0.75,
				C.brass
			)
		end
		shell(kit, { x, 21, z + 1 }, 1.2, { 198, 188, 140 })
		for tier = 0, 2 do
			for book = 1, 8, 2 do
				kit:part(
					"Book spine gilt band",
					{ x - 5.75 + book * 1.35, 2 + tier * 5, z + 2.55 },
					{ 0.8, 0.16, 0.12 },
					C.cream
				)
			end
		end
		turn(kit, first, { x, 0, z }, -math.deg(a))
	end
	rug(kit, { -10, 0, 3 }, 23, 24, { 181, 164, 115 })
	kit:ball("Hanging chair green seat", { -10, 3.6, 3 }, { 10, 2.8, 9 }, C.green)
	kit:ball("Hanging chair rounded back", { -10, 7.3, -0.3 }, { 10, 9, 2.7 }, { 142, 186, 58 })
	for _, sign in { -1, 1 } do
		rod(
			kit,
			"Hanging chair wicker arm",
			{ -10 + sign * 4.7, 5, 6 },
			{ -10 + sign * 4.7, 7.5, -0.2 },
			0.6,
			C.brass
		)
		rod(kit, "Hanging chair suspension", { -10 + sign * 4.5, 5.5, 5 }, { -10, 24.5, 1.5 }, 0.18, C.cream)
	end
	hoop(kit, "Hanging chair ceiling loop", { -10, 25, 1.5 }, 0.8, 0.8, 0.3, C.brass, false, 10)
	rod(kit, "Hanging chair ceiling tether", { -10, 25.8, 1.5 }, { -10, 27.9, 1.5 }, 0.25, C.brass)
	barrel(kit, { -23, 2.4, 2 }, 4.8, 4.5)
	kit:part("Open book left pages", { -24, 5.2, 2 }, { 2, 0.4, 3 }, C.cream, nil, nil, { 0, 0, -10 })
	kit:part("Open book right pages", { -22, 5.2, 2 }, { 2, 0.4, 3 }, C.cream, nil, nil, { 0, 0, 10 })
	for i = 0, 3 do
		kit:part("Open book ink lines", { -23.9, 5.55, 1.2 + i * 0.5 }, { 1.3, 0.03, 0.08 }, C.blue)
	end

	kit:part("Organ carved cabinet", { -31, 3, 29 }, { 13, 6, 7 }, C.wood, nil, "Wood")
	kit:ball("Organ rounded keyboard ledge", { -31, 6, 32 }, { 14, 1.5, 5 }, C.brass)
	for i = 0, 14 do
		kit:part("Organ ivory key", { -37 + i * 0.84, 6.9, 32.2 }, { 0.77, 0.25, 2.8 }, C.cream)
		if i % 7 ~= 2 and i % 7 ~= 6 then
			kit:part("Organ ebony key", { -36.6 + i * 0.84, 7.15, 31.4 }, { 0.38, 0.35, 1.5 }, C.dark)
		end
	end
	for i = 0, 2 do
		local x, h = -35 + i * 4, 15 + i * 3
		rod(kit, "Bent organ pipe upright", { x, 5.5, 27 }, { x, h, 27 }, 1.8, { 124, 163, 158 })
		kit:ball("Organ pipe rounded elbow", { x, h, 27 }, { 1.9, 1.9, 1.9 }, { 124, 163, 158 })
		rod(kit, "Bent organ pipe mouth", { x, h, 27 }, { x + 1.8, h, 29 }, 1.8, { 124, 163, 158 })
		kit:ball("Organ pipe dark opening", { x + 1.85, h, 29.5 }, { 1.35, 1.35, 0.2 }, C.dark)
		kit:cylinder("Organ pipe brass cuff", { x, 10, 27 }, { 0.7, 2, 2 }, C.brass)
	end
	kit:ball("Organ bench upholstered seat", { -31, 3, 36.5 }, { 10, 1.5, 3.5 }, { 167, 94, 83 })
	for _, x in { -35, -27 } do
		rod(kit, "Organ bench foot", { x, 0.2, 36.5 }, { x, 3, 36.5 }, 0.9, C.wood)
	end
	kit:secret("pineapple-three-pipe-organ", "Three bent organ pipes", { -23, 4, 32 }, C.brass)

	kit:ball("Conch fireplace hearth", { 28, 0.8, 30 }, { 19, 1.6, 12 }, { 199, 178, 133 })
	kit:ball("Conch fireplace shadow", { 28, 5, 30.5 }, { 11, 8.5, 2 }, C.dark)
	for i = 0, 8 do
		local a = i * math.pi / 8
		local rib = kit:ball(
			"Conch fireplace fluted rim",
			{ 28 + math.cos(a) * 6.5, 2 + math.sin(a) * 10, 30 },
			{ 2.8, 5, 4.5 },
			{ 214 - i % 3 * 9, 195 - i % 3 * 7, 150 }
		)
		rib.rotation[3] = math.deg(a) - 90
	end
	for i = -1, 1 do
		local coal = kit:ball("Pearl hearth glow", { 28 + i * 2.5, 2.3, 32 }, { 2, 2.7, 2 }, { 247, 177, 87 })
		coal.material = "Neon"
	end
	kit:light({ 28, 5, 33 }, { 255, 183, 105 }, 24)
	kit:ball("Oval jellyfish portrait frame", { 30, 19, 42.5 }, { 11.5, 14, 0.8 }, C.brass)
	kit:ball("Oval jellyfish portrait field", { 30, 19, 41.9 }, { 10, 12.5, 0.3 }, { 84, 135, 180 })
	kit:ball("Portrait jellyfish bell", { 30, 21, 41.5 }, { 6.5, 4, 0.6 }, C.pink)
	for i = -2, 2 do
		rod(
			kit,
			"Portrait jellyfish tentacle",
			{ 30 + i, 20, 41.1 },
			{ 30 + i * 1.4, 16.6, 41.1 },
			0.3,
			{ 252, 203, 209 }
		)
		rod(
			kit,
			"Portrait curled tentacle",
			{ 30 + i * 1.4, 16.6, 41.1 },
			{ 31 + i * 1.4, 15.5, 41.1 },
			0.3,
			{ 252, 203, 209 }
		)
	end
	for _, x in { 28, 31.5 } do
		kit:ball("Jellyfish bell spot", { x, 21.5, 41.1 }, { 1, 1, 0.15 }, { 185, 84, 153 })
	end
	for _, z in { -9, 9 } do
		rod(kit, "Slide passage handrail", { 32, 3.4, z }, { 47, 3.4, z }, 0.7, C.blue)
		for _, x in { 33, 45 } do
			rod(kit, "Slide passage rail post", { x, 0.3, z }, { x, 3.4, z }, 0.6, C.blue)
		end
	end
	rod(kit, "Overhead slide tube upper", { 30, 25, -22 }, { 39, 22, -12 }, 3.2, { 152, 201, 213 })
	rod(kit, "Overhead slide tube bend", { 39, 22, -12 }, { 46, 21, -8 }, 3.2, { 152, 201, 213 })
	kit:part("Slide route floor inlay", { 39, 0.04, 0 }, { 12, 0.06, 9 }, { 134, 173, 161 }).collide = false
	return kit
end

local function bedroom(): Kit
	local kit = room("spongeBedroom", { 87, 151, 177 }, { 211, 206, 176 }, false)
	kit:part("Red woven bed wall", { -18, 13, -43.25 }, { 57, 26, 0.2 }, { 181, 78, 72 })
	for x = -44, 8, 4 do
		kit:part("Red wall vertical weave", { x, 13, -43.05 }, { 0.14, 25, 0.1 }, { 219, 114, 94 })
	end
	for y = 2, 24, 2 do
		kit:part("Red wall horizontal weave", { -18, y, -42.95 }, { 57, 0.12, 0.1 }, { 224, 136, 109 })
	end
	for z = -38, 38, 8 do
		kit:part("Blue wall panel seam", { 47.2, 13, z }, { 0.15, 24, 0.18 }, { 60, 111, 141 })
		for _, y in { 2, 12, 24 } do
			kit:ball("Blue panel rivet", { 46.9, y, z }, { 0.45, 0.5, 0.5 }, { 177, 210, 215 })
		end
	end
	for _, x in { -29, -15 } do
		for _, z in { -33, -17 } do
			kit:ball("Bed rounded wooden foot", { x, 1.4, z }, { 2.1, 2.8, 2.1 }, C.wood)
		end
	end
	kit:part("Bed blue platform", { -22, 2.5, -25 }, { 18, 2, 23 }, C.blue)
	for i = 0, 1 do
		kit:ball("Bed stacked cream mattress", { -22, 4 + i * 1.6, -25 }, { 18.3, 2.5, 23 }, C.cream)
	end
	kit:part(
		"Purple flower blanket",
		{ -22, 6.4, -21 },
		{ 18.1, 0.5, 13.8 },
		{ 137, 104, 169 },
		nil,
		"Fabric"
	)
	kit:ball("Plump white pillow", { -22, 7, -32 }, { 13, 2.8, 5.2 }, { 255, 248, 218 })
	for _, x in { -29, -15 } do
		rod(kit, "Bed headboard post", { x, 1, -36 }, { x, 12, -36 }, 1, C.brass)
	end
	hoop(kit, "Headboard life ring", { -22, 11, -36 }, 6.1, 5.2, 1.7, C.cream, false, 20)
	for _, sign in { -1, 1 } do
		kit:ball("Headboard red life ring binding", { -22 + sign * 6.1, 11, -36 }, { 1.8, 3, 2 }, C.red)
		kit:ball("Headboard red life ring binding", { -22, 11 + sign * 5.2, -36 }, { 3, 1.8, 2 }, C.red)
	end
	for _, flower in { { -27, -24 }, { -18, -20 }, { -26, -16.5 } } do
		for petal = 0, 4 do
			local a = petal * math.pi * 2 / 5
			kit:ball(
				"Blanket five-petal flower",
				{ flower[1] + math.cos(a) * 1.1, 6.7, flower[2] + math.sin(a) * 1.1 },
				{ 1.7, 0.16, 1.7 },
				{ 242, 177, 179 }
			)
		end
		kit:ball("Blanket flower center", { flower[1], 6.8, flower[2] }, { 1.1, 0.18, 1.1 }, C.cream)
	end
	rug(kit, { -22, 0, -5 }, 20, 8, { 155, 121, 167 })
	barrel(kit, { -39, 3, -28 }, 6, 5.5)
	rod(kit, "Foghorn alarm neck", { -39, 6.2, -28 }, { -39, 9, -28 }, 1.1, C.brass)
	for i = 0, 4 do
		kit:cylinder(
			"Foghorn flared bell",
			{ -39, 9, -28 + i * 0.75 },
			{ 0.9, 1.5 + i * 0.75, 1.5 + i * 0.75 },
			C.brass,
			{ 0, 90, 0 }
		)
	end
	kit:cylinder("Foghorn dark opening", { -39, 9, -24.5 }, { 0.12, 3.5, 3.5 }, C.dark, { 0, 90, 0 })
	hoop(kit, "Foghorn polished lip", { -39, 9, -24.35 }, 2.2, 2.2, 0.25, C.cream, false, 16)
	kit:secret("pineapple-foghorn-alarm", "Foghorn alarm", { -38, 5, -22 }, C.brass)
	local first = #kit.parts + 1
	porthole(kit, { -46.5, 15, -9 }, 4.5)
	turn(kit, first, { -46.5, 15, -9 }, 90)
	gary(kit, { -28, 0.7, 20 }, 1.4, false)
	rug(kit, { -28, 0, 20 }, 12, 9, { 156, 188, 134 })
	kit:secret("pineapple-garys-corner", "Gary's cozy corner", { -29, 3.8, 26 }, C.pink)
	kit:part("Gary toy block", { -36, 0.8, 22 }, { 1.6, 1.6, 1.6 }, C.blue, nil, nil, { 0, 18, 0 })
	kit:ball("Gary toy ball", { -36, 1, 18 }, { 2, 2, 2 }, C.red)

	kit:part("Bathroom partition", { 12, 13, -27 }, { 1.2, 26, 34 }, { 155, 200, 201 })
	kit:part("Bathroom front left pier", { 16, 13, -10 }, { 8, 26, 1.2 }, { 155, 200, 201 })
	kit:part("Bathroom front right pier", { 44, 13, -10 }, { 8, 26, 1.2 }, { 155, 200, 201 })
	kit:part("Bathroom arch overhead", { 30, 23, -10 }, { 20, 6, 1.2 }, { 155, 200, 201 })
	for _, x in { 20, 40 } do
		rod(kit, "Bathroom arch column", { x, 0.3, -9 }, { x, 19, -9 }, 1, C.blue)
	end
	for i = 0, 7 do
		local a, b = i * math.pi / 8, (i + 1) * math.pi / 8
		rod(
			kit,
			"Bathroom shell arch",
			{ 30 + math.cos(a) * 10, 19 + math.sin(a) * 2.4, -9 },
			{ 30 + math.cos(b) * 10, 19 + math.sin(b) * 2.4, -9 },
			1,
			C.blue
		)
	end
	for x = 16, 44, 4 do
		for z = -40, -16, 4 do
			kit:part(
				"Bathroom checker tile",
				{ x, 0.04, z },
				{ 3.9, 0.06, 3.9 },
				(x + z) % 8 == 0 and { 188, 224, 219 } or { 128, 184, 196 }
			).collide =
				false
		end
	end
	for _, x in { 19, 28 } do
		for _, z in { -37, -29 } do
			kit:ball("Bathtub claw foot", { x, 1, z }, { 1.5, 2, 1.5 }, C.brass)
		end
	end
	kit:ball("Bathtub enamel body", { 23.5, 3.6, -33 }, { 13, 6, 17 }, C.cream)
	kit:ball("Bathtub inset bowl", { 23.5, 6.15, -33 }, { 10.8, 0.4, 14.5 }, C.blue)
	kit:ball("Bathtub still water", { 23.5, 6.4, -33 }, { 9.6, 0.15, 13 }, { 121, 218, 226 }).collide = false
	rod(kit, "Tub shower riser", { 23.5, 6, -41 }, { 23.5, 18, -41 }, 0.55, C.brass)
	rod(kit, "Tub shower elbow", { 23.5, 18, -41 }, { 23.5, 18, -37 }, 0.55, C.brass)
	kit:ball("Scallop shower rose", { 23.5, 17.8, -37 }, { 3, 1, 3 }, C.brass)
	kit:ball("Rubber duck body", { 22, 6.9, -30 }, { 2, 1.2, 1.5 }, { 255, 217, 66 })
	kit:ball("Rubber duck head", { 22, 7.8, -29.5 }, { 1, 1, 1 }, { 255, 217, 66 })
	kit:part("Rubber duck bill", { 22, 7.7, -28.9 }, { 0.6, 0.3, 0.7 }, { 239, 135, 45 })
	for _, x in { 21.6, 22.4 } do
		kit:ball("Rubber duck eye", { x, 7.9, -29.2 }, { 0.15, 0.15, 0.15 }, C.dark)
	end
	barrel(kit, { 39, 3.5, -37 }, 7, 6)
	kit:ball("Bathroom bucket washbasin", { 39, 7.5, -37 }, { 7.5, 2, 6 }, C.cream)
	kit:ball("Washbasin hollow", { 39, 8.4, -37 }, { 5, 0.15, 4 }, C.blue)
	rod(kit, "Washbasin faucet", { 39, 7.9, -40 }, { 39, 10.6, -40 }, 0.45, C.brass)
	rod(kit, "Washbasin spout", { 39, 10.6, -40 }, { 39, 10.6, -38 }, 0.45, C.brass)
	porthole(kit, { 39, 16, -42.4 }, 3.6)
	kit:cylinder("Toilet pedestal", { 39, 1.8, -21 }, { 3.6, 3.4, 3.4 }, C.cream)
	kit:ball("Toilet rounded bowl", { 39, 3.3, -21 }, { 5.5, 3.5, 7 }, C.cream)
	kit:ball("Toilet blue seat", { 39, 4.9, -21 }, { 5.5, 0.6, 7 }, C.blue)
	kit:ball("Toilet hollow", { 39, 5.23, -20.6 }, { 3.4, 0.12, 4.5 }, C.dark)
	kit:part("Toilet cistern", { 39, 6.3, -25.1 }, { 5.5, 5.5, 2 }, C.cream)
	kit:ball("Toilet flush handle", { 41, 7, -23.9 }, { 0.8, 0.4, 0.4 }, C.brass)
	rod(kit, "Bath towel rail", { 14, 11, -21 }, { 14, 11, -15 }, 0.45, C.brass)
	kit:part("Folded striped bath towel", { 14, 8.8, -18 }, { 0.35, 4.4, 4 }, C.pink, nil, "Fabric")
	for _, z in { -19, -17 } do
		kit:part("Towel cream stripe", { 14.2, 8.8, z }, { 0.08, 4.4, 0.25 }, C.cream)
	end

	for _, x in { 26, 32 } do
		rod(kit, "Rooftop ladder upright", { x, 0.3, 39 }, { x, 24.7, 39 }, 0.7, C.brass)
	end
	for y = 2, 24, 2 do
		rod(kit, "Rooftop ladder rung", { 26, y, 39 }, { 32, y, 39 }, 0.6, C.blue)
	end
	kit:part("Closed rooftop hatch frame", { 29, 25.35, 39 }, { 10, 0.5, 8 }, C.brass)
	kit:part("Rooftop hatch inset", { 29, 25, 39 }, { 8.5, 0.3, 6.5 }, C.blue)
	rod(kit, "Hatch pull handle", { 27.5, 24.5, 39 }, { 30.5, 24.5, 39 }, 0.5, C.cream)
	shell(kit, { -13, 19, 42 }, 1.6, C.pink)
	kit:light({ -13, 18, 39.7 }, { 255, 203, 169 }, 24)
	return kit
end

return function(): { WorldKit.Part }
	local result: { WorldKit.Part } = {}
	for _, kit in { exterior(), livingRoom(), library(), bedroom() } do
		for _, part in kit.parts do
			table.insert(result, part)
		end
	end
	return result
end
