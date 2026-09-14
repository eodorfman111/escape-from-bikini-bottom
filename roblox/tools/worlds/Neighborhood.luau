--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")
type Kit = WorldKit.Kit
local bun, pickle, gold = { 222, 169, 82 }, { 99, 151, 61 }, { 249, 207, 89 }
local cream, red, blue = { 255, 240, 191 }, { 209, 75, 65 }, { 66, 142, 172 }

local function wagon(): Kit
	local kit = WorldKit.new("street", { 52, 0, 2 })
	kit:part("Patty Wagon parking pad", { 0, 0.05, 0 }, { 32, 0.1, 26 }, { 159, 161, 132 }, nil, "Concrete").collide =
		false
	kit:part("Patty Wagon chassis", { 0, 2.7, 0 }, { 15, 1.5, 16 }, blue)
	kit:ball("Patty Wagon bottom bun", { 0, 4, 0 }, { 19, 3.5, 17 }, bun)
	kit:ball("Patty Wagon grilled patty", { 0, 5.5, 0 }, { 18.5, 2, 16.5 }, { 112, 71, 45 })
	kit:part("Patty Wagon melted cheese", { 0, 6.3, 0 }, { 17, 0.5, 16 }, gold, nil, nil, { 0, 7, 0 })
	for i = 0, 7 do
		local a = i * math.pi / 4
		kit:ball(
			"Patty Wagon ruffled lettuce",
			{ math.cos(a) * 7.5, 6.7, math.sin(a) * 6.5 },
			{ 5, 1.2, 5 },
			pickle
		)
	end
	kit:ball("Patty Wagon sesame hood", { 0, 8.1, 4.2 }, { 18.5, 6, 10 }, bun)
	kit:ball("Patty Wagon rear bun", { 0, 8, -6.2 }, { 18, 4.5, 3.2 }, bun)
	for _, x in { -8, 8 } do
		kit:part("Patty Wagon bun cockpit rail", { x, 8, -2 }, { 1.5, 2.5, 7 }, bun)
	end
	for _, x in { -3.3, 3.3 } do
		kit:part("Patty Wagon open cabin seat", { x, 7.3, -3.3 }, { 5.5, 1, 4 }, red)
		kit:part("Patty Wagon seat back", { x, 9, -5.1 }, { 5.5, 3.5, 0.7 }, red)
	end
	kit:cylinder("Patty Wagon steering column", { -3.3, 8.5, -0.5 }, { 3, 0.4, 0.4 }, blue)
	kit:cylinder("Patty Wagon steering wheel", { -3.3, 10, -0.5 }, { 0.25, 2.5, 2.5 }, pickle)
	for _, x in { -5.5, 5.5 } do
		kit:cylinder("Patty Wagon headlight rim", { x, 6.7, 9 }, { 0.8, 2.3, 2.3 }, blue, { 0, 90, 0 })
		kit:ball("Patty Wagon headlight", { x, 6.7, 9.5 }, { 1.8, 1.8, 0.4 }, cream).material = "Neon"
	end
	kit:part("Patty Wagon front bumper", { 0, 3.5, 9 }, { 14, 0.7, 1 }, cream)
	for _, side in { -1, 1 } do
		for _, z in { -5, 5 } do
			kit:cylinder(
				"Patty Wagon pickle wheel",
				{ side * 9.8, 3, z },
				{ 2, 5.8, 5.8 },
				pickle,
				{ 0, 0, 0 }
			)
			kit:cylinder(
				"Patty Wagon pickle wheel flesh",
				{ side * 10.85, 3, z },
				{ 0.15, 4.6, 4.6 },
				{ 182, 200, 102 },
				{ 0, 0, 0 }
			)
			for i = 0, 4 do
				local a = i * math.pi * 2 / 5
				kit:ball(
					"Patty Wagon pickle seed",
					{ side * 10.96, 3 + math.cos(a) * 1.2, z + math.sin(a) * 1.2 },
					{ 0.1, 0.6, 0.35 },
					cream
				)
			end
		end
	end
	for _, x in { -5, -2.5, 0, 2.5, 5 } do
		for _, z in { 3, 5.5 } do
			kit:ball("Patty Wagon sesame seed", { x, 11 - math.abs(x) * 0.07, z }, { 0.8, 0.22, 0.4 }, cream)
		end
	end
	kit:cylinder("Patty Wagon flagpole", { 8, 12, -6 }, { 9, 0.3, 0.3 }, blue)
	kit:part("Patty Wagon Krusty flag", { 5.8, 15, -6 }, { 4, 2.8, 0.15 }, red)
	kit:part("Patty flag anchor stem", { 5.8, 15, -5.85 }, { 0.25, 2, 0.1 }, cream)
	kit:part("Patty flag anchor crossbar", { 5.8, 15.3, -5.85 }, { 1.5, 0.25, 0.1 }, cream)
	kit:secret("street-patty-wagon", "Patty Wagon souvenir", { 14, 3, 0 }, gold)
	return kit
end

local function fields(): Kit
	local kit = WorldKit.new("street", { 80, 0, 190 })
	kit:ball("Jellyfish Fields meadow", { 0, 0.05, 0 }, { 130, 0.1, 110 }, { 152, 183, 103 }).collide = false
	for i = 0, 14 do
		local angle = i * 2.4
		local x, z = math.cos(angle) * (23 + i * 1.8), math.sin(angle) * (18 + i * 1.5)
		local y = 9 + i % 4 * 3
		local color = if i % 4 == 0 then { 167, 141, 222 } else { 238, 156, 194 }
		kit:ball("Wild jellyfish bell", { x, y, z }, { 5, 3, 5 }, color).collide = false
		kit:ball("Wild jellyfish bell rim", { x, y - 1, z }, { 5.2, 1, 5.2 }, { 231, 114, 183 }).collide =
			false
		for _, side in { -1, 0, 1 } do
			kit:cylinder("Wild jellyfish tendril", { x + side * 1.4, y - 3.4, z }, { 4, 0.25, 0.25 }, color).collide =
				false
			kit:ball(
				"Wild jellyfish spot",
				{ x + side, y + 1, z + 1 },
				{ 0.65, 0.35, 0.65 },
				{ 174, 93, 168 }
			).collide =
				false
		end
	end
	for i = 0, 16 do
		local a = i * math.pi * 2 / 17
		local x, z = math.cos(a) * 60, math.sin(a) * 47
		for offset = -1, 1 do
			kit:ball("Fields sea grass", { x + offset, 2 + i % 3, z }, { 0.6, 4 + i % 3 * 2, 1.5 }, pickle).collide =
				false
		end
	end
	kit:part("Jellyfishing picnic blanket", { 19, 0.12, 0 }, { 14, 0.1, 12 }, red).collide = false
	for i = -2, 2 do
		kit:part("Picnic blanket cream stripe", { 19 + i * 2.5, 0.19, 0 }, { 1.1, 0.04, 12 }, cream).collide =
			false
	end
	kit:supply({ 20, 2, 0 })
	kit:cylinder("Jellyfishing net handle", { 6, 3, 0 }, { 6, 0.4, 0.4 }, bun, { 0, 0, 25 }).collide = false
	kit:ball("Jellyfishing net mesh", { 4.5, 6.5, 0 }, { 4, 3.5, 0.3 }, cream).transparency = 0.5
	kit:secret("street-jellyfish-keepsake", "Jellyfishing keepsake", { 4, 3, 3 }, gold)
	return kit
end

return function(): { WorldKit.Part }
	local result = {}
	local vehicle, meadow = wagon(), fields()
	for _, kit in { vehicle, meadow } do
		for _, part in kit.parts do
			part.group = if kit == vehicle then "Patty Wagon" else "Jellyfish Fields"
			table.insert(result, part)
		end
	end
	return result
end
