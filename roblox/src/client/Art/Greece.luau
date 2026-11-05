-- Criaturas do Mar Egeu (creature_art.gd): mitologia grega.

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Sombra do Hades: alma cinza-azulada com a moeda do barqueiro.
ArtKit.use(build, animate, "shade", function(m, r)
	T.ghost(m, r, rgb(0.42, 0.48, 0.55), rgb(0.22, 0.25, 0.3), rgb(0.7, 0.85, 1.0), 0.25)
	ArtKit.cyl(m, r * 0.06, r * 0.35, CFrame.new(r * 0.95, -r * 0.1, r * 0.3) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.95, 0.78, 0.3),
		{ Material = Enum.Material.Metal })
end, T.ghostAnim)

-- Cão do Hades: escuro, de olhos em brasa.
ArtKit.use(build, animate, "hellhound", function(m, r)
	T.wolf(m, r, rgb(0.16, 0.12, 0.12), rgb(0.35, 0.1, 0.06), rgb(1.0, 0.4, 0.15))
	ArtKit.glow(m, r * 0.5, CFrame.new(r * 1.45, r * 0.1, 0), rgb(1.0, 0.45, 0.15), 0.4)
end, T.wolfAnim)

-- Minotauro: corpo de homem, cabeça de touro com chifres e argola.
ArtKit.use(build, animate, "minotaur", function(m, r)
	T.biped(m, r, rgb(0.42, 0.26, 0.16), rgb(0.35, 0.25, 0.15), rgb(1.0, 0.3, 0.15), { width = 1.2, horns = rgb(0.92, 0.88, 0.75) })
	ArtKit.ball(m, Vector3.new(r * 0.55, r * 0.35, r * 0.5), CFrame.new(r * 0.75, r * 0.45, 0), rgb(0.55, 0.38, 0.28))
	ArtKit.cyl(m, r * 0.05, r * 0.3, CFrame.new(r * 1.0, r * 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.85, 0.75, 0.3),
		{ Material = Enum.Material.Metal })
	ArtKit.anim(ArtKit.block(m, Vector3.new(r * 1.4, r * 0.15, r * 0.15), CFrame.new(r * 0.8, r * 0.1, r * 1.15), rgb(0.75, 0.68, 0.5),
		{ Material = Enum.Material.Metal }), "ArmR")
	ArtKit.wedge(m, Vector3.new(r * 0.1, r * 0.5, r * 0.6), CFrame.new(r * 1.45, r * 0.1, r * 1.15) * CFrame.Angles(0, math.rad(-90), 0),
		rgb(0.75, 0.68, 0.5), { Material = Enum.Material.Metal })
end, T.bipedAnim)

-- Harpia (ladra): asas de penas pardas e rosto humano.
ArtKit.use(build, animate, "harpy", function(m, r)
	T.bird(m, r, rgb(0.45, 0.35, 0.3), rgb(0.3, 0.22, 0.18), rgb(0.75, 0.65, 0.3), rgb(1.0, 0.4, 0.2), 0.25)
	ArtKit.ball(m, r * 0.7, CFrame.new(r * 0.75, r * 0.3, 0), rgb(0.85, 0.75, 0.68))
	ArtKit.ball(m, Vector3.new(r * 0.75, r * 0.3, r * 0.8), CFrame.new(r * 0.6, r * 0.6, 0), rgb(0.12, 0.08, 0.08))
end, T.birdAnim)

-- Escudo de bronze (espelho): hoplita atrás de um escudo redondo polido.
ArtKit.use(build, animate, "bronze_shield", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.9, r * 1.2), CFrame.new(-r * 0.3, 0, 0), rgb(0.5, 0.38, 0.25))
	ArtKit.ball(m, r * 0.7, CFrame.new(-r * 0.25, r * 0.55, 0), rgb(0.75, 0.55, 0.25), { Material = Enum.Material.Metal })
	ArtKit.wedge(m, Vector3.new(r * 0.1, r * 0.4, r * 0.8), CFrame.new(-r * 0.35, r * 1.0, 0) * CFrame.Angles(0, math.rad(90), 0), rgb(0.75, 0.15, 0.12))
	local shield = ArtKit.cyl(m, r * 0.15, r * 1.9, CFrame.new(r * 0.45, 0, 0), rgb(0.75, 0.55, 0.25),
		{ Material = Enum.Material.Metal, Reflectance = 0.4 })
	ArtKit.anim(shield, "Shield")
	ArtKit.anim(ArtKit.glow(m, r * 0.5, CFrame.new(r * 0.55, 0, 0), rgb(1.0, 0.9, 0.5), 0.2), "Shine")
end, function(model, ent, _t)
	-- Escudo erguido (fechado) reflete; baixado (aberto) deixa o soldado exposto.
	local up = if ent.reflecting then 1 else 0
	local st = ArtKit.state(model)
	local cur = st.open or 1
	cur += (up - cur) * 0.2
	st.open = cur
	ArtKit.pose(model, "Shield", CFrame.new(0, 0, (1 - cur) * 1.2) * CFrame.Angles(0, (1 - cur) * 0.9, 0))
	ArtKit.visible(model, "Shine", cur > 0.5, 0.2)
end)

-- Lâmpade (mariposa): ninfa do submundo com uma tocha.
ArtKit.use(build, animate, "lampad", function(m, r)
	T.moth(m, r, rgb(0.5, 0.4, 0.68), rgb(1.0, 0.7, 0.3), rgb(1.0, 0.7, 0.3))
	ArtKit.ball(m, r * 0.55, CFrame.new(r * 0.45, r * 0.25, 0), rgb(0.85, 0.82, 0.75))
	ArtKit.block(m, Vector3.new(r * 0.08, r * 0.8, r * 0.08), CFrame.new(r * 0.75, r * 0.4, r * 0.45), rgb(0.45, 0.32, 0.2))
	ArtKit.glow(m, r * 0.4, CFrame.new(r * 0.75, r * 0.85, r * 0.45), rgb(1.0, 0.7, 0.3))
end, T.mothAnim)

-- Névoa do Estige.
ArtKit.use(build, animate, "fog_greece", function(m, r)
	T.fogbank(m, r, rgb(0.12, 0.14, 0.2), rgb(0.6, 1.0, 0.75))
end, T.fogbankAnim)

-- Serpente da górgona.
ArtKit.use(build, animate, "gorgon_snake", function(m, r)
	T.serpent(m, r, rgb(0.3, 0.5, 0.25), rgb(0.75, 0.85, 0.45), rgb(1.0, 0.9, 0.3), 6)
end, T.serpentAnim)

-- Bloco de mármore.
ArtKit.use(build, animate, "marble", function(m, r)
	T.boulder(m, r, rgb(0.88, 0.86, 0.82), rgb(1.0, 1.0, 0.98), rgb(0.55, 0.55, 0.6), Enum.Material.Marble)
end, T.boulderAnim)

return { build = build, animate = animate }
