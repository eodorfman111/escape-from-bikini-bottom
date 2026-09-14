--!strict
-- selene: allow(incorrect_standard_library_use)
local luau = require("@lune/luau")
-- selene: allow(incorrect_standard_library_use)
local fs = require("@lune/fs")
-- selene: allow(incorrect_standard_library_use)
local roblox = require("../tools/Roblox")
-- selene: allow(incorrect_standard_library_use)
type Models = typeof(require("../src/shared/Models"))
local models: Models = luau.load(fs.readFile("src/shared/Models.luau"), {
	debugName = "Models",
	environment = {
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Color3 = roblox.Color3,
		CFrame = roblox.CFrame,
		Enum = roblox.Enum,
	},
})()
local objects: { Instance } = {}
for _, id in { "sponge", "patrick", "sandy", "gary", "squid", "fish" } do
	local model = models.creature(id, id == "fish")
	assert(model.PrimaryPart ~= nil, "Each creature has a transform root")
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			assert(
				child.Anchored and not child.CanCollide and not child.CanTouch,
				"Cosmetic parts are kinematic"
			)
			if id ~= "fish" then
				assert(not child.CanQuery, "Helpers cannot absorb player shots")
			end
		end
	end
	table.insert(objects, model)
end
for _, id in { "bubble", "spatula", "jelly" } do
	local model = models.weapon(id)
	assert(model.PrimaryPart ~= nil, "View weapon root")
	table.insert(objects, model)
end
local character = roblox.Instance.new("Model")
local root = roblox.Instance.new("Part")
root.Name, root.Parent = "HumanoidRootPart", character
local face = roblox.Instance.new("Decal")
face.Parent = root
models.dress(character, "sponge")
models.dress(character, "sponge")
local costumes = 0
for _, child in character:GetChildren() do
	if child.Name == "ConchCostume" then
		costumes += 1
		for _, part in child:GetChildren() do
			if part:IsA("BasePart") then
				assert(not part.Anchored and part.Massless, "Costume must not anchor the player")
				assert(part:FindFirstChildOfClass("WeldConstraint") ~= nil, "Costume must follow the avatar")
			end
		end
	end
end
assert(costumes == 1, "Appearance reloading must not duplicate costumes")
table.insert(objects, character)
local restored = roblox.deserializeModel(roblox.serializeModel(objects))
assert(#restored == 10, "All model factories serialize with valid property types")
print("PASS six creatures, three weapons and welded costume construction/serialization")
