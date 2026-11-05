-- Rio Encantado (scripts/world/river_background.gd): rio largo e barrento
-- entre duas margens de mata fechada, vitórias-régias, troncos à deriva e a
-- ilhota com praia, açaizeiros, uma palafita e a canoa do faroleiro.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.07, 0.12, 0.09))
	Kit.island(m, Color3.fromRGB(190, 160, 110), Color3.fromRGB(60, 105, 50))

	local rng = Random.new(53)
	-- Margens de mata (topo e base da tela), copas de vários verdes.
	local greens = { Color3.fromRGB(30, 70, 35), Color3.fromRGB(40, 90, 45), Color3.fromRGB(25, 60, 40), Color3.fromRGB(55, 100, 50) }
	for _, side in { -1, 1 } do
		Kit.block(m, CFrame.new(Kit.at(0, side * 470, 0.4)), Vector3.new(240, 0.8, 22), Color3.fromRGB(60, 45, 30), { Material = Enum.Material.Mud })
		local x = -1100
		while x < 1100 do
			local y = side * rng:NextNumber(330, 380)
			Kit.ball(m, Kit.at(x, y, 1.6), Vector3.new(1, 0.7, 1) * rng:NextNumber(26, 48) * Kit.S * 2, greens[rng:NextInteger(1, #greens)],
				{ Material = Enum.Material.Grass })
			x += rng:NextNumber(40, 64)
		end
	end
	-- Vitórias-régias (PADS): disco verde com borda e uma flor de vez em quando.
	for i, p in { Vector3.new(-330, -150, 30), Vector3.new(260, -210, 24), Vector3.new(-460, 120, 36), Vector3.new(420, 150, 28),
		Vector3.new(180, 250, 20), Vector3.new(-200, 230, 22), Vector3.new(560, -60, 26), Vector3.new(-560, -230, 22), Vector3.new(330, -40, 16) } do
		Kit.disc(m, Kit.at(p.X, p.Y), p.Z * Kit.S, 0.1, 0.08, Color3.fromRGB(60, 120, 50), { Material = Enum.Material.Grass })
		Kit.disc(m, Kit.at(p.X, p.Y), p.Z * Kit.S * 0.92, 0.1, 0.1, Color3.fromRGB(80, 140, 60), { Material = Enum.Material.Grass })
		if i % 3 == 0 then
			Kit.ball(m, Kit.at(p.X + p.Z * 0.3, p.Y, 0.3), 0.7, Color3.fromRGB(240, 170, 200))
		end
	end
	-- Troncos à deriva.
	for _, l in { Vector3.new(-250, -60, 0.4), Vector3.new(300, 90, -0.3), Vector3.new(-120, 180, 1.1), Vector3.new(500, -180, 0.2) } do
		Kit.part(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 0.6, 0.6),
			CFrame = CFrame.new(Kit.at(l.X, l.Y, 0.1)) * CFrame.Angles(0, l.Z, 0), Color = Color3.fromRGB(90, 62, 40),
			Material = Enum.Material.Wood })
	end
	-- Açaizeiros e mata baixa na ilhota.
	for i, p in { Vector2.new(-55, -40), Vector2.new(60, -30), Vector2.new(40, 55), Vector2.new(-20, -70) } do
		Kit.palm(m, p.X, p.Y, i * 0.7)
	end
	-- Palafita (STILT_POS): casa de madeira sobre estacas, janela acesa.
	local stilt = CFrame.new(Kit.at(-58, 46, 2.2)) * CFrame.Angles(0, 0.3, 0)
	for _, o in { Vector3.new(-0.9, 0, -0.8), Vector3.new(0.9, 0, -0.8), Vector3.new(-0.9, 0, 0.8), Vector3.new(0.9, 0, 0.8) } do
		Kit.block(m, stilt * CFrame.new(o + Vector3.new(0, -1, 0)), Vector3.new(0.2, 2, 0.2), Color3.fromRGB(80, 55, 35), { Material = Enum.Material.Wood })
	end
	Kit.block(m, stilt, Vector3.new(2.4, 1.2, 2), Color3.fromRGB(140, 100, 60), { Material = Enum.Material.WoodPlanks, CastShadow = true })
	Kit.wedge(m, stilt * CFrame.new(0, 0.9, 0.5), Vector3.new(2.6, 0.7, 1.1), Color3.fromRGB(170, 140, 70), { Material = Enum.Material.Fabric })
	Kit.wedge(m, stilt * CFrame.new(0, 0.9, -0.5) * CFrame.Angles(0, math.pi, 0), Vector3.new(2.6, 0.7, 1.1), Color3.fromRGB(170, 140, 70),
		{ Material = Enum.Material.Fabric })
	local window = Kit.block(m, stilt * CFrame.new(1.21, 0, 0), Vector3.new(0.05, 0.45, 0.45), Color3.fromRGB(255, 200, 120),
		{ Material = Enum.Material.Neon })
	Kit.light(window, Color3.fromRGB(255, 190, 110), 6, 1)
	-- Canoa na praia.
	Kit.boat(m, 70, 70, 0.8, 3.2, Color3.fromRGB(110, 70, 40))
end
