-- Avatares dos faroleiros: nascem na ilha, andam livres (no saguão e na
-- partida), não morrem nem caem no mar, atravessam uns aos outros e levam uma
-- lanterna na mão direita, de onde sai o feixe de cada um. A mira e o giro
-- do corpo ficam no cliente (Client.client.luau); o servidor lê a posição do
-- HumanoidRootPart para a origem do feixe (Main.server.luau).

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Balance = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Balance"))

local GROUP = "FkAvatars"
local LANTERN_LIGHT = Color3.fromRGB(255, 214, 150)

pcall(function()
	PhysicsService:RegisterCollisionGroup(GROUP)
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
end)

StarterPlayer.CameraMinZoomDistance = Balance.CAMERA_MIN_ZOOM
StarterPlayer.CameraMaxZoomDistance = Balance.CAMERA_MAX_ZOOM
StarterPlayer.CameraMode = Enum.CameraMode.Classic
StarterPlayer.EnableMouseLockOption = true
StarterPlayer.CharacterWalkSpeed = Balance.AVATAR_WALK_SPEED
-- Se algo matar o avatar (cair no vazio antes do cenário existir), volta logo.
-- O próprio Roblox recarrega (CharacterAutoLoads, ligado no Main): chamar
-- LoadCharacter aqui também poderia carregar o personagem duas vezes.
Players.RespawnTime = 1

-- Onde o avatar volta se cair: um dos pontos de nascimento do cenário.
local function spawnPoint(): CFrame
	local scenery = workspace:FindFirstChild("FogkeeperScenery")
	local colliders = scenery and scenery:FindFirstChild("Colliders")
	if colliders then
		local spawns = {}
		for _, c in colliders:GetChildren() do
			if c:IsA("SpawnLocation") then
				table.insert(spawns, c)
			end
		end
		if #spawns > 0 then
			return spawns[math.random(1, #spawns)].CFrame + Vector3.new(0, 4, 0)
		end
	end
	return CFrame.new(0, 10, Balance.ISLAND_RADIUS * Balance.STUDS_PER_UNIT * 0.5)
end

-- Lanterna simples soldada na mão direita (R15) ou no braço direito (R6).
local function giveLantern(character: Model)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		or character:WaitForChild("RightHand", 3) or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") or character:FindFirstChild("FkLantern") then
		return
	end
	local lantern = Instance.new("Model")
	lantern.Name = "FkLantern"
	local function piece(size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
		local p = Instance.new("Part")
		if shape then
			p.Shape = shape
		end
		p.Size = size
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.35, 0) * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = p
		weld.Parent = p
		p.Parent = lantern
		return p
	end
	local dark = Color3.fromRGB(45, 40, 38)
	piece(Vector3.new(0.5, 0.12, 0.5), CFrame.new(0, 0.3, 0), dark, Enum.Material.Metal)
	local glass = piece(Vector3.new(0.42, 0.45, 0.42), CFrame.new(), LANTERN_LIGHT, Enum.Material.Neon)
	glass.Name = "Glass"
	glass.Transparency = 0.15
	piece(Vector3.new(0.5, 0.12, 0.5), CFrame.new(0, -0.28, 0), dark, Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Color = LANTERN_LIGHT
	light.Range = 12
	light.Brightness = 1.5
	light.Shadows = false
	light.Parent = glass
	lantern.Parent = character
end

-- Luz da lanterna na direção do feixe: um SpotLight num Attachment do
-- HumanoidRootPart, que o cliente já vira para a mira durante a partida (a mão
-- balança com a animação, o tronco não). Fica na altura da mão, um pouco à
-- frente e inclinado para baixo, para iluminar o chão, a água e as criaturas.
-- O cliente (Renderer) ajusta cor, abertura e alcance pelo feixe de cada um.
local function giveAimLight(character: Model)
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart or not rootPart:IsA("BasePart") or rootPart:FindFirstChild("FkAimLight") then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "FkAimLight"
	attachment.CFrame = CFrame.new(0.8, -1.2, -0.8) * CFrame.Angles(math.rad(-8), 0, 0)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Color = LANTERN_LIGHT
	spot.Angle = 50
	spot.Range = 36
	spot.Brightness = 2
	spot.Shadows = false
	spot.Parent = attachment
	attachment.Parent = rootPart
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.WalkSpeed = Balance.AVATAR_WALK_SPEED
	-- Ninguém se machuca: a vida que importa é a do farol.
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.HealthChanged:Connect(function()
		if humanoid.Health < humanoid.MaxHealth and humanoid.Health > 0 then
			humanoid.Health = humanoid.MaxHealth
		end
	end)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = GROUP
		end
	end
	character.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = GROUP
		end
	end)
	giveLantern(character)
	giveAimLight(character)
end

local function onPlayer(player: Player)
	player.CameraMinZoomDistance = Balance.CAMERA_MIN_ZOOM
	player.CameraMaxZoomDistance = Balance.CAMERA_MAX_ZOOM
	-- StarterPlayer só vale para quem entra depois; quem já está no jogo recebe aqui.
	player.CameraMode = Enum.CameraMode.Classic
	player.DevEnableMouseLock = true
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

-- Quem cair da ilha (ou nascer antes do cenário existir) volta para ela.
local checkTimer = 0
RunService.Heartbeat:Connect(function(dt)
	checkTimer -= dt
	if checkTimer > 0 then
		return
	end
	checkTimer = 0.5
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and root.Position.Y < Balance.FALL_RESET_Y then
			character:PivotTo(spawnPoint())
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
end)
