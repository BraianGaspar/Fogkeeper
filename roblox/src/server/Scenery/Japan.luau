-- Mar dos Yōkai (scripts/world/japan_background.gd): mar escuro, um torii
-- vermelho dentro d'água, rochedos com cordas sagradas, lanternas de papel
-- do Obon à deriva e a ilha com santuário, lanternas de pedra e pinheiros.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.06, 0.07, 0.16))
	Kit.island(m, Color3.fromRGB(180, 165, 135), Color3.fromRGB(60, 95, 60))

	local red = Color3.fromRGB(200, 45, 35)
	local dark = Color3.fromRGB(35, 30, 30)
	-- Torii na água (TORII_POS): dois pilares, duas vigas.
	local torii = CFrame.new(Kit.at(330, -175, 0)) * CFrame.Angles(0, 0.35, 0)
	for _, s in { -1, 1 } do
		Kit.cylinder(m, (torii * CFrame.new(0, 0, s * 2)).Position, 5, 0.45, red, { Material = Enum.Material.Wood })
	end
	Kit.block(m, torii * CFrame.new(0, 5.2, 0), Vector3.new(0.6, 0.5, 6.2), dark, { Material = Enum.Material.Wood })
	Kit.block(m, torii * CFrame.new(0, 4.3, 0), Vector3.new(0.4, 0.35, 5), red, { Material = Enum.Material.Wood })
	-- Rochedos casados com a corda sagrada (shimenawa).
	for _, r in { Vector2.new(-420, 150), Vector2.new(-470, 175), Vector2.new(470, 200) } do
		Kit.rock(m, r.X, r.Y, 26, Color3.fromRGB(70, 70, 80), 0.9)
	end
	Kit.block(m, CFrame.new(Kit.at(-445, 162, 1.8)) * CFrame.Angles(0, -0.46, 0), Vector3.new(5.5, 0.25, 0.25), Color3.fromRGB(220, 200, 150),
		{ Material = Enum.Material.Fabric })
	-- Lanternas do Obon flutuando (poucas com luz, por desempenho).
	local rng = Random.new(11)
	for i = 1, 14 do
		local a = rng:NextNumber() * 2 * math.pi
		local d = rng:NextNumber(160, 560)
		local lantern = Kit.block(m, CFrame.new(Kit.at(math.cos(a) * d, math.sin(a) * d, 0.35)), Vector3.new(0.7, 0.6, 0.7),
			Color3.fromRGB(255, 170, 90), { Material = Enum.Material.Neon, Transparency = 0.1 })
		if i % 4 == 0 then
			Kit.light(lantern, Color3.fromRGB(255, 160, 80), 7, 1)
		end
	end
	-- Santuário na ilha: plataforma, telhado curvo e corda.
	local shrine = CFrame.new(Kit.at(-50, -55, 1.6)) * CFrame.Angles(0, 0.5, 0)
	Kit.block(m, shrine, Vector3.new(2.4, 1.4, 2), Color3.fromRGB(150, 60, 40), { Material = Enum.Material.WoodPlanks, CastShadow = true })
	Kit.wedge(m, shrine * CFrame.new(0, 1, 0.6), Vector3.new(3, 0.8, 1.4), dark, { Material = Enum.Material.Slate, CastShadow = true })
	Kit.wedge(m, shrine * CFrame.new(0, 1, -0.6) * CFrame.Angles(0, math.pi, 0), Vector3.new(3, 0.8, 1.4), dark, { Material = Enum.Material.Slate, CastShadow = true })
	-- Lanternas de pedra e pinheiros.
	for _, p in { Vector2.new(30, -70), Vector2.new(-75, 10), Vector2.new(60, 40) } do
		local pos = Kit.at(p.X, p.Y, 0.7)
		Kit.cylinder(m, pos, 1, 0.4, Color3.fromRGB(150, 150, 145), { Material = Enum.Material.Slate })
		local box = Kit.block(m, CFrame.new(pos + Vector3.new(0, 1.3, 0)), Vector3.new(0.8, 0.6, 0.8), Color3.fromRGB(255, 200, 120),
			{ Material = Enum.Material.Neon })
		Kit.light(box, Color3.fromRGB(255, 190, 110), 5, 1)
		Kit.wedge(m, CFrame.new(pos + Vector3.new(0, 1.8, 0)), Vector3.new(1.1, 0.4, 1.1), Color3.fromRGB(130, 130, 125), { Material = Enum.Material.Slate })
	end
	for _, t in { Vector3.new(-30, 60, 11), Vector3.new(70, -15, 10), Vector3.new(-70, -25, 9) } do
		Kit.pine(m, t.X, t.Y, t.Z, Color3.fromRGB(35, 65, 45))
	end
end
