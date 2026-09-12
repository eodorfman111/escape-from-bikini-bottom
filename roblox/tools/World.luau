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
local WorldKit = require("./WorldKit")

return function(): { WorldKit.Part }
	local parts: { WorldKit.Part } = {}
	for _, build in { Street, Pineapple, Moai, Rock, Krusty, Chum } do
		for _, part in build() do
			table.insert(parts, part)
		end
	end
	return parts
end
