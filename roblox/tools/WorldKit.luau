--!strict
-- selene: allow(incorrect_standard_library_use)
local Roblox = require("./Roblox")
local Vector3, CFrame = Roblox.Vector3, Roblox.CFrame
export type Triple = { number }
export type Part = {
	name: string,
	zone: string,
	position: Triple,
	size: Triple,
	color: Triple,
	shape: string,
	material: string,
	rotation: Triple,
	collide: boolean,
	transparency: number,
	light: number,
	label: string?,
	secret: string?,
	supply: boolean?,
	group: string?,
	castShadow: boolean?,
}
local WorldKit = {}
WorldKit.__index = WorldKit
export type Kit = typeof(setmetatable({ parts = {} :: { Part }, zone = "", origin = { 0, 0, 0 } }, WorldKit))

function WorldKit.new(zone: string, origin: Triple): Kit
	return setmetatable({ parts = {}, zone = zone, origin = origin }, WorldKit)
end

function WorldKit.part(
	self: Kit,
	name: string,
	p: Triple,
	size: Triple,
	color: Triple,
	shape: string?,
	material: string?,
	rotation: Triple?
): Part
	local item: Part = {
		name = name,
		zone = self.zone,
		position = { p[1] + self.origin[1], p[2] + self.origin[2], p[3] + self.origin[3] },
		size = size,
		color = color,
		shape = shape or "Block",
		material = material or "SmoothPlastic",
		rotation = rotation or { 0, 0, 0 },
		collide = true,
		transparency = 0,
		light = 0,
	}
	table.insert(self.parts, item)
	return item
end

function WorldKit.ball(self: Kit, name: string, p: Triple, size: Triple, color: Triple): Part
	return self:part(name, p, size, color, "Ball")
end

function WorldKit.triangle(
	self: Kit,
	name: string,
	a: Triple,
	b: Triple,
	c: Triple,
	color: Triple,
	material: string?
)
	local av, bv, cv =
		Vector3.new(a[1], a[2], a[3]), Vector3.new(b[1], b[2], b[3]), Vector3.new(c[1], c[2], c[3])
	local ab, ac, bc = bv - av, cv - av, cv - bv
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		cv, av = av, cv
	elseif ac.Magnitude > bc.Magnitude then
		bv, av = av, bv
	end
	ab, ac, bc = bv - av, cv - av, cv - bv
	if ac:Cross(ab).Magnitude < 0.00001 then
		return
	end
	local right = ac:Cross(ab).Unit
	local back = bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	for _, wedge in
		{
			{ center = (av + bv) / 2, right = right, back = back, length = math.abs(ab:Dot(back)) },
			{ center = (av + cv) / 2, right = -right, back = -back, length = math.abs(ac:Dot(back)) },
		}
	do
		if wedge.length < 0.00001 then
			continue
		end
		local x, y, z = CFrame.fromMatrix(wedge.center, wedge.right, up, wedge.back):ToEulerAnglesXYZ()
		self:part(
			name,
			{ wedge.center.X, wedge.center.Y, wedge.center.Z },
			{ 0.08, height, wedge.length },
			color,
			"Wedge",
			material,
			{ math.deg(x), math.deg(y), math.deg(z) }
		)
	end
end

function WorldKit.quad(
	self: Kit,
	name: string,
	a: Triple,
	b: Triple,
	c: Triple,
	d: Triple,
	color: Triple,
	material: string?
)
	self:triangle(name, a, b, c, color, material)
	self:triangle(name, a, c, d, color, material)
end

function WorldKit.cylinder(
	self: Kit,
	name: string,
	p: Triple,
	size: Triple,
	color: Triple,
	rotation: Triple?
): Part
	return self:part(name, p, size, color, "Cylinder", nil, rotation or { 0, 0, 90 })
end

function WorldKit.label(self: Kit, text: string, p: Triple, color: Triple?): Part
	local item = self:part("Sign", p, { 1, 1, 1 }, color or { 255, 245, 208 })
	item.transparency = 1
	item.collide = false
	item.label = text
	return item
end

function WorldKit.light(self: Kit, p: Triple, color: Triple, range: number): Part
	local item = self:ball("Pearl lamp", p, { 1.5, 1.5, 1.5 }, color)
	item.material = "Neon"
	item.light = range
	item.collide = false
	return item
end

function WorldKit.room(
	self: Kit,
	width: number,
	depth: number,
	height: number,
	wall: Triple,
	floor: Triple,
	sideDoor: boolean?
)
	self:part("Floor", { 0, -0.6, 0 }, { width + 2, 1.2, depth + 2 }, floor, nil, "WoodPlanks")
	self:part("Ceiling", { 0, height + 0.5, 0 }, { width + 2, 1, depth + 2 }, wall)
	self:part("Back wall", { 0, height / 2, -depth / 2 }, { width, height, 1.2 }, wall)
	self:part("Left wall", { -width / 2, height / 2, 0 }, { 1.2, height, depth }, wall)
	for _, sign in { -1, 1 } do
		self:part(
			"Entrance wall",
			{ sign * (width / 4 + 3), height / 2, depth / 2 },
			{ width / 2 - 6, height, 1.2 },
			wall
		)
	end
	self:part("Entrance lintel", { 0, 17 + (height - 17) / 2, depth / 2 }, { 12, height - 17, 1.2 }, wall)
	if sideDoor then
		for _, sign in { -1, 1 } do
			self:part(
				"Right wall",
				{ width / 2, height / 2, sign * (depth / 4 + 3) },
				{ 1.2, height, depth / 2 - 6 },
				wall
			)
		end
		self:part("Stair lintel", { width / 2, 17 + (height - 17) / 2, 0 }, { 1.2, height - 17, 12 }, wall)
	else
		self:part("Right wall", { width / 2, height / 2, 0 }, { 1.2, height, depth }, wall)
	end
	for x = -width / 2 + 12, width / 2 - 8, 24 do
		self:light({ x, height - 3, -8 }, { 255, 224, 155 }, 40)
	end
end

function WorldKit.sofa(self: Kit, p: Triple, color: Triple)
	self:part("Couch seat", { p[1], p[2] + 2.2, p[3] }, { 16, 4, 7 }, color)
	self:part("Couch back", { p[1], p[2] + 5, p[3] - 3 }, { 16, 7, 2 }, color)
	for _, sign in { -1, 1 } do
		self:ball("Rolled couch arm", { p[1] + sign * 8, p[2] + 4, p[3] }, { 3, 4, 8 }, color)
	end
end

function WorldKit.table(self: Kit, p: Triple, color: Triple)
	self:cylinder("Table top", { p[1], p[2] + 5, p[3] }, { 1, 10, 10 }, color)
	self:cylinder("Table pedestal", { p[1], p[2] + 2.5, p[3] }, { 5, 1.5, 1.5 }, color)
end

function WorldKit.bookshelf(self: Kit, p: Triple, width: number, color: Triple)
	self:part("Bookshelf backing", { p[1], p[2] + 9, p[3] }, { width, 18, 1 }, color)
	for tier = 0, 3 do
		self:part("Bamboo shelf", { p[1], p[2] + tier * 5, p[3] + 1.5 }, { width, 0.7, 4 }, color)
		if tier < 3 then
			for j = 1, math.floor(width / 1.4) do
				local n = j + tier * 11
				self:part(
					"Book",
					{ p[1] - width / 2 + j * 1.35, p[2] + tier * 5 + 2.2, p[3] + 1.5 },
					{ 1, 2.8 + n % 3 * 0.4, 2 },
					{ 70 + n * 47 % 160, 65 + n * 31 % 150, 85 + n * 19 % 150 }
				)
			end
		end
	end
end

function WorldKit.picture(self: Kit, p: Triple, width: number, height: number, motif: string, color: Triple)
	self:part("Picture frame", p, { width + 1, height + 1, 0.8 }, { 174, 115, 42 }, nil, "Wood")
	self:part("Painted canvas", { p[1], p[2], p[3] + 0.5 }, { width, height, 0.2 }, color)
	local face = self:ball(
		motif,
		{ p[1], p[2] + height * 0.1, p[3] + 0.7 },
		{ width * 0.45, height * 0.55, 0.2 },
		{ 136, 202, 177 }
	)
	face.collide = false
	self:label(motif, { p[1], p[2] - height / 2 - 1, p[3] + 1 })
end

function WorldKit.secret(self: Kit, id: string, name: string, p: Triple, color: Triple)
	local item = self:ball(name, p, { 2.5, 2.5, 2.5 }, color)
	item.secret = id
	item.material = "Neon"
	item.collide = false
	self:label(name, { p[1], p[2] + 3, p[3] })
end

function WorldKit.supply(self: Kit, p: Triple)
	local item = self:part("Supply chest", p, { 5, 4, 4 }, { 94, 170, 141 }, nil, "WoodPlanks")
	item.supply = true
	self:label("SUPPLIES · E", { p[1], p[2] + 4, p[3] })
end
return WorldKit
