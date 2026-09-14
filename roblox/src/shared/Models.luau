--!strict
local Models = {}
local cream = Color3.fromRGB(255, 245, 219)
local black = Color3.fromRGB(35, 42, 51)

local function part(
	model: Model,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color = name, size, color
	if shape == Enum.PartType.Ball then
		local mesh = Instance.new("SpecialMesh")
		mesh.Name, mesh.MeshType = "Ellipsoid", Enum.MeshType.Sphere
		mesh.Scale, mesh.Parent = Vector3.one, p
	else
		p.Shape = shape or Enum.PartType.Block
	end
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CFrame = CFrame.new(position)
	p.Parent = model
	return p
end

function Models.creature(id: string, hostile: boolean?): Model
	local model = Instance.new("Model")
	model.Name = id
	local root = part(model, "Root", Vector3.zero, Vector3.one, cream)
	root.Transparency = 1
	model.PrimaryPart = root
	local color = if id == "sponge"
		then Color3.fromRGB(250, 220, 56)
		elseif id == "patrick" then Color3.fromRGB(242, 154, 175)
		elseif id == "squid" then Color3.fromRGB(133, 191, 178)
		elseif id == "sandy" then Color3.fromRGB(226, 231, 239)
		elseif id == "gary" then Color3.fromRGB(151, 220, 218)
		else Color3.fromRGB(88, 151, 168)
	local body = part(
		model,
		"Body",
		Vector3.zero,
		Vector3.new(3.5, 3.5, 1.7),
		color,
		if id == "sponge" then Enum.PartType.Block else Enum.PartType.Ball
	)
	if id == "sponge" then
		part(model, "White shirt", Vector3.new(0, -1, -0.02), Vector3.new(3.55, 0.6, 1.75), cream)
		part(
			model,
			"Brown pants",
			Vector3.new(0, -1.65, 0),
			Vector3.new(3.4, 0.7, 1.8),
			Color3.fromRGB(141, 86, 44)
		)
		part(
			model,
			"Red tie",
			Vector3.new(0, -1.15, -0.95),
			Vector3.new(0.3, 0.8, 0.15),
			Color3.fromRGB(214, 54, 48)
		)
		for i = 1, 7 do
			part(
				model,
				"Sponge pore",
				Vector3.new(-1.55 + i % 2 * 3.1, -0.7 + i % 4 * 0.65, -0.87),
				Vector3.new(0.24, 0.35, 0.05),
				Color3.fromRGB(201, 170, 31),
				Enum.PartType.Ball
			)
		end
	elseif id == "patrick" then
		part(
			model,
			"Star point",
			Vector3.new(0, 1.9, 0),
			Vector3.new(1.7, 2.6, 1.3),
			color,
			Enum.PartType.Ball
		)
		part(
			model,
			"Green shorts",
			Vector3.new(0, -1.1, 0),
			Vector3.new(3.5, 1.5, 1.8),
			Color3.fromRGB(157, 199, 78)
		)
		for i = -1, 1, 2 do
			part(
				model,
				"Purple flower",
				Vector3.new(i, -1.15, -0.95),
				Vector3.new(0.65, 0.7, 0.15),
				Color3.fromRGB(164, 96, 178),
				Enum.PartType.Ball
			)
		end
	elseif id == "squid" then
		part(model, "Squid head", Vector3.new(0, 1.6, 0), Vector3.new(3.4, 3.4, 2), color, Enum.PartType.Ball)
		part(
			model,
			"Long nose",
			Vector3.new(0, 0.7, -1.3),
			Vector3.new(0.65, 1.9, 1),
			color,
			Enum.PartType.Ball
		)
		part(
			model,
			"Polo shirt",
			Vector3.new(0, -0.4, 0),
			Vector3.new(2, 1.6, 1.65),
			Color3.fromRGB(164, 114, 53)
		)
	elseif id == "sandy" then
		local helmet = part(
			model,
			"Air helmet",
			Vector3.new(0, 1.7, 0),
			Vector3.new(3.3, 3.2, 3.3),
			cream,
			Enum.PartType.Ball
		)
		helmet.Transparency = 0.65
		part(
			model,
			"Squirrel head",
			Vector3.new(0, 1.5, -0.2),
			Vector3.new(2, 2, 1.6),
			Color3.fromRGB(160, 106, 59),
			Enum.PartType.Ball
		)
		part(
			model,
			"Helmet flower",
			Vector3.new(1.2, 3, 0),
			Vector3.new(1, 0.5, 1),
			Color3.fromRGB(243, 121, 190),
			Enum.PartType.Ball
		)
	elseif id == "gary" then
		body.Size = Vector3.new(3.6, 1, 3)
		body.Position = Vector3.new(0, -1.8, 0)
		part(
			model,
			"Pink shell",
			Vector3.new(0, -0.5, 0.4),
			Vector3.new(2.8, 2.6, 2.6),
			Color3.fromRGB(230, 149, 175),
			Enum.PartType.Ball
		)
		for i = -1, 1, 2 do
			part(model, "Eye stalk", Vector3.new(i * 0.65, 0, -1.1), Vector3.new(0.3, 2, 0.3), color)
		end
	else
		body.Size = Vector3.new(2.8, 3.8, 2)
		for i = -1, 1, 2 do
			part(
				model,
				"Fish fin",
				Vector3.new(i * 1.9, 0, 0),
				Vector3.new(1.5, 2, 0.5),
				Color3.fromRGB(186, 126, 183),
				Enum.PartType.Ball
			)
		end
	end
	local eyeY = if id == "squid" or id == "sandy" then 1.9 else 0.9
	for i = -1, 1, 2 do
		part(
			model,
			"Eye",
			Vector3.new(i * 0.65, eyeY, -1.02),
			Vector3.new(1.05, 1.25, 0.45),
			cream,
			Enum.PartType.Ball
		)
		part(
			model,
			"Pupil",
			Vector3.new(i * 0.65, eyeY, -1.28),
			Vector3.new(0.4, 0.55, 0.18),
			if hostile then Color3.fromRGB(248, 105, 100) else black,
			Enum.PartType.Ball
		)
		if id ~= "gary" then
			local leg = part(
				model,
				"Leg",
				Vector3.new(i * 0.9, -2.15, 0),
				Vector3.new(0.65, 1, 0.7),
				color,
				Enum.PartType.Ball
			)
			leg.Color = if id == "sandy" then cream else color
			part(
				model,
				"Shoe",
				Vector3.new(i * 0.9, -2.55, -0.2),
				Vector3.new(1.1, 0.45, 1.2),
				black,
				Enum.PartType.Ball
			)
			local arm = part(
				model,
				"Arm",
				Vector3.new(i * 2.05, -0.4, 0),
				Vector3.new(0.65, 2.2, 0.65),
				color,
				Enum.PartType.Ball
			)
			arm.CFrame *= CFrame.Angles(0, 0, i * 0.35)
		end
	end
	part(model, "Smile", Vector3.new(0, 0.05, -1), Vector3.new(1, 0.14, 0.12), black)
	if hostile then
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") and child ~= root then
				child.CanQuery = true
			end
		end
	end
	return model
end

function Models.dress(character: Model, id: string)
	if id == "explorer" then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local old = character:FindFirstChild("ConchCostume")
	if old then
		old:Destroy()
	end
	for _, child in character:GetDescendants() do
		if child:IsA("BasePart") then
			child.Transparency = 1
		elseif child:IsA("Decal") then
			child:Destroy()
		end
	end
	local costume = Models.creature(id)
	for _, child in costume:GetChildren() do
		if child:IsA("BasePart") then
			child.CFrame = root.CFrame * child.CFrame
			child.Anchored, child.Massless = false, true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = root, child, child
		end
	end
	costume.Name, costume.Parent = "ConchCostume", character
end

function Models.weapon(id: string): Model
	local model = Instance.new("Model")
	model.Name = "ViewWeapon"
	local color = if id == "spatula"
		then Color3.fromRGB(239, 169, 66)
		elseif id == "jelly" then Color3.fromRGB(232, 119, 213)
		else Color3.fromRGB(84, 218, 237)
	local grip = part(model, "Grip", Vector3.zero, Vector3.new(0.3, 0.65, 0.45), Color3.fromRGB(49, 81, 90))
	model.PrimaryPart = grip
	part(model, "Barrel", Vector3.new(0, 0.35, -0.5), Vector3.new(0.6, 0.6, 1.3), color, Enum.PartType.Ball)
	if id == "spatula" then
		part(model, "Spatula blade", Vector3.new(0, 0.6, -1.2), Vector3.new(0.85, 0.12, 0.9), cream)
	else
		local orb = part(
			model,
			"Bubble chamber",
			Vector3.new(0, 0.65, -0.3),
			Vector3.new(0.7, 0.7, 0.7),
			color,
			Enum.PartType.Ball
		)
		orb.Material = Enum.Material.Neon
	end
	return model
end
return Models
