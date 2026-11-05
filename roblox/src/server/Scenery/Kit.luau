-- Peças básicas dos cenários. As posições dos cenários estão nas unidades do
-- Godot (as mesmas dos arquivos scripts/world/*.gd) e viram studs aqui.
-- Tudo é ancorado e sem colisão: o cenário é só visual. Sem sombra, a não ser
-- quando a peça pede (CastShadow = true: árvores e casas da ilha, na luz do farol).

local Kit = {}

Kit.S = 0.1 -- studs por unidade (Balance.STUDS_PER_UNIT)
Kit.ISLAND_RADIUS = 72
local VERTICAL = CFrame.Angles(0, 0, math.rad(90)) -- cilindros do Roblox deitam no eixo X

-- Ponto do mapa (unidades do Godot) a `h` studs de altura.
function Kit.at(x: number, y: number, h: number?): Vector3
	return Vector3.new(x * Kit.S, h or 0, y * Kit.S)
end

function Kit.part(parent: Instance, props: { [string]: any }): BasePart
	local class = props.ClassName or "Part"
	local p = Instance.new(class) :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "ClassName" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function merge(base: { [string]: any }, extra: { [string]: any }?): { [string]: any }
	for k, v in extra or {} do
		base[k] = v
	end
	return base
end

-- Bloco com CFrame e tamanho em studs.
function Kit.block(parent: Instance, cf: CFrame, size: Vector3, color: Color3, extra: { [string]: any }?): BasePart
	return Kit.part(parent, merge({ CFrame = cf, Size = size, Color = color }, extra))
end

-- Cunha (telhados, velas, proas).
function Kit.wedge(parent: Instance, cf: CFrame, size: Vector3, color: Color3, extra: { [string]: any }?): BasePart
	return Kit.part(parent, merge({ ClassName = "WedgePart", CFrame = cf, Size = size, Color = color }, extra))
end

-- Esfera (ou elipsoide, se `size` não for uniforme) centrada em `pos`.
function Kit.ball(parent: Instance, pos: Vector3, size: Vector3 | number, color: Color3, extra: { [string]: any }?): BasePart
	local s = if typeof(size) == "number" then Vector3.one * size else size :: Vector3
	if s.X == s.Y and s.Y == s.Z then
		return Kit.part(parent, merge({ Shape = Enum.PartType.Ball, Size = s, CFrame = CFrame.new(pos), Color = color }, extra))
	end
	local p = Kit.part(parent, merge({ Size = s, CFrame = CFrame.new(pos), Color = color }, extra))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Cilindro em pé: centro da base em `pos`, altura e diâmetro em studs.
function Kit.cylinder(parent: Instance, pos: Vector3, height: number, diameter: number, color: Color3, extra: { [string]: any }?): BasePart
	return Kit.part(parent, merge({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * VERTICAL, Color = color,
	}, extra))
end

-- Disco no plano do mar com topo em `top` (raio em studs).
function Kit.disc(parent: Instance, center: Vector3, radius: number, height: number, top: number, color: Color3, extra: { [string]: any }?): BasePart
	return Kit.cylinder(parent, Vector3.new(center.X, top - height, center.Z), height, radius * 2, color, extra)
end

-- Cone em pé feito de discos empilhados (telhados, pinheiros, pirâmides redondas).
function Kit.cone(parent: Instance, pos: Vector3, height: number, diameter: number, color: Color3, steps: number?, extra: { [string]: any }?)
	local n = steps or 4
	for i = 0, n - 1 do
		local k = 1 - i / n
		Kit.cylinder(parent, pos + Vector3.new(0, height * i / n, 0), height / n, diameter * k, color, extra)
	end
end

-- Mar: plano grande chamado "Sea". O cliente (DayCycle) recolore pela paleta.
--   kind = "water" (padrão): "Sea" vira o fundo do mar (topo em Kit.SEABED) e o
--     World enche de água de verdade (Terrain) até a altura 0, depois da escala.
--     O modelo ganha o atributo "Water".
--   kind = "ice": placa de gelo na altura 0 (fiorde), sem água.
Kit.SEABED = -1.6 -- topo do fundo do mar antes da escala (-4 studs com WORLD_SCALE 2,5)
function Kit.sea(parent: Instance, color: Color3, kind: string?): BasePart
	if kind == "ice" then
		parent:SetAttribute("Water", false)
		return Kit.part(parent, { Name = "Sea", Size = Vector3.new(400, 1, 400), CFrame = CFrame.new(0, -0.5, 0), Color = color,
			Material = Enum.Material.Ice, Reflectance = 0.05 })
	end
	parent:SetAttribute("Water", true)
	return Kit.part(parent, { Name = "Sea", Size = Vector3.new(400, 1, 400), CFrame = CFrame.new(0, Kit.SEABED - 0.5, 0), Color = color,
		Material = Enum.Material.Sand })
end

-- Ilha do farol: água rasa, praia e topo. Com água de verdade (Kit.sea), a
-- água rasa é um banco de areia logo abaixo da superfície ("ShallowBed"),
-- que clareia a água em volta da ilha; no gelo, é o disco "Shallows"
-- recolorido pela paleta.
function Kit.island(parent: Instance, beach: Color3, top: Color3, topMaterial: Enum.Material?)
	local r = Kit.ISLAND_RADIUS * Kit.S
	if parent:GetAttribute("Water") == true then
		Kit.disc(parent, Vector3.zero, r * 1.45, 0.4, -0.25, beach:Lerp(Color3.new(0, 0, 0), 0.25), { Name = "ShallowBed",
			Material = Enum.Material.Sand })
	else
		Kit.disc(parent, Vector3.zero, r * 1.32, 0.1, 0.02, Color3.fromRGB(60, 100, 130), { Name = "Shallows", Transparency = 0.55,
			Material = Enum.Material.Neon })
	end
	Kit.disc(parent, Vector3.zero, r, 1.2, 0.6, beach, { Material = Enum.Material.Sand, Name = "Beach" })
	Kit.disc(parent, Vector3.zero, r * 0.82, 1.3, 0.7, top, { Material = topMaterial or Enum.Material.Grass, Name = "IslandTop" })
end

-- Pedra arredondada meio afundada (raio em unidades). As da ilha e da beira
-- fazem sombra na luz do farol; as distantes, não (desempenho).
function Kit.rock(parent: Instance, x: number, y: number, r: number, color: Color3?, flat: number?)
	local d = r * Kit.S * 2
	Kit.ball(parent, Kit.at(x, y, -d * 0.1), Vector3.new(d, d * (flat or 0.6), d * 0.9),
		color or Color3.fromRGB(78, 84, 96), { Material = Enum.Material.Slate, CastShadow = x * x + y * y < 110 * 110 })
end

-- Árvore redonda vista de cima (copa) com tronco curto.
function Kit.tree(parent: Instance, x: number, y: number, r: number, color: Color3, h: number?)
	local d = r * Kit.S * 2
	local base = h or 0.7
	Kit.cylinder(parent, Kit.at(x, y, base), 1, d * 0.2, Color3.fromRGB(80, 55, 35), { Material = Enum.Material.Wood, CastShadow = true })
	Kit.ball(parent, Kit.at(x, y, base + 1 + d * 0.3), Vector3.new(d, d * 0.75, d), color, { Material = Enum.Material.Grass, CastShadow = true })
end

-- Pinheiro: cone escuro.
function Kit.pine(parent: Instance, x: number, y: number, r: number, color: Color3, h: number?)
	local d = r * Kit.S * 2
	Kit.cone(parent, Kit.at(x, y, h or 0.7), d * 1.4, d, color, 4, { Material = Enum.Material.Grass, CastShadow = true })
end

-- Palmeira: tronco e folhas em leque.
function Kit.palm(parent: Instance, x: number, y: number, phase: number, h: number?)
	local base = Kit.at(x, y, h or 0.7)
	Kit.cylinder(parent, base, 2.2, 0.35, Color3.fromRGB(115, 82, 46), { Material = Enum.Material.Wood, CastShadow = true })
	local top = base + Vector3.new(0, 2.2, 0)
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi + phase
		local color = if i % 2 == 0 then Color3.fromRGB(64, 107, 46) else Color3.fromRGB(82, 128, 56)
		Kit.block(parent, CFrame.new(top) * CFrame.Angles(0, a, 0) * CFrame.new(0.9, -0.15, 0) * CFrame.Angles(0, 0, -0.35),
			Vector3.new(1.9, 0.12, 0.45), color, { Material = Enum.Material.Grass, CastShadow = true })
	end
end

-- Luz pontual (lanternas, boias, fogueiras).
function Kit.light(part: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1.5
	l.Shadows = false
	l.Parent = part
	return l
end

-- Barco simples: casco, mastro e vela (ângulo em radianos; tamanho em studs).
function Kit.boat(parent: Instance, x: number, y: number, angle: number, length: number, hull: Color3, sail: Color3?, sailShape: string?)
	local cf = CFrame.new(Kit.at(x, y, 0.15)) * CFrame.Angles(0, -angle, 0)
	local w = length * 0.3
	Kit.block(parent, cf, Vector3.new(length * 0.75, 0.5, w), hull, { Material = Enum.Material.WoodPlanks })
	Kit.wedge(parent, cf * CFrame.new(length * 0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(w, 0.5, length * 0.25), hull,
		{ Material = Enum.Material.WoodPlanks })
	Kit.wedge(parent, cf * CFrame.new(-length * 0.5, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(w, 0.5, length * 0.25), hull,
		{ Material = Enum.Material.WoodPlanks })
	if sail then
		Kit.cylinder(parent, (cf * CFrame.new(0, 0.25, 0)).Position, length * 0.55, 0.12, Color3.fromRGB(70, 50, 32), { Material = Enum.Material.Wood })
		if sailShape == "triangle" then
			Kit.wedge(parent, cf * CFrame.new(0, length * 0.32, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.05, length * 0.45, length * 0.4),
				sail, { Material = Enum.Material.Fabric })
		else
			Kit.block(parent, cf * CFrame.new(0, length * 0.35, 0), Vector3.new(0.05, length * 0.35, w * 1.6), sail, { Material = Enum.Material.Fabric })
		end
	end
end

return Kit
