-- Luz e clima por mapa e hora da noite (porta de scripts/core/day_cycle.gd e
-- scripts/world/fog.gd). O cliente chama DayCycle.update a cada quadro; as
-- mudanças em Lighting e no cenário são locais (cada jogador vê o mesmo,
-- porque todos seguem o mesmo relógio do servidor).
--
--   DayCycle.update(mapId, progress, endless)
--     progress: fração da noite (0 = 18:00, 1 = 06:00; até 1.1 = dia claro)
--     endless:  no modo sem fim as noites se repetem (progress é usado mod 1)
--   DayCycle.reduceFlashes = true  -> sem relâmpagos que piscam a tela
--   DayCycle.weather = false       -> sem chuva, neve, areia, pétalas e luzes
--   DayCycle.p                     -> paleta atual (tabela de Maps.sample)
--
-- A água do mar é do Terrain (server/World.luau); aqui ela ganha cor, ondas,
-- transparência e reflexo por mapa e hora (tabela WATER).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maps = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Maps"))

local DayCycle = {}

DayCycle.reduceFlashes = false
DayCycle.weather = true
DayCycle.p = Maps.sample("bay", 0)

local SKY_Y = 25 -- studs acima do ponto que a câmera olha (o clima acompanha a câmera em terceira pessoa)
local AREA = Vector3.new(140, 1, 140) -- área coberta pelo clima em volta da câmera

local currentMap = ""
local flash = 0
local lightningTimer = 3
local emitters: { [string]: ParticleEmitter } = {}
local weatherPart: BasePart? = nil
local auroraParts: { BasePart } = {}
local rng = Random.new()

local gradeCache: ColorCorrectionEffect? = nil
local atmosphereCache: Atmosphere? = nil

local function grade(): ColorCorrectionEffect
	if gradeCache and gradeCache.Parent == Lighting then
		return gradeCache
	end
	local g = Lighting:FindFirstChild("FogkeeperGrade") :: ColorCorrectionEffect?
	if not g then
		local made = Instance.new("ColorCorrectionEffect")
		made.Name = "FogkeeperGrade"
		made.Parent = Lighting
		g = made
	end
	gradeCache = g
	return g :: ColorCorrectionEffect
end

local function atmosphere(): Atmosphere
	if atmosphereCache and atmosphereCache.Parent == Lighting then
		return atmosphereCache
	end
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then
		a = Instance.new("Atmosphere")
		a.Parent = Lighting
	end
	atmosphereCache = a
	return a :: Atmosphere
end

local bloomCache: BloomEffect? = nil
local function bloomEffect(): BloomEffect?
	if bloomCache and bloomCache.Parent == Lighting then
		return bloomCache
	end
	bloomCache = Lighting:FindFirstChildOfClass("BloomEffect")
	return bloomCache
end

-- Emissores de clima, todos num bloco invisível acima do mar.
local function emitter(name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Enabled = false
	e.LightEmission = 0
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = weatherPart
	emitters[name] = e
	return e
end

local function buildWeather()
	if weatherPart then
		return
	end
	local p = Instance.new("Part")
	p.Name = "FogkeeperWeather"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = AREA
	p.CFrame = CFrame.new(0, SKY_Y, 0)
	p.Parent = workspace
	weatherPart = p
	emitter("rain", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(170, 200, 230)),
		Size = NumberSequence.new(0.12), Transparency = NumberSequence.new(0.35), Lifetime = NumberRange.new(0.6, 0.8),
		Speed = NumberRange.new(45, 55), EmissionDirection = Enum.NormalId.Bottom, Rate = 0, SpreadAngle = Vector2.new(5, 5) })
	emitter("snow", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(240, 245, 255)),
		Size = NumberSequence.new(0.35), Transparency = NumberSequence.new(0.2), Lifetime = NumberRange.new(3, 4),
		Speed = NumberRange.new(7, 10), EmissionDirection = Enum.NormalId.Bottom, Rate = 0, SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(4, 0, 1) })
	emitter("sand", { Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(215, 175, 110)),
		Size = NumberSequence.new(3), Transparency = NumberSequence.new(0.75), Lifetime = NumberRange.new(2, 3),
		Speed = NumberRange.new(8, 12), EmissionDirection = Enum.NormalId.Bottom, Rate = 0, SpreadAngle = Vector2.new(40, 40),
		Acceleration = Vector3.new(18, 0, 3) })
	emitter("petals", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(255, 180, 200)),
		Size = NumberSequence.new(0.3), Transparency = NumberSequence.new(0.1), Lifetime = NumberRange.new(4, 6),
		Speed = NumberRange.new(4, 6), EmissionDirection = Enum.NormalId.Bottom, Rate = 0, SpreadAngle = Vector2.new(35, 35),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90), Acceleration = Vector3.new(3, 0, 1) })
	emitter("fireflies", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(230, 255, 120)),
		Size = NumberSequence.new(0.4), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(3, 5), LightEmission = 1,
		Speed = NumberRange.new(5, 7), EmissionDirection = Enum.NormalId.Bottom, Rate = 0, SpreadAngle = Vector2.new(40, 40), Drag = 1 })
	emitter("fairy_lights", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(150, 255, 200)),
		Size = NumberSequence.new(0.45), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(3, 5), LightEmission = 1,
		Speed = NumberRange.new(5, 7), EmissionDirection = Enum.NormalId.Bottom, Rate = 0, SpreadAngle = Vector2.new(40, 40), Drag = 1 })
end

-- Aurora do fiorde: faixas neon translúcidas no alto da tela (topo = -Z).
local function buildAurora()
	if #auroraParts > 0 then
		return
	end
	local colors = { Color3.fromRGB(80, 255, 170), Color3.fromRGB(110, 200, 255), Color3.fromRGB(190, 120, 255) }
	for i = 1, 3 do
		local p = Instance.new("Part")
		p.Name = "Aurora"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = colors[i]
		p.Size = Vector3.new(320, 0.1, 10 + i * 3)
		-- No céu, ao norte: com a câmera em terceira pessoa a aurora fica no horizonte.
		p.CFrame = CFrame.new(0, 45 + i * 4, -170 - i * 14) * CFrame.Angles(0.5, 0.08 * i, 0)
		p.Transparency = 1
		p.Parent = workspace
		table.insert(auroraParts, p)
	end
end

local function setRate(name: string, rate: number)
	local e = emitters[name]
	if e then
		e.Rate = rate
		e.Enabled = rate > 0
	end
end

-- Água do Terrain por mapa (só visual): transparência (1 = límpida), reflexo,
-- tamanho e velocidade das ondas, e quanto da cor da onda entra na água. A
-- tempestade aumenta as ondas. O fiorde não tem água (o mar é gelo).
local WATER_MIN_BRIGHTNESS = 0.42 -- abaixo deste brilho (V do HSV), a água puxa para WATER_NIGHT
local WATER_NIGHT = Color3.fromRGB(34, 74, 112) -- azul-marinho de mar à noite
local WATER = {
	bay = { clear = 0.35, reflect = 0.55, wave = 0.18, speed = 10, tint = 0.22 },
	fjord = { clear = 0.4, reflect = 0.6, wave = 0.05, speed = 4, tint = 0.2 },
	amazon = { clear = 0.12, reflect = 0.3, wave = 0.06, speed = 5, tint = 0.3 }, -- rio barrento
	japan = { clear = 0.3, reflect = 0.65, wave = 0.14, speed = 8, tint = 0.2 },
	egypt = { clear = 0.5, reflect = 0.5, wave = 0.12, speed = 8, tint = 0.25 },
	greece = { clear = 0.6, reflect = 0.5, wave = 0.15, speed = 9, tint = 0.28 }, -- Egeu claro
	celtic = { clear = 0.3, reflect = 0.55, wave = 0.24, speed = 12, tint = 0.2 },
}
local waterShown: { [string]: any } = {}

-- Grava uma propriedade do Terrain só quando ela muda de verdade (mexer na
-- água a cada quadro à toa custa).
local function setWater(t: Terrain, prop: string, value: any)
	local last = waterShown[prop]
	local changed
	if typeof(value) == "Color3" then
		changed = last == nil or math.abs(last.R - value.R) + math.abs(last.G - value.G) + math.abs(last.B - value.B) > 0.006
	else
		changed = last == nil or math.abs(last - value) > 0.004
	end
	if changed then
		local target: any = t
		target[prop] = value
		waterShown[prop] = value
	end
end

-- Recolore o mar e a água rasa do cenário atual com a paleta. Com água do
-- Terrain (atributo "Water" do cenário), a cor vai para Terrain.WaterColor e
-- "Sea" é o fundo (fica com a cor escura do mar).
local function tintScenery(mapId: string, p: { [string]: any }, storm: number)
	local scenery = workspace:FindFirstChild("FogkeeperScenery")
	if not scenery then
		return
	end
	local sea = scenery:FindFirstChild("Sea") :: BasePart?
	if sea then
		sea.Color = p.sea
	end
	local shallows = scenery:FindFirstChild("Shallows") :: BasePart?
	if shallows then
		shallows.Color = (p.sea :: Color3):Lerp(p.wave, 0.25)
	end
	if scenery:GetAttribute("Water") ~= true then
		return
	end
	local t = workspace:FindFirstChildOfClass("Terrain")
	if not t then
		return
	end
	local w = WATER[mapId] or WATER.bay
	-- A paleta da noite veio do jogo 2D e deixa a água do Terrain quase preta:
	-- quanto mais escura, mais ela é puxada para um azul-marinho de mar à noite.
	local color = (p.sea :: Color3):Lerp(p.wave, w.tint)
	local _, _, v = color:ToHSV()
	if v < WATER_MIN_BRIGHTNESS then
		color = color:Lerp(WATER_NIGHT, (WATER_MIN_BRIGHTNESS - v) / WATER_MIN_BRIGHTNESS)
	end
	setWater(t, "WaterColor", color)
	setWater(t, "WaterTransparency", w.clear)
	setWater(t, "WaterReflectance", w.reflect)
	setWater(t, "WaterWaveSize", math.clamp(w.wave + storm * 0.25, 0, 1))
	setWater(t, "WaterWaveSpeed", w.speed + storm * 10)
end

function DayCycle.update(mapId: string, progress: number, endless: boolean, dt: number?)
	local step = dt or (1 / 60)
	local f = if endless then progress % 1 else math.clamp(progress, 0, 1.1)
	local p = Maps.sample(mapId, f)
	DayCycle.p = p
	if mapId ~= currentMap then
		currentMap = mapId
		buildWeather()
		if Maps.WEATHER[mapId] and Maps.WEATHER[mapId].aurora then
			buildAurora()
		end
	end
	if weatherPart then
		local focus = workspace.CurrentCamera.Focus.Position
		weatherPart.CFrame = CFrame.new(focus.X, focus.Y + SKY_Y, focus.Z)
	end
	local storm: number = p.storm or 0
	local night: number = p.night or 0
	local land: Color3 = p.land

	-- Relógio do céu (sol baixo no entardecer e no amanhecer) e luz ambiente
	-- com a tinta "land" da paleta, para a ilha ter a cor do Godot.
	Lighting.ClockTime = (18 + math.min(f, 1.05) * 12) % 24
	Lighting.Brightness = 1 + (1 - night) * 1.2
	Lighting.Ambient = land:Lerp(Color3.new(0, 0, 0), 0.25)
	Lighting.OutdoorAmbient = land:Lerp(Color3.new(0, 0, 0), 0.15)

	-- Névoa: a Atmosphere com a cor e a densidade da névoa do mapa.
	local atm = atmosphere()
	atm.Color = p.fog
	atm.Decay = (p.fog :: Color3):Lerp(Color3.new(0, 0, 0), 0.5)
	atm.Density = math.clamp(0.12 + (p.fog_a or 1) * 0.16, 0, 0.6)
	atm.Haze = 0.5 + storm * 1.5

	-- Brilho do pôr e do nascer do sol: tinta quente no quadro todo.
	local g = grade()
	local warm = math.max(p.dusk or 0, p.dawn or 0)
	g.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 200, 160), warm * 0.5)
	flash = math.max(0, flash - step * 4)

	-- Relâmpagos durante a tempestade (desligados com "reduzir clarões").
	local weather = Maps.WEATHER[mapId] or {}
	if weather.lightning and storm > 0.6 and DayCycle.weather and not DayCycle.reduceFlashes then
		lightningTimer -= step
		if lightningTimer <= 0 then
			lightningTimer = rng:NextNumber(3, 7)
			flash = 1
		end
	end
	g.Brightness = flash * 0.35
	-- Um pouco de contraste e cor na noite; a tempestade tira a cor.
	g.Contrast = 0.08
	g.Saturation = 0.06 - 0.16 * storm
	-- Brilho do neon (olhos, lâmpadas, brasas): mais contido com "reduzir clarões".
	local bloom = bloomEffect()
	if bloom then
		local intensity = if DayCycle.reduceFlashes then 0.35 else 0.6
		if bloom.Intensity ~= intensity then
			bloom.Intensity = intensity
		end
	end
	tintScenery(mapId, p, storm)

	-- Clima: o que cai na tempestade e o que flutua a noite toda.
	local on = DayCycle.weather
	for name in emitters do
		local rate = 0
		if on and weather.storm == name then
			rate = storm * (if name == "rain" then 260 elseif name == "sand" then 70 else 140)
		end
		if on and weather.ambient == name then
			local amount = night * (1 - 0.7 * storm)
			if name == "fairy_lights" then
				amount *= 0.6
			end
			rate = math.max(rate, amount * (if name == "snow" then 40 elseif name == "petals" then 12 else 18))
		end
		setRate(name, rate)
	end
	local aurora = if on and mapId == "fjord" then (p.aurora or 0) else 0
	for i, part in auroraParts do
		part.Transparency = 1 - aurora * (0.55 - i * 0.1)
	end
end

return DayCycle
