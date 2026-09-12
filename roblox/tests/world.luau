--!strict
-- selene: allow(incorrect_standard_library_use)
local World = require("../tools/World")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")
-- selene: allow(incorrect_standard_library_use)
local roblox = require("../tools/Roblox")
-- selene: allow(incorrect_standard_library_use)
local fs = require("@lune/fs")
-- selene: allow(incorrect_standard_library_use)
local Rules = require("../src/shared/Rules")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end
local specs, repeatSpecs = World(), World()
local discoveries: { [string]: boolean } = {}
local counts: { [string]: number } = {}
local checks = 0
local function check(ok: boolean, message: string)
	assert(ok, message)
	checks += 1
end
local shapes = { Block = true, Wedge = true, Ball = true, Cylinder = true }
for i, spec in specs do
	counts[spec.zone] = (counts[spec.zone] or 0) + 1
	check(Config.Zones[spec.zone] ~= nil and shapes[spec.shape] == true, spec.name .. " valid zone/shape")
	for j = 1, 3 do
		check(
			Rules.finite(spec.position[j]) and Rules.finite(spec.size[j]) and spec.size[j] > 0,
			"Finite geometry"
		)
		check(
			spec.position[j] == repeatSpecs[i].position[j] and spec.size[j] == repeatSpecs[i].size[j],
			"Deterministic geometry"
		)
	end
	if spec.secret then
		check(not discoveries[spec.secret], "Unique discovery ID: " .. spec.secret)
		discoveries[spec.secret] = true
	end
end
for zone in Config.Zones do
	check((counts[zone] or 0) > 100, "Every zone is furnished")
end
local portalMap: { [string]: Config.Portal } = {}
for _, portal in Config.Portals do
	check(portalMap[portal.id] == nil, "Unique door")
	portalMap[portal.id] = portal
end
for _, portal in Config.Portals do
	local target = portalMap[portal.target]
	check(target ~= nil and target.target == portal.id, "Reciprocal portals")
	check((vec(portal.position) - vec(target.position)).Magnitude > 100, "Remote interiors")
	local normal, center = vec(portal.normal), vec(portal.position)
	local right = Vector3.new(normal.Z, 0, -normal.X)
	for _, spec in specs do
		if spec.zone ~= portal.zone or not spec.collide then
			continue
		end
		local transform = CFrame.new(vec(spec.position))
			* CFrame.Angles(
				math.rad(spec.rotation[1]),
				math.rad(spec.rotation[2]),
				math.rad(spec.rotation[3])
			)
		for distance = -2, 7, 3 do
			for sideways = -2, 2, 2 do
				for height = 1, 6, 2.5 do
					local point = center + normal * distance + right * sideways + Vector3.new(0, height, 0)
					local localPoint = transform:PointToObjectSpace(point)
					local half = vec(spec.size) / 2
					local inside = math.abs(localPoint.X) < half.X - 0.01
						and math.abs(localPoint.Y) < half.Y - 0.01
						and math.abs(localPoint.Z) < half.Z - 0.01
					check(not inside, portal.id .. " blocked by " .. spec.name)
				end
			end
		end
	end
end
local place = roblox.deserializePlace(fs.readFile("build/ConchStreetSurvival.rbxl"))
local world = place:GetService("Workspace"):FindFirstChild("ConchWorld")
check(world ~= nil, "Static world embedded in place")
local scripts = 0
local promptCount = 0
for _, descendant in place:GetDescendants() do
	local source = if descendant:IsA("Script")
		then descendant.Source
		elseif descendant:IsA("LocalScript") then descendant.Source
		elseif descendant:IsA("ModuleScript") then descendant.Source
		else nil
	if source then
		scripts += 1
		check(#source > 0, "Source code embedded")
	elseif descendant:IsA("ProximityPrompt") then
		promptCount += 1
		local parent = descendant.Parent
		check(
			parent ~= nil and typeof(parent:GetAttribute("Zone")) == "string",
			"Prompt has authoritative zone"
		)
	end
end
check(scripts >= 6, "Server, client and shared modules in place")
check(promptCount >= 30, "All secrets, supplies and barricades in place")
local total = 0
for _ in discoveries do
	total += 1
end
check(total == 20, "Twenty unique keepsakes")
print("PASS", checks, "geometry, doorway-clearance and place round-trip assertions;", #specs, "modeled parts")
