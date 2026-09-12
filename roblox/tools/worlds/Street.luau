--!strict
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("../WorldKit")

return function(): { WorldKit.Part }
	local kit = WorldKit.new("street", { 0, 0, 0 })
	kit:part("Sea floor", { 30, -2, 30 }, { 470, 4, 260 }, { 226, 207, 145 }, nil, "Sand")
	kit:part("Conch Street", { 30, 0.02, 47 }, { 450, 0.08, 32 }, { 161, 142, 99 }, nil, "Sand")
	for x = -184, 250, 14 do
		kit:part("Road marker", { x, 0.1, 47 }, { 6, 0.08, 0.7 }, { 235, 222, 158 }).collide = false
	end
	for _, x in { -110, -55, 0, 90, 175 } do
		kit:part("Door path", { x, 0.05, 26 }, { 14, 0.1, 32 }, { 233, 222, 174 }).collide = false
		kit:cylinder("Mailbox post", { x + 19, 3, 24 }, { 6, 0.8, 0.8 }, { 81, 100, 96 })
		kit:part("Mailbox", { x + 19, 6, 24 }, { 3, 2, 4 }, { 108, 146, 157 })
	end
	for i = 0, 34 do
		local x = -182 + i * 12
		local z = -72 - (i % 3) * 9
		kit:ball("Distant reef", { x, 9 + i % 7, z }, { 28, 28 + i % 5 * 6, 25 }, { 91, 165, 162 })
		for j = 0, 2 do
			kit:ball(
				"Coral",
				{ x + j * 2, 3 + j * 2, 103 + i % 3 * 4 },
				{ 2, 6 + j * 4, 2 },
				{ 160 + i % 4 * 20, 95 + i % 5 * 15, 160 }
			)
		end
	end
	for i = 0, 6 do
		local x, y = -155 + i * 65, 65 + i % 2 * 23
		for petal = 0, 4 do
			local a = petal * math.pi * 2 / 5
			local part = kit:ball(
				"Sea flower",
				{ x + math.cos(a) * 10, y + math.sin(a) * 10, -97 },
				{ 13, 13, 0.5 },
				{ 95, 187, 181 }
			)
			part.collide = false
			part.transparency = 0.45
		end
	end
	kit:label("CONCH STREET\nExplore • Find coins • Hire your crew", { 30, 14, 84 })
	kit:part("Lifeguard supply stand", { 45, 3, 80 }, { 9, 6, 5 }, { 38, 133, 142 }, nil, "WoodPlanks")
	kit:supply({ 44, 2, 74 })
	for _, wall in
		{
			{ { -202, 20, 30 }, { 2, 40, 264 } },
			{ { 262, 20, 30 }, { 2, 40, 264 } },
			{ { 30, 20, -102 }, { 464, 40, 2 } },
			{ { 30, 20, 162 }, { 464, 40, 2 } },
		}
	do
		kit:part("Reef boundary", wall[1], wall[2], { 60, 135, 146 }).transparency = 1
	end
	return kit.parts
end
