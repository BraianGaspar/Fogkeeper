-- Criaturas do Mar dos Yōkai (creature_art.gd). "kyubi_decoy" é a ilusão
-- (papel decoy), com id próprio para não ser tratada como o chefe Kyūbi.

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Funayūrei: fantasma de afogado em quimono branco, segurando uma concha.
ArtKit.use(build, animate, "funayurei", function(m, r)
	T.ghost(m, r, rgb(0.82, 0.86, 0.92), rgb(0.9, 0.92, 0.95), rgb(0.3, 0.6, 1.0), 0.2)
	ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.35, r * 1.2), CFrame.new(r * 0.15, r * 0.65, 0), rgb(0.06, 0.06, 0.08))
	ArtKit.ball(m, Vector3.new(r * 0.5, r * 0.25, r * 0.5), CFrame.new(r * 0.9, 0, r * 0.6), rgb(0.5, 0.36, 0.22))
end, T.ghostAnim)

-- Kitsune: raposa laranja de peito branco e várias caudas.
ArtKit.use(build, animate, "kitsune", function(m, r)
	T.wolf(m, r, rgb(0.92, 0.55, 0.22), rgb(0.98, 0.92, 0.85), rgb(1.0, 0.85, 0.2))
	for i = -1, 1 do
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.3, r * 0.35), CFrame.new(-r * 1.3, r * 0.3, i * r * 0.35) * CFrame.Angles(0, i * 0.4, 0.3),
			if i == 0 then rgb(0.98, 0.92, 0.85) else rgb(0.92, 0.55, 0.22)), "Tail")
	end
end, T.wolfAnim)

-- Kyūbi (ilusão): raposa branca com nove caudas em leque.
ArtKit.use(build, animate, "kyubi_decoy", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 1.7, r * 0.8, r * 0.9), CFrame.new(), rgb(0.97, 0.96, 0.98))
	ArtKit.ball(m, Vector3.new(r * 0.8, r * 0.65, r * 0.7), CFrame.new(r * 0.95, r * 0.2, 0), rgb(0.97, 0.96, 0.98))
	ArtKit.ball(m, Vector3.new(r * 0.5, r * 0.28, r * 0.32), CFrame.new(r * 1.35, r * 0.1, 0), rgb(0.85, 0.3, 0.35))
	for _, s in { -1, 1 } do
		ArtKit.wedge(m, Vector3.new(r * 0.1, r * 0.4, r * 0.25), CFrame.new(r * 0.8, r * 0.6, s * r * 0.22), rgb(0.85, 0.3, 0.35))
	end
	for i = 0, 8 do
		local a = math.pi + (i - 4) * 0.28
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.9, r * 0.28, r * 0.5),
			CFrame.Angles(0, -a, 0) * CFrame.new(r * 1.4, r * 0.15, 0), rgb(0.96, 0.95, 1.0), { Transparency = 0.1 }), "Tail")
		ArtKit.glow(m, r * 0.25, CFrame.Angles(0, -a, 0) * CFrame.new(r * 2.35, r * 0.2, 0), rgb(1.0, 0.5, 0.2))
	end
	ArtKit.eyes(m, r * 1.2, r * 0.35, r * 0.18, r * 0.13, rgb(1.0, 0.5, 0.2))
end, function(model, ent, t)
	ArtKit.pose(model, "Tail", function(p)
		local z = (p:GetAttribute("Offset") :: CFrame).Position.Z
		return CFrame.Angles(0, math.sin(t * 0.9 * 6 + z) * 0.12, 0)
	end)
end)

-- Oni: ogro vermelho de chifres e porrete de ferro.
ArtKit.use(build, animate, "oni", function(m, r)
	T.biped(m, r, rgb(0.75, 0.2, 0.16), rgb(0.45, 0.1, 0.08), rgb(1.0, 0.95, 0.3), { width = 1.2, horns = rgb(0.95, 0.9, 0.75) })
	ArtKit.ball(m, Vector3.new(r * 0.7, r * 0.3, r * 0.8), CFrame.new(r * 0.1, r * 0.95, 0), rgb(0.1, 0.08, 0.08))
	ArtKit.anim(ArtKit.cyl(m, r * 1.6, r * 0.32, CFrame.new(r * 0.9, r * 0.1, r * 1.15), rgb(0.28, 0.28, 0.3), { Material = Enum.Material.Metal }),
		"ArmR")
	ArtKit.block(m, Vector3.new(r * 1.3, r * 0.2, r * 1.5), CFrame.new(-r * 0.1, -r * 0.2, 0), rgb(0.9, 0.7, 0.2))
end, T.bipedAnim)

-- Karasu-tengu (ladrão): corvo de bico vermelho.
ArtKit.use(build, animate, "tengu", function(m, r)
	T.bird(m, r, rgb(0.12, 0.1, 0.14), rgb(0.08, 0.07, 0.1), rgb(0.85, 0.2, 0.15), rgb(1.0, 0.85, 0.3), 0.7)
end, T.birdAnim)

-- Kappa (espelho): carapaça de tartaruga e o prato d'água na cabeça.
ArtKit.use(build, animate, "kappa", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 1.2, r * 0.9, r * 1.2), CFrame.new(r * 0.1, 0, 0), rgb(0.35, 0.6, 0.35))
	ArtKit.ball(m, r * 0.75, CFrame.new(r * 0.6, r * 0.45, 0), rgb(0.32, 0.52, 0.3))
	ArtKit.cyl(m, r * 0.1, r * 0.55, CFrame.new(r * 0.6, r * 0.85, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.75, 0.88, 0.95),
		{ Material = Enum.Material.Glass, Transparency = 0.2 })
	ArtKit.wedge(m, Vector3.new(r * 0.3, r * 0.15, r * 0.3), CFrame.new(r * 1.05, r * 0.35, 0) * CFrame.Angles(0, math.rad(-90), 0), rgb(0.9, 0.75, 0.2))
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.5, r * 0.6, r * 1.6), CFrame.new(-r * 0.3, r * 0.25, 0), rgb(0.2, 0.38, 0.22), { Reflectance = 0.25 }),
		"Lid")
	ArtKit.eyes(m, r * 0.9, r * 0.55, r * 0.2, r * 0.14, rgb(1.0, 0.95, 0.4))
end, T.shellAnim)

-- Chōchin-obake (mariposa): lanterna de papel com um olho e a língua de fora.
ArtKit.use(build, animate, "chochin", function(m, r)
	ArtKit.glow(m, r * 2.4, CFrame.new(), rgb(1.0, 0.6, 0.3), 0.88)
	ArtKit.cyl(m, r * 1.6, r * 1.4, CFrame.new() * CFrame.Angles(0, 0, math.rad(90)), rgb(1.0, 0.72, 0.4),
		{ Material = Enum.Material.Neon, Transparency = 0.15 })
	for i = -1, 1 do
		ArtKit.cyl(m, r * 0.05, r * 1.45, CFrame.new(0, i * r * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.6, 0.45, 0.3))
	end
	ArtKit.cyl(m, r * 0.2, r * 0.9, CFrame.new(0, r * 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.15, 0.12, 0.1))
	ArtKit.glow(m, r * 0.45, CFrame.new(r * 0.6, r * 0.2, 0), rgb(1.0, 1.0, 0.85))
	ArtKit.ball(m, r * 0.2, CFrame.new(r * 0.75, r * 0.2, 0), rgb(0.15, 0.12, 0.1))
	ArtKit.anim(ArtKit.block(m, Vector3.new(r * 0.6, r * 0.08, r * 0.25), CFrame.new(r * 0.85, -r * 0.35, 0), rgb(0.9, 0.3, 0.35)), "Tongue")
end, function(model, ent, t)
	ArtKit.pose(model, "Tongue", CFrame.Angles(0, math.sin(t * 8 + (ent.id or 0)) * 0.4, 0))
	ArtKit.scale(model, ent.scale or 1)
end)

-- Névoa dos afogados.
ArtKit.use(build, animate, "fog_japan", function(m, r)
	T.fogbank(m, r, rgb(0.15, 0.12, 0.28), rgb(1.0, 0.3, 0.3))
end, T.fogbankAnim)

-- Hitodama: alma de fogo azulado.
ArtKit.use(build, animate, "hitodama", function(m, r)
	T.wisp(m, r, rgb(0.55, 0.7, 1.0), rgb(0.92, 0.96, 1.0))
end, T.wispAnim)

-- Onda erguida pelo monge do mar: cristas de água em arco.
ArtKit.use(build, animate, "wave", function(m, r)
	for k = 0, 2 do
		local d = r * (2.6 - k * 0.6)
		ArtKit.anim(ArtKit.ball(m, Vector3.new(d * 0.35, d * 0.25 + k * 0.1, d), CFrame.new(r * (-0.3 + k * 0.3), k * r * 0.12, 0),
			if k == 2 then rgb(0.92, 0.97, 1.0) else rgb(0.6, 0.8, 0.95), { Transparency = 0.1 + k * 0.1 }), "Crest")
	end
end, function(model, ent, t)
	ArtKit.pose(model, "Crest", function(p)
		local x = (p:GetAttribute("Offset") :: CFrame).Position.X
		return CFrame.new(0, math.sin(t * 6 + x * 3 + (ent.id or 0)) * 0.12, 0)
	end)
end)

return { build = build, animate = animate }
