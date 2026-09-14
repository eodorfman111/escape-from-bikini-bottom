--!strict
-- selene: allow(incorrect_standard_library_use)
local Street = require("./worlds/Street")
-- selene: allow(incorrect_standard_library_use)
local Pineapple = require("./worlds/Pineapple")
-- selene: allow(incorrect_standard_library_use)
local Moai = require("./worlds/Moai")
-- selene: allow(incorrect_standard_library_use)
local Rock = require("./worlds/Rock")
-- selene: allow(incorrect_standard_library_use)
local Krusty = require("./worlds/Krusty")
-- selene: allow(incorrect_standard_library_use)
local Chum = require("./worlds/Chum")
-- selene: allow(incorrect_standard_library_use)
local School = require("./worlds/School")
-- selene: allow(incorrect_standard_library_use)
local Neighborhood = require("./worlds/Neighborhood")
-- selene: allow(incorrect_standard_library_use)
local WorldKit = require("./WorldKit")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")
-- selene: allow(incorrect_standard_library_use)
local Roblox = require("./Roblox")
local CFrame = Roblox.CFrame

return function(): { WorldKit.Part }
	local parts: { WorldKit.Part } = {}
	for _, builder in
		{
			{ id = "street", build = Street },
			{ id = "pineapple", build = Pineapple },
			{ id = "moai", build = Moai },
			{ id = "rock", build = Rock },
			{ id = "krab", build = Krusty },
			{ id = "bucket", build = Chum },
			{ id = "school", build = School },
			{ id = "neighborhood", build = Neighborhood },
		}
	do
		local exterior = Config.Exteriors[builder.id]
		for _, part in builder.build() do
			if part.zone == "street" and exterior then
				part.position = Config.exteriorPoint(builder.id, part.position)
				part.size = {
					part.size[1] * exterior.scale,
					part.size[2] * exterior.scale,
					part.size[3] * exterior.scale,
				}
				local x, y, z = (CFrame.Angles(0, math.rad(exterior.yaw), 0) * CFrame.Angles(
					math.rad(part.rotation[1]),
					math.rad(part.rotation[2]),
					math.rad(part.rotation[3])
				)):ToEulerAnglesXYZ()
				part.rotation = { math.deg(x), math.deg(y), math.deg(z) }
				part.group = part.group or builder.id .. "-exterior"
				part.light *= exterior.scale
			end
			table.insert(parts, part)
		end
	end
	return parts
end
