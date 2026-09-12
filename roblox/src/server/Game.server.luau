--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Shared = ReplicatedStorage:WaitForChild("Conch")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Models = require(Shared.Models)
local Protocol = require(Shared.Protocol)
local Action = Shared:WaitForChild("Action") :: RemoteEvent
local Update = Shared:WaitForChild("Update") :: RemoteEvent
local Effect = Shared:WaitForChild("Effect") :: RemoteEvent
local world = workspace:WaitForChild("ConchWorld")
local actors = Instance.new("Folder")
actors.Name, actors.Parent = "ConchActors", workspace
Players.CharacterAutoLoads = false

type Crew = { id: string, model: Model, nextAttack: number }
type State = {
	wallet: Rules.Wallet,
	magazines: { [string]: Rules.Magazine },
	weapon: string,
	avatar: string,
	zone: string,
	ready: boolean,
	survival: boolean,
	bucket: Rules.Bucket,
	previous: Vector3?,
	lastPortal: number,
	supplyAt: number,
	crew: { Crew },
	message: string,
	messageUntil: number,
	loading: boolean,
}
type Fish = {
	model: Model,
	zone: string,
	health: number,
	slowUntil: number,
	attackAt: number,
	pathAt: number,
	pending: boolean,
	waypoints: { Vector3 },
	waypoint: number,
}
type Slime = { zone: string, position: Vector3, expires: number, owner: Player }
local states: { [Player]: State } = {}
local fish: { Fish } = {}
local slime: { Slime } = {}
local barriers: { [string]: number } = {}
local portals: { [string]: Config.Portal } = {}
local doorParts: { [string]: BasePart } = {}
local totalDiscoveries = 0
local phase, wave, deadline = "lobby", 0, 0
local lastBroadcast, accumulator = 0, 0

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end
local function triple(v: Vector3): { number }
	return { v.X, v.Y, v.Z }
end
local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end
local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end
local function humanOf(player: Player): Humanoid?
	return if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
end
local function alive(player: Player): boolean
	local humanoid = humanOf(player)
	return humanoid ~= nil and humanoid.Health > 0
end
local function toast(player: Player, message: string)
	local state = states[player]
	if state then
		state.message, state.messageUntil = message, os.clock() + 5
	end
end
local function everyone(message: string)
	for player in states do
		toast(player, message)
	end
end
local function lineClear(a: Vector3, b: Vector3): boolean
	if (b - a).Magnitude < 0.05 then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	return workspace:Raycast(a, b - a, params) == nil
end
local function canMove(a: Vector3, b: Vector3): boolean
	if (b - a).Magnitude < 0.01 then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	return workspace:Blockcast(CFrame.new(a), Vector3.new(2.6, 5, 2.6), b - a, params) == nil
end
local function effect(kind: string, a: Vector3, b: Vector3, color: Color3, amount: number)
	Effect:FireAllClients(kind, a, b, color, amount)
end
local function clearFish()
	for _, enemy in fish do
		enemy.model:Destroy()
	end
	table.clear(fish)
	table.clear(slime)
end
local function hit(enemy: Fish, damage: number, slow: number, owner: Player)
	if enemy.health <= 0 then
		return
	end
	enemy.health -= damage
	enemy.slowUntil = math.max(enemy.slowUntil, os.clock() + slow)
	if enemy.health <= 0 then
		local state = states[owner]
		if state then
			state.wallet.coins += Config.KillCoins
		end
		effect("pop", enemy.model:GetPivot().Position, Vector3.zero, Color3.fromRGB(248, 211, 95), 2)
		enemy.model:Destroy()
	end
end
local function area(
	position: Vector3,
	zone: string,
	damage: number,
	radius: number,
	slow: number,
	owner: Player
)
	for _, enemy in fish do
		if enemy.health > 0 and enemy.zone == zone then
			local point = enemy.model:GetPivot().Position
			if (point - position).Magnitude <= radius and lineClear(position, point) then
				hit(enemy, damage, slow, owner)
			end
		end
	end
end
local function livingFighters(): { Player }
	local result: { Player } = {}
	for player, state in states do
		if state.ready and state.survival and alive(player) then
			table.insert(result, player)
		end
	end
	return result
end
for _, portal in Config.Portals do
	portals[portal.id] = portal
end
local function barrierId(portal: Config.Portal): string?
	if portal.barricade then
		return portal.id
	end
	local target = portals[portal.target]
	return if target.barricade then target.id else nil
end
local function nextDoor(from: string, target: string): Config.Portal?
	local queue = { from }
	local visited: { [string]: boolean } = { [from] = true }
	local first: { [string]: Config.Portal } = {}
	local index = 1
	while index <= #queue do
		local zone = queue[index]
		index += 1
		for _, door in Config.Portals do
			if door.zone == zone then
				local destination = portals[door.target].zone
				if not visited[destination] then
					visited[destination] = true
					first[destination] = first[zone] or door
					if destination == target then
						return first[destination]
					end
					table.insert(queue, destination)
				end
			end
		end
	end
	return nil
end
local function teleport(player: Player, state: State, portal: Config.Portal, root: BasePart)
	local destination = portals[portal.target]
	local from, toward = -vec(portal.normal), vec(destination.normal)
	local yaw = math.atan2(-toward.X, -toward.Z) - math.atan2(-from.X, -from.Z)
	local rotation = CFrame.Angles(0, yaw, 0)
	local position = vec(destination.position) + toward * 5 + Vector3.new(0, 3.2, 0)
	if player.Character then
		player.Character:PivotTo(CFrame.new(position) * rotation * root.CFrame.Rotation)
	end
	root.AssemblyLinearVelocity = rotation:VectorToWorldSpace(root.AssemblyLinearVelocity)
	state.zone, state.previous, state.lastPortal = destination.zone, position, os.clock()
	player:SetAttribute("ConchZone", state.zone)
	Effect:FireClient(player, "portal", Vector3.new(0, yaw, 0), Vector3.zero, Color3.new(0.2, 0.8, 0.9), 0.2)
	for _, member in state.crew do
		member.model:PivotTo(CFrame.new(position + Vector3.new(3, 0, 3)))
	end
end
local function travel(player: Player, state: State, now: number)
	local root = rootOf(player)
	if not root or not alive(player) then
		state.previous = nil
		return
	end
	local position, previous = root.Position, state.previous
	if not Rules.finite(position.X) or not Rules.finite(position.Y) or not Rules.finite(position.Z) then
		return
	end
	if previous and now - state.lastPortal > 0.8 then
		for _, portal in Config.Portals do
			if
				portal.zone == state.zone
				and (position - vec(portal.position)).Magnitude < 30
				and Rules.crossed(
					triple(previous),
					triple(position),
					portal.position,
					portal.normal,
					portal.width
				)
			then
				teleport(player, state, portal, root)
				return
			end
		end
	end
	local zone = Config.Zones[state.zone]
	local offset = position - vec(zone.origin)
	if
		math.abs(offset.X) > zone.size[1] / 2 + 10
		or math.abs(offset.Z) > zone.size[3] / 2 + 10
		or position.Y < -20
	then
		local safe = if state.zone == "street"
			then vec(Config.Spawn)
			else vec(zone.origin) + Vector3.new(0, 4, 30)
		if player.Character then
			player.Character:PivotTo(CFrame.new(safe))
		end
		state.previous = safe
	else
		state.previous = position
	end
end
local function loadCharacter(player: Player, state: State)
	if state.loading then
		return
	end
	state.loading = true
	local ok = pcall(function()
		player:LoadCharacterAsync()
	end)
	state.loading = false
	if not ok then
		state.ready = false
		toast(player, "Character could not load. Choose your character again.")
	end
end
local function join(player: Player)
	if states[player] then
		return
	end
	local magazines: { [string]: Rules.Magazine } = {}
	for id, weapon in Config.Weapons do
		magazines[id] = { ammo = weapon.magazine, lastShot = -math.huge, reloadAt = 0 }
	end
	local state: State = {
		wallet = { coins = Config.StartingCoins, weapons = { bubble = true }, helpers = {}, discoveries = {} },
		magazines = magazines,
		weapon = "bubble",
		avatar = "explorer",
		zone = "street",
		ready = false,
		survival = false,
		bucket = { tokens = 30, updated = os.clock() },
		previous = nil,
		lastPortal = 0,
		supplyAt = 0,
		crew = {},
		message = "",
		messageUntil = 0,
		loading = false,
	}
	states[player] = state
	player.CharacterAppearanceLoaded:Connect(function(character)
		Models.dress(character, state.avatar)
	end)
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart", 15)
		local humanoid = character:WaitForChild("Humanoid", 15)
		if not root or not root:IsA("BasePart") or not humanoid or not humanoid:IsA("Humanoid") then
			state.ready = false
			return
		end
		humanoid.WalkSpeed, humanoid.MaxHealth, humanoid.Health = 20, 100, 100
		humanoid.UseJumpPower, humanoid.JumpPower = true, 42
		character:PivotTo(CFrame.new(vec(Config.Spawn)))
		state.zone, state.previous, state.lastPortal = "street", nil, os.clock()
		player:SetAttribute("ConchZone", "street")
		for id, magazine in state.magazines do
			magazine.ammo, magazine.reloadAt = Config.Weapons[id].magazine, 0
		end
		Models.dress(character, state.avatar)
		humanoid.Died:Once(function()
			toast(player, "Rescued! Returning to Conch Street in five seconds.")
			task.delay(5, function()
				if states[player] == state and state.ready then
					loadCharacter(player, state)
				end
			end)
		end)
	end)
end
Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do
	join(player)
end
Players.PlayerRemoving:Connect(function(player)
	local state = states[player]
	if state then
		for _, member in state.crew do
			member.model:Destroy()
		end
	end
	states[player] = nil
end)

local function fire(player: Player, state: State, direction: Vector3)
	local root = rootOf(player)
	if
		not root
		or not alive(player)
		or not Rules.finite(direction.X)
		or not Rules.finite(direction.Y)
		or not Rules.finite(direction.Z)
		or direction.Magnitude < 0.01
		or direction.Magnitude > 2
	then
		return
	end
	local weapon = Config.Weapons[state.weapon]
	if not Rules.shoot(state.magazines[state.weapon], os.clock(), weapon.interval, weapon.magazine) then
		return
	end
	local head = if player.Character then player.Character:FindFirstChild("Head") else nil
	local origin = if head and head:IsA("BasePart")
		then head.Position
		else root.Position + Vector3.new(0, 1.5, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world, actors }
	local result = workspace:Raycast(origin, direction.Unit * weapon.range, params)
	local endpoint = if result then result.Position else origin + direction.Unit * weapon.range
	effect("shot", origin, endpoint, rgb(weapon.color), if state.weapon == "jelly" then 0.25 else 0.12)
	if result then
		for _, enemy in fish do
			if
				enemy.health > 0
				and enemy.zone == state.zone
				and result.Instance:IsDescendantOf(enemy.model)
			then
				if weapon.splash > 0 then
					area(
						enemy.model:GetPivot().Position,
						enemy.zone,
						weapon.damage,
						weapon.splash,
						weapon.slow,
						player
					)
					effect("burst", endpoint, Vector3.zero, rgb(weapon.color), weapon.splash)
				else
					hit(enemy, weapon.damage, weapon.slow, player)
				end
				break
			end
		end
	end
end

Action.OnServerEvent:Connect(function(player: Player, action: unknown, payload: unknown)
	local state = states[player]
	if not state or typeof(action) ~= "string" or not Rules.admit(state.bucket, os.clock()) then
		return
	end
	if action == "start" and typeof(payload) == "string" then
		if not state.ready and Config.Avatars[payload] then
			state.avatar, state.ready = payload, true
			task.spawn(loadCharacter, player, state)
		end
		return
	end
	if not state.ready or not alive(player) then
		return
	end
	if action == "fire" and typeof(payload) == "Vector3" then
		fire(player, state, payload)
	elseif action == "reload" then
		local weapon = Config.Weapons[state.weapon]
		Rules.reload(state.magazines[state.weapon], os.clock(), weapon.magazine, weapon.reload)
	elseif action == "equip" and typeof(payload) == "string" and state.wallet.weapons[payload] then
		state.weapon = payload
	elseif (action == "weapon" or action == "helper") and typeof(payload) == "string" then
		local product = if action == "weapon" then Config.Weapons[payload] else Config.Helpers[payload]
		if not product then
			return
		end
		local ok, message = Rules.purchase(state.wallet, action, payload, product.price, Config.MaxHelpers)
		toast(player, message)
		if ok then
			if action == "weapon" then
				state.weapon = payload
			else
				local model = Models.creature(payload)
				model.Parent = actors
				local root = rootOf(player)
				if root then
					model:PivotTo(root.CFrame * CFrame.new(4, 0, 4))
				end
				table.insert(state.crew, { id = payload, model = model, nextAttack = 0 })
			end
		end
	elseif action == "dismiss" and typeof(payload) == "string" then
		local index = table.find(state.wallet.helpers, payload)
		if index then
			table.remove(state.wallet.helpers, index)
			for i = #state.crew, 1, -1 do
				if state.crew[i].id == payload then
					state.crew[i].model:Destroy()
					table.remove(state.crew, i)
				end
			end
			toast(player, "Helper dismissed. Hiring again costs coins.")
		end
	elseif action == "survival" then
		state.survival = true
		if phase == "lobby" or phase == "defeat" or phase == "victory" then
			clearFish()
			wave, phase, deadline = 0, "intermission", os.clock() + 20
			everyone("The fish are coming! Stock up and hire your crew.")
		end
	elseif action == "explore" then
		state.survival = false
		toast(player, "Exploration mode: fish will leave you alone.")
	end
end)

for _, descendant in world:GetDescendants() do
	if descendant:IsA("BasePart") then
		local id = descendant:GetAttribute("Portal")
		if typeof(id) == "string" then
			doorParts[id] = descendant
		end
	end
	if descendant:IsA("BasePart") and typeof(descendant:GetAttribute("Discovery")) == "string" then
		totalDiscoveries += 1
	end
	if not descendant:IsA("ProximityPrompt") then
		continue
	end
	local target = descendant.Parent
	if not target or not target:IsA("BasePart") then
		continue
	end
	descendant.Triggered:Connect(function(player: Player)
		local state, root = states[player], rootOf(player)
		local targetZone = target:GetAttribute("Zone")
		if not state or not root or not state.ready or not alive(player) or targetZone ~= state.zone then
			return
		end
		if (root.Position - target.Position).Magnitude > descendant.MaxActivationDistance + 3 then
			return
		end
		local now = os.clock()
		if not Rules.admit(state.bucket, now) then
			return
		end
		local discovery = target:GetAttribute("Discovery")
		local portalId = target:GetAttribute("Portal")
		if typeof(discovery) == "string" then
			if Rules.discover(state.wallet, discovery, Config.DiscoveryCoins) then
				toast(player, "Discovered " .. target.Name .. " • +" .. Config.DiscoveryCoins .. " coins")
				Effect:FireClient(player, "discovery", target.Position, Vector3.zero, target.Color, 3)
			else
				toast(player, "You already discovered this.")
			end
		elseif target:GetAttribute("Supply") == true then
			if now < state.supplyAt then
				toast(player, "Supplies replenish in " .. math.ceil(state.supplyAt - now) .. " seconds")
				return
			end
			local human = humanOf(player)
			if human then
				human.Health = human.MaxHealth
			end
			for id, magazine in state.magazines do
				magazine.ammo, magazine.reloadAt = Config.Weapons[id].magazine, 0
			end
			state.supplyAt = now + 30
			toast(player, "Health and magazines restored")
		elseif typeof(portalId) == "string" and portals[portalId] then
			local key = barrierId(portals[portalId])
			if key and (barriers[key] or 0) <= now and state.wallet.coins >= 40 then
				state.wallet.coins -= 40
				barriers[key] = now + 15
				toast(player, "Door barricaded for 15 seconds. Your crew can pass.")
			else
				toast(player, "Barricade costs 40 coins; wait for an active barrier to expire.")
			end
		end
	end)
end

local function spawnWave(fighters: { Player })
	wave += 1
	phase = "combat"
	local count = Rules.waveCount(wave, #fighters)
	for i = 1, count do
		local enemy: Fish = {
			model = Models.creature("fish", true),
			zone = "street",
			health = 40 + wave * 15,
			slowUntil = 0,
			attackAt = 0,
			pathAt = os.clock() + i * 0.08,
			pending = false,
			waypoints = {},
			waypoint = 1,
		}
		enemy.model.Parent = actors
		enemy.model:PivotTo(CFrame.new(-175 + (i * 41 % 400), 3, 123 + i % 4 * 5))
		table.insert(fish, enemy)
	end
	everyone("Wave " .. wave .. " • " .. count .. " restless fish")
end

local function navigate(enemy: Fish, goal: Vector3, now: number, dt: number)
	local position = enemy.model:GetPivot().Position
	if now >= enemy.pathAt and not enemy.pending then
		enemy.pathAt, enemy.pending = now + 2.5, true
		task.spawn(function()
			local zone = enemy.zone
			local path = PathfindingService:CreatePath({
				AgentRadius = 1.6,
				AgentHeight = 6,
				AgentCanJump = false,
				WaypointSpacing = 5,
			})
			local ok = pcall(function()
				path:ComputeAsync(position, goal)
			end)
			if enemy.health > 0 and enemy.zone == zone and ok and path.Status == Enum.PathStatus.Success then
				local points: { Vector3 } = {}
				for _, waypoint in path:GetWaypoints() do
					table.insert(points, Vector3.new(waypoint.Position.X, 3, waypoint.Position.Z))
				end
				enemy.waypoints, enemy.waypoint = points, 2
			end
			enemy.pending = false
		end)
	end
	local target = enemy.waypoints[enemy.waypoint]
	if canMove(position, Vector3.new(goal.X, 3, goal.Z)) then
		target = goal
	end
	if not target then
		return
	end
	target = Vector3.new(target.X, 3, target.Z)
	local delta = target - position
	if delta.Magnitude < 1 then
		enemy.waypoint += 1
	elseif canMove(position, position + delta.Unit * math.min(delta.Magnitude, 2)) then
		local distance = math.min(delta.Magnitude, Rules.speed(8 + wave * 0.6, enemy.slowUntil, now) * dt)
		local nextPosition = position + delta.Unit * distance
		enemy.model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + delta.Unit))
	end
end
local function updateFish(now: number, dt: number, fighters: { Player })
	for i = #fish, 1, -1 do
		local enemy = fish[i]
		if enemy.health <= 0 then
			table.remove(fish, i)
			continue
		end
		local position = enemy.model:GetPivot().Position
		local chosen: Player? = nil
		local nearest = math.huge
		for _, player in fighters do
			local root = rootOf(player)
			if root then
				local distance = if states[player].zone == enemy.zone
					then (root.Position - position).Magnitude
					else 10000
				if distance < nearest then
					chosen, nearest = player, distance
				end
			end
		end
		if not chosen then
			continue
		end
		local root = rootOf(chosen)
		if not root then
			continue
		end
		local goal = root.Position
		if states[chosen].zone ~= enemy.zone then
			local portal = nextDoor(enemy.zone, states[chosen].zone)
			if not portal then
				continue
			end
			goal = vec(portal.position) + vec(portal.normal) * 2 + Vector3.new(0, 3, 0)
			if (position - goal).Magnitude < 3 then
				local key = barrierId(portal)
				if key and (barriers[key] or 0) > now then
					continue
				end
				local destination = portals[portal.target]
				local point = vec(destination.position) + vec(destination.normal) * 5 + Vector3.new(0, 3, 0)
				enemy.model:PivotTo(CFrame.lookAt(point, point + vec(destination.normal)))
				enemy.zone, enemy.waypoints, enemy.pathAt = destination.zone, {}, now
				continue
			end
		elseif nearest < 5 and now >= enemy.attackAt and lineClear(position, root.Position) then
			local human = humanOf(chosen)
			if human then
				human:TakeDamage(8 + wave * 2)
			end
			enemy.attackAt = now + 1
			Effect:FireClient(chosen, "hurt", position, Vector3.zero, Color3.new(1, 0.2, 0.2), 0.25)
		end
		navigate(enemy, goal, now, dt)
	end
end

local function updateCrew(player: Player, state: State, now: number, dt: number)
	local root = rootOf(player)
	if not root or not alive(player) then
		return
	end
	for i, member in state.crew do
		local spec = Config.Helpers[member.id]
		local anchor = (root.CFrame * CFrame.new((i - 2) * 4, 0, 6)).Position
		anchor = Vector3.new(anchor.X, 3, anchor.Z)
		local position = member.model:GetPivot().Position
		local closest: Fish? = nil
		local nearest = spec.range
		if state.survival then
			for _, enemy in fish do
				if enemy.zone == state.zone and enemy.health > 0 then
					local distance = (enemy.model:GetPivot().Position - root.Position).Magnitude
					if distance < nearest and lineClear(root.Position, enemy.model:GetPivot().Position) then
						closest, nearest = enemy, distance
					end
				end
			end
		end
		if closest and member.id == "sandy" then
			anchor = closest.model:GetPivot().Position + Vector3.new(2, 0, 0)
		end
		local step = if (position - anchor).Magnitude > 70
			then anchor
			else position:Lerp(anchor, math.min(1, dt * 5))
		local facing = if closest then closest.model:GetPivot().Position else step + root.CFrame.LookVector
		if (facing - step).Magnitude > 0.01 then
			member.model:PivotTo(CFrame.lookAt(step, Vector3.new(facing.X, step.Y, facing.Z)))
		end
		if now < member.nextAttack or not state.survival then
			continue
		end
		if member.id == "gary" then
			member.nextAttack = now + spec.interval
			table.insert(slime, { zone = state.zone, position = step, expires = now + 7, owner = player })
			effect("slime", Vector3.new(step.X, 0.15, step.Z), Vector3.zero, Color3.fromRGB(123, 223, 174), 7)
		elseif closest and lineClear(step, closest.model:GetPivot().Position) then
			member.nextAttack = now + spec.interval
			local point = closest.model:GetPivot().Position
			if member.id == "sandy" and (step - point).Magnitude > 6 then
				member.nextAttack = now + 0.2
				continue
			end
			if spec.splash > 0 then
				area(point, state.zone, spec.damage, spec.splash, spec.slow, player)
				effect("burst", point, Vector3.zero, rgb(spec.color), spec.splash)
			else
				hit(closest, spec.damage, spec.slow, player)
			end
			effect(if member.id == "patrick" then "rock" else "shot", step, point, rgb(spec.color), 0.18)
			if member.id == "sandy" and closest.health > 0 then
				local push = root.CFrame.LookVector * 4
				if lineClear(point, point + push) then
					closest.model:PivotTo(closest.model:GetPivot() + push)
				end
			end
		end
	end
end
local function broadcast(now: number)
	for player, state in states do
		local weapon = Config.Weapons[state.weapon]
		local mag = state.magazines[state.weapon]
		Rules.finishReload(mag, now, weapon.magazine)
		local discoveries = 0
		for _ in state.wallet.discoveries do
			discoveries += 1
		end
		local humanoid = humanOf(player)
		local packet: Protocol.Snapshot = {
			coins = state.wallet.coins,
			health = if humanoid then math.ceil(humanoid.Health) else 0,
			ammo = mag.ammo,
			capacity = weapon.magazine,
			reloading = mag.reloadAt > now,
			weapon = state.weapon,
			weapons = state.wallet.weapons,
			helpers = state.wallet.helpers,
			discoveries = state.wallet.discoveries,
			discoveryCount = discoveries,
			discoveryTotal = totalDiscoveries,
			zone = state.zone,
			wave = wave,
			enemies = #fish,
			phase = phase,
			countdown = math.max(0, math.ceil(deadline - now)),
			ready = state.ready,
			survival = state.survival,
			message = if now < state.messageUntil then state.message else "",
		}
		Update:FireClient(player, packet)
	end
end
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.1 then
		return
	end
	local step, now = math.min(accumulator, 0.25), os.clock()
	accumulator = 0
	for id, door in doorParts do
		local key = barrierId(portals[id])
		door.Transparency = if key and (barriers[key] or 0) > now then 0.35 else 0.92
	end
	for player, state in states do
		if state.ready then
			travel(player, state, now)
			updateCrew(player, state, now, step)
		end
	end
	for i = #slime, 1, -1 do
		local patch = slime[i]
		if patch.expires <= now or not states[patch.owner] then
			table.remove(slime, i)
		else
			area(
				patch.position,
				patch.zone,
				Config.Helpers.gary.damage * step,
				5.5,
				Config.Helpers.gary.slow,
				patch.owner
			)
		end
	end
	local fighters = livingFighters()
	if phase == "intermission" and now >= deadline and #fighters > 0 then
		spawnWave(fighters)
	elseif phase == "combat" then
		updateFish(now, step, fighters)
		local nextPhase = Rules.nextPhase(phase, #fighters, #fish, wave, Config.MaxWaves)
		if nextPhase ~= phase then
			phase = nextPhase
			if nextPhase == "defeat" then
				clearFish()
				everyone("The crew was rescued. Press Survival to try again.")
			else
				for _, player in fighters do
					states[player].wallet.coins += Config.WaveCoins
				end
				deadline = now + 20
				everyone(
					if nextPhase == "victory"
						then "Conch Street saved! Five waves cleared. Start another raid anytime."
						else "Wave cleared! +60 coins • 20 seconds to restock."
				)
			end
		end
	end
	if now - lastBroadcast >= 0.25 then
		lastBroadcast = now
		broadcast(now)
	end
end)
