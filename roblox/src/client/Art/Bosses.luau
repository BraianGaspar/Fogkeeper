-- Modelos 3D dos 15 chefes e das partes que eles criam (cabeças de Cila,
-- símbolos da Esfinge), feitos de peças simples. Mesmo formato das artes de
-- criaturas:
--   build[art](model, radius)     monta as peças (radius em studs; se vier em
--                                 unidades de jogo, > 8, é convertido)
--   animate[art](model, ent, t)   anima a cada quadro, DEPOIS do PivotTo;
--                                 ent = {visual, aux, hp, lit, hidden, facing, scale, pos}
--   trails[art]                   corpo de serpente desenhado pelo rastro
--                                 (ver o comentário de `trails` no fim)
-- Os modelos olham para +X, com Y para cima. Peças com o atributo BaseColor
-- ficam laranja quando queimam; peças cuja cor a animação controla (fogo,
-- olhos que acendem) não têm esse atributo.

local Bosses = { build = {}, animate = {}, trails = {} }

local S = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("Balance")).STUDS_PER_UNIT

-- O Renderer passa o raio em studs (no máximo ~12 com S = 0,25); valores bem
-- maiores só podem ser unidades de jogo e são convertidos.
local function studs(radius: number): number
	return if radius > 20 then radius * S else radius
end

-- Peças --------------------------------------------------------------------

local function new(model: Model, class: string, size: Vector3, cf: CFrame, color: Color3, opts: { [string]: any }?): BasePart
	local p = Instance.new(class) :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.CFrame = cf
	p.Color = color
	local o = opts or {}
	if o.neon then
		p.Material = Enum.Material.Neon
	end
	if o.transparency then
		p.Transparency = o.transparency
	end
	if o.material then
		p.Material = o.material
	end
	if o.name then
		p.Name = o.name
	end
	if not o.noBurn then
		p:SetAttribute("BaseColor", color)
	end
	p:SetAttribute("LocalCFrame", cf) -- posição de repouso, para as animações
	p.Parent = model
	return p
end

local function block(model, size, cf, color, opts)
	return new(model, "Part", size, cf, color, opts)
end

local function wedge(model, size, cf, color, opts)
	return new(model, "WedgePart", size, cf, color, opts)
end

-- Elipsoide (bola achatada): Part com malha de esfera.
local function ellipsoid(model, size: Vector3, cf, color, opts)
	local p = new(model, "Part", size, cf, color, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function ball(model, d: number, cf, color, opts)
	return ellipsoid(model, Vector3.new(d, d, d), cf, color, opts)
end

-- Cilindro deitado no eixo X (o padrão do Roblox).
local function cylinder(model, length: number, d: number, cf, color, opts)
	local p = new(model, "Part", Vector3.new(length, d, d), cf, color, opts) :: Part
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Disco horizontal (cilindro em pé, achatado).
local function disc(model, d: number, h: number, cf, color, opts)
	return cylinder(model, h, d, cf * CFrame.Angles(0, 0, math.rad(90)), color, opts)
end

local function eyes(model, x: number, y: number, side: number, d: number, color: Color3, name: string?)
	for _, s in { -1, 1 } do
		ball(model, d, CFrame.new(x, y, s * side), color, { neon = true, noBurn = true, name = name or "Eye" })
	end
end

-- Animação ------------------------------------------------------------------

-- Coloca a peça em `local` relativo ao pivô do modelo.
local function setLocal(model: Model, p: BasePart, localCf: CFrame)
	p.CFrame = model:GetPivot() * localCf
end

local function rest(p: BasePart): CFrame
	return p:GetAttribute("LocalCFrame") :: CFrame
end

local function each(model: Model, name: string, fn: (BasePart, number) -> ())
	local i = 0
	for _, p in model:GetChildren() do
		if p.Name == name and p:IsA("BasePart") then
			i += 1
			fn(p, i)
		end
	end
end

local function setTransparency(model: Model, name: string, value: number)
	each(model, name, function(p)
		p.Transparency = value
	end)
end

-- Leviatã ---------------------------------------------------------------------

local SEA_DARK = Color3.new(0.1, 0.25, 0.3)
local SEA_BELLY = Color3.new(0.25, 0.5, 0.48)
local SEA_SPIKE = Color3.new(0.55, 0.75, 0.7)

Bosses.build.leviathan = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 2.2, r * 1.1, r * 1.6), CFrame.new(0, 0, 0), SEA_DARK)
	wedge(m, Vector3.new(r * 1.2, r * 0.35, r * 1.4), CFrame.new(r * 1.1, r * 0.15, 0) * CFrame.Angles(0, math.rad(-90), 0), SEA_DARK, { name = "JawUp" })
	wedge(m, Vector3.new(r * 1.1, r * 0.3, r * 1.3), CFrame.new(r * 1.05, -r * 0.2, 0) * CFrame.Angles(math.rad(180), math.rad(-90), 0), SEA_BELLY, { name = "JawDown" })
	block(m, Vector3.new(r * 1.0, r * 0.1, r * 0.9), CFrame.new(r * 1.0, -r * 0.02, 0), Color3.new(0.3, 0.02, 0.05), { noBurn = true })
	for i = 0, 4 do
		wedge(m, Vector3.new(r * 0.08, r * 0.18, r * 0.12), CFrame.new(r * (0.6 + i * 0.22), r * 0.02, r * 0.35), Color3.new(0.95, 0.92, 0.85), { noBurn = true })
		wedge(m, Vector3.new(r * 0.08, r * 0.18, r * 0.12), CFrame.new(r * (0.6 + i * 0.22), r * 0.02, -r * 0.35), Color3.new(0.95, 0.92, 0.85), { noBurn = true })
	end
	for _, s in { -1, 1 } do
		wedge(m, Vector3.new(r * 0.12, r * 0.9, r * 0.8), CFrame.new(-r * 0.5, r * 0.4, s * r * 0.6) * CFrame.Angles(s * 0.6, math.rad(90), 0), SEA_SPIKE)
	end
	eyes(m, r * 0.35, r * 0.4, r * 0.45, r * 0.26, Color3.new(1, 0.85, 0.3))
end

Bosses.animate.leviathan = function(m, ent, t)
	local bite = 0.25 + 0.25 * math.sin(t * 5)
	each(m, "JawUp", function(p)
		setLocal(m, p, rest(p) * CFrame.Angles(0, 0, -bite * 0.6))
	end)
	each(m, "JawDown", function(p)
		setLocal(m, p, rest(p) * CFrame.Angles(0, 0, bite * 0.6))
	end)
end

Bosses.trails.leviathan = {
	count = 13, spacing = 1.5, -- studs entre segmentos ao longo do rastro
	build = function(i: number, n: number, radius: number): Model
		local r = studs(radius) * (0.95 - i * 0.05)
		local seg = Instance.new("Model")
		ball(seg, r * 2, CFrame.new(), SEA_DARK)
		ball(seg, r * 1.1, CFrame.new(0, -r * 0.25, 0), SEA_BELLY)
		wedge(seg, Vector3.new(r * 0.12, r * 0.9, r * 0.9), CFrame.new(0, r * 0.8, 0) * CFrame.Angles(0, math.rad(90), 0), SEA_SPIKE)
		return seg
	end,
}

-- Kraken --------------------------------------------------------------------

local KRAKEN = Color3.new(0.45, 0.1, 0.18)
local KRAKEN_DARK = Color3.new(0.25, 0.05, 0.1)

Bosses.build.kraken = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 2.6, r * 1.4, r * 1.8), CFrame.new(-r * 0.3, 0, 0), KRAKEN)
	for i = 0, 5 do
		ball(m, r * 0.2, CFrame.new(-r * (0.3 + i * 0.18), r * 0.65, math.sin(i * 2.1) * r * 0.4), KRAKEN_DARK)
	end
	for i = 0, 7 do
		local a = math.pi + (i - 3.5) * 0.45
		local arm = cylinder(m, r * 2.6, r * 0.3, CFrame.Angles(0, -a, 0) * CFrame.new(r * 1.6, -r * 0.3, 0), KRAKEN, { name = "Arm" })
		arm:SetAttribute("Phase", i * 0.8)
		arm:SetAttribute("Angle", a)
		for j = 1, 3 do
			ball(m, r * 0.14, CFrame.Angles(0, -a, 0) * CFrame.new(r * (0.8 + j * 0.6), -r * 0.12, 0), Color3.new(0.9, 0.6, 0.65))
		end
	end
	for _, s in { -1, 1 } do
		ball(m, r * 0.55, CFrame.new(r * 0.55, r * 0.35, s * r * 0.45), Color3.new(0.95, 0.85, 0.4), { neon = true, noBurn = true, name = "Eye" })
		block(m, Vector3.new(r * 0.1, r * 0.4, r * 0.08), CFrame.new(r * 0.82, r * 0.35, s * r * 0.45), Color3.new(0.05, 0.02, 0.02), { noBurn = true })
	end
	ball(m, r * 2, CFrame.new(r * 1.4, 0, 0), Color3.new(0.05, 0.02, 0.08), { noBurn = true, transparency = 1, name = "Ink" })
end

Bosses.animate.kraken = function(m, ent, t)
	each(m, "Arm", function(p)
		local a = p:GetAttribute("Angle") :: number
		local wave = math.sin(t * 0.9 + (p:GetAttribute("Phase") :: number)) * 0.25
		local r = p.Size.X / 2.6
		setLocal(m, p, CFrame.Angles(0, -(a + wave), 0) * CFrame.new(r * 1.6, -r * 0.3, 0))
	end)
	local ink = ent.visual / 255
	each(m, "Ink", function(p)
		p.Transparency = 1 - 0.5 * ink
		local d = p:GetAttribute("D") or p.Size.X
		p:SetAttribute("D", d)
		p.Size = Vector3.one * (d :: number) * (1 + (1 - ink) * 2)
	end)
end

-- Jötunn ----------------------------------------------------------------------

local ICE_SKIN = Color3.new(0.55, 0.68, 0.78)
local FUR = Color3.new(0.35, 0.3, 0.28)
local ICE = Color3.new(0.8, 0.93, 1)

Bosses.build.jotunn = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 1.5, r * 1.6, r * 2.5), CFrame.new(-r * 0.2, 0, 0), FUR)
	for _, s in { -1, 1 } do
		ball(m, r * 0.84, CFrame.new(0, r * 0.5, s * r * 0.75), ICE_SKIN)
	end
	cylinder(m, r * 1.0, r * 0.32, CFrame.new(r * 0.45, r * 0.5, -r * 0.9) * CFrame.Angles(0, 0.3, 0), ICE_SKIN)
	cylinder(m, r * 1.0, r * 0.32, CFrame.new(r * 0.4, r * 0.5, r * 0.95), ICE_SKIN, { name = "ThrowArm" })
	ball(m, r * 0.7, CFrame.new(r * 0.9, r * 0.6, r * 1.15), ICE, { name = "Stone", transparency = 1 })
	ball(m, r * 1.0, CFrame.new(r * 0.15, r * 0.8, 0), ICE_SKIN)
	wedge(m, Vector3.new(r * 0.1, r * 0.5, r * 0.65), CFrame.new(r * 0.65, r * 0.55, 0) * CFrame.Angles(0, math.rad(-90), math.rad(180)), ICE)
	for i = 0, 4 do
		local a = -0.9 + i * 0.45
		wedge(m, Vector3.new(r * 0.1, r * 0.45, r * 0.16), CFrame.new(r * 0.1 - math.cos(a) * r * 0.3, r * 1.35, math.sin(a) * r * 0.4), ICE)
	end
	eyes(m, r * 0.6, r * 0.9, r * 0.2, r * 0.14, Color3.new(0.5, 0.9, 1))
end

Bosses.animate.jotunn = function(m, ent, t)
	local windup = ent.visual / 255
	each(m, "ThrowArm", function(p)
		setLocal(m, p, rest(p) * CFrame.new(-windup * p.Size.X * 0.7, 0, 0) * CFrame.Angles(0, 0, windup * 0.6))
	end)
	setTransparency(m, "Stone", if windup > 0.3 then 0 else 1)
	each(m, "Stone", function(p)
		setLocal(m, p, rest(p) * CFrame.new(-windup * p.Size.X * 1.6, 0, 0))
	end)
end

-- Fenrir ----------------------------------------------------------------------

local WOLF = Color3.new(0.24, 0.24, 0.28)
local WOLF_DARK = Color3.new(0.1, 0.1, 0.13)

Bosses.build.fenrir = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 2.4, r * 1.1, r * 1.2), CFrame.new(-r * 0.2, 0, 0), WOLF)
	ellipsoid(m, Vector3.new(r * 1.0, r * 0.9, r * 0.9), CFrame.new(r * 1.0, r * 0.25, 0), WOLF)
	wedge(m, Vector3.new(r * 0.5, r * 0.4, r * 0.6), CFrame.new(r * 1.6, r * 0.15, 0) * CFrame.Angles(0, math.rad(-90), 0), WOLF_DARK)
	for _, s in { -1, 1 } do
		wedge(m, Vector3.new(r * 0.12, r * 0.45, r * 0.3), CFrame.new(r * 0.8, r * 0.8, s * r * 0.3), WOLF_DARK)
		for _, f in { -1, 1 } do
			cylinder(m, r * 0.7, r * 0.22, CFrame.new(f * r * 0.6, -r * 0.45, s * r * 0.4) * CFrame.Angles(0, 0, math.rad(80)), WOLF_DARK, { name = "Leg" })
		end
	end
	ellipsoid(m, Vector3.new(r * 1.4, r * 0.4, r * 0.4), CFrame.new(-r * 1.8, r * 0.2, 0) * CFrame.Angles(0, 0, 0.3), WOLF, { name = "Tail" })
	eyes(m, r * 1.35, r * 0.4, r * 0.22, r * 0.16, Color3.new(1, 0.3, 0.2))
	-- Elos da corrente Gleipnir arrastando atrás.
	for i = 0, 3 do
		cylinder(m, r * 0.08, r * 0.3, CFrame.new(-r * (1.4 + i * 0.4), -r * 0.2, 0) * CFrame.Angles(0, math.rad(90) * (i % 2), 0),
			Color3.new(0.75, 0.75, 0.8), { material = Enum.Material.Metal, name = "Chain" })
	end
	-- Linha vermelha da investida (aparece no aviso).
	block(m, Vector3.new(1, 0.15, r * 0.5), CFrame.new(0, -r * 0.5, 0), Color3.new(1, 0.2, 0.15),
		{ neon = true, noBurn = true, transparency = 1, name = "Line" })
end

Bosses.animate.fenrir = function(m, ent, t)
	local speed = if ent.visual == 2 then 16 else 8
	each(m, "Leg", function(p, i)
		setLocal(m, p, rest(p) * CFrame.Angles(0, 0, math.sin(t * speed + i * 1.6) * 0.5))
	end)
	each(m, "Tail", function(p)
		setLocal(m, p, rest(p) * CFrame.Angles(0, math.sin(t * 4) * 0.3, 0))
	end)
	each(m, "Line", function(p)
		if ent.visual == 1 then
			-- Do lobo até a borda do farol (o modelo olha para o farol no aviso).
			local dist = Vector2.new(ent.pos.X, ent.pos.Z).Magnitude
			local len = math.max(0.5, dist - 3 - 3)
			p.Size = Vector3.new(len, p.Size.Y, p.Size.Z)
			setLocal(m, p, CFrame.new(len / 2, rest(p).Y, 0))
			p.Transparency = 0.3 + 0.35 * (0.5 + 0.5 * math.sin(t * 20))
		else
			p.Transparency = 1
		end
	end)
end

-- Iara ------------------------------------------------------------------------

local IARA_SCALES = Color3.new(0.15, 0.5, 0.4)
local IARA_SKIN = Color3.new(0.72, 0.5, 0.38)
local IARA_HAIR = Color3.new(0.05, 0.12, 0.08)

Bosses.build.iara = function(m, radius)
	local r = studs(radius)
	for i = 0, 5 do
		local w = r * (1.0 - i * 0.12)
		ellipsoid(m, Vector3.new(w * 1.1, w * 0.6, w * 0.9), CFrame.new(-r * (0.4 + i * 0.45), -r * 0.1, 0), IARA_SCALES, { name = "Tail" })
	end
	for _, s in { -1, 1 } do
		wedge(m, Vector3.new(r * 0.1, r * 0.9, r * 0.9), CFrame.new(-r * 3.1, 0, s * r * 0.4) * CFrame.Angles(0, math.rad(90), s * 0.5), Color3.new(0.85, 0.75, 0.3))
	end
	ball(m, r * 1.0, CFrame.new(r * 0.05, r * 0.1, 0), IARA_SKIN)
	for _, s in { -1, 1 } do
		cylinder(m, r * 0.8, r * 0.16, CFrame.new(r * 0.45, r * 0.1, s * r * 0.5) * CFrame.Angles(0, s * 0.4, 0), IARA_SKIN, { name = "Arm" })
	end
	ball(m, r * 0.72, CFrame.new(r * 0.45, r * 0.5, 0), IARA_SKIN)
	for i = 0, 4 do
		ellipsoid(m, Vector3.new(r * 1.8, r * 0.12, r * 0.18), CFrame.new(-r * 0.4, r * 0.4, (i - 2) * r * 0.18) * CFrame.Angles(0, (i - 2) * 0.1, 0), IARA_HAIR, { name = "Hair" })
	end
	for i = 0, 4 do
		local a = -0.9 + i * 0.45
		ball(m, r * 0.2, CFrame.new(r * 0.45 - math.cos(a) * r * 0.3, r * 0.85, math.sin(a) * r * 0.35), Color3.new(1, 0.7, 0.8))
	end
	eyes(m, r * 0.75, r * 0.55, r * 0.14, r * 0.12, Color3.new(0.4, 1, 0.8))
	ball(m, r * 4, CFrame.new(), Color3.new(0.4, 0.9, 1), { noBurn = true, transparency = 1, material = Enum.Material.Glass, name = "Bubble" })
end

Bosses.animate.iara = function(m, ent, t)
	local singing = ent.visual == 1
	each(m, "Tail", function(p, i)
		setLocal(m, p, rest(p) * CFrame.new(0, 0, math.sin(t * 1.3 - i * 0.6) * p.Size.Z * 0.3))
	end)
	each(m, "Hair", function(p, i)
		setLocal(m, p, rest(p) * CFrame.Angles(0, math.sin(t * 1.6 + i * 1.1) * 0.15, 0))
	end)
	each(m, "Arm", function(p)
		setLocal(m, p, rest(p) * CFrame.new(if singing then p.Size.X * 0.3 else 0, 0, 0))
	end)
	setTransparency(m, "Bubble", if singing then 0.75 + 0.1 * math.sin(t * 6) else 1)
end

-- Boitatá -----------------------------------------------------------------------

local FIRE = Color3.new(1, 0.5, 0.1)
local FIRE_CORE = Color3.new(1, 0.9, 0.5)
local CHAR = Color3.new(0.2, 0.12, 0.09)

Bosses.build.boitata = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 2.2, r * 1.0, r * 1.6), CFrame.new(r * 0.2, 0, 0), FIRE, { noBurn = true, name = "Head" })
	for _, s in { -1, 1 } do
		ball(m, r * 0.6, CFrame.new(r * 0.5, r * 0.35, s * r * 0.42), Color3.new(1, 1, 0.85), { neon = true, noBurn = true, name = "Eye" })
		ball(m, r * 0.2, CFrame.new(r * 0.75, r * 0.4, s * r * 0.45), Color3.new(0.2, 0.05, 0), { noBurn = true })
	end
	cylinder(m, r * 0.6, r * 0.06, CFrame.new(r * 1.6, 0, 0), Color3.new(1, 0.85, 0.3), { neon = true, noBurn = true, name = "Tongue" })
	ball(m, r * 3.2, CFrame.new(), Color3.new(1, 0.8, 0.4), { neon = true, noBurn = true, transparency = 1, name = "Flare" })
end

local function boitataColors(m: Model, blazing: boolean, t: number)
	each(m, "Head", function(p)
		p.Color = if blazing then FIRE else CHAR
		p.Material = if blazing then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end)
	each(m, "Eye", function(p)
		p.Color = if blazing then Color3.new(1, 1, 0.85) else Color3.new(1, 0.6, 0.2)
	end)
end

Bosses.animate.boitata = function(m, ent, t)
	boitataColors(m, ent.visual == 1, t)
	each(m, "Tongue", function(p)
		setLocal(m, p, rest(p) * CFrame.Angles(0, math.sin(t * 12) * 0.3, 0))
	end)
	setTransparency(m, "Flare", 1 - 0.25 * (ent.aux / 255))
end

Bosses.trails.boitata = {
	count = 16, spacing = 1.5,
	build = function(i: number, n: number, radius: number): Model
		local r = studs(radius) * (1 - i * 0.045)
		local seg = Instance.new("Model")
		ball(seg, r * 2, CFrame.new(), FIRE, { neon = true, noBurn = true, name = "Body" })
		ball(seg, r * 1.1, CFrame.new(0, r * 0.3, 0), FIRE_CORE, { neon = true, noBurn = true, name = "Core" })
		ball(seg, r * 3.4, CFrame.new(), Color3.new(1, 0.45, 0.1), { neon = true, noBurn = true, transparency = 0.88, name = "Glow" })
		for k = 0, 1 do
			local a = i * 1.7 + k * 2.6
			ball(seg, r * 0.36, CFrame.new(math.cos(a) * r * 0.45, r * 0.6, math.sin(a) * r * 0.45), Color3.new(1, 0.45, 0.1),
				{ neon = true, noBurn = true, transparency = 1, name = "Ember" })
		end
		return seg
	end,
	-- Chama acesa ou corpo escuro com brasas, conforme o visual do chefe.
	animate = function(seg: Model, i: number, ent, t: number)
		local blazing = ent.visual == 1
		for _, p in seg:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name == "Body" then
					p.Color = if blazing then Color3.new(1, 0.45 + 0.1 * math.sin(t * 9 + i), 0.1) else CHAR
					p.Material = if blazing then Enum.Material.Neon else Enum.Material.SmoothPlastic
				elseif p.Name == "Core" or p.Name == "Glow" then
					p.Transparency = if blazing then (if p.Name == "Glow" then 0.88 else 0) else 1
				elseif p.Name == "Ember" then
					p.Transparency = if blazing then 1 else 0.5 - 0.4 * math.sin(t * 4 + i)
				end
			end
		end
	end,
}

-- Cuca --------------------------------------------------------------------------

local GATOR = Color3.new(0.3, 0.42, 0.22)
local ROBE = Color3.new(0.3, 0.2, 0.3)
local GREY_HAIR = Color3.new(0.78, 0.78, 0.76)

Bosses.build.cuca = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 1.8, r * 1.4, r * 1.8), CFrame.new(-r * 0.3, 0, 0), ROBE)
	ellipsoid(m, Vector3.new(r * 1.2, r * 0.8, r * 0.9), CFrame.new(r * 0.4, r * 0.7, 0), GATOR)
	ellipsoid(m, Vector3.new(r * 1.2, r * 0.35, r * 0.6), CFrame.new(r * 1.2, r * 0.6, 0), GATOR)
	for i = 0, 3 do
		wedge(m, Vector3.new(r * 0.06, r * 0.12, r * 0.1), CFrame.new(r * (0.9 + i * 0.2), r * 0.45, r * 0.25), Color3.new(0.95, 0.92, 0.85))
		wedge(m, Vector3.new(r * 0.06, r * 0.12, r * 0.1), CFrame.new(r * (0.9 + i * 0.2), r * 0.45, -r * 0.25), Color3.new(0.95, 0.92, 0.85))
	end
	-- Cabelo grisalho desgrenhado (folclore; nada do visual da TV).
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		ball(m, r * 0.42, CFrame.new(r * 0.1 + math.cos(a) * r * 0.25, r * 1.05, math.sin(a) * r * 0.45), GREY_HAIR)
	end
	cylinder(m, r * 2.2, r * 0.12, CFrame.new(r * 0.4, r * 0.3, r * 0.9) * CFrame.Angles(0, 0, math.rad(70)), Color3.new(0.35, 0.22, 0.12))
	eyes(m, r * 0.85, r * 0.95, r * 0.25, r * 0.16, Color3.new(1, 0.85, 0.2))
	-- Círculo de runas do feitiço de sono.
	disc(m, r * 4, 0.05, CFrame.new(0, -r * 0.6, 0), Color3.new(0.7, 0.4, 1), { neon = true, noBurn = true, transparency = 1, name = "Runes" })
	disc(m, r * 3.2, 0.06, CFrame.new(0, -r * 0.58, 0), Color3.new(0.2, 0.05, 0.3), { noBurn = true, transparency = 1, name = "RunesInner" })
end

Bosses.animate.cuca = function(m, ent, t)
	local cast = ent.visual / 255
	setTransparency(m, "Runes", if cast > 0 then 0.6 - 0.4 * cast else 1)
	setTransparency(m, "RunesInner", if cast > 0 then 0.5 else 1)
	each(m, "Runes", function(p)
		setLocal(m, p, rest(p) * CFrame.Angles(t * 2, 0, 0))
	end)
end

-- Umibōzu -----------------------------------------------------------------------

Bosses.build.umibozu = function(m, radius)
	local r = studs(radius)
	ball(m, r * 2, CFrame.new(), Color3.new(0.08, 0.1, 0.16), { name = "Body" })
	ball(m, r * 0.9, CFrame.new(-r * 0.25, r * 0.55, -r * 0.25), Color3.new(0.18, 0.22, 0.3), { name = "Body" })
	for _, s in { -1, 1 } do
		ball(m, r * 0.44, CFrame.new(r * 0.75, r * 0.35, s * r * 0.32), Color3.new(1, 0.95, 0.7), { neon = true, noBurn = true, name = "Eye" })
	end
	disc(m, r * 2.3, 0.08, CFrame.new(0, -r * 0.2, 0), Color3.new(1, 0.8, 0.45), { neon = true, noBurn = true, transparency = 1, name = "Ring" })
	disc(m, r * 2.8, 0.05, CFrame.new(0, -r * 0.5, 0), Color3.new(0.8, 0.9, 1), { noBurn = true, transparency = 0.7, name = "Ripple" })
end

Bosses.animate.umibozu = function(m, ent, t)
	local shown = ent.visual / 255
	setTransparency(m, "Body", 1 - (0.22 + 0.78 * shown))
	setTransparency(m, "Ring", if ent.aux >= 255 then 0.3 else 1 - 0.6 * (ent.aux / 255))
	each(m, "Ripple", function(p)
		local k = (t * 0.6) % 1
		p.Transparency = 0.6 + 0.4 * k
		local d = p:GetAttribute("D") or p.Size.Y
		p:SetAttribute("D", d)
		p.Size = Vector3.new(p.Size.X, (d :: number) * (1 + k), (d :: number) * (1 + k))
	end)
end

-- Kyūbi -------------------------------------------------------------------------

local FOX = Color3.new(0.96, 0.88, 0.7)
local FOX_TIP = Color3.new(1, 1, 1)

Bosses.build.kyubi = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 3.2, 0.05, r * 1.8), CFrame.new(r * 0.35, -r * 0.9, r * 0.5), Color3.new(0, 0, 0), { noBurn = true, transparency = 0.65, name = "Shadow" })
	ellipsoid(m, Vector3.new(r * 1.8, r * 0.9, r * 0.9), CFrame.new(0, 0, 0), FOX)
	ellipsoid(m, Vector3.new(r * 0.9, r * 0.75, r * 0.75), CFrame.new(r * 1.0, r * 0.3, 0), FOX)
	wedge(m, Vector3.new(r * 0.4, r * 0.3, r * 0.5), CFrame.new(r * 1.5, r * 0.2, 0) * CFrame.Angles(0, math.rad(-90), 0), FOX)
	for _, s in { -1, 1 } do
		wedge(m, Vector3.new(r * 0.1, r * 0.5, r * 0.3), CFrame.new(r * 0.9, r * 0.85, s * r * 0.25), FOX)
	end
	for i = 0, 8 do
		local a = (i - 4) * 0.28
		local tail = ellipsoid(m, Vector3.new(r * 1.8, r * 0.45, r * 0.45),
			CFrame.Angles(0, a, 0) * CFrame.new(-r * 1.6, r * 0.2, 0), FOX, { name = "Tail" })
		tail:SetAttribute("Angle", a)
		ball(m, r * 0.4, CFrame.Angles(0, a, 0) * CFrame.new(-r * 2.4, r * 0.2, 0), FOX_TIP, { name = "TailTip" })
	end
	eyes(m, r * 1.35, r * 0.45, r * 0.2, r * 0.14, Color3.new(1, 0.25, 0.25))
	ball(m, r * 3, CFrame.new(), Color3.new(0.8, 0.85, 1), { neon = true, noBurn = true, transparency = 1, name = "Puff" })
end

Bosses.animate.kyubi = function(m, ent, t)
	each(m, "Tail", function(p, i)
		local a = (p:GetAttribute("Angle") :: number) + math.sin(t * 2 + i) * 0.1
		local r = p.Size.X / 1.8
		setLocal(m, p, CFrame.Angles(0, a, 0) * CFrame.new(-r * 1.6, r * 0.2, 0))
	end)
	local puff = ent.visual / 255
	each(m, "Puff", function(p)
		p.Transparency = 1 - 0.35 * puff
		local d = p:GetAttribute("D") or p.Size.X
		p:SetAttribute("D", d)
		p.Size = Vector3.one * (d :: number) * (1 + (1 - puff) * 1.5)
	end)
end

-- Esfinge e símbolos ---------------------------------------------------------------

local SAND = Color3.new(0.85, 0.7, 0.45)
local NEMES_BLUE = Color3.new(0.15, 0.3, 0.65)
local GOLD = Color3.new(1, 0.8, 0.3)

-- Símbolos: 0 ankh, 1 olho, 2 pena. Peças com nome "Glyph<n>".
local function glyph(m: Model, kind: number, cf: CFrame, size: number, name: string)
	local opts = { neon = true, noBurn = true, name = name }
	if kind == 0 then
		block(m, Vector3.new(size * 0.18, 0.1, size * 0.9), cf * CFrame.new(0, 0, size * 0.15), GOLD, opts)
		block(m, Vector3.new(size * 0.7, 0.1, size * 0.16), cf * CFrame.new(0, 0, -size * 0.05), GOLD, opts)
		disc(m, size * 0.45, 0.1, cf * CFrame.new(0, 0, -size * 0.38), GOLD, opts)
	elseif kind == 1 then
		ellipsoid(m, Vector3.new(size * 0.9, 0.1, size * 0.45), cf, GOLD, opts)
		disc(m, size * 0.25, 0.15, cf, Color3.new(0.1, 0.1, 0.2), opts)
		block(m, Vector3.new(size * 0.08, 0.1, size * 0.4), cf * CFrame.new(-size * 0.15, 0, size * 0.35), GOLD, opts)
	else
		ellipsoid(m, Vector3.new(size * 0.35, 0.1, size * 1.0), cf, GOLD, opts)
		block(m, Vector3.new(size * 0.05, 0.12, size * 1.1), cf, Color3.new(0.6, 0.45, 0.15), opts)
	end
end

Bosses.build.sphinx = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 2.6, r * 1.0, r * 1.3), CFrame.new(-r * 0.4, 0, 0), SAND)
	for _, s in { -1, 1 } do
		ellipsoid(m, Vector3.new(r * 1.1, r * 0.35, r * 0.35), CFrame.new(r * 0.8, -r * 0.3, s * r * 0.4), SAND)
	end
	ellipsoid(m, Vector3.new(r * 0.9, r * 1.0, r * 0.9), CFrame.new(r * 0.5, r * 0.65, 0), SAND)
	-- Nemes listrado.
	for i = 0, 4 do
		local c = if i % 2 == 0 then NEMES_BLUE else GOLD
		block(m, Vector3.new(r * 0.5, r * 0.12, r * 1.2), CFrame.new(r * 0.3, r * (0.45 + i * 0.13), 0), c)
	end
	eyes(m, r * 0.95, r * 0.75, r * 0.18, r * 0.12, Color3.new(0.3, 0.8, 1))
	ellipsoid(m, Vector3.new(r * 1.8, 0.05, r * 1.8), CFrame.new(-r * 0.3, -r * 0.55, 0), Color3.new(0.3, 0.8, 1),
		{ neon = true, noBurn = true, transparency = 1, name = "Weak" })
	for k = 0, 2 do
		glyph(m, k, CFrame.new(r * 0.4, r * 1.9, 0), r * 1.0, "Answer" .. k)
	end
end

Bosses.animate.sphinx = function(m, ent, t)
	local answer = ent.visual - 1 -- -1 = sem enigma
	for k = 0, 2 do
		setTransparency(m, "Answer" .. k, if k == answer then 0.1 + 0.2 * math.sin(t * 6) else 1)
	end
	setTransparency(m, "Weak", if ent.aux == 1 then 0.5 + 0.2 * math.sin(t * 8) else 1)
end

Bosses.build.sphinx_glyph = function(m, radius)
	local size = 3
	disc(m, size * 1.4, 0.05, CFrame.new(0, -0.1, 0), Color3.new(0.2, 0.15, 0.05), { noBurn = true, transparency = 0.4, name = "Base" })
	disc(m, size * 1.5, 0.06, CFrame.new(0, -0.05, 0), Color3.new(1, 0.95, 0.6), { neon = true, noBurn = true, transparency = 1, name = "Hold" })
	for k = 0, 2 do
		glyph(m, k, CFrame.new(0, 0.2, 0), size, "Glyph" .. k)
	end
end

Bosses.animate.sphinx_glyph = function(m, ent, t)
	for k = 0, 2 do
		setTransparency(m, "Glyph" .. k, if k == ent.visual then 0 else 1)
	end
	local hold = ent.aux / 255
	setTransparency(m, "Hold", if hold > 0 then 0.8 - 0.6 * hold else 1)
end

-- Apep ------------------------------------------------------------------------------

local APEP = Color3.new(0.2, 0.1, 0.25)
local APEP_STRIPE = Color3.new(0.85, 0.65, 0.2)
local APEP_NECK = 6 -- gomos entre o corpo e a cabeça

-- A entidade é o meio do corpo; a cabeça fica à frente no mesmo círculo em
-- volta do farol (aux = ângulo à frente × 60). Gomos e cabeça são postos em
-- coordenadas do mundo a cada quadro.
Bosses.build.apep = function(m, radius)
	local r = studs(radius)
	ball(m, r * 2, CFrame.new(), APEP)
	block(m, Vector3.new(r * 1.6, r * 0.2, r * 0.3), CFrame.new(0, r * 0.85, 0), APEP_STRIPE)
	for i = 1, APEP_NECK do
		local w = r * (1.0 - i * 0.03)
		ball(m, w * 2, CFrame.new(), APEP, { name = "Neck" })
	end
	ellipsoid(m, Vector3.new(r * 2.2, r * 1.1, r * 1.7), CFrame.new(), APEP, { name = "Head" })
	ball(m, r * 0.32, CFrame.new(), Color3.new(1, 0.2, 0.2), { neon = true, noBurn = true, name = "EyeL" })
	ball(m, r * 0.32, CFrame.new(), Color3.new(1, 0.2, 0.2), { neon = true, noBurn = true, name = "EyeR" })
	ball(m, r * 1.4, CFrame.new(), Color3.new(1, 0.85, 0.4), { neon = true, noBurn = true, transparency = 1, name = "Mouth" })
end

Bosses.animate.apep = function(m, ent, t)
	local pos = ent.pos
	local orbit = math.max(Vector2.new(pos.X, pos.Z).Magnitude, 0.1)
	local base = math.atan2(pos.Z, pos.X)
	local ahead = ent.aux / 60
	-- Altura do pivô do quadro: inclui o balanço e o "escondido" (-60) do renderizador.
	local y = m:GetPivot().Position.Y
	local function at(a: number): Vector3
		return Vector3.new(math.cos(a) * orbit, y, math.sin(a) * orbit)
	end
	each(m, "Neck", function(p, i)
		local a = base + ahead * i / (APEP_NECK + 1)
		p.CFrame = CFrame.new(at(a) + Vector3.new(0, math.sin(t * 3 - i * 0.6) * 0.3, 0))
	end)
	local headPos = at(base + ahead)
	local tangent = at(base + ahead + 0.01) - headPos
	local look = if tangent.Magnitude > 1e-4 then CFrame.lookAt(headPos, headPos + tangent.Unit) * CFrame.Angles(0, math.rad(90), 0) else CFrame.new(headPos)
	each(m, "Head", function(p)
		p.CFrame = look
	end)
	local r = (m:FindFirstChild("Head") :: BasePart).Size.X / 2.2
	each(m, "EyeL", function(p)
		p.CFrame = look * CFrame.new(r * 0.6, r * 0.4, -r * 0.4)
	end)
	each(m, "EyeR", function(p)
		p.CFrame = look * CFrame.new(r * 0.6, r * 0.4, r * 0.4)
	end)
	each(m, "Mouth", function(p)
		p.CFrame = look * CFrame.new(r * 1.1, 0, 0)
		p.Transparency = if ent.visual == 1 then 0.4 + 0.2 * math.sin(t * 20) else 1
	end)
end

Bosses.trails.apep = {
	count = 9, spacing = 1.5,
	build = function(i: number, n: number, radius: number): Model
		local r = studs(radius) * (1 - i * 0.06)
		local seg = Instance.new("Model")
		ball(seg, r * 2, CFrame.new(), APEP)
		if i % 2 == 0 then
			block(seg, Vector3.new(r * 1.2, r * 0.18, r * 0.3), CFrame.new(0, r * 0.85, 0), APEP_STRIPE)
		end
		return seg
	end,
}

-- Cila e cabeças ------------------------------------------------------------------------

local ROCK = Color3.new(0.45, 0.45, 0.48)
local SCYLLA_SKIN = Color3.new(0.55, 0.65, 0.6)
local SCYLLA_HEAD = Color3.new(0.3, 0.42, 0.42)

Bosses.build.scylla = function(m, radius)
	local r = studs(radius)
	for _, p in { Vector3.new(-0.6, -0.3, 0.5), Vector3.new(-0.2, -0.4, -0.7), Vector3.new(-0.9, -0.2, -0.2), Vector3.new(0.1, -0.5, 0.6) } do
		ball(m, r * 1.4, CFrame.new(p.X * r, p.Y * r, p.Z * r), ROCK, { material = Enum.Material.Slate })
	end
	ellipsoid(m, Vector3.new(r * 1.0, r * 1.6, r * 1.0), CFrame.new(-r * 0.3, r * 0.6, 0), SCYLLA_SKIN)
	ball(m, r * 0.6, CFrame.new(-r * 0.3, r * 1.55, 0), SCYLLA_SKIN)
	for _, s in { -1, 1 } do
		ball(m, r * 0.12, CFrame.new(-r * 0.05, r * 1.6, s * r * 0.12), Color3.new(0.9, 1, 0.6), { neon = true, noBurn = true })
	end
	-- Cães do ventre (a lenda) em volta da cintura.
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		ellipsoid(m, Vector3.new(r * 0.6, r * 0.4, r * 0.4), CFrame.new(-r * 0.3 + math.cos(a) * r * 0.5, r * 0.2, math.sin(a) * r * 0.5), Color3.new(0.35, 0.3, 0.28))
	end
end

Bosses.build.scylla_head = function(m, radius)
	local r = 1.6
	ellipsoid(m, Vector3.new(r * 1.8, r * 0.9, r * 1.1), CFrame.new(), SCYLLA_HEAD)
	wedge(m, Vector3.new(r * 0.9, r * 0.3, r * 1.0), CFrame.new(r * 0.9, r * 0.1, 0) * CFrame.Angles(0, math.rad(-90), 0), SCYLLA_HEAD, { name = "Jaw" })
	for i = 0, 3 do
		wedge(m, Vector3.new(r * 0.06, r * 0.16, r * 0.1), CFrame.new(r * (0.6 + i * 0.18), -r * 0.05, r * 0.3), Color3.new(0.95, 0.92, 0.85))
		wedge(m, Vector3.new(r * 0.06, r * 0.16, r * 0.1), CFrame.new(r * (0.6 + i * 0.18), -r * 0.05, -r * 0.3), Color3.new(0.95, 0.92, 0.85))
	end
	eyes(m, r * 0.45, r * 0.35, r * 0.3, r * 0.2, Color3.new(1, 0.9, 0.3))
	cylinder(m, 7, r * 0.6, CFrame.new(-3.5 - r * 0.7, 0, 0), SCYLLA_SKIN, { name = "Neck" })
end

Bosses.animate.scylla_head = function(m, ent, t)
	local progress = ent.visual / 255
	local recoiling = ent.aux == 2
	each(m, "Neck", function(p)
		-- O pescoço estica até o corpo de Cila conforme a cabeça avança.
		local len = 7 + progress * 21
		p.Size = Vector3.new(len, p.Size.Y, p.Size.Z)
		setLocal(m, p, CFrame.new(-len / 2 - 1.1, 0, 0))
	end)
	each(m, "Jaw", function(p)
		setLocal(m, p, rest(p) * CFrame.Angles(0, 0, if ent.aux == 1 then -0.3 - 0.2 * math.sin(t * 10) else 0))
	end)
	each(m, "Eye", function(p)
		p.Color = if recoiling then Color3.new(0.5, 0.45, 0.2) else Color3.new(1, 0.9, 0.3)
	end)
end

-- Medusa ----------------------------------------------------------------------------

local GORGON_SCALES = Color3.new(0.25, 0.45, 0.25)
local GORGON_SKIN = Color3.new(0.6, 0.72, 0.55)

Bosses.build.medusa = function(m, radius)
	local r = studs(radius)
	for i = 0, 6 do
		local a = i * 0.9
		local w = r * (1 - i * 0.1)
		ball(m, w * 1.3, CFrame.new(-r * 0.4 + math.cos(a) * r * 0.8, -r * 0.3, math.sin(a) * r * 0.8), GORGON_SCALES, { name = "Coil" })
	end
	ellipsoid(m, Vector3.new(r * 0.8, r * 1.3, r * 0.9), CFrame.new(r * 0.1, r * 0.4, 0), GORGON_SKIN)
	ball(m, r * 0.8, CFrame.new(r * 0.25, r * 1.2, 0), GORGON_SKIN)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local snake = cylinder(m, r * 0.7, r * 0.12,
			CFrame.new(r * 0.15 + math.cos(a) * r * 0.35, r * 1.55, math.sin(a) * r * 0.35) * CFrame.Angles(0, -a, math.rad(40)),
			Color3.new(0.2, 0.55, 0.25), { name = "Snake" })
		snake:SetAttribute("Phase", i)
	end
	for _, s in { -1, 1 } do
		ball(m, r * 0.18, CFrame.new(r * 0.6, r * 1.25, s * r * 0.15), Color3.new(0.5, 0.6, 0.4), { neon = true, noBurn = true, name = "Eye" })
	end
	-- Faixa do olhar em direção ao farol (aparece durante o olhar).
	block(m, Vector3.new(12, 0.3, r * 1.2), CFrame.new(6 + r * 0.6, r * 1.25, 0),
		Color3.new(0.6, 1, 0.5), { neon = true, noBurn = true, transparency = 1, name = "Gaze" })
end

Bosses.animate.medusa = function(m, ent, t)
	each(m, "Snake", function(p)
		local ph = p:GetAttribute("Phase") :: number
		setLocal(m, p, rest(p) * CFrame.Angles(0, math.sin(t * 5 + ph) * 0.3, 0))
	end)
	each(m, "Eye", function(p)
		if ent.visual == 2 then
			p.Color = Color3.new(0.8, 1, 0.4)
		elseif ent.visual == 1 then
			p.Color = Color3.new(0.5, 0.6, 0.4):Lerp(Color3.new(0.8, 1, 0.4), 0.5 + 0.5 * math.sin(t * 14))
		else
			p.Color = Color3.new(0.5, 0.6, 0.4)
		end
	end)
	setTransparency(m, "Gaze", if ent.visual == 2 then 0.6 + 0.1 * math.sin(t * 10) else 1)
end

-- Balor -----------------------------------------------------------------------------

local BALOR = Color3.new(0.28, 0.22, 0.3)
local BALOR_ARMOR = Color3.new(0.35, 0.33, 0.3)

Bosses.build.balor = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 1.6, r * 1.8, r * 2.2), CFrame.new(-r * 0.3, 0, 0), BALOR)
	for _, s in { -1, 1 } do
		ball(m, r * 0.8, CFrame.new(-r * 0.2, r * 0.6, s * r * 0.95), BALOR_ARMOR, { material = Enum.Material.Metal })
	end
	ellipsoid(m, Vector3.new(r * 1.1, r * 1.0, r * 1.0), CFrame.new(r * 0.35, r * 0.75, 0), BALOR)
	-- O olho único: branco, íris vermelha e a pálpebra que cobre.
	ball(m, r * 0.7, CFrame.new(r * 0.75, r * 0.85, 0), Color3.new(0.95, 0.9, 0.85), { noBurn = true })
	ball(m, r * 0.36, CFrame.new(r * 1.02, r * 0.85, 0), Color3.new(1, 0.15, 0.1), { neon = true, noBurn = true, name = "Iris" })
	ellipsoid(m, Vector3.new(r * 0.8, r * 0.75, r * 0.8), CFrame.new(r * 0.78, r * 0.85, 0), Color3.new(0.22, 0.17, 0.24), { name = "Lid" })
	-- Raio do olhar até o farol e o brilho do confronto com o feixe.
	block(m, Vector3.new(30, 0.4, 0.6), CFrame.new(r * 1.1 + 15, r * 0.85, 0), Color3.new(1, 0.15, 0.1),
		{ neon = true, noBurn = true, transparency = 1, name = "Glare" })
	ball(m, r * 1.2, CFrame.new(r * 1.2, r * 0.85, 0), Color3.new(1, 1, 0.9), { neon = true, noBurn = true, transparency = 1, name = "Clash" })
end

Bosses.animate.balor = function(m, ent, t)
	local open = ent.visual / 255
	each(m, "Lid", function(p)
		setLocal(m, p, rest(p) * CFrame.new(-open * p.Size.X * 0.45, open * p.Size.Y * 0.5, 0))
	end)
	each(m, "Glare", function(p)
		if ent.aux == 1 then
			local dist = Vector2.new(ent.pos.X, ent.pos.Z).Magnitude
			local r = (m:FindFirstChild("Iris") :: BasePart).Size.X / 0.36
			local len = math.max(0.5, dist - r * 1.1 - 3)
			p.Size = Vector3.new(len, p.Size.Y, p.Size.Z)
			setLocal(m, p, CFrame.new(r * 1.1 + len / 2, rest(p).Y, 0))
			p.Transparency = 0.3 + 0.2 * math.sin(t * 25)
		else
			p.Transparency = 1
		end
	end)
	setTransparency(m, "Clash", if ent.aux == 2 then 0.5 + 0.2 * math.sin(t * 30) else 1)
end

-- Cailleach -----------------------------------------------------------------------------

local CLOAK = Color3.new(0.35, 0.42, 0.55)
local OLD_SKIN = Color3.new(0.75, 0.78, 0.82)

Bosses.build.cailleach = function(m, radius)
	local r = studs(radius)
	ellipsoid(m, Vector3.new(r * 1.6, r * 1.6, r * 1.6), CFrame.new(-r * 0.2, 0, 0), CLOAK)
	ellipsoid(m, Vector3.new(r * 0.9, r * 0.6, r * 1.3), CFrame.new(r * 0.35, -r * 0.2, 0), Color3.new(0.5, 0.45, 0.4)) -- avental com pedras
	for i = 0, 2 do
		ball(m, r * 0.25, CFrame.new(r * 0.6, -r * 0.1, (i - 1) * r * 0.35), Color3.new(0.55, 0.55, 0.58), { material = Enum.Material.Slate })
	end
	ball(m, r * 0.8, CFrame.new(r * 0.2, r * 0.9, 0), OLD_SKIN)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		ball(m, r * 0.45, CFrame.new(math.cos(a) * r * 0.3, r * 1.1, math.sin(a) * r * 0.4), Color3.new(0.95, 0.95, 0.97))
	end
	eyes(m, r * 0.55, r * 1.0, r * 0.15, r * 0.12, Color3.new(0.5, 0.85, 1))
	cylinder(m, r * 2.6, r * 0.12, CFrame.new(r * 0.3, r * 0.4, r * 0.85) * CFrame.Angles(0, 0, math.rad(80)), Color3.new(0.4, 0.3, 0.22), { name = "Staff" })
	ball(m, r * 0.4, CFrame.new(r * 0.53, r * 1.7, r * 0.85), Color3.new(0.6, 0.9, 1), { neon = true, noBurn = true, name = "Crystal" })
	disc(m, r * 6, 0.05, CFrame.new(0, -r * 0.6, 0), Color3.new(0.9, 0.95, 1), { noBurn = true, transparency = 1, name = "Storm" })
end

Bosses.animate.cailleach = function(m, ent, t)
	local storm = ent.visual == 1
	each(m, "Storm", function(p)
		p.Transparency = if storm then 0.7 + 0.1 * math.sin(t * 6) else 1
		setLocal(m, p, rest(p) * CFrame.Angles(t * 3, 0, 0))
	end)
	each(m, "Crystal", function(p)
		p.Transparency = if storm then 0 else 0.3
	end)
end

-- Rastros (corpos de serpente) ------------------------------------------------------------
-- trails[art] = {count, spacing (studs ao longo do caminho percorrido),
--   build(i, n, radius) -> Model (segmento i de 1..n; o renderizador posiciona
--   o modelo com PivotTo no ponto do rastro, olhando no sentido do movimento),
--   animate(seg, i, ent, t)?}. O rastro sai da posição da entidade para trás.

-- Pivô na origem: as peças são montadas em volta de (0, 0, 0) e o
-- renderizador move o modelo com PivotTo. Se o modelo já tiver PrimaryPart
-- (a peça raiz do renderizador), ela manda e isto não muda nada.
for art, fn in Bosses.build do
	Bosses.build[art] = function(m: Model, radius: number)
		if not m.PrimaryPart then
			m.WorldPivot = CFrame.new()
		end
		fn(m, radius)
	end
end
for _, trail in Bosses.trails do
	local fn = trail.build
	trail.build = function(i: number, n: number, radius: number): Model
		local seg = fn(i, n, radius)
		seg.WorldPivot = CFrame.new()
		return seg
	end
end

return Bosses
