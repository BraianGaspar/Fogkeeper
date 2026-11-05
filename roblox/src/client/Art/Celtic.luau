-- Criaturas da Costa Celta (creature_art.gd): folclore irlandês e escocês.

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Banshee: mulher pálida de cabelos longos, olhos verdes.
ArtKit.use(build, animate, "banshee", function(m, r)
	T.ghost(m, r, rgb(0.78, 0.85, 0.82), rgb(0.92, 0.95, 0.95), rgb(0.5, 1.0, 0.85), 0.2)
	for i = 0, 2 do
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.4, r * 0.15, r * 0.35), CFrame.new(-r * 0.5, r * 0.45, (i - 1) * r * 0.35),
			rgb(0.85, 0.9, 0.88), { Transparency = 0.25 }), "Trail")
	end
end, T.ghostAnim)

-- Kelpie: cavalo d'água escuro de crina de algas.
ArtKit.use(build, animate, "kelpie", function(m, r)
	T.wolf(m, r, rgb(0.16, 0.22, 0.24), rgb(0.08, 0.12, 0.14), rgb(0.6, 1.0, 0.9))
	for i = 0, 3 do
		ArtKit.block(m, Vector3.new(r * 0.25, r * 0.12, r * 0.12), CFrame.new(r * (0.6 - i * 0.3), r * 0.55, 0) * CFrame.Angles(0, 0, 0.4),
			rgb(0.2, 0.45, 0.3))
	end
end, T.wolfAnim)

-- Fomoriano: gigante do mar, verde-musgo, com um braço maior.
ArtKit.use(build, animate, "fomorian", function(m, r)
	T.biped(m, r, rgb(0.32, 0.42, 0.36), rgb(0.18, 0.25, 0.22), rgb(0.25, 0.5, 0.3), { width = 1.25, head = 0.8 })
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.2, r * 0.5, r * 0.5), CFrame.new(r * 0.35, 0, r * 1.2), rgb(0.35, 0.3, 0.28)), "ArmR")
	ArtKit.glow(m, r * 0.3, CFrame.new(r * 0.62, r * 0.7, 0), rgb(0.6, 1.0, 0.5))
end, T.bipedAnim)

-- Púca (ladrão): lebre negra de olhos dourados.
ArtKit.use(build, animate, "pooka", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 1.4, r * 0.8, r * 0.9), CFrame.new(), rgb(0.1, 0.09, 0.12))
	ArtKit.ball(m, r * 0.7, CFrame.new(r * 0.7, r * 0.2, 0), rgb(0.1, 0.09, 0.12))
	for _, s in { -1, 1 } do
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.12, r * 0.25), CFrame.new(r * 0.35, r * 0.6, s * r * 0.2) * CFrame.Angles(0, s * 0.3, 0.3),
			rgb(0.3, 0.28, 0.35)), "Ear")
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.7, r * 0.3, r * 0.3), CFrame.new(-r * 0.4, -r * 0.35, s * r * 0.35), rgb(0.1, 0.09, 0.12)),
			if s < 0 then "FootL" else "FootR")
	end
	ArtKit.ball(m, r * 0.35, CFrame.new(-r * 0.75, r * 0.1, 0), rgb(0.3, 0.28, 0.35))
	ArtKit.eyes(m, r * 0.95, r * 0.35, r * 0.2, r * 0.15, rgb(1.0, 0.8, 0.2))
	ArtKit.carry(m, r)
end, function(model, ent, t)
	local hop = math.abs(math.sin(t * 9 + (ent.id or 0)))
	ArtKit.pose(model, "Ear", CFrame.Angles(0, 0, hop * 0.3))
	ArtKit.pose(model, "FootL", CFrame.new(-hop * 0.2, 0, 0))
	ArtKit.pose(model, "FootR", CFrame.new(-hop * 0.2, 0, 0))
	ArtKit.showCarry(model, ent.aux or 0)
end)

-- Selkie (espelho): foca cinzenta que, aberta, mostra o rosto de gente.
ArtKit.use(build, animate, "selkie", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 1.8, r * 0.6, r * 1.0), CFrame.new(0, -r * 0.1, 0), rgb(0.28, 0.3, 0.35))
	ArtKit.ball(m, r * 0.6, CFrame.new(r * 0.55, r * 0.15, 0), rgb(0.85, 0.75, 0.65))
	ArtKit.ball(m, Vector3.new(r * 0.6, r * 0.25, r * 0.7), CFrame.new(r * 0.45, r * 0.4, 0), rgb(0.2, 0.12, 0.08))
	ArtKit.eyes(m, r * 0.8, r * 0.2, r * 0.13, r * 0.1, rgb(0.4, 0.8, 1.0))
	-- A pele de foca é a "concha": cobre o corpo quando reflete.
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.9, r * 0.7, r * 1.1), CFrame.new(0, r * 0.15, 0), rgb(0.42, 0.45, 0.5), { Reflectance = 0.3 }), "Lid")
end, T.shellAnim)

-- Fada luminosa (mariposa).
ArtKit.use(build, animate, "fairy", function(m, r)
	T.moth(m, r, rgb(0.75, 1.0, 0.8), rgb(0.95, 0.8, 0.3), rgb(0.6, 1.0, 0.7))
end, T.mothAnim)

-- Névoa do Outro Mundo.
ArtKit.use(build, animate, "fog_celtic", function(m, r)
	T.fogbank(m, r, rgb(0.12, 0.2, 0.18), rgb(0.55, 1.0, 0.85))
end, T.fogbankAnim)

-- Péist: serpente dos lagos, verde-escura.
ArtKit.use(build, animate, "peist", function(m, r)
	T.serpent(m, r, rgb(0.2, 0.32, 0.3), rgb(0.35, 0.55, 0.45), rgb(0.9, 1.0, 0.5), 6)
end, T.serpentAnim)

-- Pedra de ogham: pedra cinza com riscos da escrita antiga, acesos.
ArtKit.use(build, animate, "ogham", function(m, r)
	T.boulder(m, r, rgb(0.5, 0.52, 0.5), rgb(0.62, 0.65, 0.6), rgb(0.3, 0.32, 0.3), Enum.Material.Slate)
	for i = 0, 3 do
		ArtKit.anim(ArtKit.block(m, Vector3.new(r * 0.08, r * 0.08, r * 0.5), CFrame.new(-r * 0.45 + i * r * 0.3, r * 0.8, 0), rgb(0.55, 1.0, 0.85),
			{ Material = Enum.Material.Neon }), "Spin")
	end
end, T.boulderAnim)

return { build = build, animate = animate }
