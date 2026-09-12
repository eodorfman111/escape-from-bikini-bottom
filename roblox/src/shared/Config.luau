--!strict
export type Triple = { number }
export type Zone = { name: string, origin: Triple, size: Triple }
export type Exterior = { origin: Triple, scale: number, yaw: number }
export type Portal = {
	id: string,
	zone: string,
	target: string,
	position: Triple,
	normal: Triple,
	width: number,
	label: string,
	barricade: boolean,
}
export type Weapon = {
	name: string,
	price: number,
	damage: number,
	interval: number,
	magazine: number,
	reload: number,
	range: number,
	splash: number,
	slow: number,
	color: Triple,
	description: string,
}
export type Helper = {
	name: string,
	price: number,
	damage: number,
	interval: number,
	range: number,
	splash: number,
	slow: number,
	description: string,
	color: Triple,
}

local Config = {}
Config.MaxWaves = 5
Config.MaxHelpers = 3
Config.StartingCoins = 100
Config.DiscoveryCoins = 80
Config.KillCoins = 12
Config.WaveCoins = 60
Config.Spawn = { -46, 5, 83 }
Config.RoadZ = 47
Config.RoadWidth = 20
Config.Exteriors = {
	pineapple = { origin = { 0, 0, 0 }, scale = 0.62, yaw = 0 },
	moai = { origin = { -46, 0, 0 }, scale = 0.6, yaw = 0 },
	rock = { origin = { -92, 0, 0 }, scale = 0.6, yaw = 0 },
	krab = { origin = { 200, 0, -10 }, scale = 0.75, yaw = 0 },
	bucket = { origin = { 200, 0, 104 }, scale = 0.7, yaw = 180 },
} :: { [string]: Exterior }
Config.RockHinge = { 0, 0, -19 }
Config.FishSpawns = {
	{ -134, 3, 91 },
	{ -78, 3, 104 },
	{ -12, 3, 110 },
	{ 68, 3, 91 },
	{ 151, 3, 47 },
	{ 251, 3, 47 },
}

function Config.exteriorPoint(id: string, point: Triple): Triple
	local exterior = Config.Exteriors[id]
	local angle = math.rad(exterior.yaw)
	local x, y, z = point[1] * exterior.scale, point[2] * exterior.scale, point[3] * exterior.scale
	return {
		exterior.origin[1] + x * math.cos(angle) + z * math.sin(angle),
		exterior.origin[2] + y,
		exterior.origin[3] - x * math.sin(angle) + z * math.cos(angle),
	}
end
Config.Avatars =
	{ explorer = "Reef Explorer", sponge = "SpongeBob", patrick = "Patrick", squid = "Squidward" }
Config.Zones = {
	street = { name = "Conch Street", origin = { 70, 0, 65 }, size = { 540, 150, 370 } },
	sponge = { name = "Pineapple · living room & kitchen", origin = { 0, 0, 650 }, size = { 96, 26, 88 } },
	spongeLibrary = { name = "Pineapple · library", origin = { 0, 0, 850 }, size = { 96, 28, 88 } },
	spongeBedroom = {
		name = "Pineapple · bedroom & bathroom",
		origin = { 0, 0, 1050 },
		size = { 96, 26, 88 },
	},
	squid = { name = "Moai · living room & dining room", origin = { 300, 0, 650 }, size = { 96, 26, 88 } },
	squidLibrary = { name = "Moai · library", origin = { 300, 0, 850 }, size = { 96, 28, 88 } },
	squidStudio = { name = "Moai · portrait studio", origin = { 300, 0, 1050 }, size = { 96, 26, 88 } },
	patrick = {
		name = "Rock · sand living room & kitchen",
		origin = { -300, 0, 650 },
		size = { 96, 26, 88 },
	},
	krusty = {
		name = "Krusty Krab · dining room & grill",
		origin = { 600, 0, 650 },
		size = { 116, 30, 100 },
	},
	chum = {
		name = "Chum Bucket · restaurant & laboratory",
		origin = { 900, 0, 650 },
		size = { 116, 30, 100 },
	},
} :: { [string]: Zone }

Config.Portals = {} :: { Portal }
local function pair(
	id: string,
	zone: string,
	position: Triple,
	normal: Triple,
	targetZone: string,
	targetPosition: Triple,
	targetNormal: Triple,
	label: string,
	barricade: boolean
)
	local width = 10
	local exterior = Config.Exteriors[id]
	if zone == "street" and exterior then
		position = Config.exteriorPoint(id, position)
		local angle = math.rad(exterior.yaw)
		normal = { math.sin(angle), 0, math.cos(angle) }
		width *= exterior.scale
	end
	table.insert(Config.Portals, {
		id = id .. "-out",
		zone = zone,
		target = id .. "-in",
		position = position,
		normal = normal,
		width = width,
		label = label,
		barricade = barricade,
	})
	table.insert(Config.Portals, {
		id = id .. "-in",
		zone = targetZone,
		target = id .. "-out",
		position = targetPosition,
		normal = targetNormal,
		width = 10,
		label = "Return",
		barricade = false,
	})
end
pair(
	"pineapple",
	"street",
	{ 0, 0, 16 },
	{ 0, 0, 1 },
	"sponge",
	{ 0, 0, 694 },
	{ 0, 0, -1 },
	"SpongeBob's house",
	true
)
pair(
	"moai",
	"street",
	{ 0, 0, 16 },
	{ 0, 0, 1 },
	"squid",
	{ 300, 0, 694 },
	{ 0, 0, -1 },
	"Squidward's house",
	true
)
pair(
	"rock",
	"street",
	{ 0, 0, 16 },
	{ 0, 0, 1 },
	"patrick",
	{ -300, 0, 694 },
	{ 0, 0, -1 },
	"Patrick's house",
	true
)
pair(
	"krab",
	"street",
	{ 0, 0, 10 },
	{ 0, 0, 1 },
	"krusty",
	{ 600, 0, 700 },
	{ 0, 0, -1 },
	"Krusty Krab",
	true
)
pair(
	"bucket",
	"street",
	{ 0, 0, 10 },
	{ 0, 0, 1 },
	"chum",
	{ 900, 0, 700 },
	{ 0, 0, -1 },
	"Chum Bucket",
	true
)
pair(
	"pineapple-stairs",
	"sponge",
	{ 48, 0, 650 },
	{ -1, 0, 0 },
	"spongeLibrary",
	{ 0, 0, 894 },
	{ 0, 0, -1 },
	"Library stairs",
	false
)
pair(
	"pineapple-slide",
	"spongeLibrary",
	{ 48, 0, 850 },
	{ -1, 0, 0 },
	"spongeBedroom",
	{ 0, 0, 1094 },
	{ 0, 0, -1 },
	"Bedroom slide",
	false
)
pair(
	"moai-stairs",
	"squid",
	{ 348, 0, 650 },
	{ -1, 0, 0 },
	"squidLibrary",
	{ 300, 0, 894 },
	{ 0, 0, -1 },
	"Library stairs",
	false
)
pair(
	"moai-elevator",
	"squidLibrary",
	{ 348, 0, 850 },
	{ -1, 0, 0 },
	"squidStudio",
	{ 300, 0, 1094 },
	{ 0, 0, -1 },
	"Portrait studio",
	false
)

Config.Weapons = {
	bubble = {
		name = "Bubble Blaster",
		price = 0,
		damage = 24,
		interval = 0.32,
		magazine = 14,
		reload = 1.5,
		range = 180,
		splash = 0,
		slow = 0.3,
		color = { 95, 225, 250 },
		description = "Quick bubbles briefly slow a fish.",
	},
	spatula = {
		name = "Spatula Launcher",
		price = 220,
		damage = 72,
		interval = 0.85,
		magazine = 6,
		reload = 2,
		range = 200,
		splash = 4,
		slow = 0,
		color = { 250, 173, 56 },
		description = "Heavy spatulas hit hard and splash nearby fish.",
	},
	jelly = {
		name = "Jellyfish Zapper",
		price = 380,
		damage = 30,
		interval = 0.65,
		magazine = 10,
		reload = 2,
		range = 130,
		splash = 12,
		slow = 1.4,
		color = { 252, 121, 220 },
		description = "Electric bursts zap and slow a cluster.",
	},
} :: { [string]: Weapon }

Config.Helpers = {
	sponge = {
		name = "SpongeBob",
		price = 100,
		damage = 18,
		interval = 1.2,
		range = 55,
		splash = 0,
		slow = 0.5,
		color = { 251, 221, 60 },
		description = "Bubble shots keep distant fish busy.",
	},
	patrick = {
		name = "Patrick",
		price = 180,
		damage = 42,
		interval = 2.4,
		range = 45,
		splash = 7,
		slow = 0,
		color = { 246, 153, 166 },
		description = "Throws rocks that hit several fish.",
	},
	sandy = {
		name = "Sandy",
		price = 300,
		damage = 65,
		interval = 1.1,
		range = 14,
		splash = 9,
		slow = 0,
		color = { 240, 238, 222 },
		description = "Karate sweeps knock back close attackers.",
	},
	gary = {
		name = "Gary",
		price = 160,
		damage = 8,
		interval = 1.8,
		range = 18,
		splash = 11,
		slow = 3,
		color = { 163, 220, 234 },
		description = "Leaves slime trails that slow passing fish.",
	},
} :: { [string]: Helper }
return Config
