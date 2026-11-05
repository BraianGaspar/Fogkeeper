-- Fiorde Congelado (scripts/world/fjord_background.gd): placa de gelo
-- rachada ("Sea" é o gelo, sem água do Terrain), buracos de água escura, pináculos de gelo, um
-- drakkar preso, pedras rúnicas e a ilha nevada com pegadas.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.12, 0.16, 0.26), "ice")
	Kit.island(m, Color3.fromRGB(200, 210, 225), Color3.fromRGB(235, 242, 250), Enum.Material.Snow)

	local rng = Random.new(31)
	local water = Color3.fromRGB(10, 20, 35)
	local crack = Color3.fromRGB(60, 80, 110)
	-- Buracos de água escura no gelo.
	for _, h in { Vector3.new(-300, -160, 40), Vector3.new(260, 200, 34), Vector3.new(420, -120, 28), Vector3.new(-160, 260, 22),
		Vector3.new(-520, 60, 30), Vector3.new(560, 260, 26) } do
		Kit.disc(m, Kit.at(h.X, h.Y), h.Z * Kit.S, 0.1, 0.04, water, { Material = Enum.Material.Glass, Transparency = 0.1 })
	end
	-- Rachaduras: traços finos partindo da ilha.
	for i = 1, 16 do
		local a = i / 16 * 2 * math.pi + rng:NextNumber(-0.2, 0.2)
		local from = rng:NextNumber(110, 200)
		local len = rng:NextNumber(80, 260)
		local mid = from + len / 2
		Kit.block(m, CFrame.new(Kit.at(math.cos(a) * mid, math.sin(a) * mid, 0.03)) * CFrame.Angles(0, -a, 0),
			Vector3.new(len * Kit.S, 0.05, 0.12), crack, { Material = Enum.Material.Slate })
	end
	-- Pináculos de gelo.
	for _, p in { Vector3.new(-420, -220, 30), Vector3.new(380, -260, 26), Vector3.new(500, 120, 34), Vector3.new(-560, 210, 28),
		Vector3.new(180, 300, 20), Vector3.new(-250, -300, 24) } do
		Kit.cone(m, Kit.at(p.X, p.Y, 0), p.Z * Kit.S * 2.2, p.Z * Kit.S * 2, Color3.fromRGB(190, 225, 245), 5,
			{ Material = Enum.Material.Ice, Transparency = 0.1 })
	end
	-- Drakkar preso no gelo (SHIP_POS): casco, cabeça de dragão, vela listrada.
	local ship = CFrame.new(Kit.at(-440, 200, 0.2)) * CFrame.Angles(0, -0.5, 0.08)
	Kit.block(m, ship, Vector3.new(7.5, 0.8, 1.8), Color3.fromRGB(95, 65, 40), { Material = Enum.Material.WoodPlanks })
	Kit.block(m, ship * CFrame.new(4, 0.9, 0) * CFrame.Angles(0, 0, -0.5), Vector3.new(0.4, 2, 0.4), Color3.fromRGB(95, 65, 40), { Material = Enum.Material.Wood })
	Kit.ball(m, (ship * CFrame.new(4.5, 1.8, 0)).Position, Vector3.new(0.9, 0.6, 0.6), Color3.fromRGB(120, 85, 50), { Material = Enum.Material.Wood })
	for i = 0, 4 do
		Kit.block(m, ship * CFrame.new(-1.2 + i * 0.55, 2.4, 0), Vector3.new(0.55, 2.4, 0.06),
			if i % 2 == 0 then Color3.fromRGB(180, 40, 35) else Color3.fromRGB(230, 220, 200), { Material = Enum.Material.Fabric })
	end
	-- Pedras rúnicas na ilha.
	for _, r in { Vector2.new(-96, -58), Vector2.new(92, 48), Vector2.new(-20, 108) } do
		local stone = Kit.block(m, CFrame.new(Kit.at(r.X, r.Y, 1.9)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0.05),
			Vector3.new(0.7, 2.4, 1.2), Color3.fromRGB(110, 115, 120), { Material = Enum.Material.Slate, CastShadow = true })
		Kit.block(m, stone.CFrame * CFrame.new(0.36, 0.2, 0), Vector3.new(0.02, 1.4, 0.7), Color3.fromRGB(110, 220, 255),
			{ Material = Enum.Material.Neon, Transparency = 0.3 })
	end
	-- Pinheiros nevados e pegadas que vêm do sul.
	for _, t in { Vector3.new(-60, -30, 12), Vector3.new(-40, 60, 11), Vector3.new(55, -60, 10) } do
		Kit.pine(m, t.X, t.Y, t.Z, Color3.fromRGB(40, 70, 60))
		Kit.ball(m, Kit.at(t.X, t.Y, 0.7 + t.Z * Kit.S * 2.8), Vector3.new(1, 0.4, 1), Color3.fromRGB(240, 245, 255), { Material = Enum.Material.Snow })
	end
	for i = 0, 10 do
		local y = 110 + i * 22
		Kit.block(m, CFrame.new(Kit.at((if i % 2 == 0 then -6 else 6) + math.sin(i) * 8, y, 0.03)), Vector3.new(0.35, 0.04, 0.55),
			Color3.fromRGB(120, 140, 170))
	end
end
