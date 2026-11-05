-- Costa Celta (scripts/world/celtic_background.gd): penhascos verdes à
-- esquerda com ovelhas, um círculo de pedras numa ilhota, florestas de algas,
-- um currach e a ilha com uma cruz alta de pedra e urze.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.05, 0.1, 0.12))
	Kit.island(m, Color3.fromRGB(150, 140, 120), Color3.fromRGB(70, 115, 65))

	local grass = Color3.fromRGB(65, 110, 60)
	local stone = Color3.fromRGB(125, 130, 125)
	-- Penhasco à esquerda (SHORE_X = -370): paredão escuro e topo de grama.
	Kit.block(m, CFrame.new(Kit.at(-370 - 400, 0, 1.2)), Vector3.new(80, 2.4, 140), Color3.fromRGB(75, 72, 70), { Material = Enum.Material.Slate })
	Kit.block(m, CFrame.new(Kit.at(-370 - 410, 0, 2.5)), Vector3.new(80, 0.3, 140), grass, { Material = Enum.Material.Grass })
	local rng = Random.new(41)
	for _ = 1, 7 do
		local p = Kit.at(rng:NextNumber(-660, -420), rng:NextNumber(-320, 320), 2.9)
		Kit.ball(m, p, Vector3.new(0.9, 0.6, 0.6), Color3.fromRGB(235, 232, 225), { Material = Enum.Material.Fabric })
		Kit.ball(m, p + Vector3.new(0.5, 0, 0), 0.35, Color3.fromRGB(40, 38, 40))
	end
	-- Círculo de pedras na ilhota (RING).
	Kit.disc(m, Kit.at(380, -190), 6.5, 0.8, 0.4, grass, { Material = Enum.Material.Grass })
	for i = 0, 8 do
		local a = i / 9 * 2 * math.pi
		Kit.block(m, CFrame.new(Kit.at(380 + math.cos(a) * 46, -190 + math.sin(a) * 46, 1.5)) * CFrame.Angles(0, -a, 0),
			Vector3.new(0.6, 2.4, 1), stone, { Material = Enum.Material.Slate })
	end
	-- Florestas de algas (KELP): fitas escuras logo abaixo da superfície.
	for _, k in { Vector2.new(-200, -170), Vector2.new(240, 140), Vector2.new(-120, 230), Vector2.new(180, -260), Vector2.new(520, 220) } do
		for j = 0, 4 do
			Kit.block(m, CFrame.new(Kit.at(k.X + j * 9 - 18, k.Y + (j % 2) * 8, -0.02)) * CFrame.Angles(0, 0.3 * j, 0),
				Vector3.new(0.3, 0.05, 3.5), Color3.fromRGB(35, 70, 45), { Transparency = 0.2, Material = Enum.Material.Grass })
		end
	end
	-- Currach: barco de couro escuro.
	Kit.boat(m, 300, 230, 0.9, 3.4, Color3.fromRGB(60, 45, 35))
	-- Cruz alta de pedra com anel, urze e ovelhas na ilha.
	local cross = Kit.at(-45, -45, 0.7)
	Kit.block(m, CFrame.new(cross + Vector3.new(0, 1.8, 0)), Vector3.new(0.5, 3.6, 0.5), stone, { Material = Enum.Material.Slate, CastShadow = true })
	Kit.block(m, CFrame.new(cross + Vector3.new(0, 2.8, 0)), Vector3.new(0.5, 0.5, 2), stone, { Material = Enum.Material.Slate })
	Kit.part(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.3, 1.3), CFrame = CFrame.new(cross + Vector3.new(0, 2.8, 0)),
		Color = stone, Material = Enum.Material.Slate })
	for i = 0, 7 do
		local a = i * 0.8 + 1
		Kit.ball(m, Kit.at(math.cos(a) * 50, math.sin(a) * 50, 0.85), Vector3.new(0.9, 0.35, 0.9), Color3.fromRGB(150, 80, 150),
			{ Material = Enum.Material.Grass })
	end
	for _, s in { Vector2.new(40, 50), Vector2.new(60, 20) } do
		Kit.ball(m, Kit.at(s.X, s.Y, 1.1), Vector3.new(0.9, 0.6, 0.6), Color3.fromRGB(235, 232, 225), { Material = Enum.Material.Fabric })
	end
end
