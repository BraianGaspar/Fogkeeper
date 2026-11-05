-- Criaturas da Baía da Névoa (creature_art.gd). `r` = raio em studs; o
-- modelo olha para +X. Também traz "tentacle", que o Kraken usa.

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Espectro da névoa: fantasma lilás com cauda.
ArtKit.use(build, animate, "wraith", function(m, r)
	T.ghost(m, r, rgb(0.5, 0.45, 0.72), rgb(0.8, 0.75, 1.0), rgb(0.75, 0.95, 1.0), 0.15)
end, T.ghostAnim)

-- Sereia: cabeça, cabelo esverdeado e cauda de peixe.
ArtKit.use(build, animate, "siren", function(m, r)
	ArtKit.ball(m, r * 1.1, CFrame.new(r * 0.35, r * 0.2, 0), rgb(0.55, 0.72, 0.68))
	ArtKit.ball(m, Vector3.new(r * 1.3, r * 0.5, r * 1.2), CFrame.new(r * 0.05, r * 0.45, 0), rgb(0.08, 0.2, 0.24))
	ArtKit.ball(m, Vector3.new(r * 1.3, r * 0.6, r * 0.7), CFrame.new(-r * 0.45, 0, 0), rgb(0.12, 0.45, 0.5))
	ArtKit.anim(ArtKit.wedge(m, Vector3.new(r * 0.12, r * 0.4, r * 1.1), CFrame.new(-r * 1.25, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
		rgb(0.25, 0.7, 0.72)), "Fin")
	ArtKit.eyes(m, r * 0.85, r * 0.35, r * 0.2, r * 0.16, rgb(0.6, 1.0, 0.9))
end, function(model, ent, t)
	ArtKit.pose(model, "Fin", CFrame.Angles(0, math.sin(t * 9 + (ent.id or 0)) * 0.5, 0))
end)

-- Caranguejo de Karkinos: casco largo, pinças e olhos em hastes.
ArtKit.use(build, animate, "crab", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 1.5, r * 0.7, r * 1.9), CFrame.new(), rgb(0.55, 0.2, 0.14))
	ArtKit.ball(m, Vector3.new(r * 1.1, r * 0.4, r * 1.4), CFrame.new(-r * 0.05, r * 0.25, 0), rgb(0.7, 0.3, 0.2))
	for _, s in { -1, 1 } do
		ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.7, r * 0.45, r * 0.5), CFrame.new(r * 0.95, 0, s * r * 0.75), rgb(0.7, 0.3, 0.2)),
			if s < 0 then "ClawL" else "ClawR")
		for i = 0, 2 do
			ArtKit.block(m, Vector3.new(r * 0.12, r * 0.12, r * 0.8), CFrame.new(-r * 0.4 + i * r * 0.35, -r * 0.15, s * r * 1.05)
				* CFrame.Angles(0, s * 0.3, 0), rgb(0.32, 0.1, 0.08))
		end
	end
	ArtKit.eyes(m, r * 0.7, r * 0.55, r * 0.22, r * 0.18, rgb(1.0, 0.9, 0.5))
end, function(model, ent, t)
	local snap = math.max(0, math.sin(t * 6 + (ent.id or 0))) * 0.4
	ArtKit.pose(model, "ClawL", CFrame.Angles(0, snap, 0))
	ArtKit.pose(model, "ClawR", CFrame.Angles(0, -snap, 0))
end)

-- Gaivota-fantasma (ladra).
ArtKit.use(build, animate, "ghost_gull", function(m, r)
	T.bird(m, r, rgb(0.82, 0.88, 0.96), rgb(0.6, 0.66, 0.78), rgb(0.95, 0.8, 0.35), rgb(0.5, 1.0, 1.0))
end, T.birdAnim)

-- Ostra abissal (espelho).
ArtKit.use(build, animate, "oyster", function(m, r)
	T.shell(m, r, rgb(0.48, 0.44, 0.5), rgb(0.9, 0.75, 0.8), rgb(0.3, 0.27, 0.32))
end, T.shellAnim)

-- Água-viva luminosa (mariposa): sino translúcido e filamentos.
ArtKit.use(build, animate, "jellyfish", function(m, r)
	ArtKit.glow(m, r * 2.4, CFrame.new(), rgb(0.85, 0.65, 1.0), 0.85)
	ArtKit.ball(m, Vector3.new(r * 1.6, r * 0.9, r * 1.6), CFrame.new(0, r * 0.2, 0), rgb(0.85, 0.65, 1.0),
		{ Transparency = 0.35, Material = Enum.Material.Neon })
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi
		ArtKit.anim(ArtKit.block(m, Vector3.new(r * 1.1, r * 0.08, r * 0.08), CFrame.new(-r * 0.55 + math.cos(a) * r * 0.3, -r * 0.1,
			math.sin(a) * r * 0.5), rgb(0.7, 0.5, 0.95), { Transparency = 0.25 }), "Strand")
	end
end, function(model, ent, t)
	ArtKit.pose(model, "Strand", function(p)
		local z = (p:GetAttribute("Offset") :: CFrame).Position.Z
		return CFrame.Angles(0, math.sin(t * 4 + z * 3 + (ent.id or 0)) * 0.4, 0)
	end)
	ArtKit.scale(model, ent.scale or 1)
end)

-- Névoa devoradora.
ArtKit.use(build, animate, "fog_bay", function(m, r)
	T.fogbank(m, r, rgb(0.16, 0.12, 0.24), rgb(0.85, 0.4, 1.0))
end, T.fogbankAnim)

-- Tentáculo do Kraken: gomos vinho com ventosas claras.
ArtKit.use(build, animate, "tentacle", function(m, r)
	T.serpent(m, r, rgb(0.5, 0.14, 0.25), rgb(0.85, 0.55, 0.6), rgb(1.0, 0.85, 0.6), 5)
end, T.serpentAnim)

return { build = build, animate = animate }
