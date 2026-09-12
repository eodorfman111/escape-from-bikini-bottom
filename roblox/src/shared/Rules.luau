--!strict
export type Wallet = {
	coins: number,
	weapons: { [string]: boolean },
	helpers: { string },
	discoveries: { [string]: boolean },
}
export type Magazine = { ammo: number, lastShot: number, reloadAt: number }
export type Bucket = { tokens: number, updated: number }
export type Triple = { number }
local Rules = {}

function Rules.finite(n: number): boolean
	return n == n and math.abs(n) < math.huge
end

function Rules.purchase(
	wallet: Wallet,
	kind: string,
	id: string,
	price: number,
	limit: number
): (boolean, string)
	if kind ~= "weapon" and kind ~= "helper" then
		return false, "Unknown purchase"
	end
	if not Rules.finite(price) or price < 0 then
		return false, "Invalid price"
	end
	if kind == "weapon" and wallet.weapons[id] then
		return false, "Already owned"
	end
	if kind == "helper" then
		if table.find(wallet.helpers, id) then
			return false, "Already on your crew"
		end
		if #wallet.helpers >= limit then
			return false, "Crew is full"
		end
	end
	if wallet.coins < price then
		return false, "Find more coins first"
	end
	wallet.coins -= price
	if kind == "weapon" then
		wallet.weapons[id] = true
	else
		table.insert(wallet.helpers, id)
	end
	return true, "Purchased!"
end

function Rules.discover(wallet: Wallet, id: string, reward: number): boolean
	if wallet.discoveries[id] then
		return false
	end
	wallet.discoveries[id] = true
	wallet.coins += reward
	return true
end

function Rules.finishReload(mag: Magazine, now: number, capacity: number)
	if mag.reloadAt > 0 and now >= mag.reloadAt then
		mag.ammo = capacity
		mag.reloadAt = 0
	end
end

function Rules.reload(mag: Magazine, now: number, capacity: number, seconds: number): boolean
	Rules.finishReload(mag, now, capacity)
	if mag.reloadAt > 0 or mag.ammo == capacity then
		return false
	end
	mag.reloadAt = now + seconds
	return true
end

function Rules.shoot(mag: Magazine, now: number, interval: number, capacity: number): boolean
	Rules.finishReload(mag, now, capacity)
	if mag.reloadAt > 0 or mag.ammo <= 0 or now - mag.lastShot < interval then
		return false
	end
	mag.lastShot = now
	mag.ammo -= 1
	return true
end

function Rules.admit(bucket: Bucket, now: number): boolean
	bucket.tokens = math.min(30, bucket.tokens + math.max(0, now - bucket.updated) * 15)
	bucket.updated = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function Rules.crossed(
	previous: Triple,
	current: Triple,
	center: Triple,
	normal: Triple,
	width: number
): boolean
	local a = (previous[1] - center[1]) * normal[1] + (previous[3] - center[3]) * normal[3]
	local b = (current[1] - center[1]) * normal[1] + (current[3] - center[3]) * normal[3]
	if a < 0 or b > 0 or a == b then
		return false
	end
	local t = a / (a - b)
	local x = previous[1] + (current[1] - previous[1]) * t - center[1]
	local z = previous[3] + (current[3] - previous[3]) * t - center[3]
	local y = previous[2] + (current[2] - previous[2]) * t - center[2]
	return math.abs(x * normal[3] - z * normal[1]) <= width / 2 and y >= 0 and y <= 14
end

function Rules.waveCount(wave: number, players: number): number
	return math.min(40, 6 + wave * 3 + players * 2)
end

function Rules.speed(base: number, slowUntil: number, now: number): number
	return base * (if slowUntil > now then 0.35 else 1)
end

function Rules.nextPhase(phase: string, alive: number, fish: number, wave: number, maximum: number): string
	if phase ~= "combat" then
		return phase
	end
	if alive == 0 then
		return "defeat"
	elseif fish == 0 then
		return if wave >= maximum then "victory" else "intermission"
	end
	return phase
end
return Rules
