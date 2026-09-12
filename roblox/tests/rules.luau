--!strict
-- selene: allow(incorrect_standard_library_use)
local Rules = require("../src/shared/Rules")
-- selene: allow(incorrect_standard_library_use)
local Config = require("../src/shared/Config")

local checks = 0
local function expect(value: boolean, message: string)
	assert(value, message)
	checks += 1
end
local wallet: Rules.Wallet = { coins = 600, weapons = { bubble = true }, helpers = {}, discoveries = {} }
expect(Rules.purchase(wallet, "weapon", "spatula", Config.Weapons.spatula.price, 3), "Buy valid weapon")
expect(wallet.coins == 380 and wallet.weapons.spatula, "Debit exactly once")
expect(
	not Rules.purchase(wallet, "weapon", "spatula", 220, 3) and wallet.coins == 380,
	"Replay cannot charge twice"
)
expect(
	not Rules.purchase(wallet, "helper", "sandy", 1000, 3) and #wallet.helpers == 0,
	"Insufficient funds are atomic"
)
expect(not Rules.purchase(wallet, "other", "bad", -10, 3), "Reject unknown category")
expect(not Rules.purchase(wallet, "helper", "bad", 0 / 0, 3), "Reject nonfinite price")
for _, id in { "sponge", "gary", "patrick" } do
	wallet.coins += 200
	expect(Rules.purchase(wallet, "helper", id, Config.Helpers[id].price, 3), "Hire helper")
end
local before = wallet.coins
expect(
	not Rules.purchase(wallet, "helper", "sandy", 1, 3) and wallet.coins == before,
	"Full crew cannot overspend"
)
expect(not Rules.purchase(wallet, "helper", "gary", 1, 3), "Duplicate helper blocked")
expect(Rules.discover(wallet, "pineapple-secret", 80), "Discovery awards")
expect(
	not Rules.discover(wallet, "pineapple-secret", 80) and wallet.coins == before + 80,
	"Discovery replay cannot farm coins"
)

local weapon = Config.Weapons.bubble
local mag: Rules.Magazine = { ammo = weapon.magazine, lastShot = -math.huge, reloadAt = 0 }
expect(Rules.shoot(mag, 0, weapon.interval, weapon.magazine), "First shot")
expect(
	not Rules.shoot(mag, 0.01, weapon.interval, weapon.magazine) and mag.ammo == 13,
	"Spam cannot bypass cooldown or consume ammo"
)
expect(Rules.reload(mag, 0.1, weapon.magazine, weapon.reload), "Reload partially empty weapon")
expect(not Rules.shoot(mag, 1, weapon.interval, weapon.magazine), "Cannot shoot during reload")
expect(not Rules.reload(mag, 1, weapon.magazine, weapon.reload), "Cannot restart active reload")
expect(
	Rules.shoot(mag, 2, weapon.interval, weapon.magazine) and mag.ammo == 13,
	"Reload finishes before next shot"
)
mag.ammo = 0
expect(not Rules.shoot(mag, 3, weapon.interval, weapon.magazine), "Empty magazine cannot fire")
local bucket: Rules.Bucket = { tokens = 2, updated = 0 }
expect(Rules.admit(bucket, 0), "Burst token one")
expect(Rules.admit(bucket, 0), "Burst token two")
expect(not Rules.admit(bucket, 0), "Burst limit")
expect(Rules.admit(bucket, 1), "Token refill")
expect(
	not Rules.finite(math.huge) and not Rules.finite(0 / 0) and Rules.finite(-25),
	"Vector components must be finite"
)

for _, portal in Config.Portals do
	local n, c = portal.normal, portal.position
	expect(
		Rules.crossed(
			{ c[1] + n[1] * 2, 3, c[3] + n[3] * 2 },
			{ c[1] - n[1] * 2, 3, c[3] - n[3] * 2 },
			c,
			n,
			portal.width
		),
		"Every threshold works"
	)
	expect(
		not Rules.crossed(
			{ c[1] - n[1], 3, c[3] - n[3] },
			{ c[1] + n[1], 3, c[3] + n[3] },
			c,
			n,
			portal.width
		),
		"Wrong direction does not teleport"
	)
	expect(
		not Rules.crossed(
			{ c[1] + n[1] + n[3] * 10, 3, c[3] + n[3] - n[1] * 10 },
			{ c[1] - n[1] + n[3] * 10, 3, c[3] - n[3] - n[1] * 10 },
			c,
			n,
			portal.width
		),
		"Outside doorway stays in zone"
	)
end
expect(Rules.nextPhase("combat", 0, 0, 1, 5) == "defeat", "Last fighter death takes precedence")
expect(Rules.nextPhase("combat", 2, 0, 4, 5) == "intermission", "Cooperative wave clear")
expect(Rules.nextPhase("combat", 2, 0, 5, 5) == "victory", "Final wave victory")
expect(Rules.nextPhase("combat", 1, 1, 5, 5) == "combat", "Surviving enemy prevents victory")
expect(Rules.waveCount(5, 20) == 40, "Population scales within server cap")
expect(Rules.speed(10, 3, 2) == 3.5 and Rules.speed(10, 3, 3) == 10, "Gary slow expires precisely")
local other: Rules.Wallet = { coins = 100, weapons = { bubble = true }, helpers = {}, discoveries = {} }
expect(
	Rules.discover(other, "pineapple-secret", 80) and other.coins == 180,
	"Discovery ownership is per player"
)
print("PASS", checks, "combat, economy, portal and multiplayer-state assertions")
