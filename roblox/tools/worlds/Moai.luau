--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../../src/shared/Config")

type Kit = WorldKit.Kit
type Triple = WorldKit.Triple
type Portrait = "tophat" | "mosaic" | "geometric" | "relief" | "bold"

local stoneLight = { 135, 179, 193 }
local stoneDark = { 69, 105, 129 }
local brass = { 206, 173, 92 }
local bamboo = { 182, 145, 77 }
local ink = { 39, 55, 68 }
local cream = { 247, 226, 181 }
local jade = { 121, 185, 172 }
local blue = { 79, 145, 187 }

local function rod(kit: Kit, name: string, a: Triple, b: Triple, diameter: number, color: Triple)
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	return kit:cylinder(
		name,
		{ (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		{ length, diameter, diameter },
		color,
		{ 0, -math.deg(math.atan2(dz, dx)), math.deg(math.atan2(dy, math.sqrt(dx * dx + dz * dz))) }
	)
end

local function bambooPole(kit: Kit, x: number, z: number, height: number, color: Triple)
	kit:cylinder("Bamboo upright", { x, height / 2, z }, { height, 0.65, 0.65 }, color)
	for y = 2, height - 1, 6 do
		kit:cylinder("Bamboo node", { x, y, z }, { 0.22, 0.85, 0.85 }, brass)
	end
end

local function shellLamp(kit: Kit, x: number, y: number, z: number, standing: boolean)
	if standing then
		kit:cylinder("Shell lamp foot", { x, 0.35, z }, { 0.7, 4, 4 }, brass)
		kit:cylinder("Shell lamp stem", { x, y / 2, z }, { y, 0.6, 0.6 }, bamboo)
	end
	kit:ball("Scallop hinge", { x, y, z }, { 2, 1.4, 1.5 }, brass)
	for rib = -3, 3 do
		local angle = math.rad(rib * 19)
		local petal = kit:ball(
			"Scallop lamp rib",
			{ x + math.sin(angle) * 1.65, y + math.cos(angle) * 1.65, z },
			{ 1.2, 4.5, 1.5 },
			if rib % 2 == 0 then cream else { 235, 198, 162 }
		)
		petal.rotation = { 0, 0, -rib * 19 }
		petal.collide = false
	end
	kit:light({ x, y + 1, z + 1.2 }, { 255, 220, 160 }, 26)
end

local function chair(kit: Kit, x: number, z: number, color: Triple)
	kit:ball("Rounded bamboo chair cushion", { x, 3.2, z }, { 6, 1.4, 5.5 }, color)
	for _, side in { -1, 1 } do
		bambooPole(kit, x + side * 2.5, z - 2.2, 9, blue)
		bambooPole(kit, x + side * 2.5, z + 2.2, 3.2, blue)
		rod(kit, "Chair arm", { x + side * 2.7, 5, z - 2 }, { x + side * 2.7, 5, z + 2.2 }, 0.6, blue)
	end
	for y = 5, 9, 2 do
		rod(kit, "Chair back rail", { x - 2.5, y, z - 2.2 }, { x + 2.5, y, z - 2.2 }, 0.65, blue)
	end
end

local function rug(kit: Kit, x: number, z: number, width: number, depth: number)
	kit:ball("Oval woven rug border", { x, 0.065, z }, { width, 0.13, depth }, { 144, 124, 90 })
	kit:ball("Oval woven rug", { x, 0.12, z }, { width - 1.5, 0.12, depth - 1.5 }, { 202, 205, 139 })
	for _, side in { -1, 1 } do
		for offset = -4, 4, 2 do
			rod(
				kit,
				"Rug tassel",
				{ x + side * (width / 2 - 0.4), 0.08, z + offset },
				{ x + side * (width / 2 + 0.8), 0.08, z + offset },
				0.12,
				cream
			).collide =
				false
		end
	end
end

local function room(kit: Kit, wall: Triple, floor: Triple, height: number, sideDoor: boolean)
	kit:room(96, 88, height, wall, floor, sideDoor)
	for _, part in kit.parts do
		if part.name == "Ceiling" then
			part.color = { 98, 145, 192 }
		end
	end
	kit:part("Back cornice", { 0, height - 1, -43 }, { 95, 1.1, 1.5 }, brass)
	kit:part("Back skirting", { 0, 1, -43 }, { 95, 1.3, 1.2 }, bamboo)
	for _, side in { -1, 1 } do
		kit:part("Side cornice", { side * 47, height - 1, 0 }, { 1.4, 1.1, 86 }, brass)
		kit:part("Front cornice", { side * 27.5, height - 1, 43 }, { 39, 1.1, 1.5 }, brass)
		kit:part("Front skirting", { side * 27.5, 1, 43 }, { 39, 1.3, 1.2 }, bamboo)
		bambooPole(kit, side * 7.8, 43, 18, brass)
		for z = -36, 36, 12 do
			if side == -1 or not sideDoor or math.abs(z) > 7 then
				bambooPole(kit, side * 46.9, z, height - 2, bamboo)
			end
		end
		for x = 14, 42, 14 do
			bambooPole(kit, side * x, -42.9, height - 2, bamboo)
		end
	end
	for step = 0, 8 do
		local angle = math.pi * step / 8
		kit:ball(
			"Arched entrance molding",
			{ math.cos(angle) * 7.8, 18 + math.sin(angle) * 4.5, 43 },
			{ 1.8, 1.5, 1.5 },
			brass
		)
	end
	kit:part("Left skirting", { -47, 1, 0 }, { 1.2, 1.3, 86 }, bamboo)
	if sideDoor then
		for _, side in { -1, 1 } do
			kit:part("Split right skirting", { 47, 1, side * 27.5 }, { 1.2, 1.3, 39 }, bamboo)
			bambooPole(kit, 46.8, side * 7.8, 18, brass)
		end
		kit:part("Nautical passage header", { 46.8, 19, 0 }, { 1.4, 2.2, 16.5 }, stoneDark)
		for z = -6, 6, 3 do
			kit:ball("Passage brass rivet", { 45.95, 19, z }, { 0.4, 0.4, 0.4 }, brass)
		end
	else
		kit:part("Right skirting", { 47, 1, 0 }, { 1.2, 1.3, 86 }, bamboo)
	end
	for x = -39, 39, 13 do
		for z = -36, 36, 24 do
			kit:part(
				"Parquet inlay",
				{ x, 0.018, z },
				{ 7.8, 0.035, 0.16 },
				if (x + z) % 2 == 0 then { 154, 117, 137 } else { 192, 158, 165 },
				nil,
				"Wood",
				{ 0, if z % 24 == 0 then 35 else -35, 0 }
			).collide =
				false
		end
	end
end

local function portrait(
	kit: Kit,
	x: number,
	y: number,
	z: number,
	scale: number,
	style: Portrait,
	yaw: number,
	secret: string?
)
	local art = WorldKit.new(kit.zone, { 0, 0, 0 })
	if style == "relief" or style == "tophat" then
		art:ball("Oval carved portrait frame", { 0, 0, 0 }, { 10, 13, 0.8 }, brass)
		art:ball("Oval portrait ground", { 0, 0, 0.35 }, { 8.8, 11.8, 0.65 }, stoneDark)
	else
		art:part("Gallery frame backing", { 0, 0, 0 }, { 10, 12, 0.5 }, ink, nil, "Wood")
		art:part(
			"Pigmented portrait ground",
			{ 0, 0, 0.32 },
			{ 9, 11, 0.2 },
			if style == "bold" then { 223, 167, 80 } else { 196, 179, 133 }
		)
		for _, side in { -1, 1 } do
			rod(art, "Carved frame rail", { side * 4.9, -6, 0.5 }, { side * 4.9, 6, 0.5 }, 0.55, brass)
			rod(art, "Carved frame rail", { -4.9, side * 6, 0.5 }, { 4.9, side * 6, 0.5 }, 0.55, brass)
			art:ball("Frame corner rosette", { side * 4.9, 6, 0.55 }, { 0.95, 0.95, 0.5 }, cream)
		end
	end
	if style == "mosaic" then
		local tiles = { { 103, 148, 141 }, { 190, 135, 94 }, { 215, 184, 106 }, { 139, 151, 116 } }
		for col = -3, 3 do
			for row = -4, 4 do
				art:part(
					"Mosaic tessera",
					{ col * 1.15, row * 1.15, 0.55 },
					{ 1.03, 1.03, 0.18 },
					tiles[(col * 3 + row) % #tiles + 1]
				)
			end
		end
		art:part(
			"Mosaic rust shoulder",
			{ -0.8, -2.4, 0.85 },
			{ 4, 2.3, 0.25 },
			{ 159, 84, 50 },
			"Wedge",
			nil,
			{ 0, 0, 18 }
		)
		art:part(
			"Mosaic crimson sash",
			{ 0.7, -1, 1 },
			{ 0.8, 7, 0.2 },
			{ 145, 57, 62 },
			nil,
			nil,
			{ 0, 0, 12 }
		)
		art:ball("Mosaic profile", { -0.6, 2.1, 1 }, { 3.2, 3, 0.4 }, jade)
		art:part(
			"Mosaic angular nose",
			{ 1.4, 1.3, 1.15 },
			{ 3.3, 1.2, 0.3 },
			jade,
			"Wedge",
			nil,
			{ 0, 0, -10 }
		)
		art:ball("Mosaic eye", { -0.6, 2.2, 1.3 }, { 0.9, 1.2, 0.15 }, cream)
		art:ball("Mosaic pupil", { -0.4, 2.2, 1.4 }, { 0.3, 0.7, 0.12 }, ink)
	elseif style == "geometric" then
		art:part("Cubist forehead", { -0.5, 1.9, 0.8 }, { 5, 4.3, 0.4 }, jade, "Wedge", nil, { 0, 0, 14 })
		art:part("Cubist cheek", { 1.3, -0.4, 0.9 }, { 3, 4, 0.4 }, blue, "Wedge", nil, { 0, 0, -22 })
		art:part(
			"Cubist nose",
			{ 0.2, -0.7, 1.2 },
			{ 1.5, 4.5, 0.3 },
			{ 169, 197, 148 },
			nil,
			nil,
			{ 0, 0, 28 }
		)
		art:part("Cubist ochre collar", { -0.5, -3.7, 1 }, { 5, 1.8, 0.3 }, brass, "Wedge")
		for _, side in { -1, 1 } do
			art:part(
				"Cubist eye",
				{ side * 1.2, 1.4, 1.25 },
				{ 1.2, 0.8, 0.3 },
				cream,
				nil,
				nil,
				{ 0, 0, side * 18 }
			)
			art:ball("Cubist pupil", { side * 1.2, 1.3, 1.5 }, { 0.3, 0.45, 0.15 }, ink)
		end
		rod(art, "Angular portrait mouth", { -2.2, -2.5, 1.5 }, { 1.7, -3.2, 1.5 }, 0.22, ink)
	elseif style == "bold" then
		art:ball("Bold and Brash sculpted head", { -0.4, 3.1, 0.8 }, { 3.4, 2.8, 0.55 }, jade)
		rod(art, "Dancing torso", { -0.1, 2.3, 0.8 }, { -0.3, -1.8, 0.8 }, 1.6, jade)
		rod(art, "Sweeping left arm", { -0.2, 1.3, 0.8 }, { -3.4, 0, 0.8 }, 0.85, jade)
		rod(art, "Raised right arm", { 0.3, 1.3, 0.8 }, { 2.8, 0.2, 0.8 }, 0.85, jade)
		art:ball("Dancer bent elbow", { 2.8, 0.5, 0.8 }, { 1.2, 1.5, 0.7 }, jade)
		for _, side in { -1, 1 } do
			rod(art, "Dancer leg", { -0.3, -1.4, 0.8 }, { side * 2.8, -4.1, 0.8 }, 1.1, jade)
			art:ball("Dancer foot", { side * 2.8, -4.1, 0.8 }, { 1.7, 0.9, 0.6 }, jade)
		end
		rod(art, "Dancer nose", { 0.3, 3, 1.1 }, { 0.8, 1.7, 1.1 }, 0.48, stoneDark)
	else
		local skin = if style == "relief" then blue else jade
		art:ball(
			"Portrait shoulders",
			{ 0, -3.3, 0.8 },
			{ 5.8, 2, 0.8 },
			if style == "relief" then stoneLight else brass
		)
		art:ball("Portrait neck", { 0, -1.5, 0.8 }, { 2.8, 4.5, 0.8 }, skin)
		art:ball("Sculpted self portrait brow", { 0, 2.5, 0.8 }, { 6.5, 4.4, 1 }, skin)
		for _, side in { -1, 1 } do
			art:ball("Portrait half lidded eye", { side * 1.15, 1, 1.3 }, { 1.7, 2.5, 0.45 }, cream)
			art:ball("Portrait tired pupil", { side * 0.95, 0.65, 1.6 }, { 0.45, 1.1, 0.2 }, { 124, 63, 63 })
			art:ball("Portrait eyelid", { side * 1.15, 1.85, 1.6 }, { 1.85, 1.3, 0.3 }, skin)
		end
		art:ball("Portrait long nose", { 0, -0.3, 1.8 }, { 1.6, 4, 1 }, skin)
		art:ball("Portrait drooping nose tip", { -0.2, -1.6, 1.8 }, { 2.2, 1.6, 1.1 }, skin)
		rod(art, "Portrait dry smile", { -2.2, -2.5, 1.4 }, { 1.9, -2.5, 1.4 }, 0.18, ink)
		if style == "tophat" then
			art:part(
				"Portrait top hat crown",
				{ -0.5, 4.6, 1.2 },
				{ 2.8, 2.7, 0.65 },
				ink,
				nil,
				nil,
				{ 0, 0, 9 }
			)
			art:part("Portrait hat brim", { -0.5, 3.5, 1.5 }, { 4.8, 0.45, 0.8 }, ink, nil, nil, { 0, 0, 9 })
			art:part("Portrait silk hat band", { -0.45, 4, 1.6 }, { 2.9, 0.45, 0.2 }, { 152, 69, 75 })
			for _, side in { -1, 1 } do
				art:ball("Portrait bow tie", { side * 0.8, -3.3, 1.4 }, { 1.5, 0.9, 0.3 }, { 152, 69, 75 })
			end
		else
			for row = 0, 2 do
				rod(
					art,
					"Relief forehead engraving",
					{ -1.9, 2.7 + row * 0.5, 1.35 },
					{ 1.7, 2.7 + row * 0.5, 1.35 },
					0.1,
					stoneLight
				)
			end
		end
	end
	if secret then
		art:ball("Collector's wax seal", { -3.4, -4.3, 1.4 }, { 0.8, 0.8, 0.3 }, brass).secret = secret
	end
	local angle = math.rad(yaw)
	for _, part in art.parts do
		local px, py, pz = part.position[1] * scale, part.position[2] * scale, part.position[3] * scale
		part.position = {
			kit.origin[1] + x + px * math.cos(angle) + pz * math.sin(angle),
			kit.origin[2] + y + py,
			kit.origin[3] + z - px * math.sin(angle) + pz * math.cos(angle),
		}
		part.size = { part.size[1] * scale, part.size[2] * scale, part.size[3] * scale }
		part.rotation[2] += yaw
		part.collide = false
		table.insert(kit.parts, part)
	end
end

local function exterior(): Kit
	local kit = WorldKit.new("street", { 0, 0, 0 })
	local shell, face, shade = { 57, 92, 130 }, { 82, 122, 162 }, { 37, 63, 96 }
	local profiles = {
		{ 0, 22, 16 },
		{ 20, 20, 15 },
		{ 48, 16.5, 13 },
		{ 65, 15, 12 },
		{ 69, 12.5, 10 },
	}
	local function outline(profile: Triple): { Triple }
		local y, w, d = profile[1], profile[2], profile[3]
		local bevel = 4
		return {
			{ -w + bevel, y, d },
			{ w - bevel, y, d },
			{ w, y, d - bevel },
			{ w, y, -d + bevel },
			{ w - bevel, y, -d },
			{ -w + bevel, y, -d },
			{ -w, y, -d + bevel },
			{ -w, y, d - bevel },
		}
	end
	for level = 1, #profiles - 1 do
		local lower, upper = outline(profiles[level]), outline(profiles[level + 1])
		for edge = 1, 8 do
			local nextEdge = edge % 8 + 1
			if level == 1 and edge == 1 then
				kit:quad(
					"Moai left entrance pier",
					lower[1],
					{ -7.5, 0, 16 },
					{ -7.5, 20, 15 },
					upper[1],
					shell,
					"Slate"
				)
				kit:quad(
					"Moai right entrance pier",
					{ 7.5, 0, 16 },
					lower[2],
					upper[2],
					{ 7.5, 20, 15 },
					shell,
					"Slate"
				)
			else
				kit:quad(
					"Tapered blue Moai shell",
					lower[edge],
					lower[nextEdge],
					upper[nextEdge],
					upper[edge],
					shell,
					"Slate"
				)
			end
		end
	end
	local top = outline(profiles[#profiles])
	for edge = 1, 8 do
		kit:triangle("Flattened Moai crown", { 0, 69, 0 }, top[edge], top[edge % 8 + 1], shell, "Slate")
	end
	kit:part("Single heavy Moai brow", { 0, 47, 14.8 }, { 34, 5.5, 7 }, shell, nil, "Slate")
	kit:part("Brow lower shadow", { 0, 44.1, 15 }, { 33, 0.3, 6 }, shade, nil, "Slate")
	kit:quad(
		"Tapered nose face",
		{ -5, 22, 24 },
		{ 5, 22, 24 },
		{ 2.2, 44, 19 },
		{ -2.2, 44, 19 },
		face,
		"Slate"
	)
	kit:quad(
		"Nose left flank",
		{ -5, 22, 14 },
		{ -5, 22, 24 },
		{ -2.2, 44, 19 },
		{ -2.2, 44, 13 },
		shell,
		"Slate"
	)
	kit:quad(
		"Nose right flank",
		{ 5, 22, 24 },
		{ 5, 22, 14 },
		{ 2.2, 44, 13 },
		{ 2.2, 44, 19 },
		shade,
		"Slate"
	)
	kit:quad("Nose lower face", { -5, 22, 14 }, { 5, 22, 14 }, { 5, 22, 24 }, { -5, 22, 24 }, shade, "Slate")
	kit:part("Recess above arched doorway", { 0, 19.7, 14.7 }, { 15, 2, 1 }, shell, nil, "Slate")
	for _, side in { -1, 1 } do
		kit:part("Rectangular Moai ear", { side * 22, 30, 3 }, { 7, 23, 11 }, shade, nil, "Slate")
		kit:part("Moai ear face", { side * 22, 30, 8.7 }, { 5.5, 21, 0.8 }, shell, nil, "Slate")
		kit:cylinder(
			"Eye porthole rim",
			{ side * 9, 39, 15 },
			{ 1.6, 10.3, 10.3 },
			{ 94, 126, 190 },
			{ 0, 90, 0 }
		)
		kit:cylinder("Porthole inner recess", { side * 9, 39, 15.9 }, { 0.3, 7.8, 7.8 }, shade, { 0, 90, 0 })
		kit:cylinder(
			"Deep blue porthole",
			{ side * 9, 39, 16.1 },
			{ 0.2, 6.6, 6.6 },
			{ 82, 177, 209 },
			{ 0, 90, 0 }
		)
		kit:part(
			"Porthole glass reflection",
			{ side * 9 - 0.7, 39.4, 16.24 },
			{ 1, 5, 0.06 },
			{ 149, 213, 230 },
			nil,
			nil,
			{ 0, 0, 24 }
		).collide =
			false
		for bolt = 0, 7 do
			local angle = math.pi * bolt / 4
			kit:ball(
				"Porthole rivet",
				{ side * 9 + math.cos(angle) * 4.5, 39 + math.sin(angle) * 4.5, 16 },
				{ 0.48, 0.48, 0.48 },
				shade
			)
		end
		kit:part(
			"Open wooden door leaf",
			{ side * 7.9, 8.5, 11 },
			{ 0.7, 17, 9 },
			{ 157, 112, 52 },
			nil,
			"WoodPlanks"
		)
		for y = 2, 14, 6 do
			kit:part("Door brass strap", { side * 7.5, y, 11 }, { 0.12, 0.5, 9 }, brass)
		end
		kit:ball("Door knob", { side * 7.4, 8, 7.5 }, { 0.8, 0.8, 0.8 }, brass)
		rod(kit, "Arched doorway upright", { side * 7.5, 0, 16 }, { side * 7.5, 11, 16 }, 0.6, shade)
	end
	for i = 0, 15 do
		local a, b = i * math.pi / 16, (i + 1) * math.pi / 16
		rod(
			kit,
			"Arched doorway stone edge",
			{ 7.5 * math.cos(a), 11 + 7.5 * math.sin(a), 16 },
			{ 7.5 * math.cos(b), 11 + 7.5 * math.sin(b), 16 },
			0.6,
			shade
		)
	end
	return kit
end

local function clarinet(kit: Kit, x: number, z: number)
	kit:cylinder("Clarinet display foot", { x, 0.4, z }, { 0.8, 4, 4 }, brass)
	kit:cylinder("Clarinet flared bell", { x, 1.4, z }, { 1.4, 2.4, 2.4 }, ink)
	kit:cylinder("Clarinet barrel", { x, 4.6, z }, { 5.8, 0.9, 0.9 }, ink)
	for y = 2, 7, 1 do
		kit:cylinder("Clarinet silver joint", { x, y, z }, { 0.15, 1.04, 1.04 }, { 202, 211, 205 })
		kit:ball("Clarinet key", { x + 0.38, y + 0.2, z + 0.45 }, { 0.35, 0.28, 0.3 }, cream)
	end
	rod(kit, "Clarinet mouthpiece", { x, 7.5, z }, { x + 0.3, 8.7, z }, 0.6, ink)
	kit:part("Golden practice reed", { x + 0.28, 8.15, z + 0.36 }, { 0.3, 1.2, 0.12 }, brass).secret =
		"moai-golden-reed"
end

local function kitchen(kit: Kit)
	for _, x in { -35, -23, -11 } do
		kit:part("Rounded cabinet body", { x, 3.5, -36 }, { 10.5, 7, 8 }, { 144, 157, 102 }, nil, "Wood")
		kit:ball("Cabinet counter edge", { x, 7.2, -36 }, { 11.5, 1.2, 8.6 }, cream)
		for _, side in { -1, 1 } do
			kit:part(
				"Cabinet inset door",
				{ x + side * 2.5, 3.5, -31.85 },
				{ 4.5, 5.4, 0.35 },
				{ 177, 184, 125 }
			)
			kit:ball("Cabinet shell pull", { x + side * 0.8, 4, -31.5 }, { 0.7, 0.5, 0.5 }, brass)
		end
	end
	kit:ball("Sink brass rim", { -23, 7.8, -36 }, { 6.5, 0.5, 5 }, brass)
	kit:ball("Sink dark basin", { -23, 7.98, -36 }, { 5.4, 0.3, 4 }, stoneDark)
	rod(kit, "Faucet riser", { -23, 7.8, -38 }, { -23, 10, -38 }, 0.6, brass)
	rod(kit, "Faucet spout", { -23, 10, -38 }, { -23, 10, -36 }, 0.6, brass)
	for _, x in { -37, -33 } do
		for _, z in { -38, -34 } do
			kit:cylinder("Stove burner", { x, 7.9, z }, { 0.25, 2.4, 2.4 }, ink)
		end
	end
	kit:cylinder("Teakettle", { -35, 8.9, -36 }, { 2.2, 2.3, 2.3 }, { 147, 180, 160 })
	kit:ball("Kettle lid", { -35, 10, -36 }, { 2.5, 0.6, 2.5 }, brass)
	rod(kit, "Kettle spout", { -34, 9, -36 }, { -32.9, 9.8, -36 }, 0.5, brass)
	kit:part("Porthole refrigerator", { 33, 8, -36 }, { 10, 16, 9 }, { 173, 201, 182 })
	kit:ball("Rounded refrigerator cap", { 33, 16, -36 }, { 10, 2.8, 9 }, { 173, 201, 182 })
	kit:part("Refrigerator door seam", { 33, 6, -31.35 }, { 9, 0.2, 0.2 }, stoneDark)
	kit:cylinder("Refrigerator porthole rim", { 33, 11, -31.2 }, { 0.5, 5.5, 5.5 }, brass, { 0, 90, 0 })
	kit:cylinder("Refrigerator porthole", { 33, 11, -30.85 }, { 0.2, 4.3, 4.3 }, stoneDark, { 0, 90, 0 })
	rod(kit, "Refrigerator handle", { 29.3, 7.5, -30.8 }, { 29.3, 11.5, -30.8 }, 0.5, cream)
	for _, side in { -1, 1 } do
		bambooPole(kit, side * 9.5, -23, 18, brass)
		kit:part("Kitchen arch shoulder", { side * 29, 21, -23 }, { 38, 4, 1.2 }, { 182, 192, 133 })
	end
	for step = 0, 10 do
		local angle = math.pi * step / 10
		kit:ball(
			"Kitchen arch voussoir",
			{ math.cos(angle) * 9.5, 18 + math.sin(angle) * 5, -23 },
			{ 2, 1.7, 1.6 },
			cream
		)
	end
end

local function living(): Kit
	local kit = WorldKit.new("squid", Config.Zones.squid.origin)
	room(kit, { 174, 189, 118 }, { 184, 136, 157 }, 26, true)
	rug(kit, -28, 24, 30, 23)
	kit:sofa({ -28, 0, 12 }, { 113, 151, 80 })
	for offset = -1, 1 do
		kit:ball("Sofa plump cushion", { -28 + offset * 5, 4.4, 12.6 }, { 4.7, 1.2, 5.4 }, { 142, 172, 99 })
		kit:ball("Sofa back button", { -28 + offset * 5, 6, 10.2 }, { 0.4, 0.4, 0.4 }, brass)
	end
	kit:ball("Sofa bolster pillow", { -33, 6, 12 }, { 3, 4, 2 }, { 193, 184, 114 })
	kit:table({ -27, 0, 25 }, bamboo)
	kit:cylinder("Tea saucer", { -27, 5.6, 25 }, { 0.2, 2.5, 2.5 }, cream)
	kit:cylinder("Tea cup", { -27, 6.1, 25 }, { 0.9, 1.5, 1.5 }, cream)
	kit:cylinder("Tea surface", { -27, 6.57, 25 }, { 0.04, 1.1, 1.1 }, { 102, 68, 44 })
	kit:ball("Tea cup handle", { -26.1, 6.1, 25 }, { 0.6, 0.7, 0.4 }, cream)
	kit:part("Television stand", { -41, 2, 29 }, { 8, 4, 6 }, bamboo, nil, "Wood")
	kit:ball("Rounded television cabinet", { -41, 6, 29 }, { 8, 6, 5 }, stoneDark)
	kit:ball("Convex television screen", { -41, 6.2, 31.3 }, { 6, 4.2, 0.65 }, { 119, 176, 170 })
	for _, side in { -1, 1 } do
		rod(kit, "Television aerial", { -41, 9, 29 }, { -41 + side * 2, 12, 29 }, 0.15, brass)
		kit:ball("Television dial", { -37.8, 5 + side * 0.8, 31 }, { 0.6, 0.6, 0.6 }, brass)
	end
	shellLamp(kit, -42, 10, 12, true)
	clarinet(kit, -14, 33)
	kit:part("Sheet music stand", { -15, 8, 20 }, { 5.5, 3.8, 0.6 }, ink, nil, nil, { -15, 0, 0 })
	kit:cylinder("Music stand pole", { -15, 3.7, 20 }, { 7.4, 0.45, 0.45 }, ink)
	kit:cylinder("Music stand foot", { -15, 0.3, 20 }, { 0.6, 3, 3 }, ink)
	for row = 0, 4 do
		kit:part("Music staff", { -15, 7.1 + row * 0.35, 20.7 }, { 4.6, 0.06, 0.1 }, cream).collide = false
	end
	for note = 0, 3 do
		kit:ball(
			"Printed music note",
			{ -16.5 + note, 7.4 + note % 3 * 0.35, 20.8 },
			{ 0.4, 0.25, 0.12 },
			brass
		)
	end
	portrait(kit, -27, 13, -21.7, 0.95, "tophat", 0, nil)
	kit:part("Portrait display partition", { -28, 11, -22.7 }, { 33, 22, 1.2 }, { 174, 189, 118 })
	kitchen(kit)
	kit:cylinder("Dining table rounded top", { 27, 5.5, 21 }, { 1.1, 14, 14 }, { 145, 182, 143 })
	kit:cylinder("Dining table pedestal", { 27, 2.7, 21 }, { 5.4, 2.3, 2.3 }, bamboo)
	kit:ball("Dining table foot", { 27, 0.5, 21 }, { 8, 1, 8 }, bamboo)
	for _, x in { 19, 35 } do
		chair(kit, x, 23, { 148, 182, 159 })
		kit:cylinder("Dinner plate", { x + (27 - x) * 0.5, 6.16, 21 }, { 0.18, 3.2, 3.2 }, cream)
	end
	shellLamp(kit, 27, 19, 21, false)
	rod(kit, "Dining pendant chain", { 27, 23, 21 }, { 27, 26, 21 }, 0.22, brass)
	kit:supply({ 37, 2, 35 })
	for _, side in { -1, 1 } do
		kit:part("Supply chest strap", { 37 + side * 1.7, 2, 37.08 }, { 0.5, 3.8, 0.15 }, brass)
	end
	kit:part("Supply chest clasp", { 37, 2.2, 37.15 }, { 0.8, 1.2, 0.2 }, brass)
	kit:part("Stair route emblem backing", { 45.9, 12, -11 }, { 0.3, 5.5, 4 }, stoneDark)
	for step = 0, 3 do
		kit:part(
			"Physical stair route emblem",
			{ 45.65, 10.5 + step * 0.8, -12.2 + step * 0.8 },
			{ 0.2, 0.65, 0.9 },
			brass
		)
	end
	return kit
end

local function bookcase(kit: Kit, x: number, z: number, width: number)
	kit:part("Library olive backing", { x, 10, z }, { width, 20, 1 }, { 80, 91, 55 })
	for _, side in { -1, 1 } do
		bambooPole(kit, x + side * width / 2, z + 1.8, 21, brass)
	end
	local bookColors =
		{ { 116, 127, 112 }, { 155, 117, 117 }, { 151, 154, 123 }, { 90, 116, 137 }, { 175, 146, 104 } }
	for tier = 0, 3 do
		kit:part(
			"Gold bamboo shelf",
			{ x, 0.7 + tier * 5, z + 1.6 },
			{ width + 0.8, 0.7, 4.6 },
			brass,
			nil,
			"Wood"
		)
		rod(
			kit,
			"Shelf rounded lip",
			{ x - width / 2, 0.9 + tier * 5, z + 4 },
			{ x + width / 2, 0.9 + tier * 5, z + 4 },
			0.45,
			bamboo
		)
		for index = 1, math.floor((width - 1.5) / 1.9) do
			local bx = x - width / 2 + 0.35 + index * 1.9
			local height = 2.8 + (tier + index) % 3 * 0.4
			local book = kit:part(
				"Muted library volume",
				{ bx, 1.1 + tier * 5 + height / 2, z + 1.9 },
				{ 1.35, height, 2.7 },
				bookColors[(tier + index) % #bookColors + 1]
			)
			kit:part("Book spine gilding", { bx, 1.8 + tier * 5, z + 3.3 }, { 0.7, 0.14, 0.08 }, brass)
			if x == -28 and tier == 1 and index == 3 then
				book.name = "First edition of Solitude"
				book.color = { 65, 108, 113 }
				book.secret = "moai-first-edition"
			end
		end
	end
	kit:ball("Bookcase scalloped crest", { x, 21, z + 1.5 }, { width + 1, 2, 4 }, bamboo)
end

local function library(): Kit
	local kit = WorldKit.new("squidLibrary", Config.Zones.squidLibrary.origin)
	room(kit, { 167, 126, 91 }, { 182, 141, 162 }, 28, true)
	for _, x in { -28, 0, 28 } do
		bookcase(kit, x, -40, 21)
	end
	bookcase(kit, -32, -14, 21)
	bookcase(kit, 30, -14, 19)
	rug(kit, -25, 22, 31, 25)
	chair(kit, -27, 19, { 117, 160, 186 })
	kit:ball("Reading chair lumbar pillow", { -27, 5.5, 17.5 }, { 4.4, 2.3, 1.8 }, { 202, 194, 132 })
	shellLamp(kit, -39, 10, 21, true)
	kit:table({ -15, 0, 23 }, brass)
	kit:part("Open book left page", { -16, 5.65, 23 }, { 1.9, 0.18, 3.2 }, cream, nil, nil, { 0, 0, 5 })
	kit:part("Open book right page", { -14, 5.65, 23 }, { 1.9, 0.18, 3.2 }, cream, nil, nil, { 0, 0, -5 })
	for row = 0, 4 do
		kit:part("Open book line", { -15.9, 5.86, 22 + row * 0.4 }, { 1.3, 0.035, 0.05 }, ink).collide = false
	end
	kit:part("Reading desk", { 28, 5, 24 }, { 17, 1, 9 }, bamboo, nil, "Wood")
	for _, dx in { -7, 7 } do
		for _, dz in { -3, 3 } do
			kit:cylinder("Reading desk turned leg", { 28 + dx, 2.5, 24 + dz }, { 5, 1, 1 }, brass)
		end
	end
	chair(kit, 28, 15, { 117, 160, 186 })
	kit:ball("Library globe", { 32, 8.3, 24 }, { 4, 4, 4 }, stoneLight)
	kit:cylinder("Globe pedestal", { 32, 6.2, 24 }, { 1.4, 2, 2 }, brass)
	rod(kit, "Globe axis", { 30.6, 6.5, 24 }, { 33.4, 10.2, 24 }, 0.2, brass)
	for patch = 0, 4 do
		local angle = patch * 1.15
		kit:ball(
			"Globe island",
			{ 32 + math.sin(angle) * 1.65, 8.3 + math.cos(angle) * 1.3, 25.1 },
			{ 1.1, 0.8, 0.5 },
			{ 131, 172, 135 }
		)
	end
	for stack = 0, 2 do
		kit:part(
			"Desk folio",
			{ 23, 5.8 + stack * 0.5, 24 },
			{ 4, 0.45, 3 },
			{ 130 + stack * 14, 112, 107 },
			nil,
			nil,
			{ 0, stack * 6, 0 }
		)
	end
	shellLamp(kit, 39, 11, 30, true)
	shellLamp(kit, -17, 19, -41.2, false)
	shellLamp(kit, 17, 19, -41.2, false)
	portrait(kit, -46.2, 10, 4, 0.8, "relief", 90, "moai-blue-relief")
	kit:part("Nautical elevator call plate", { 45.9, 7, 11 }, { 0.5, 3, 2 }, stoneDark)
	kit:ball("Elevator pearl call button", { 45.5, 7.2, 11 }, { 0.6, 0.75, 0.75 }, cream)
	for _, side in { -1, 1 } do
		kit:part("Elevator guide rail", { 46, 9, side * 8.7 }, { 0.6, 18, 0.6 }, stoneLight, nil, "Metal")
	end
	kit:cylinder("Elevator floor dial rim", { 45.9, 22, 0 }, { 0.4, 3.5, 3.5 }, brass, { 0, 0, 0 })
	kit:cylinder("Elevator floor dial", { 45.6, 22, 0 }, { 0.2, 2.8, 2.8 }, ink, { 0, 0, 0 })
	rod(kit, "Elevator dial needle", { 45.35, 22, 0 }, { 45.35, 22.9, -0.6 }, 0.17, cream)
	return kit
end

local function studio(): Kit
	local kit = WorldKit.new("squidStudio", Config.Zones.squidStudio.origin)
	room(kit, { 192, 114, 114 }, { 163, 168, 167 }, 26, false)
	for _, part in kit.parts do
		if part.name == "Parquet inlay" then
			part.color = { 126, 139, 148 }
		end
	end
	portrait(kit, -31, 13, -42.3, 1.15, "tophat", 0, nil)
	portrait(kit, -10, 13, -42.3, 1.15, "mosaic", 0, nil)
	portrait(kit, 12, 13, -42.3, 1.15, "geometric", 0, nil)
	portrait(kit, 34, 13, -42.3, 1.05, "relief", 0, nil)
	portrait(kit, -46, 12, 20, 1.1, "geometric", 90, nil)
	portrait(kit, 46, 12, 18, 1.1, "mosaic", -90, nil)
	for _, x in { -31, -10, 12, 34 } do
		kit:part("Picture light hood", { x, 22, -40.5 }, { 5, 0.7, 2 }, brass)
		kit:light({ x, 21.3, -40.3 }, { 255, 226, 174 }, 21)
	end
	kit:ball("Painter's flat drop cloth", { 23, 0.06, -15 }, { 29, 0.12, 24 }, { 220, 205, 174 })
	for _, side in { -1, 1 } do
		rod(
			kit,
			"Easel splayed front leg",
			{ 23 + side * 4.2, 0, -15 },
			{ 23 + side * 2.5, 17, -16 },
			0.75,
			bamboo
		)
	end
	rod(kit, "Easel rear leg", { 23, 15, -16 }, { 23, 0, -23 }, 0.8, bamboo)
	kit:part("Easel canvas ledge", { 23, 4.2, -14.9 }, { 13, 0.8, 2 }, bamboo)
	kit:part("Easel canvas clamp", { 23, 17.2, -15.4 }, { 3, 0.8, 1.3 }, brass)
	portrait(kit, 23, 10.5, -15.4, 1, "bold", 0, "moai-bold-and-brash")
	kit:label("Bold and Brash · bonus exhibit", { 23, 18.9, -15.4 }, cream)
	kit:cylinder("Painter stool cushion", { 14, 3.5, -11 }, { 1, 4.5, 4.5 }, { 151, 119, 87 })
	for leg = 0, 2 do
		local angle = leg * math.pi * 2 / 3
		rod(
			kit,
			"Painter stool leg",
			{ 14 + math.cos(angle) * 1.8, 0, -11 + math.sin(angle) * 1.8 },
			{ 14 + math.cos(angle) * 1.1, 3.2, -11 + math.sin(angle) * 1.1 },
			0.65,
			bamboo
		)
	end
	kit:ball("Artist kidney palette", { 14, 4.2, -11 }, { 4.6, 0.35, 3.2 }, { 194, 154, 100 })
	kit:ball("Palette thumb recess", { 15.3, 4.39, -10.6 }, { 0.7, 0.08, 0.7 }, { 97, 70, 50 })
	local paints =
		{ { 165, 60, 67 }, { 231, 190, 74 }, { 67, 126, 161 }, { 117, 164, 128 }, { 154, 114, 171 } }
	for index, color in paints do
		kit:ball("Palette paint dab", { 12.8 + (index - 1) * 0.55, 4.43, -11.6 }, { 0.48, 0.18, 0.5 }, color)
		kit:ball(
			"Old paint on drop cloth",
			{ 31 + index % 2, 0.14, -21 + index * 1.3 },
			{ 0.7, 0.12, 0.5 },
			color
		).collide =
			false
	end
	kit:part("Studio supply sideboard", { -30, 3.5, -29 }, { 24, 7, 8 }, { 137, 85, 82 }, nil, "Wood")
	kit:part("Paint stained worktop", { -30, 7.2, -29 }, { 25, 0.6, 8.8 }, bamboo, nil, "Wood")
	for drawer = 0, 2 do
		kit:part(
			"Artist sideboard drawer",
			{ -37 + drawer * 7, 4, -24.8 },
			{ 6.1, 4.4, 0.3 },
			{ 180, 112, 105 }
		)
		kit:ball("Sideboard shell handle", { -37 + drawer * 7, 4.5, -24.5 }, { 1.3, 0.6, 0.6 }, brass)
	end
	for index, color in paints do
		kit:cylinder("Paint pigment pot", { -39 + index * 2, 8.2, -28 }, { 1.4, 1.5, 1.5 }, color)
		kit:cylinder("Pigment pot lid", { -39 + index * 2, 8.95, -28 }, { 0.2, 1.65, 1.65 }, cream)
	end
	kit:cylinder("Brush crock", { -22, 8.5, -29 }, { 2.5, 2.8, 2.8 }, stoneLight)
	for brush = 0, 4 do
		local bx = -23 + brush * 0.45
		rod(
			kit,
			"Paintbrush handle",
			{ bx, 8.2, -29 },
			{ bx + (brush - 2) * 0.3, 12 + brush % 2, -29 },
			0.18,
			brass
		)
		kit:ball(
			"Paintbrush bristles",
			{ bx + (brush - 2) * 0.3, 12.2 + brush % 2, -29 },
			{ 0.4, 1, 0.4 },
			paints[brush + 1]
		)
	end
	kit:cylinder("Sculpture plinth", { -27, 2, 20 }, { 4, 7, 7 }, stoneDark)
	kit:cylinder("Sculpture plinth cap", { -27, 4.3, 20 }, { 0.6, 8, 8 }, brass)
	kit:ball("Unfinished sculpted shoulders", { -27, 5.6, 20 }, { 6, 2.4, 4 }, stoneLight)
	kit:ball("Unfinished sculpted neck", { -27, 7.4, 20 }, { 2.6, 4, 3 }, stoneLight)
	kit:ball("Unfinished sculpted head", { -27, 10.2, 20 }, { 7, 4.8, 4.5 }, stoneLight)
	kit:ball("Unfinished sculpted nose", { -27, 8.6, 23 }, { 1.7, 4, 2 }, stoneLight)
	for _, side in { -1, 1 } do
		kit:ball("Sculpture hollow eye", { -27 + side * 1.4, 9.6, 22.2 }, { 1.4, 1.6, 0.4 }, stoneDark)
	end
	shellLamp(kit, -40, 10, 30, true)
	kit:sofa({ 27, 0, 30 }, { 159, 88, 113 })
	kit:ball("Studio chaise cushion", { 27, 4.4, 30 }, { 14, 1.2, 6 }, { 195, 122, 139 })
	return kit
end

return function(): { WorldKit.Part }
	local result: { WorldKit.Part } = {}
	for _, kit in { exterior(), living(), library(), studio() } do
		for _, part in kit.parts do
			table.insert(result, part)
		end
	end
	return result
end
