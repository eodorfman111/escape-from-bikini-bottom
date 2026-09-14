--!strict
-- selene: allow(incorrect_standard_library_use)
local World = require("../tools/World")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")
-- selene: allow(incorrect_standard_library_use)
local AudioConfig = require("../src/shared/AudioConfig")
-- selene: allow(incorrect_standard_library_use)
local Roblox = require("../tools/Roblox")
-- selene: allow(incorrect_standard_library_use)
local fs = require("@lune/fs")
local parts = World()
local names: { [string]: number } = {}
local secrets: { [string]: boolean } = {}
local wagonParts = 0
for _, part in parts do
	names[part.name] = (names[part.name] or 0) + 1
	if part.secret then
		assert(not secrets[part.secret], "Discovery IDs remain unique")
		secrets[part.secret] = true
	end
	if part.group == "Patty Wagon" then
		wagonParts += 1
	end
	if part.group and (string.find(part.group, "-exterior", 1, true) or part.group == "PatrickLid") then
		assert(
			part.transparency == 0 or part.transparency == 1,
			"Exterior surfaces do not reveal empty shells"
		)
	end
end
for _, id in
	{
		"school-good-noodle-board",
		"school-roger-case",
		"school-anchor-marker",
		"school-finish-keepsake",
		"street-patty-wagon",
		"street-jellyfish-keepsake",
	}
do
	assert(secrets[id], "Missing exploration reward: " .. id)
end
for _, name in
	{
		"Boating chalkboard",
		"Good Noodle Board",
		"Roger glass case",
		"Mrs Puff teacher desk",
		"Lighthouse lantern",
		"Boating practice course",
		"Course bleacher seat",
		"Practice ramp",
		"Training boat hull",
		"Patty Wagon grilled patty",
		"Patty Wagon open cabin seat",
		"Patty Wagon pickle wheel",
		"Patty Wagon sesame seed",
		"Patty Wagon Krusty flag",
		"Wild jellyfish bell",
		"Service wing floor",
		"Frozen patty shelf",
		"Dry storage shelf",
		"Heads and tails partition",
		"Porcelain toilet",
		"Dumpster body",
	}
do
	assert(names[name], "Missing modeled feature: " .. name)
end
assert(names["Student desk writing top"] == 10, "Ten student desks furnish the classroom")
assert(names["Patty Wagon pickle wheel"] == 4, "Four pickle wheels")
assert(wagonParts > 50 and wagonParts <= 100, "The parked editable vehicle stays within its part budget")
assert(
	Config.Zones.street.size[1] >= 900 and Config.Zones.street.size[3] >= 540,
	"Expanded exploration bounds"
)
assert(Config.Exteriors.pineapple.origin[1] - Config.Exteriors.moai.origin[1] >= 80, "Pineapple lot spacing")
assert(Config.Exteriors.moai.origin[1] - Config.Exteriors.rock.origin[1] >= 80, "Patrick lot spacing")
for _, track in { AudioConfig.Explore, AudioConfig.Combat, AudioConfig.Danger } do
	assert(string.match(track, "^rbxassetid://%d+$"), "Music ships with hosted asset IDs")
end
assert(AudioConfig.Volume > 0 and AudioConfig.Volume <= 1, "Audible default volume")
local place = Roblox.deserializePlace(fs.readFile("build/ConchStreetSurvival.rbxl"))
local covers: { [string]: boolean } = {}
local triggers: { [string]: boolean } = {}
local prompts = 0
for _, instance in place:GetDescendants() do
	assert(not instance:IsA("BillboardGui"), "No floating English world labels in the built place")
	if instance:IsA("ProximityPrompt") then
		prompts += 1
	end
	if not instance:IsA("BasePart") then
		continue
	end
	local cover, portal = instance:GetAttribute("DoorCover"), instance:GetAttribute("Portal")
	if typeof(cover) == "string" then
		assert(not covers[cover], "Each doorway has exactly one opaque cover")
		assert(
			instance.Transparency == 0 and not instance.CanCollide and not instance.CanQuery,
			"Opaque traversable cover"
		)
		covers[cover] = true
	end
	if typeof(portal) == "string" then
		assert(
			instance.Transparency == 1 and not instance.CanCollide,
			"Portal triggers stay invisible and traversable"
		)
		triggers[portal] = true
	end
end
for _, portal in Config.Portals do
	assert(covers[portal.id] and triggers[portal.id], "Covered doorway serialized: " .. portal.id)
end
assert(prompts >= 35, "Discoveries, supplies and barricades retain usable prompts")
print(
	"PASS expansion content, opaque doors, label removal, spacing and hosted music configuration;",
	wagonParts,
	"vehicle parts"
)
