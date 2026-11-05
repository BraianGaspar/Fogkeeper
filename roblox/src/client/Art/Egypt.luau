-- Criaturas do Farol de Alexandria (creature_art.gd).

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Múmia: faixas de linho e olhos verdes.
ArtKit.use(build, animate, "mummy", function(m, r)
	T.biped(m, r, rgb(0.82, 0.76, 0.6), rgb(0.82, 0.76, 0.6), rgb(0.4, 1.0, 0.5))
	for i = 0, 3 do
		ArtKit.block(m, Vector3.new(r * 1.15, r * 0.08, r * 1.75), CFrame.new(-r * 0.1, -r * 0.3 + i * r * 0.22, 0) * CFrame.Angles(0.15 * (i - 1.5), 0, 0),
			rgb(0.6, 0.54, 0.42))
	end
	-- Braços esticados para a frente, como nas lendas.
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "ArmL" or p.Name == "ArmR") then
			p.CFrame = p.CFrame * CFrame.new(r * 0.35, r * 0.2, 0)
			p:SetAttribute("Offset", p.CFrame)
		end
	end
end, T.bipedAnim)

-- Chacal de Anúbis: negro com detalhes dourados.
ArtKit.use(build, animate, "jackal", function(m, r)
	T.wolf(m, r, rgb(0.1, 0.09, 0.09), rgb(0.75, 0.6, 0.2), rgb(1.0, 0.8, 0.2))
end, T.wolfAnim)

-- Crocodilo de Sobek: corpo baixo e comprido, focinho longo, colar dourado.
ArtKit.use(build, animate, "sobek", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 2.2, r * 0.55, r * 1.0), CFrame.new(-r * 0.2, 0, 0), rgb(0.3, 0.42, 0.22))
	ArtKit.block(m, Vector3.new(r * 1.1, r * 0.35, r * 0.45), CFrame.new(r * 1.3, 0, 0), rgb(0.3, 0.42, 0.22))
	for i = 0, 4 do
		ArtKit.block(m, Vector3.new(r * 0.2, r * 0.15, r * 0.25), CFrame.new(-r * 0.9 + i * r * 0.35, r * 0.3, 0), rgb(0.2, 0.28, 0.14))
	end
	ArtKit.cyl(m, r * 0.15, r * 0.9, CFrame.new(r * 0.75, 0, 0), rgb(1.0, 0.85, 0.2), { Material = Enum.Material.Metal })
	for _, s in { -1, 1 } do
		for _, x in { r * 0.4, -r * 0.7 } do
			ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 0.45, r * 0.2, r * 0.3), CFrame.new(x, -r * 0.15, s * r * 0.6), rgb(0.55, 0.6, 0.35)),
				if (x > 0) == (s > 0) then "LegA" else "LegB")
		end
	end
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.4, r * 0.3, r * 0.45), CFrame.new(-r * 1.6, 0, 0), rgb(0.3, 0.42, 0.22)), "Tail")
	ArtKit.eyes(m, r * 0.85, r * 0.3, r * 0.25, r * 0.13, rgb(1.0, 0.85, 0.2))
end, T.wolfAnim)

-- Íbis de Thoth (ladrão): ave branca de bico longo e curvo.
ArtKit.use(build, animate, "ibis", function(m, r)
	T.bird(m, r, rgb(0.95, 0.94, 0.9), rgb(0.15, 0.15, 0.18), rgb(0.2, 0.2, 0.22), rgb(1.0, 0.7, 0.2), 1.0)
end, T.birdAnim)

-- Escaravelho de ouro (espelho).
ArtKit.use(build, animate, "scarab", function(m, r)
	T.shell(m, r, rgb(0.85, 0.65, 0.15), rgb(0.2, 0.35, 0.6), rgb(0.55, 0.35, 0.08))
	for _, s in { -1, 1 } do
		for i = 0, 2 do
			ArtKit.block(m, Vector3.new(r * 0.1, r * 0.1, r * 0.7), CFrame.new(r * (0.5 - i * 0.5), -r * 0.15, s * r * 0.95) * CFrame.Angles(0, s * 0.3, 0),
				rgb(0.3, 0.2, 0.05))
		end
	end
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p.Name == "Lid" then
			p.Material = Enum.Material.Metal
		end
	end
end, T.shellAnim)

-- Alma Ba (mariposa): ave dourada de asas azuis.
ArtKit.use(build, animate, "ba", function(m, r)
	T.moth(m, r, rgb(0.95, 0.78, 0.35), rgb(0.2, 0.4, 0.75), rgb(1.0, 0.85, 0.4))
	ArtKit.ball(m, r * 0.55, CFrame.new(r * 0.55, r * 0.2, 0), rgb(0.85, 0.65, 0.45))
end, T.mothAnim)

-- Tempestade de areia.
ArtKit.use(build, animate, "fog_egypt", function(m, r)
	T.fogbank(m, r, rgb(0.45, 0.36, 0.22), rgb(1.0, 0.75, 0.3))
end, T.fogbankAnim)

-- Naja de Apep: serpente roxa de capelo aberto.
ArtKit.use(build, animate, "cobra", function(m, r)
	T.serpent(m, r, rgb(0.35, 0.25, 0.4), rgb(0.45, 0.3, 0.5), rgb(1.0, 0.3, 0.2), 5)
	ArtKit.ball(m, Vector3.new(r * 0.5, r * 0.2, r * 1.4), CFrame.new(r * 0.25, r * 0.3, 0), rgb(0.9, 0.75, 0.3))
end, T.serpentAnim)

-- Pedra de arenito.
ArtKit.use(build, animate, "sandstone", function(m, r)
	T.boulder(m, r, rgb(0.75, 0.6, 0.38), rgb(0.95, 0.85, 0.6), rgb(0.45, 0.33, 0.2), Enum.Material.Sandstone)
end, T.boulderAnim)

return { build = build, animate = animate }
