--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Conch")
local Config = require(Shared.Config)
local Protocol = require(Shared.Protocol)
local Models = require(Shared.Models)
local AudioConfig = require(Shared.AudioConfig)
local Action = Shared:WaitForChild("Action") :: RemoteEvent
local Update = Shared:WaitForChild("Update") :: RemoteEvent
local Effect = Shared:WaitForChild("Effect") :: RemoteEvent
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera :: Camera
local snapshot: Protocol.Snapshot? = nil
local menu = "start"
local firing, muted = false, false
local lastShot, recoil = 0, 0
local equipped = ""
local viewWeapon: Model? = nil
local currentTrack = ""
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "ConchHUD", false, true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local ink = Color3.fromRGB(14, 42, 55)
local sea = Color3.fromRGB(26, 75, 86)
local gold = Color3.fromRGB(253, 206, 101)
local white = Color3.fromRGB(233, 248, 241)

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end
local function label(
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	fontSize: number
): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Position, item.Size, item.Text = position, size, text
	item.Font, item.TextSize, item.TextColor3 = Enum.Font.GothamMedium, fontSize, white
	item.TextXAlignment, item.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	item.TextWrapped = true
	item.Parent = parent
	return item
end
local function button(
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	callback: () -> ()
): TextButton
	local item = Instance.new("TextButton")
	item.Position, item.Size, item.Text = position, size, text
	item.Font, item.TextSize, item.TextColor3 = Enum.Font.GothamBold, 16, ink
	item.BackgroundColor3, item.AutoButtonColor = gold, true
	item.Parent = parent
	round(item, 10)
	item.Activated:Connect(callback)
	return item
end
local function panel(parent: Instance, position: UDim2, size: UDim2): Frame
	local item = Instance.new("Frame")
	item.Position, item.Size, item.BackgroundColor3, item.Parent = position, size, ink, parent
	item.BackgroundTransparency, item.BorderSizePixel = 0.1, 0
	round(item, 16)
	return item
end
local top = panel(gui, UDim2.fromOffset(18, 42), UDim2.new(1, -36, 0, 84))
local location = label(top, "CONCH STREET", UDim2.fromOffset(18, 10), UDim2.new(0.6, 0, 0, 27), 20)
local status =
	label(top, "Choose your character to begin", UDim2.fromOffset(18, 43), UDim2.new(1, -35, 0, 26), 15)
local currency = label(top, "100 COINS", UDim2.new(0.65, 0, 0, 8), UDim2.new(0.32, 0, 0, 30), 20)
currency.TextColor3, currency.TextXAlignment = gold, Enum.TextXAlignment.Right
local bottom = panel(gui, UDim2.new(0, 18, 1, -105), UDim2.fromOffset(365, 87))
local combat = label(bottom, "HEALTH 100", UDim2.fromOffset(16, 9), UDim2.fromOffset(335, 29), 20)
local ammo =
	label(bottom, "Bubble Blaster • 14 / 14", UDim2.fromOffset(16, 45), UDim2.fromOffset(335, 24), 15)
local crosshair = label(gui, "+", UDim2.new(0.5, -12, 0.5, -12), UDim2.fromOffset(24, 24), 26)
crosshair.TextXAlignment = Enum.TextXAlignment.Center
local notice = label(gui, "", UDim2.fromScale(0.16, 0.73), UDim2.new(0.68, 0, 0, 60), 20)
notice.TextXAlignment, notice.TextStrokeTransparency = Enum.TextXAlignment.Center, 0.3
local fade = Instance.new("Frame")
fade.Size, fade.BackgroundColor3, fade.BackgroundTransparency = UDim2.fromScale(1, 1), sea, 1
fade.ZIndex, fade.Parent = 10, gui
local travelCover = Instance.new("Frame")
travelCover.Size, travelCover.BackgroundColor3 = UDim2.fromScale(1, 1), Color3.fromRGB(14, 69, 91)
travelCover.BackgroundTransparency, travelCover.ZIndex, travelCover.Parent = 1, 100, gui
travelCover.BorderSizePixel = 0
local travelText = Instance.new("TextLabel")
travelText.Size, travelText.Position = UDim2.fromScale(1, 0.15), UDim2.fromScale(0, 0.43)
travelText.BackgroundTransparency, travelText.TextTransparency = 1, 1
travelText.Text, travelText.TextSize, travelText.Font =
	"Traveling through Bikini Bottom...", 26, Enum.Font.GothamMedium
travelText.TextColor3, travelText.ZIndex, travelText.Parent = Color3.fromRGB(222, 249, 239), 101, travelCover
local travelTween: Tween? = nil
local travelVersion = 0
local overlay = panel(gui, UDim2.new(0.5, -330, 0.5, -295), UDim2.fromOffset(660, 590))
overlay.ZIndex = 3
local scale = Instance.new("UIScale")
scale.Parent = overlay
local content = Instance.new("ScrollingFrame")
content.Position, content.Size = UDim2.fromOffset(22, 96), UDim2.new(1, -44, 1, -155)
content.BackgroundTransparency, content.BorderSizePixel = 1, 0
content.ScrollBarThickness, content.CanvasSize, content.Parent = 5, UDim2.fromOffset(0, 800), overlay
local title = label(overlay, "CONCH STREET", UDim2.fromOffset(24, 20), UDim2.fromOffset(590, 34), 28)
title.TextColor3 = gold
local subtitle = label(
	overlay,
	"A little cartoon logic. A lot of restless fish.",
	UDim2.fromOffset(24, 58),
	UDim2.fromOffset(590, 25),
	15
)
local showMenu: (string) -> ()
local function toggleSurvival()
	local data = snapshot
	if data and data.ready then
		Action:FireServer(
			if data.survival and (data.phase == "combat" or data.phase == "intermission")
				then "explore"
				else "survival"
		)
	end
end
local close = button(
	overlay,
	"BACK TO GAME",
	UDim2.new(0.5, -110, 1, -48),
	UDim2.fromOffset(220, 34),
	function()
		showMenu("")
	end
)
close.Modal = true
local raidButton =
	button(overlay, "SURVIVAL • V", UDim2.new(0, 24, 1, -48), UDim2.fromOffset(160, 34), toggleSurvival)
local guideButton = button(
	overlay,
	"FIELD GUIDE • G",
	UDim2.new(1, -184, 1, -48),
	UDim2.fromOffset(160, 34),
	function()
		showMenu(if menu == "guide" then "shop" else "guide")
	end
)

local function card(y: number, heading: string, detail: string): Frame
	local frame = panel(content, UDim2.fromOffset(0, y), UDim2.new(1, -10, 0, 98))
	frame.BackgroundColor3 = sea
	label(frame, heading, UDim2.fromOffset(14, 8), UDim2.new(1, -180, 0, 29), 19).TextColor3 = gold
	label(frame, detail, UDim2.fromOffset(14, 40), UDim2.new(1, -180, 0, 48), 14)
	return frame
end
local function renderMenu()
	for _, child in content:GetChildren() do
		child:Destroy()
	end
	close.Visible = menu ~= "start"
	raidButton.Visible = menu ~= "start"
	guideButton.Visible = menu ~= "start"
	local data = snapshot
	if menu == "start" then
		title.Text, subtitle.Text =
			"CONCH STREET SURVIVAL", "Choose your explorer. Everyone can use every weapon and helper."
		for i, id in { "explorer", "sponge", "patrick", "squid" } do
			local frame = card(
				(i - 1) * 104,
				Config.Avatars[id],
				if id == "explorer" then "Your Roblox avatar" else "Original modeled costume"
			)
			button(frame, "PLAY", UDim2.new(1, -140, 0, 29), UDim2.fromOffset(120, 38), function()
				Action:FireServer("start", id)
				subtitle.Text = "Loading your character…"
			end)
		end
		content.CanvasSize = UDim2.fromOffset(0, 430)
	elseif menu == "shop" then
		title.Text, subtitle.Text =
			"THE CREW & GEAR SHOP", "Session coins • choose up to three helpers • B to return"
		local y = 0
		for _, id in { "bubble", "spatula", "jelly" } do
			local spec = Config.Weapons[id]
			local owned = data ~= nil and data.weapons[id] == true
			local frame = card(y, spec.name, spec.description .. "  Damage: " .. spec.damage)
			button(
				frame,
				if owned then "EQUIP" else spec.price .. " COINS",
				UDim2.new(1, -145, 0, 28),
				UDim2.fromOffset(128, 40),
				function()
					Action:FireServer(if owned then "equip" else "weapon", id)
				end
			)
			y += 104
		end
		for _, id in { "sponge", "patrick", "sandy", "gary" } do
			local spec = Config.Helpers[id]
			local hired = data ~= nil and table.find(data.helpers, id) ~= nil
			local frame =
				card(y, spec.name, spec.description .. (if hired then " Dismissal gives no refund." else ""))
			button(
				frame,
				if hired then "DISMISS" else spec.price .. " COINS",
				UDim2.new(1, -145, 0, 28),
				UDim2.fromOffset(128, 40),
				function()
					Action:FireServer(if hired then "dismiss" else "helper", id)
				end
			)
			y += 104
		end
		content.CanvasSize = UDim2.fromOffset(0, y)
	elseif menu == "guide" then
		title.Text, subtitle.Text =
			"THE CONCH STREET FIELD GUIDE", "Explore all five landmarks and find twenty keepsakes."
		local notes = {
			{
				"A playable reconstruction",
				"The show changes layouts between episodes. These connected rooms combine recurring details; they are not an exact canonical floor plan.",
			},
			{
				"The pineapple",
				"Walk between the living room, kitchen, library, bedroom and bathroom through enclosed hallways. Only the street doorway teleports. Look for the organ, flower blanket, foghorn and Gary.",
			},
			{
				"The moai",
				"Gold bamboo library, shell lamps and blue chairs; salmon portrait studio with distinct self-portraits. Sources: Squid Wood and Unfriendly Ghost. Bold and Brash is a bonus exhibit.",
			},
			{
				"The rock",
				"Lifted rock lid, sand sofa, kitchen and sleeping nook. Sources: Pink Purloiner, Donut of Shame and Growth Spout. Look for the secret box.",
			},
			{
				"Restaurants",
				"Krusty Krab: dining room, cashier boat, grill, office, restrooms, freezer, storage and a rear dumpster yard. Across the road, explore Karen's Chum Bucket laboratory.",
			},
			{
				"Beyond Conch Street",
				"Find the parked Patty Wagon beside the pineapple. Follow the road east to Mrs. Puff's classroom, lighthouse and boat course, or head south to Jellyfish Fields. Find 26 keepsakes worth 80 coins each.",
			},
			{
				"Survival tips",
				"Click / RT: fire. R / X: reload. B / Y: shop. 1–3: weapons. E: supplies/discoveries. Doors work by walking through. Barricades hold fish for 15 seconds. Coins last this server session.",
			},
			{
				"Audio",
				"Music is enabled with Roblox Creator Store tracks: Marching To Honolulu, Tropical Jazz OL, and Intense Chase, courtesy of APM Music. Original optional WAV loops are also included.",
			},
		}
		for i, note in notes do
			local frame = card((i - 1) * 122, note[1], note[2])
			frame.Size = UDim2.new(1, -10, 0, 116)
			for _, child in frame:GetChildren() do
				if child:IsA("TextLabel") then
					child.Size = UDim2.new(1, -28, 0, if child.Text == note[1] then 28 else 64)
				end
			end
		end
		content.CanvasSize = UDim2.fromOffset(0, #notes * 122)
	end
end

showMenu = function(nextMenu: string)
	menu, firing = nextMenu, false
	overlay.Visible = menu ~= ""
	crosshair.Visible = menu == ""
	if menu ~= "" then
		camera.CameraType = Enum.CameraType.Scriptable
		if menu == "start" then
			camera.CFrame = CFrame.lookAt(Vector3.new(18, 32, 110), Vector3.new(0, 13, 0))
		end
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior, UserInputService.MouseIconEnabled = Enum.MouseBehavior.Default, true
		ContextActionService:BindActionAtPriority(
			"ConchMenuMovement",
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			3000,
			Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight,
			Enum.PlayerActions.CharacterJump
		)
		renderMenu()
	else
		ContextActionService:UnbindAction("ConchMenuMovement")
		camera.CameraType, player.CameraMode = Enum.CameraType.Custom, Enum.CameraMode.LockFirstPerson
		local human = if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
		if human then
			camera.CameraSubject = human
		end
		UserInputService.MouseBehavior, UserInputService.MouseIconEnabled =
			Enum.MouseBehavior.LockCenter, false
	end
end
button(gui, "GEAR • B", UDim2.new(1, -150, 1, -65), UDim2.fromOffset(130, 43), function()
	if snapshot and snapshot.ready then
		showMenu(if menu == "shop" then "" else "shop")
	end
end)
button(gui, "FIELD GUIDE", UDim2.new(1, -150, 1, -116), UDim2.fromOffset(130, 38), function()
	if snapshot and snapshot.ready then
		showMenu(if menu == "guide" then "" else "guide")
	end
end)
local survival =
	button(gui, "SURVIVAL • V", UDim2.new(1, -150, 0, 138), UDim2.fromOffset(130, 38), toggleSurvival)
local hasMusic = AudioConfig.Explore ~= "" or AudioConfig.Combat ~= "" or AudioConfig.Danger ~= ""
local musicButton: TextButton
musicButton = button(
	gui,
	if hasMusic then "MUSIC ON" else "MUSIC SETUP",
	UDim2.new(1, -150, 0, 184),
	UDim2.fromOffset(130, 34),
	function()
		if not hasMusic then
			if snapshot and snapshot.ready then
				showMenu("guide")
			end
			return
		end
		muted = not muted
		musicButton.Text = if muted then "MUSIC OFF" else "MUSIC ON"
		currentTrack = ""
	end
)

local musicFolder = SoundService:WaitForChild("ConchMusic")
local tracks: { [string]: Sound } = {}
for _, name in { "Explore", "Combat", "Danger" } do
	local sound = musicFolder:WaitForChild(name) :: Sound
	sound.SoundId = AudioConfig[name]
	sound.Volume, sound.Looped = 0, true
	tracks[name] = sound
	task.spawn(function()
		local ok, message = pcall(function()
			ContentProvider:PreloadAsync({ sound })
		end)
		if not ok or not sound.IsLoaded then
			warn("Conch music could not load " .. name .. ": " .. tostring(message))
			musicButton.Text = "AUDIO LOAD ERROR"
		end
	end)
end
local function updateMusic(data: Protocol.Snapshot)
	local name = if data.survival
			and data.health > 0
			and data.health < 30
		then "Danger"
		elseif data.survival and data.phase == "combat" then "Combat"
		else "Explore"
	if muted then
		name = "Muted"
	end
	if currentTrack == name then
		return
	end
	currentTrack = name
	for id, sound in tracks do
		local volume = if id == name then AudioConfig.Volume else 0
		if volume > 0 and sound.SoundId ~= "" and not sound.IsPlaying then
			sound:Play()
		end
		TweenService:Create(sound, TweenInfo.new(1.5), { Volume = volume }):Play()
	end
end
local previousShopKey = ""
Update.OnClientEvent:Connect(function(data: Protocol.Snapshot)
	snapshot = data
	top.Visible, bottom.Visible, survival.Visible = data.ready, data.ready, data.ready
	if data.ready and menu == "start" then
		showMenu("")
	elseif not data.ready and menu ~= "start" then
		showMenu("start")
	end
	location.Text = Config.Zones[data.zone].name
	currency.Text = data.coins .. " COINS"
	status.Text = if not data.survival
		then "EXPLORING • " .. data.discoveryCount .. "/" .. data.discoveryTotal .. " discoveries"
		elseif data.phase == "intermission" then "NEXT WAVE IN "
			.. data.countdown
			.. "s • "
			.. #data.helpers
			.. "/3 helpers"
		else string.upper(data.phase)
			.. " • WAVE "
			.. data.wave
			.. "/"
			.. Config.MaxWaves
			.. " • "
			.. data.enemies
			.. " fish"
	combat.Text = "HEALTH " .. data.health .. "  •  CREW " .. #data.helpers .. "/3"
	combat.TextColor3 = if data.health < 30 then Color3.fromRGB(255, 132, 118) else white
	ammo.Text = Config.Weapons[data.weapon].name
		.. "  •  "
		.. (if data.reloading then "RELOADING…" else data.ammo .. " / " .. data.capacity)
	notice.Text = data.message
	survival.Text = if data.survival and (data.phase == "combat" or data.phase == "intermission")
		then "EXPLORE • V"
		else "SURVIVAL • V"
	raidButton.Text = survival.Text
	if equipped ~= data.weapon then
		equipped = data.weapon
		if viewWeapon then
			viewWeapon:Destroy()
		end
		local model = Models.weapon(equipped)
		model:ScaleTo(0.65)
		model.Parent = camera
		viewWeapon = model
	end
	local key = data.coins
		.. ":"
		.. table.concat(data.helpers, ",")
		.. ":"
		.. tostring(data.weapons.spatula)
		.. tostring(data.weapons.jelly)
	if menu == "shop" and previousShopKey ~= key then
		previousShopKey = key
		local scroll = content.CanvasPosition
		renderMenu()
		content.CanvasPosition = scroll
	end
	updateMusic(data)
end)

local function visualPart(position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.Material, part.Color, part.Position = Enum.Material.Neon, color, position
	part.Parent = camera
	return part
end
Effect.OnClientEvent:Connect(function(kind: string, a: Vector3, b: Vector3, color: Color3, amount: number)
	if kind == "travelStart" then
		travelVersion += 1
		local version = travelVersion
		if travelTween then
			travelTween:Cancel()
		end
		travelText.TextTransparency = 0
		local tween = TweenService:Create(travelCover, TweenInfo.new(0.2), { BackgroundTransparency = 0 })
		travelTween = tween
		tween:Play()
		task.delay(0.22, function()
			if version == travelVersion then
				travelCover.BackgroundTransparency = 0
				Action:FireServer("travelReady")
			end
		end)
		return
	elseif kind == "portal" or kind == "travelCancel" then
		travelVersion += 1
		if travelTween then
			travelTween:Cancel()
		end
		if kind == "portal" then
			camera.CFrame = CFrame.new(camera.CFrame.Position)
				* CFrame.Angles(0, a.Y, 0)
				* camera.CFrame.Rotation
		end
		travelText.TextTransparency = 1
		local tween = TweenService:Create(
			travelCover,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15),
			{ BackgroundTransparency = 1 }
		)
		travelTween = tween
		tween:Play()
		return
	elseif kind == "hurt" then
		fade.BackgroundColor3, fade.BackgroundTransparency = color, 0.65
		TweenService:Create(fade, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		return
	end
	if (a - camera.CFrame.Position).Magnitude > 230 then
		return
	end
	local part = visualPart(a, color)
	if kind == "shot" then
		part.Size = Vector3.new(amount, amount, math.max(0.1, (b - a).Magnitude))
		part.CFrame = CFrame.lookAt((a + b) / 2, b)
		TweenService:Create(part, TweenInfo.new(0.16), { Transparency = 1 }):Play()
		Debris:AddItem(part, 0.2)
	elseif kind == "rock" then
		part.Shape, part.Material, part.Size = Enum.PartType.Ball, Enum.Material.Slate, Vector3.one * 1.4
		TweenService:Create(part, TweenInfo.new(0.25), { Position = b }):Play()
		Debris:AddItem(part, 0.3)
	elseif kind == "slime" then
		part.Shape, part.Size, part.Transparency = Enum.PartType.Cylinder, Vector3.new(0.15, 11, 11), 0.5
		part.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		TweenService:Create(part, TweenInfo.new(amount), { Transparency = 1 }):Play()
		Debris:AddItem(part, amount)
	else
		part.Shape, part.Size, part.Transparency = Enum.PartType.Ball, Vector3.one, 0.4
		TweenService:Create(part, TweenInfo.new(0.5), { Size = Vector3.one * amount * 2, Transparency = 1 })
			:Play()
		Debris:AddItem(part, 0.6)
	end
end)
local function controls(action: string, state: Enum.UserInputState): Enum.ContextActionResult
	if action == "ConchGuide" and state == Enum.UserInputState.Begin and snapshot and snapshot.ready then
		showMenu(if menu == "guide" then "" else "guide")
		return Enum.ContextActionResult.Sink
	end
	if action == "ConchSurvival" and state == Enum.UserInputState.Begin then
		toggleSurvival()
		return Enum.ContextActionResult.Sink
	end
	if action == "ConchShop" and state == Enum.UserInputState.Begin and snapshot and snapshot.ready then
		showMenu(if menu == "" then "shop" else "")
		return Enum.ContextActionResult.Sink
	end
	if menu ~= "" then
		return Enum.ContextActionResult.Pass
	end
	if action == "ConchFire" then
		firing = state == Enum.UserInputState.Begin
	elseif action == "ConchReload" and state == Enum.UserInputState.Begin then
		Action:FireServer("reload")
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction(
	"ConchFire",
	controls,
	true,
	Enum.UserInputType.MouseButton1,
	Enum.KeyCode.ButtonR2
)
ContextActionService:BindAction("ConchReload", controls, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("ConchShop", controls, false, Enum.KeyCode.B, Enum.KeyCode.ButtonY)
ContextActionService:BindAction("ConchSurvival", controls, false, Enum.KeyCode.V)
ContextActionService:BindAction("ConchGuide", controls, false, Enum.KeyCode.G)
ContextActionService:SetTitle("ConchFire", "FIRE")
ContextActionService:SetTitle("ConchReload", "RELOAD")
ContextActionService:SetPosition("ConchFire", UDim2.new(1, -240, 1, -220))
ContextActionService:SetPosition("ConchReload", UDim2.new(1, -330, 1, -170))
UserInputService.InputBegan:Connect(function(input, handled)
	if handled or menu ~= "" then
		return
	end
	local id = if input.KeyCode == Enum.KeyCode.One
		then "bubble"
		elseif input.KeyCode == Enum.KeyCode.Two then "spatula"
		elseif input.KeyCode == Enum.KeyCode.Three then "jelly"
		else nil
	if id then
		Action:FireServer("equip", id)
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	firing = false
end)
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	camera.CameraSubject = humanoid
	if menu == "" then
		showMenu("")
	end
end)
RunService.RenderStepped:Connect(function(dt: number)
	local viewport = camera.ViewportSize
	local factor = math.min(1, (viewport.X - 32) / 660, (viewport.Y - 60) / 590)
	scale.Scale = factor
	overlay.Position = UDim2.new(0.5, -330 * factor, 0.5, -295 * factor)
	local data = snapshot
	if firing and menu == "" and data and data.health > 0 and not data.reloading then
		local spec = Config.Weapons[data.weapon]
		if os.clock() - lastShot >= spec.interval + 0.02 then
			lastShot, recoil = os.clock(), 0.12
			if data.ammo > 0 then
				Action:FireServer("fire", camera.CFrame.LookVector)
			else
				Action:FireServer("reload")
			end
		end
	end
	recoil = math.max(0, recoil - dt * 0.8)
	if viewWeapon then
		if menu == "" and data and data.health > 0 then
			viewWeapon:PivotTo(
				camera.CFrame * CFrame.new(0.8, -0.95, -2 + recoil) * CFrame.Angles(recoil, 0, 0)
			)
		else
			viewWeapon:PivotTo(CFrame.new(0, -500, 0))
		end
	end
end)
showMenu("start")
