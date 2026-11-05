-- Cenário do mapa e o farol. World.build troca o cenário inteiro (o anterior
-- é destruído) e monta o farol com a aparência escolhida. Cada mapa tem o
-- seu arquivo em Scenery/ (função que recebe o modelo e o Kit).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Maps = require(Shared:WaitForChild("Maps"))
local Keepers = require(Shared:WaitForChild("Keepers"))
local Kit = require(script.Parent:WaitForChild("Scenery"):WaitForChild("Kit"))

local World = {}

World.current = { map = "", keeper = "" }

local MODEL_NAME = "FogkeeperScenery"
local ISLAND_TOP = 0.7 -- topo da ilha nos cenários (Kit.island), antes da escala
local WALL_SEGMENTS = 28

-- Altura do chão da ilha em studs, já na escala do mundo.
function World.groundY(): number
	return ISLAND_TOP * Balance.WORLD_SCALE
end

-- Farol na origem, com ~10 studs de altura antes da escala (~25 depois).
function World.buildLighthouse(parent: Instance, keeperId: string): Model
	local k = Keepers.get(keeperId)
	local tower = Instance.new("Model")
	tower.Name = "Lighthouse"
	tower.Parent = parent
	local base = Vector3.new(0, 0.6, 0)
	Kit.cylinder(tower, base, 1, 4.8, k.trim, { Material = Enum.Material.Cobblestone })
	local y = base.Y + 1
	if k.shape == "iron" then
		-- Treliça escura com anéis de latão e quatro pernas.
		Kit.cylinder(tower, Vector3.new(0, y, 0), 5.6, 2.2, k.base, { Material = Enum.Material.Metal })
		for i = 0, 3 do
			local a = i / 4 * 2 * math.pi + math.pi / 4
			Kit.block(tower, CFrame.new(math.cos(a) * 1.5, y + 2.8, math.sin(a) * 1.5) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, 0.12),
				Vector3.new(0.3, 5.8, 0.3), k.base, { Material = Enum.Material.Metal })
		end
		for i = 0, 2 do
			Kit.cylinder(tower, Vector3.new(0, y + 1.2 + i * 1.7, 0), 0.25, 3 - i * 0.25, k.stripe, { Material = Enum.Material.Metal })
		end
	elseif k.shape == "stone" then
		-- Pedra antiga com blocos salientes e musgo.
		Kit.cylinder(tower, Vector3.new(0, y, 0), 5.6, 3.4, k.base, { Material = Enum.Material.Cobblestone })
		for i = 0, 9 do
			local a = i * 2.39
			Kit.block(tower, CFrame.new(math.cos(a) * 1.65, y + 0.5 + (i % 5) * 1.05, math.sin(a) * 1.65) * CFrame.Angles(0, -a, 0),
				Vector3.new(0.4, 0.5, 0.8), k.trim, { Material = Enum.Material.Slate })
		end
		for i = 0, 4 do
			local a = i * 1.3
			Kit.ball(tower, Vector3.new(math.cos(a) * 1.5, y + 0.6 + i * 1.1, math.sin(a) * 1.5), Vector3.new(0.9, 0.5, 0.9), k.stripe,
				{ Material = Enum.Material.Grass })
		end
	else
		-- Faixas alternadas (clássico) ou corpo claro (cristal).
		for i = 0, 3 do
			local color = if i % 2 == 0 then k.base else k.stripe
			if k.shape == "crystal" then
				color = k.base
			end
			Kit.cylinder(tower, Vector3.new(0, y + i * 1.4, 0), 1.4, 3.6 - i * 0.24, color,
				{ Material = if k.shape == "crystal" then Enum.Material.Glass else Enum.Material.Concrete,
					Transparency = if k.shape == "crystal" then 0.15 else 0 })
		end
	end
	local top = y + 5.6
	-- Galeria, lanterna e telhado.
	Kit.cylinder(tower, Vector3.new(0, top, 0), 0.3, 3.6, k.trim, { Material = Enum.Material.Metal, Name = "Gallery" })
	local glass = Kit.cylinder(tower, Vector3.new(0, top + 0.3, 0), 1.2, 2.2, k.lamp,
		{ Material = Enum.Material.Glass, Transparency = 0.45, Name = "Lantern" })
	glass.Reflectance = 0.1
	local lamp = Kit.ball(tower, Vector3.new(0, top + 0.9, 0), 1.6, k.lamp, { Material = Enum.Material.Neon, Name = "Lamp" })
	-- A lâmpada faz sombra (Future): árvores, casas e avatares da ilha. Galeria,
	-- vidro e telhado não fazem sombra (Kit), senão cobririam a ilha toda.
	local lampLight = Kit.light(lamp, k.lamp, 22, 2.5)
	lampLight.Shadows = true
	Kit.cone(tower, Vector3.new(0, top + 1.5, 0), 1.4, 2.6, k.roof, 4, { Material = Enum.Material.Metal })
	Kit.ball(tower, Vector3.new(0, top + 3, 0), 0.4, k.trim, { Material = Enum.Material.Metal })
	tower:SetAttribute("Keeper", keeperId)
	return tower
end

-- Peças invisíveis para os avatares (na escala dos cenários, antes do
-- ScaleTo): chão da ilha, tronco do farol, mureta na borda (ninguém cai no
-- mar) e os pontos onde os avatares nascem.
function World.buildColliders(parent: Instance)
	local folder = Instance.new("Model")
	folder.Name = "Colliders"
	folder.Parent = parent
	local r = Kit.ISLAND_RADIUS * Kit.S
	local function solid(part: BasePart)
		part.Transparency = 1
		part.CanCollide = true
		part.CanQuery = true
		return part
	end
	solid(Kit.disc(folder, Vector3.zero, r * 1.02, 1.3, ISLAND_TOP, Color3.new(), { Name = "Floor" }))
	-- Do tamanho da base de pedra (4,8), a parte mais larga do farol: com
	-- menos que isso o avatar entrava um pouco na base.
	solid(Kit.cylinder(folder, Vector3.new(0, ISLAND_TOP, 0), 9, 5, Color3.new(), { Name = "Tower" }))
	for i = 0, WALL_SEGMENTS - 1 do
		local a = i / WALL_SEGMENTS * 2 * math.pi
		local width = 2 * math.pi * r / WALL_SEGMENTS + 0.2
		solid(Kit.block(folder, CFrame.new(math.cos(a) * r, ISLAND_TOP + 2, math.sin(a) * r) * CFrame.Angles(0, -a, 0),
			Vector3.new(0.3, 4, width), Color3.new(), { Name = "Wall" }))
	end
	for i = 0, Balance.MAX_PLAYERS - 1 do
		local a = i / Balance.MAX_PLAYERS * 2 * math.pi + math.pi / 4
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Duration = 0 -- sem campo de força
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.CanQuery = false
		spawn.Size = Vector3.new(1.2, 0.1, 1.2)
		spawn.CFrame = CFrame.new(math.cos(a) * r * 0.55, ISLAND_TOP + 0.05, math.sin(a) * r * 0.55)
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
		spawn.Parent = folder
	end
end

local function terrain(): Terrain?
	return workspace:FindFirstChildOfClass("Terrain")
end

-- Água de verdade (Terrain) sobre o fundo "Sea", em studs finais (depois do
-- ScaleTo, que não mexe no Terrain): uma camada só de voxels (4 studs), da
-- altura do fundo até a superfície em y = 0. Cor, ondas e transparência
-- ficam com o cliente (DayCycle), por mapa e hora. Se falhar, o "Sea" volta
-- a ser o plano neon de antes, na superfície.
local function fillWater(model: Model)
	local sea = model:FindFirstChild("Sea") :: BasePart?
	if not sea or model:GetAttribute("Water") ~= true then
		return
	end
	local ok, err = pcall(function()
		local t = terrain()
		assert(t, "sem Terrain")
		local bedTop = sea.Position.Y + sea.Size.Y / 2
		local depth = math.max(4, math.ceil(-bedTop / 4) * 4)
		t:FillBlock(CFrame.new(sea.Position.X, -depth / 2, sea.Position.Z), Vector3.new(sea.Size.X, depth, sea.Size.Z), Enum.Material.Water)
	end)
	if not ok then
		warn("[World] água do Terrain falhou: " .. tostring(err))
		model:SetAttribute("Water", false)
		sea.Material = Enum.Material.Neon
		sea.CFrame = CFrame.new(sea.Position.X, -sea.Size.Y / 2, sea.Position.Z)
	end
end

-- Troca o cenário. Não refaz nada se mapa e farol forem os mesmos.
function World.build(mapId: string, keeperId: string): Model
	local old = workspace:FindFirstChild(MODEL_NAME)
	if old and World.current.map == mapId and World.current.keeper == keeperId then
		return old :: Model
	end
	if old then
		old:Destroy()
	end
	-- A água do mapa anterior (Terrain) sai junto com o cenário.
	local t = terrain()
	if t then
		pcall(function()
			t:Clear()
		end)
	end
	local map = Maps.get(mapId)
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local module = script.Parent.Scenery:FindFirstChild(map.scenery)
	if module then
		local ok, err = pcall(function()
			local build: any = require(module)
			build(model, Kit)
		end)
		if not ok then
			warn("[World] cenário " .. map.scenery .. " falhou: " .. tostring(err))
		end
	end
	World.buildLighthouse(model, keeperId)
	World.buildColliders(model)
	-- Cenários e farol foram desenhados em 0,1 stud por unidade; o mundo usa
	-- Balance.STUDS_PER_UNIT. Escala tudo junto, em volta do farol.
	model.WorldPivot = CFrame.new()
	model:ScaleTo(Balance.WORLD_SCALE)
	model:SetAttribute("Map", mapId)
	fillWater(model)
	model.Parent = workspace
	World.current = { map = mapId, keeper = keeperId }
	return model
end

-- Efeitos de luz que o cliente (DayCycle) ajusta a cada quadro.
-- Lighting.Technology (Future) não é scriptável: vem do build.ps1, no XML.
-- Em aparelhos fracos o próprio Roblox reduz a qualidade da luz e das sombras.
function World.setupLighting()
	Lighting.ClockTime = 18
	Lighting.Brightness = 1.5
	Lighting.Ambient = Color3.fromRGB(90, 100, 125)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 110, 140)
	-- Sombras: só as peças que pedem (árvores, casas, avatares) na luz da
	-- lâmpada do farol e da lanterna; o resto do cenário tem CastShadow falso.
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	-- Reflexos suaves do céu no metal, no vidro, no gelo e na água.
	Lighting.EnvironmentDiffuseScale = 0.25
	Lighting.EnvironmentSpecularScale = 0.5
	-- Céu da noite: estrelas e lua do próprio Roblox (sem assets externos).
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.StarCount = 3000
		sky.CelestialBodiesShown = true
		sky.MoonAngularSize = 14
		sky.SunAngularSize = 16
		sky.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("SunRaysEffect") then
		local rays = Instance.new("SunRaysEffect")
		rays.Intensity = 0.04
		rays.Spread = 0.5
		rays.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.25
		atmosphere.Haze = 1
		atmosphere.Color = Color3.fromRGB(150, 160, 190)
		atmosphere.Decay = Color3.fromRGB(60, 70, 100)
		atmosphere.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.6
		bloom.Size = 30
		bloom.Threshold = 0.9
		bloom.Parent = Lighting
	end
	if not Lighting:FindFirstChild("FogkeeperGrade") then
		local grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "FogkeeperGrade"
		grade.Parent = Lighting
	end
end

return World
