-- Desenha o que o servidor manda: criaturas e chefes (Snapshot, suavizados
-- entre um envio e outro), brasas, os feixes de todos os jogadores (principal
-- e extras de BeamsJson) e os efeitos (Fx).
-- Os modelos vêm de client/Art/*.luau: cada módulo devolve
--   { build = {[art] = fn(model, raioEmStuds)}, animate = {[art] = fn(model, ent, t)},
--     trails = {[art] = {count, spacing, build(i, n, raio) -> Model, animate?(seg, i, ent, t)}} }
-- Convenção das artes (client/ArtKit.luau): frente em +X, topo em +Y, pivô na
-- origem; animate roda depois do PivotTo de cada quadro.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Data = require(script.Parent:WaitForChild("Ui"):WaitForChild("Data"))

local Renderer = {}

local S = Balance.STUDS_PER_UNIT or 0.1
-- Alturas e tamanhos fixos foram pensados em 0,1 stud por unidade; K leva à escala do mundo.
local K = Balance.WORLD_SCALE or 1
local CREATURE_Y = 1.1 * K
local BOSS_Y = 1.5 * K
local BEAM_Y = 0.95 * K -- feixes que saem do farol (lentes, farolete, sinalizador)
local EMBER_Y = 0.9 * K
local HAND_DROP = 1.4 -- o feixe do faroleiro sai um pouco abaixo do HumanoidRootPart (altura da mão)
local FAN = 6 -- triângulos por feixe
local SMOOTH = 14
local BURN = Color3.fromRGB(255, 150, 60)
local CHARM = Color3.fromRGB(120, 255, 220)

Renderer.BEAM_COLORS = {
	Color3.fromRGB(255, 225, 150), Color3.fromRGB(150, 225, 255), Color3.fromRGB(255, 160, 210), Color3.fromRGB(170, 255, 170),
}
local EXTRA_COLORS = {
	sweeper = Color3.new(0.65, 0.88, 1.0), mirror = Color3.new(0.85, 0.9, 1.0), beacon = Color3.new(1.0, 0.85, 0.5),
}

Renderer.shake = 0 -- intensidade do tremor de câmera (o Client lê e decai)
Renderer.reduceFlashes = false
Renderer.app = nil :: any -- interface, para avisos e recados vindos de Fx

local root = Instance.new("Folder")
root.Name = "FogkeeperView"
root.Parent = workspace

-- Artes ------------------------------------------------------------------------

local builders: { [string]: (Model, number) -> () } = {}
local animators: { [string]: (Model, any, number) -> () } = {}
local trailDefs: { [string]: any } = {}

local artFolder = script.Parent:FindFirstChild("Art") or script.Parent:WaitForChild("Art", 5)
if artFolder then
	-- Chefes por último, para que um id repetido sempre use o modelo do chefe
	-- (a ilusão da Kyūbi tem id próprio, "kyubi_decoy").
	local mods = artFolder:GetChildren()
	table.sort(mods, function(a, b)
		local ka = if a.Name == "Bosses" then 1 else 0
		local kb = if b.Name == "Bosses" then 1 else 0
		if ka ~= kb then
			return ka < kb
		end
		return a.Name < b.Name
	end)
	for _, mod in mods do
		if mod:IsA("ModuleScript") then
			local ok, art = pcall(require, mod)
			if ok and type(art) == "table" then
				for id, fn in art.build or {} do
					builders[id] = fn
				end
				for id, fn in art.animate or {} do
					animators[id] = fn
				end
				for id, def in art.trails or {} do
					trailDefs[id] = def
				end
			else
				warn("[Fogkeeper] arte com erro: " .. mod.Name .. ": " .. tostring(art))
			end
		end
	end
end

-- Modelo genérico quando a arte ainda não existe: uma bola com olhos.
local function fallback(m: Model, r: number)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * r * 2
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.fromRGB(200, 210, 235)
	p:SetAttribute("BaseColor", p.Color)
	p.Parent = m
	for _, side in { -1, 1 } do
		local e = p:Clone()
		e.Size = Vector3.one * r * 0.35
		e.Color = Color3.new(0, 0, 0)
		e:SetAttribute("BaseColor", nil)
		e.CFrame = CFrame.new(r * 0.7, r * 0.3, side * r * 0.35)
		e.Parent = m
	end
end

-- Monta o modelo de uma arte (também usado pelo bestiário).
function Renderer.buildModel(art: string): Model
	local m = Instance.new("Model")
	m.Name = art
	m.WorldPivot = CFrame.new()
	local r = Data.artRadius(art) * S
	local fn = builders[art] or fallback
	local ok, err = pcall(fn, m, r)
	if not ok then
		warn("[Fogkeeper] arte " .. art .. ": " .. tostring(err))
		m:ClearAllChildren()
		fallback(m, r)
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	return m
end

function Renderer.hasArt(art: string): boolean
	return builders[art] ~= nil
end

local function scaleModel(model: Model, s: number)
	if s <= 0 then
		return
	end
	local last = model:GetAttribute("LastScale") or 1
	if math.abs(last - s) > 0.02 then
		model:SetAttribute("LastScale", s)
		model:ScaleTo(s)
	end
end

-- Partes de um modelo que recebem a cor da queima (as com BaseColor).
local function burnParts(model: Model): { BasePart }
	local out = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("BaseColor") then
			table.insert(out, p)
		end
	end
	return out
end

local function toWorld(x: number, y: number, h: number): Vector3
	return Vector3.new(x * S, h, y * S)
end

local function fxPart(shape: Enum.PartType, color: Color3, size: Vector3, cf: CFrame, transparency: number): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.CFrame = cf
	p.Transparency = transparency
	p.Parent = root
	return p
end

-- Disco que cresce e some: clarão, pulso, respingo, tinta, maré.
function Renderer.ring(center: Vector3, radius: number, color: Color3, duration: number, transparency: number?)
	local flat = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	local start = transparency or 0.3
	if Renderer.reduceFlashes then
		start = math.max(start, 0.6)
	end
	local p = fxPart(Enum.PartType.Cylinder, color, Vector3.new(0.1, 1, 1), flat, start)
	local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.1, radius * 2, radius * 2), Transparency = 1 })
	tween.Completed:Connect(function()
		p:Destroy()
	end)
	tween:Play()
end

-- Qualidade gráfica do Roblox (Esc > Configurações). Nos níveis baixos, menos
-- partículas e nada de luzes extras. "Automático" (0) conta como médio: o
-- próprio Roblox já reduz luz e sombra em aparelho fraco.
local qualityCache, qualityAt = 5, -math.huge
local function quality(): number
	local now = os.clock()
	if now - qualityAt > 2 then
		qualityAt = now
		local ok, level = pcall(function()
			return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
		end)
		qualityCache = if ok and type(level) == "number" and level > 0 then level else 5
	end
	return qualityCache
end

local function lowQuality(): boolean
	return quality() <= 3
end

-- Partículas: um ponto invisível com emissores que disparam rajadas (Emit)
-- onde for preciso, sem criar peças. As partículas ficam no mundo
-- (LockedToPart falso) enquanto o ponto pula para o próximo efeito.
local PARTICLE_BUDGET = 500 -- partículas por segundo, no máximo
local WATER_Y = 0.1 -- superfície da água do Terrain (server/World.luau)
local fxAttachment: Attachment
local emitters: { [string]: ParticleEmitter } = {}
local budget, budgetAt = PARTICLE_BUDGET, 0
do
	local host = Instance.new("Part")
	host.Name = "FxHost"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.CastShadow = false
	host.Transparency = 1
	host.Size = Vector3.one * 0.2
	host.CFrame = CFrame.new(0, -50, 0)
	host.Parent = root
	fxAttachment = Instance.new("Attachment")
	fxAttachment.Parent = host
	local sparkle = "rbxasset://textures/particles/sparkles_main.dds"
	local smoke = "rbxasset://textures/particles/smoke_main.dds"
	local defs: { [string]: { [string]: any } } = {
		-- Fagulhas de queima e de brasa recolhida.
		sparks = { Texture = sparkle, LightEmission = 1,
			Color = ColorSequence.new(Color3.fromRGB(255, 210, 110), Color3.fromRGB(255, 90, 40)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2 * K), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(5, 12), SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 6, 0), Drag = 3 },
		-- Fumaça escura de criatura que se desfaz.
		smoke = { Texture = smoke, LightEmission = 0, Color = ColorSequence.new(Color3.fromRGB(60, 55, 70)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 * K), NumberSequenceKeypoint.new(1, 2 * K) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 2.5, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40) },
		-- Respingos de água (criatura surgindo do mar, golpe na água).
		spray = { Texture = sparkle, LightEmission = 0.3, Color = ColorSequence.new(Color3.fromRGB(215, 235, 255)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18 * K), NumberSequenceKeypoint.new(1, 0.1) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.8) }),
			Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(9, 16), EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, -40, 0) },
	}
	for name, props in defs do
		local e = Instance.new("ParticleEmitter")
		e.Name = name
		e.Rate = 0
		e.LockedToPart = false
		for k, v in props do
			(e :: any)[k] = v
		end
		e.Parent = fxAttachment
		emitters[name] = e
	end
end

-- Dispara `count` partículas de `name` em `pos`, dentro do orçamento.
local function emit(name: string, pos: Vector3, count: number)
	local e = emitters[name]
	if not e then
		return
	end
	local now = os.clock()
	if now - budgetAt >= 1 then
		budgetAt = now
		budget = PARTICLE_BUDGET
	end
	local n = count
	if lowQuality() then
		n *= 0.4
	end
	if Renderer.reduceFlashes and name == "sparks" then
		n *= 0.6
	end
	n = math.min(math.max(1, math.floor(n + 0.5)), budget)
	if n <= 0 then
		return
	end
	budget -= n
	fxAttachment.WorldPosition = pos
	e:Emit(n)
end

-- Respingo na superfície do mar (no gelo do fiorde, parecem lascas brancas).
local function splashAt(pos: Vector3, count: number)
	emit("spray", Vector3.new(pos.X, WATER_Y, pos.Z), count)
end

-- Luzes extras (brasas e chefes): poucas, e nenhuma em qualidade baixa.
local MAX_EMBER_LIGHTS = 6
local emberLights = 0

local function burst(pos: Vector3, size: number)
	local p = fxPart(Enum.PartType.Ball, Color3.fromRGB(255, 190, 90), Vector3.one * size * 0.5, CFrame.new(pos),
		if Renderer.reduceFlashes then 0.5 else 0.1)
	local tween = TweenService:Create(p, TweenInfo.new(0.35), { Size = Vector3.one * size * 1.8, Transparency = 1 })
	tween.Completed:Connect(function()
		p:Destroy()
	end)
	tween:Play()
end

-- Criaturas e brasas ---------------------------------------------------------------

local entities = {} -- id -> entidade desenhada
local embers = {} -- id -> {part, pos, target}

local function angleLerp(a: number, b: number, k: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * k
end

local function newEntity(e, target: Vector3)
	local model = Renderer.buildModel(e.art)
	model.Parent = root
	local ent = {
		id = e.id, art = e.art, model = model, parts = burnParts(model), pos = target, target = target, hp = e.hp,
		lit = 0, litNow = false, hidden = false, facing = e.facing, facingTarget = e.facing, visual = 0, aux = 0, scale = 1,
		elite = false, charmed = false, reflecting = false, stunned = false, path = { target }, segments = {}, eliteRing = nil,
	}
	local trail = trailDefs[e.art]
	if trail then
		local r = Data.artRadius(e.art) * S
		for i = 1, trail.count or 10 do
			local ok, seg = pcall(trail.build, i, trail.count or 10, r)
			if ok and seg then
				seg.Parent = root
				ent.segments[i] = { model = seg, parts = burnParts(seg) }
			end
		end
	end
	return ent
end

local function destroyEntity(ent)
	ent.model:Destroy()
	for _, seg in ent.segments do
		seg.model:Destroy()
	end
	if ent.eliteRing then
		ent.eliteRing:Destroy()
	end
end

function Renderer.snapshot(list: { any }, emberList: { any }, deaths: { any })
	for _, d in deaths do
		local pos = toWorld(d.x, d.y, CREATURE_Y)
		burst(pos, (if d.big then 10 else 2.5) * K)
		emit("sparks", pos, if d.big then 40 else 10)
		emit("smoke", pos, if d.big then 12 else 3)
		if d.big then
			Renderer.shake = math.max(Renderer.shake, 0.6)
		end
	end
	local seen = {}
	for _, e in list do
		seen[e.id] = true
		local ent = entities[e.id]
		local boss = Data.bosses()[e.art] ~= nil
		local target = toWorld(e.x, e.y, if boss then BOSS_Y else CREATURE_Y)
		if ent and ent.art ~= e.art then
			destroyEntity(ent)
			ent = nil
		end
		if not ent then
			ent = newEntity(e, target)
			entities[e.id] = ent
			-- Surge do mar: respingo na superfície. Chefe ganha uma luz própria.
			if not e.hidden then
				splashAt(target, if boss then 30 else 8)
			end
			if boss and not lowQuality() then
				local body = ent.model.PrimaryPart or ent.model:FindFirstChildWhichIsA("BasePart", true)
				if body then
					local light = Instance.new("PointLight")
					light.Name = "FkBossLight"
					light.Color = Color3.fromRGB(255, 130, 90)
					light.Range = math.clamp(Data.artRadius(e.art) * S * 3, 10, 40)
					light.Brightness = 1.2
					light.Shadows = false
					light.Parent = body
				end
			end
		end
		ent.target = target
		ent.hp = e.hp
		ent.litNow = e.lit
		ent.hidden = e.hidden
		ent.visual = e.visual
		ent.aux = e.aux
		ent.facingTarget = e.facing
		ent.scale = if e.scale > 0 then e.scale else 1
		ent.elite = e.elite
		ent.charmed = e.charmed
		ent.reflecting = e.reflecting
		ent.stunned = e.stunned
	end
	for id, ent in entities do
		if not seen[id] then
			destroyEntity(ent)
			entities[id] = nil
		end
	end

	local seenEmbers = {}
	for _, m in emberList do
		seenEmbers[m.id] = true
		local target = toWorld(m.x, m.y, EMBER_Y)
		local em = embers[m.id]
		if not em then
			local p = fxPart(Enum.PartType.Ball, Color3.fromRGB(255, 150, 50), Vector3.one * 0.7 * K, CFrame.new(target), 0)
			em = { part = p, pos = target, lit = false }
			if emberLights < MAX_EMBER_LIGHTS and not lowQuality() then
				emberLights += 1
				em.lit = true
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 150, 60)
				light.Range = 4 * K
				light.Brightness = 1
				light.Shadows = false
				light.Parent = p
			end
			embers[m.id] = em
		end
		em.target = target
	end
	for id, em in embers do
		if not seenEmbers[id] then
			-- Recolhida (ou apagada): umas fagulhas no lugar.
			emit("sparks", em.pos, 5)
			if em.lit then
				emberLights -= 1
			end
			em.part:Destroy()
			embers[id] = nil
		end
	end
end

function Renderer.clear()
	for id, ent in entities do
		destroyEntity(ent)
		entities[id] = nil
	end
	for id, em in embers do
		em.part:Destroy()
		embers[id] = nil
	end
	emberLights = 0
end

-- Corpo de serpente: segmentos espalhados pelo caminho percorrido.
local function placeTrail(ent, t: number, y: number)
	local def = trailDefs[ent.art]
	local spacing = def.spacing or 1.5
	local path = ent.path
	local seg = 1
	local walked = 0
	local wantNext = spacing
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		local len = (b - a).Magnitude
		while seg <= #ent.segments and walked + len >= wantNext do
			local k = if len > 0 then (wantNext - walked) / len else 0
			local p = a:Lerp(b, k)
			local dir = a - b
			local s = ent.segments[seg]
			local at = Vector3.new(p.X, y, p.Z)
			local look = if dir.Magnitude > 1e-3 then Vector3.new(dir.X, 0, dir.Z).Unit else Vector3.xAxis
			s.model:PivotTo(CFrame.lookAt(at, at + look) * CFrame.Angles(0, math.rad(90), 0))
			if def.animate then
				pcall(def.animate, s.model, seg, ent, t)
			end
			seg += 1
			wantNext += spacing
		end
		walked += len
	end
	-- Rastro ainda curto (recém-surgido): o resto fica no último ponto.
	for i = seg, #ent.segments do
		local last = path[#path]
		ent.segments[i].model:PivotTo(CFrame.new(last.X, y, last.Z))
	end
end

local function colorize(parts: { BasePart }, lit: number, charmed: boolean)
	for _, p in parts do
		local base = p:GetAttribute("BaseColor") :: Color3?
		if base then
			local c = base:Lerp(BURN, lit * 0.85)
			if charmed then
				c = c:Lerp(CHARM, 0.4)
			end
			p.Color = c
		end
	end
end

local function updateEntities(dt: number, t: number)
	local k = 1 - math.exp(-SMOOTH * dt)
	for _, ent in entities do
		ent.pos = ent.pos:Lerp(ent.target, k)
		ent.facing = angleLerp(ent.facing, ent.facingTarget, math.min(1, dt * 10))
		ent.lit = math.clamp(ent.lit + (if ent.litNow then dt * 6 else -dt * 3), 0, 1)
		local bob = math.sin(t * 3 + ent.id) * 0.12
		-- Escondida (mergulho, sumiço): não é desenhada; fica bem abaixo do mar.
		local y = if ent.hidden then -60 else ent.pos.Y + bob
		-- Ângulo a do jogo aponta (cos a, sin a) em X/Z: girar -a no eixo Y.
		local cf = CFrame.new(ent.pos.X, y, ent.pos.Z) * CFrame.Angles(0, -ent.facing, 0)
		ent.model:PivotTo(cf)
		scaleModel(ent.model, ent.scale)
		local anim = animators[ent.art]
		if anim then
			local ok, err = pcall(anim, ent.model, ent, t)
			if not ok and not ent.warned then
				ent.warned = true
				warn("[Fogkeeper] animação " .. ent.art .. ": " .. tostring(err))
			end
		end
		-- Recolorir centenas de peças por quadro custa caro: só quando a queima
		-- ou o encanto mudam de verdade.
		local recolor = ent.shownLit == nil or math.abs(ent.lit - ent.shownLit) > 0.02 or ent.shownCharmed ~= ent.charmed
			or (ent.lit == 0 and ent.shownLit ~= 0)
		if recolor then
			ent.shownLit = ent.lit
			ent.shownCharmed = ent.charmed
			colorize(ent.parts, ent.lit, ent.charmed)
		end
		-- Queimando na luz: fagulhas de vez em quando.
		if ent.lit > 0.6 and not ent.hidden then
			ent.sparkT = (ent.sparkT or 0) - dt
			if ent.sparkT <= 0 then
				ent.sparkT = 0.2
				emit("sparks", ent.pos, 2)
			end
		end
		if ent.elite and not ent.eliteRing then
			local r = Data.artRadius(ent.art) * S * 1.6
			ent.eliteRing = fxPart(Enum.PartType.Cylinder, Color3.fromRGB(255, 80, 60), Vector3.new(0.05, r * 2, r * 2), CFrame.new(), 0.55)
		end
		if ent.eliteRing then
			ent.eliteRing.CFrame = CFrame.new(ent.pos.X, if ent.hidden then -60 else 0.6 * K, ent.pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		end
		if #ent.segments > 0 then
			local path = ent.path
			if (path[1] - ent.pos).Magnitude > 0.25 then
				table.insert(path, 1, ent.pos)
				local def = trailDefs[ent.art]
				local maxPoints = math.ceil(((def.count or 10) + 2) * (def.spacing or 1.5) / 0.25) + 4
				while #path > maxPoints do
					table.remove(path)
				end
			end
			placeTrail(ent, t, y - 0.2)
			if recolor then
				for _, s in ent.segments do
					colorize(s.parts, ent.lit, ent.charmed)
				end
			end
		end
	end
	for _, em in embers do
		em.pos = em.pos:Lerp(em.target, k)
		em.part.CFrame = CFrame.new(em.pos.X, em.pos.Y + math.sin(t * 5 + em.pos.X) * 0.1, em.pos.Z)
	end
end

-- Feixes ----------------------------------------------------------------------

local beams = {} -- jogador -> {wedges, main, extras}

local function wedge(): WedgePart
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.CastShadow = false
	w.Material = Enum.Material.Neon
	w.Transparency = 1
	w.Parent = root
	return w
end

-- Triângulo a-b-c com duas cunhas (técnica clássica do Roblox).
local function triangle(a: Vector3, b: Vector3, c: Vector3, w1: WedgePart, w2: WedgePart)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	w1.Size = Vector3.new(0.05, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	w2.Size = Vector3.new(0.05, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
end

-- Desenha um leque a partir de wedges[start..]; retorna o próximo índice livre.
local function drawFan(b, start: number, origin: Vector3, angle: number, half: number, range: number, color: Color3, transparency: number): number
	local r = range * S
	if half <= 0 or r <= 0.1 or angle ~= angle then
		return start
	end
	for i = 1, FAN do
		local i1, i2 = start + (i - 1) * 2, start + (i - 1) * 2 + 1
		b.wedges[i1] = b.wedges[i1] or wedge()
		b.wedges[i2] = b.wedges[i2] or wedge()
		local a1 = angle - half + 2 * half * (i - 1) / FAN
		local a2 = angle - half + 2 * half * i / FAN
		local p1 = origin + Vector3.new(math.cos(a1), 0, math.sin(a1)) * r
		local p2 = origin + Vector3.new(math.cos(a2), 0, math.sin(a2)) * r
		triangle(origin, p1, p2, b.wedges[i1], b.wedges[i2])
		b.wedges[i1].Color = color
		b.wedges[i2].Color = color
		b.wedges[i1].Transparency = transparency
		b.wedges[i2].Transparency = transparency
	end
	return start + FAN * 2
end

-- De onde sai o feixe principal de um jogador: a lanterna do avatar (ou o farol,
-- sem personagem).
local function beamOrigin(player: Player): Vector3
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		local p = rootPart.Position
		return Vector3.new(p.X, p.Y - HAND_DROP, p.Z)
	end
	return Vector3.new(0, BEAM_Y, 0)
end

-- Luz da lanterna (SpotLight criado por server/Avatars.server.luau no
-- HumanoidRootPart): na partida, cor, abertura e alcance do feixe de cada um;
-- fora dela, luz quente de lanterna. Sombra só na do próprio jogador e em
-- qualidade alta. Mudanças locais (não replicam), iguais em todos os clientes.
local LANTERN_LIGHT = Color3.fromRGB(255, 214, 150)
local function aimLight(player: Player, color: Color3?, half: number?, range: number?)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local attachment = rootPart and rootPart:FindFirstChild("FkAimLight")
	local spot = attachment and attachment:FindFirstChildOfClass("SpotLight")
	if not spot then
		return
	end
	local c = color or LANTERN_LIGHT
	local angle = if half then math.clamp(math.deg(half) * 2.2, 30, 120) else 50
	local reach = if range then math.clamp(range * S * 0.9, 16, 60) else 36
	if spot.Color ~= c then
		spot.Color = c
	end
	if math.abs(spot.Angle - angle) > 0.5 then
		spot.Angle = angle
	end
	if math.abs(spot.Range - reach) > 0.5 then
		spot.Range = reach
	end
	local shadows = player == Players.LocalPlayer and quality() >= 6
	if spot.Shadows ~= shadows then
		spot.Shadows = shadows
	end
end

local function beamFor(player: Player)
	local b = beams[player]
	if not b then
		b = { wedges = {}, main = player:GetAttribute("AimAngle") or 0, extras = {}, raw = "", list = {} }
		beams[player] = b
	end
	return b
end

-- `localAngle` é o ângulo previsto do próprio jogador (sem atraso de rede).
function Renderer.updateBeams(dt: number, playing: boolean, localAngle: number, ink: boolean)
	local me = Players.LocalPlayer
	for player, b in beams do
		if player.Parent == nil then
			for _, w in b.wedges do
				w:Destroy()
			end
			beams[player] = nil
		end
	end
	for _, player in Players:GetPlayers() do
		local b = beamFor(player)
		local used = 1
		local half = player:GetAttribute("BeamHalf")
		local range = player:GetAttribute("BeamRange")
		if playing and half and range then
			local server = player:GetAttribute("AimAngle") or b.main
			if player == me then
				b.main = localAngle
			else
				b.main = angleLerp(b.main, server, math.min(1, dt * 12))
			end
			-- Cor escolhida com o passe "Feixes Arco-íris" (server/Monetization), ou a da vaga.
			local chosen = player:GetAttribute("BeamColor")
			local color = if typeof(chosen) == "Color3" then chosen
				else Renderer.BEAM_COLORS[player:GetAttribute("Slot") or 1] or Renderer.BEAM_COLORS[1]
			local over = player:GetAttribute("Overcharge") == true
			local base = if over then 0.38 elseif ink then 0.78 else 0.62
			local own = beamOrigin(player)
			used = drawFan(b, used, own, b.main, half, range, color, base)
			aimLight(player, color, half, range)
			-- Extras: lentes e espelho seguem o feixe principal; farolete e
			-- sinalizador giram sozinhos (suavizados).
			local raw = player:GetAttribute("BeamsJson")
			if raw ~= b.raw then
				b.raw = raw
				b.list = Data.decode(raw) or {}
			end
			for i, x in b.list do
				if type(x) == "table" and x.a and x.h and x.r then
					local kind = x.k or "lens"
					local angle: number
					if kind == "lens" or kind == "mirror" then
						angle = b.main + (x.a - server)
					else
						b.extras[i] = angleLerp(b.extras[i] or x.a, x.a, math.min(1, dt * 10))
						angle = b.extras[i]
					end
					-- Espelho sai do faroleiro, como o principal; o resto sai do farol.
						local from = if kind == "mirror" then own else Vector3.new(0, BEAM_Y, 0)
						used = drawFan(b, used, from, angle, x.h, x.r, EXTRA_COLORS[kind] or color, math.min(0.85, base + 0.08))
				end
			end
		else
			aimLight(player, nil, nil, nil)
		end
		for i = used, #b.wedges do
			b.wedges[i].Transparency = 1
		end
	end
end

function Renderer.update(dt: number, t: number)
	updateEntities(dt, t)
end

-- Efeitos ------------------------------------------------------------------------

local function at(data, h: number): Vector3
	h *= K
	if type(data) == "table" and data.x and data.y then
		return toWorld(data.x, data.y, h)
	end
	return Vector3.new(0, h, 0)
end

function Renderer.fx(name: string, data: any)
	data = if type(data) == "table" then data else {}
	local app = Renderer.app
	local me = Players.LocalPlayer
	local Text = Data.Text
	if name == "flash" then
		Renderer.ring(at(data, 1), (data.radius or 230) * S, Color3.fromRGB(255, 245, 210), 0.5, 0.1)
		if app then
			app.flashScreen(Color3.new(1, 0.97, 0.85), 0.25)
		end
	elseif name == "pulse" then
		Renderer.ring(at(data, 1), (data.radius or 170) * S, Color3.fromRGB(255, 200, 120), 0.6, 0.4)
	elseif name == "tide" then
		Renderer.ring(at(data, 0.8), (data.radius or 320) * S, Color3.fromRGB(110, 190, 255), 0.8, 0.35)
	elseif name == "beacon" then
		Renderer.ring(at(data, 1), (data.radius or 120) * S, Color3.fromRGB(255, 215, 120), 0.6, 0.3)
	elseif name == "hit" then
		if app then
			app.hurt()
		end
		Renderer.shake = math.max(Renderer.shake, 0.35)
	elseif name == "splash" then
		Renderer.ring(at(data, 0.5), (data.radius or 50) * S, Color3.fromRGB(200, 230, 255), 0.6, 0.4)
		splashAt(at(data, 0.5), 20)
	elseif name == "ink" then
		Renderer.ring(at(data, 0.6), (data.radius or 200) * S, Color3.fromRGB(20, 10, 30), 1.5, 0.2)
	elseif name == "boss_down" then
		Renderer.ring(at(data, 1), (data.radius or 180) * S, Color3.fromRGB(255, 220, 120), 1.0, 0.1)
		Renderer.shake = math.max(Renderer.shake, 0.8)
	elseif name == "boss_warning" then
		if app then
			app.flashScreen(Color3.new(0.9, 0.1, 0.1), 0.18)
		end
	elseif name == "petrify" then
		if app then
			app.flashScreen(Color3.new(0.7, 0.7, 0.65), 0.35)
		end
	elseif name == "level" then
		if app then
			app.announce("Nível %d!", { data.level or 0 }, Color3.fromRGB(190, 150, 255), false)
		end
	elseif name == "relic" then
		if app then
			local relic = Data.relic(data.id or "")
			app.toast(Text.format("Relíquias: %s", { Text.t(relic.name) }) .. " — " .. Text.t(relic.desc or ""), Color3.new(0.7, 0.9, 1))
		end
	elseif name == "achievement" or name == "unlock" then
		if app and (data.userId == nil or data.userId == me.UserId) then
			local label = if name == "achievement" then "Conquista: %s" else "Liberado: %s"
			app.toast(Text.format(label, { data.name or data.id or "" }), Color3.new(0.55, 0.9, 0.6))
		end
	elseif name == "sfx" then
		-- Som próprio de um chefe: {id, x, y}.
		if app and app.ctx and app.ctx.sounds then
			app.ctx.sounds.play(data.id or "")
		end
		return
	elseif data.x and data.y then
		-- Efeito próprio de um chefe sem tratamento especial: um anel no lugar.
		Renderer.ring(at(data, 1), (data.radius or 60) * S, Color3.fromRGB(255, 200, 160), 0.6, 0.4)
	end
	if app and app.ctx and app.ctx.sounds then
		app.ctx.sounds.play(name)
	end
end

return Renderer
