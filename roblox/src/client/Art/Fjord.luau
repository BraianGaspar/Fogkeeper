-- Criaturas do Fiorde Congelado (creature_art.gd). Também traz "boulder"
-- (pedra de gelo que o Jötunn arremessa).

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Draugr: morto-vivo de armadura, elmo com chifres curtos e espada.
ArtKit.use(build, animate, "draugr", function(m, r)
	T.biped(m, r, rgb(0.45, 0.55, 0.58), rgb(0.16, 0.2, 0.26), rgb(0.4, 0.85, 1.0), { horns = rgb(0.85, 0.82, 0.7) })
	ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.35, r * 0.9), CFrame.new(r * 0.25, r * 0.95, 0), rgb(0.5, 0.52, 0.55), { Material = Enum.Material.Metal })
	ArtKit.block(m, Vector3.new(r * 1.4, r * 0.1, r * 0.15), CFrame.new(r * 0.8, 0, r * 1), rgb(0.6, 0.65, 0.7), { Material = Enum.Material.Metal })
end, T.bipedAnim)

-- Lobo de gelo.
ArtKit.use(build, animate, "ice_wolf", function(m, r)
	T.wolf(m, r, rgb(0.78, 0.86, 0.95), rgb(0.45, 0.55, 0.68), rgb(0.5, 0.95, 1.0))
end, T.wolfAnim)

-- Troll de gelo: corpo enorme, cabelo de geada e porrete.
ArtKit.use(build, animate, "troll", function(m, r)
	T.biped(m, r, rgb(0.38, 0.48, 0.52), rgb(0.22, 0.28, 0.32), rgb(1.0, 0.75, 0.3), { width = 1.2, head = 0.8 })
	ArtKit.ball(m, Vector3.new(r * 0.8, r * 0.3, r * 0.9), CFrame.new(r * 0.15, r * 0.95, 0), rgb(0.75, 0.88, 0.95), { Transparency = 0.2 })
	ArtKit.anim(ArtKit.cyl(m, r * 1.4, r * 0.3, CFrame.new(r * 0.8, r * 0.1, r * 1.15), rgb(0.35, 0.24, 0.15), { Material = Enum.Material.Wood }),
		"ArmR")
end, T.bipedAnim)

-- Corvo de Odin (ladrão).
ArtKit.use(build, animate, "raven", function(m, r)
	T.bird(m, r, rgb(0.1, 0.1, 0.14), rgb(0.17, 0.17, 0.24), rgb(0.3, 0.3, 0.33), rgb(1.0, 0.85, 0.3))
end, T.birdAnim)

-- Escudo de gelo (espelho).
ArtKit.use(build, animate, "ice_shell", function(m, r)
	T.shell(m, r, rgb(0.62, 0.82, 0.95), rgb(0.35, 0.45, 0.6), rgb(0.88, 0.97, 1.0))
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p.Name == "Lid" then
			p.Material = Enum.Material.Ice
		end
	end
end, T.shellAnim)

-- Mariposa de geada.
ArtKit.use(build, animate, "frost_moth", function(m, r)
	T.moth(m, r, rgb(0.82, 0.9, 1.0), rgb(0.35, 0.55, 0.85), rgb(0.4, 0.95, 1.0))
end, T.mothAnim)

-- Névoa de Niflheim.
ArtKit.use(build, animate, "fog_fjord", function(m, r)
	T.fogbank(m, r, rgb(0.2, 0.26, 0.34), rgb(0.5, 0.95, 1.0))
end, T.fogbankAnim)

-- Pedra de gelo.
ArtKit.use(build, animate, "boulder", function(m, r)
	T.boulder(m, r, rgb(0.62, 0.8, 0.92), rgb(0.9, 0.97, 1.0), rgb(0.35, 0.5, 0.62), Enum.Material.Ice)
end, T.boulderAnim)

return { build = build, animate = animate }
