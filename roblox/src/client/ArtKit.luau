-- Peças e moldes das criaturas (porta das funções genéricas de
-- scripts/gameplay/creature_art.gd: bird, shell, moth, fogbank, wisp, wolf,
-- boulder...). Os arquivos de client/Art usam estes moldes com as cores de
-- cada mapa.
--
-- Convenções:
--   * `r` é o raio da criatura em studs; o modelo é montado na origem, com a
--     frente apontando para +X e o topo para +Y (a câmera vê de cima).
--   * Toda peça guarda o atributo "BaseColor" (o renderizador puxa para o
--     laranja da queima).
--   * Peças animadas guardam "Offset" (CFrame em relação ao pivô do modelo);
--     as funções de animação recolocam essas peças a partir de model:GetPivot(),
--     por isso o renderizador deve chamar animate DEPOIS do PivotTo do quadro.

local ArtKit = {}

local function setup(p: BasePart, color: Color3, props: { [string]: any }?)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	for k, v in props or {} do
		(p :: any)[k] = v
	end
	p:SetAttribute("BaseColor", color)
end

-- Bola (ou elipsoide via malha) com centro em `cf`.
function ArtKit.ball(m: Model, size: Vector3 | number, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local s = if typeof(size) == "number" then Vector3.one * size else size :: Vector3
	local p = Instance.new("Part")
	if s.X == s.Y and s.Y == s.Z then
		p.Shape = Enum.PartType.Ball
	else
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Size = s
	p.CFrame = cf
	setup(p, color, props)
	p.Parent = m
	return p
end

function ArtKit.block(m: Model, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	setup(p, color, props)
	p.Parent = m
	return p
end

-- Cunha: a face inclinada desce de +Y/-Z para -Y/+Z (padrão do Roblox).
function ArtKit.wedge(m: Model, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	setup(p, color, props)
	p.Parent = m
	return p
end

-- Cilindro com o eixo ao longo de X local de `cf`.
function ArtKit.cyl(m: Model, length: number, diameter: number, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, diameter, diameter)
	p.CFrame = cf
	setup(p, color, props)
	p.Parent = m
	return p
end

-- Brilho: bola neon (olhos, chamas, lanternas).
function ArtKit.glow(m: Model, d: number, cf: CFrame, color: Color3, transparency: number?): BasePart
	return ArtKit.ball(m, d, cf, color, { Material = Enum.Material.Neon, Transparency = transparency or 0 })
end

-- Par de olhos acesos à frente (x), na altura y, separados por `gap`.
function ArtKit.eyes(m: Model, x: number, y: number, gap: number, d: number, color: Color3)
	for _, s in { -1, 1 } do
		ArtKit.glow(m, d, CFrame.new(x, y, s * gap), color)
	end
end

-- Marca a peça como animada: guarda o nome e o offset em relação ao pivô.
function ArtKit.anim(p: BasePart, name: string): BasePart
	p.Name = name
	p:SetAttribute("Offset", p.CFrame)
	return p
end

-- Recoloca todas as peças com o nome dado: pivô * offset * `extra`.
function ArtKit.pose(model: Model, name: string, extra: CFrame | ((BasePart) -> CFrame))
	local pivot = model:GetPivot()
	local sc = model:GetScale() -- offsets foram gravados na escala 1
	for _, p in model:GetChildren() do
		if p.Name == name and p:IsA("BasePart") then
			local offset = p:GetAttribute("Offset") :: CFrame?
			if offset then
				local e = if typeof(extra) == "function" then (extra :: any)(p) else extra
				local scaled = offset - offset.Position + offset.Position * sc
				p.CFrame = pivot * scaled * e
			end
		end
	end
end

-- Como pose, mas `transform` vale no espaço do MODELO (em volta do pivô):
-- pivô * transform * offset. Serve para girar várias peças juntas em volta
-- de um eixo comum (asas na linha do corpo, tampa na dobradiça, pedra que rola).
function ArtKit.poseModel(model: Model, name: string, transform: CFrame)
	local pivot = model:GetPivot()
	local sc = model:GetScale()
	for _, p in model:GetChildren() do
		if p.Name == name and p:IsA("BasePart") then
			local offset = p:GetAttribute("Offset") :: CFrame?
			if offset then
				p.CFrame = pivot * transform * (offset - offset.Position + offset.Position * sc)
			end
		end
	end
end

-- Escala o modelo inteiro (mariposas que crescem). Só refaz se mudou.
function ArtKit.scale(model: Model, s: number)
	if s <= 0 then
		return
	end
	local last = model:GetAttribute("LastScale") or 1
	if math.abs(last - s) > 0.02 then
		model:SetAttribute("LastScale", s)
		model:ScaleTo(s)
	end
end

-- Mostra ou esconde as peças com o nome dado.
function ArtKit.visible(model: Model, name: string, on: boolean, transparency: number?)
	for _, p in model:GetChildren() do
		if p.Name == name and p:IsA("BasePart") then
			p.Transparency = if on then (transparency or 0) else 1
		end
	end
end

-- Brasas carregadas pela ladra (aux = quantidade): bolinhas acesas sob o corpo.
function ArtKit.carry(m: Model, r: number)
	for i = 1, 4 do
		local a = i / 4 * 2 * math.pi
		local p = ArtKit.glow(m, r * 0.32, CFrame.new(-r * 0.2 + math.cos(a) * r * 0.25, -r * 0.45, math.sin(a) * r * 0.25),
			Color3.new(1, 0.6, 0.2))
		p.Name = "Carry" .. i
	end
end

function ArtKit.showCarry(model: Model, count: number)
	for i = 1, 4 do
		local p = model:FindFirstChild("Carry" .. i) :: BasePart?
		if p then
			p.Transparency = if i <= count then 0 else 1
		end
	end
end

-- Moldes ----------------------------------------------------------------------

local T = {}
ArtKit.T = T

-- Ave (gaivota, corvo, tengu, íbis, harpia sem rosto): corpo, asas que
-- batem, bico e olhos. `beak` = comprimento relativo do bico.
function T.bird(m: Model, r: number, body: Color3, wing: Color3, beakColor: Color3, eye: Color3, beak: number?)
	ArtKit.ball(m, Vector3.new(r * 1.6, r * 0.8, r * 0.9), CFrame.new(), body)
	ArtKit.ball(m, r * 0.75, CFrame.new(r * 0.7, r * 0.15, 0), body)
	ArtKit.wedge(m, Vector3.new(r * 0.2, r * 0.2, r * (beak or 0.46) * 2),
		CFrame.new(r * (1.05 + (beak or 0.46) * 0.6), r * 0.1, 0) * CFrame.Angles(0, math.rad(-90), 0), beakColor)
	for _, s in { -1, 1 } do
		ArtKit.anim(ArtKit.block(m, Vector3.new(r * 0.9, r * 0.08, r * 1.5), CFrame.new(-r * 0.1, r * 0.2, s * r * 0.95), wing),
			if s < 0 then "WingL" else "WingR")
	end
	ArtKit.block(m, Vector3.new(r * 0.6, r * 0.06, r * 0.5), CFrame.new(-r * 0.95, r * 0.05, 0), wing)
	ArtKit.eyes(m, r * 0.95, r * 0.35, r * 0.22, r * 0.18, eye)
	ArtKit.carry(m, r)
end

function T.birdAnim(model: Model, ent, t: number)
	-- Asas giram em volta da linha do corpo (eixo X do modelo), não do próprio centro.
	local flap = math.sin(t * 11 + (ent.id or 0)) * 0.5
	ArtKit.poseModel(model, "WingL", CFrame.Angles(flap, 0, 0))
	ArtKit.poseModel(model, "WingR", CFrame.Angles(-flap, 0, 0))
	ArtKit.showCarry(model, ent.aux or 0)
end

-- Concha/casca refletora (ostra, escudo de gelo, escaravelho): a tampa abre
-- quando ent.reflecting é falso.
function T.shell(m: Model, r: number, outer: Color3, inner: Color3, ridge: Color3)
	ArtKit.ball(m, Vector3.new(r * 1.8, r * 0.5, r * 1.8), CFrame.new(0, -r * 0.1, 0), outer)
	ArtKit.glow(m, r * 0.7, CFrame.new(r * 0.05, r * 0.05, 0), inner, 0.1)
	local lid = ArtKit.ball(m, Vector3.new(r * 1.8, r * 0.45, r * 1.8), CFrame.new(0, r * 0.2, 0), outer, { Reflectance = 0.3 })
	ArtKit.anim(lid, "Lid")
	for i = -1, 1 do
		ArtKit.anim(ArtKit.block(m, Vector3.new(r * 1.6, r * 0.06, r * 0.1), CFrame.new(0, r * 0.42, i * r * 0.45), ridge), "Lid")
	end
end

function T.shellAnim(model: Model, ent, _t: number)
	local open = if ent.reflecting then 0 else 1
	local cur = model:GetAttribute("Open") or 0
	cur += (open - cur) * 0.2
	model:SetAttribute("Open", cur)
	-- Dobradiça na borda de trás das peças "Lid": a tampa e os frisos giram
	-- juntos e a frente sobe (antes cada peça girava no próprio centro e os
	-- frisos se soltavam da tampa).
	local sc = model:GetScale()
	local hx, hy = 0, 0
	for _, p in model:GetChildren() do
		if p.Name == "Lid" and p:IsA("BasePart") then
			local o = p:GetAttribute("Offset") :: CFrame?
			if o then
				hx = math.min(hx, o.Position.X * sc - p.Size.X * 0.5)
				hy = math.max(hy, o.Position.Y * sc)
			end
		end
	end
	local hinge = CFrame.new(hx, hy, 0)
	ArtKit.poseModel(model, "Lid", hinge * CFrame.Angles(0, 0, cur * 0.9) * hinge:Inverse())
end

-- Mariposa (mariposa de geada, alma Ba, fada): asas largas que batem e um
-- halo que cresce com ent.scale.
function T.moth(m: Model, r: number, wingColor: Color3, spot: Color3, eye: Color3)
	ArtKit.glow(m, r * 2.6, CFrame.new(), eye, 0.88)
	ArtKit.ball(m, Vector3.new(r * 1.1, r * 0.45, r * 0.45), CFrame.new(), Color3.new(0.25, 0.22, 0.28))
	for _, s in { -1, 1 } do
		local w = ArtKit.ball(m, Vector3.new(r * 1.1, r * 0.08, r * 1.4), CFrame.new(-r * 0.05, r * 0.1, s * r * 0.8), wingColor,
			{ Transparency = 0.15 })
		ArtKit.anim(w, if s < 0 then "WingL" else "WingR")
		ArtKit.anim(ArtKit.glow(m, r * 0.35, CFrame.new(0, r * 0.16, s * r * 0.85), spot), if s < 0 then "WingL" else "WingR")
	end
	ArtKit.eyes(m, r * 0.5, r * 0.1, r * 0.12, r * 0.14, eye)
end

function T.mothAnim(model: Model, ent, t: number)
	local flap = 0.35 + 0.35 * math.sin(t * 14 + (ent.id or 0))
	ArtKit.poseModel(model, "WingL", CFrame.Angles(flap, 0, 0))
	ArtKit.poseModel(model, "WingR", CFrame.Angles(-flap, 0, 0))
	ArtKit.scale(model, ent.scale or 1)
end

-- Névoa devoradora: volume translúcido de nuvens com olhos acesos. Some
-- conforme a vida cai.
function T.fogbank(m: Model, r: number, tint: Color3, eye: Color3)
	for i = 0, 8 do
		local a = i / 9 * 2 * math.pi
		local d = r * (0.8 + 0.25 * math.sin(i * 1.7))
		ArtKit.anim(ArtKit.ball(m, Vector3.new(d, d * 0.45, d), CFrame.new(math.cos(a) * r * 0.5, 0, math.sin(a) * r * 0.5), tint,
			{ Transparency = 0.45 }), "Puff")
	end
	ArtKit.ball(m, Vector3.new(r * 1.4, r * 0.5, r * 1.4), CFrame.new(0, r * 0.1, 0), tint, { Transparency = 0.35 })
	for _, p in { Vector3.new(0.3, 0, -0.25), Vector3.new(0.3, 0, 0.25), Vector3.new(-0.3, 0, 0.4) } do
		ArtKit.glow(m, r * 0.1, CFrame.new(p.X * r, r * 0.35, p.Z * r), eye)
	end
end

function T.fogbankAnim(model: Model, ent, t: number)
	local fade = 0.45 + (1 - (ent.hp or 1)) * 0.45
	ArtKit.pose(model, "Puff", function(p)
		local k = (p:GetAttribute("Offset") :: CFrame).Position.X
		return CFrame.new(0, math.sin(t * 0.8 + k) * 0.2, 0)
	end)
	for _, p in model:GetChildren() do
		if p.Name == "Puff" and p:IsA("BasePart") then
			p.Transparency = fade
		end
	end
end

-- Fogo-fátuo / hitodama: núcleo aceso com cauda de chama.
function T.wisp(m: Model, r: number, color: Color3, core: Color3)
	ArtKit.glow(m, r * 1.6, CFrame.new(), color, 0.35)
	ArtKit.glow(m, r * 0.8, CFrame.new(r * 0.1, 0, 0), core)
	for i = 1, 4 do
		ArtKit.anim(ArtKit.glow(m, r * (1.2 - i * 0.22), CFrame.new(-r * (0.4 + i * 0.5), 0, 0), color, 0.3 + i * 0.12), "Tail")
	end
end

function T.wispAnim(model: Model, ent, t: number)
	ArtKit.pose(model, "Tail", function(p)
		local x = (p:GetAttribute("Offset") :: CFrame).Position.X
		return CFrame.new(0, 0, math.sin(t * 10 + (ent.id or 0) + x * 2) * 0.25)
	end)
end

-- Lobo/chacal/cão: corpo comprido, cabeça com focinho, orelhas, rabo, patas.
function T.wolf(m: Model, r: number, fur: Color3, back: Color3, eye: Color3)
	ArtKit.ball(m, Vector3.new(r * 1.9, r * 0.8, r * 0.9), CFrame.new(-r * 0.1, 0, 0), fur)
	ArtKit.ball(m, Vector3.new(r * 1.3, r * 0.35, r * 0.6), CFrame.new(-r * 0.2, r * 0.35, 0), back)
	ArtKit.ball(m, Vector3.new(r * 0.8, r * 0.65, r * 0.7), CFrame.new(r * 0.95, r * 0.2, 0), fur)
	ArtKit.ball(m, Vector3.new(r * 0.55, r * 0.3, r * 0.35), CFrame.new(r * 1.35, r * 0.1, 0), back)
	for _, s in { -1, 1 } do
		ArtKit.wedge(m, Vector3.new(r * 0.1, r * 0.4, r * 0.25), CFrame.new(r * 0.8, r * 0.6, s * r * 0.22), back)
		for _, x in { r * 0.6, -r * 0.7 } do
			ArtKit.anim(ArtKit.block(m, Vector3.new(r * 0.2, r * 0.6, r * 0.2), CFrame.new(x, -r * 0.45, s * r * 0.35), back),
				if (x > 0) == (s > 0) then "LegA" else "LegB")
		end
	end
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.25, r * 0.25), CFrame.new(-r * 1.3, r * 0.25, 0) * CFrame.Angles(0, 0, 0.3), back), "Tail")
	ArtKit.eyes(m, r * 1.2, r * 0.35, r * 0.18, r * 0.14, eye)
end

function T.wolfAnim(model: Model, ent, t: number)
	local gait = math.sin(t * 11 + (ent.id or 0)) * 0.5
	ArtKit.pose(model, "LegA", CFrame.Angles(0, 0, gait))
	ArtKit.pose(model, "LegB", CFrame.Angles(0, 0, -gait))
	ArtKit.pose(model, "Tail", CFrame.Angles(0, math.sin(t * 6) * 0.4, 0))
end

-- Pedra que rola (gelo, arenito, mármore, ogham): bloco facetado girando.
function T.boulder(m: Model, r: number, rock: Color3, light: Color3, crack: Color3, material: Enum.Material?)
	local mat = material or Enum.Material.Slate
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 2, r * 1.7, r * 1.9), CFrame.new(), rock, { Material = mat }), "Spin")
	ArtKit.anim(ArtKit.block(m, Vector3.new(r * 1.2, r * 1.2, r * 1.2), CFrame.Angles(0.6, 0.4, 0.2), light, { Material = mat }), "Spin")
	ArtKit.anim(ArtKit.block(m, Vector3.new(r * 1.4, r * 0.12, r * 0.12), CFrame.new(0, r * 0.75, 0) * CFrame.Angles(0, 0.5, 0), crack), "Spin")
end

function T.boulderAnim(model: Model, ent, t: number)
	-- Rola em volta do centro do modelo (o friso e as runas acompanham a pedra).
	ArtKit.poseModel(model, "Spin", CFrame.Angles(0, 0, -t * 3 - (ent.id or 0)))
end

-- Fantasma (espectro, sombra, banshee, funayūrei): capuz, corpo que se
-- desfaz numa cauda e olhos acesos.
function T.ghost(m: Model, r: number, body: Color3, trail: Color3, eye: Color3, transparency: number?)
	local tr = transparency or 0.2
	ArtKit.ball(m, r * 1.6, CFrame.new(r * 0.2, r * 0.1, 0), body, { Transparency = tr })
	for i = 1, 3 do
		ArtKit.anim(ArtKit.ball(m, r * (1.3 - i * 0.28), CFrame.new(-r * (0.3 + i * 0.5), 0, 0), trail, { Transparency = tr + i * 0.12 }),
			"Trail")
	end
	ArtKit.eyes(m, r * 0.85, r * 0.3, r * 0.25, r * 0.22, eye)
end

function T.ghostAnim(model: Model, ent, t: number)
	ArtKit.pose(model, "Trail", function(p)
		local x = (p:GetAttribute("Offset") :: CFrame).Position.X
		return CFrame.new(0, 0, math.sin(t * 5 + (ent.id or 0) + x * 1.5) * 0.3)
	end)
end

-- Serpente (naja, serpente da górgona, péist, tentáculo): gomos que ondulam.
function T.serpent(m: Model, r: number, body: Color3, belly: Color3, eye: Color3, segments: number?)
	local n = segments or 5
	for i = 0, n - 1 do
		local d = r * (1.2 - i * 0.12)
		ArtKit.anim(ArtKit.ball(m, Vector3.new(d, d * 0.7, d), CFrame.new(r * 0.4 - i * r * 0.55, 0, 0), if i % 2 == 0 then body else belly),
			"Seg")
	end
	ArtKit.eyes(m, r * 0.85, r * 0.25, r * 0.2, r * 0.15, eye)
end

function T.serpentAnim(model: Model, ent, t: number)
	ArtKit.pose(model, "Seg", function(p)
		local x = (p:GetAttribute("Offset") :: CFrame).Position.X
		return CFrame.new(0, 0, math.sin(t * 7 + (ent.id or 0) + x * 1.8) * 0.35 * math.clamp(-x, 0, 3))
	end)
end

-- Bípede de cima (múmia, corpo-seco, draugr, curupira, minotauro, oni...):
-- ombros, cabeça, braços que balançam e pés.
function T.biped(m: Model, r: number, skin: Color3, cloth: Color3, eye: Color3, opts: { [string]: any }?)
	local o = opts or {}
	local w = o.width or 1
	ArtKit.ball(m, Vector3.new(r * 1.1, r * 1.1, r * 1.7 * w), CFrame.new(-r * 0.1, 0, 0), cloth)
	ArtKit.ball(m, r * 0.85 * (o.head or 1), CFrame.new(r * 0.25, r * 0.55, 0), skin)
	for _, s in { -1, 1 } do
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.35, r * 0.35), CFrame.new(r * 0.25, 0, s * r * 0.95 * w), skin),
			if s < 0 then "ArmL" else "ArmR")
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.55, r * 0.3, r * 0.35), CFrame.new(-r * 0.2, -r * 0.5, s * r * 0.4), cloth),
			if s < 0 then "FootL" else "FootR")
	end
	if o.horns then
		for _, s in { -1, 1 } do
			ArtKit.wedge(m, Vector3.new(r * 0.12, r * 0.6, r * 0.25), CFrame.new(r * 0.3, r * 1.05, s * r * 0.35) * CFrame.Angles(s * 0.4, 0, 0),
				o.horns)
		end
	end
	if o.eyes ~= false then
		ArtKit.eyes(m, r * 0.62, r * 0.68, r * 0.18, r * 0.16, eye)
	end
end

function T.bipedAnim(model: Model, ent, t: number)
	local swing = math.sin(t * 8 + (ent.id or 0)) * 0.35
	ArtKit.pose(model, "ArmL", CFrame.new(swing, 0, 0))
	ArtKit.pose(model, "ArmR", CFrame.new(-swing, 0, 0))
	ArtKit.pose(model, "FootL", CFrame.new(-swing * 0.6, 0, 0))
	ArtKit.pose(model, "FootR", CFrame.new(swing * 0.6, 0, 0))
end

-- Liga um molde a ids de arte: devolve `build` e `animate` prontos.
function ArtKit.use(build: { [string]: any }, animate: { [string]: any }, id: string, maker: (Model, number) -> (), anim: any?)
	build[id] = maker
	if anim then
		animate[id] = anim
	end
end

return ArtKit
