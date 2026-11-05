-- Baía da Névoa (scripts/world/background.gd): mar aberto, rochedos, um
-- naufrágio, boias acesas, a casa do faroleiro e árvores na ilha.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.05, 0.085, 0.14))
	Kit.island(m, Color3.fromRGB(176, 160, 120), Color3.fromRGB(70, 110, 60))

	-- Casa do faroleiro (HOUSE_POS, girada).
	local house = CFrame.new(Kit.at(50, -50, 1.5)) * CFrame.Angles(0, -0.4, 0)
	Kit.block(m, house, Vector3.new(2.4, 1.6, 2), Color3.fromRGB(150, 120, 90), { Material = Enum.Material.WoodPlanks, CastShadow = true })
	Kit.block(m, house * CFrame.new(0, 1, 0), Vector3.new(2.7, 0.5, 2.3), Color3.fromRGB(110, 40, 35), { Material = Enum.Material.Slate, CastShadow = true })
	local window = Kit.block(m, house * CFrame.new(1.21, 0.1, 0), Vector3.new(0.05, 0.5, 0.5), Color3.fromRGB(255, 210, 130),
		{ Material = Enum.Material.Neon })
	Kit.light(window, Color3.fromRGB(255, 200, 120), 6, 1)

	for _, t in { Vector3.new(-62, -42, 11), Vector3.new(-74, 16, 12), Vector3.new(-28, -76, 10), Vector3.new(70, 22, 12), Vector3.new(-50, 55, 13) } do
		Kit.tree(m, t.X, t.Y, t.Z, Color3.fromRGB(45, 85, 50))
	end
	local rng = Random.new(7)
	for _ = 1, 12 do
		local a = rng:NextNumber() * 2 * math.pi
		local d = rng:NextNumber(70, 92)
		Kit.rock(m, math.cos(a) * d, math.sin(a) * d, rng:NextNumber(3, 7))
	end

	-- Ilhotas rochosas (as mesmas do Godot).
	for _, s in { Vector3.new(-380, -195, 26), Vector3.new(420, 140, 20), Vector3.new(250, -285, 14), Vector3.new(-250, 270, 18),
		Vector3.new(570, -250, 30), Vector3.new(-575, 30, 22), Vector3.new(150, 300, 12) } do
		Kit.rock(m, s.X, s.Y, s.Z, Color3.fromRGB(70, 76, 88), 0.7)
		Kit.rock(m, s.X + s.Z * 0.5, s.Y - s.Z * 0.3, s.Z * 0.5, Color3.fromRGB(88, 94, 106), 0.6)
	end

	-- Naufrágio (WRECK_POS): casco inclinado e mastro quebrado.
	local wreck = CFrame.new(Kit.at(-440, 205, 0.1)) * CFrame.Angles(0.15, 0.6, 0.25)
	Kit.block(m, wreck, Vector3.new(7, 1, 2.4), Color3.fromRGB(80, 55, 35), { Material = Enum.Material.WoodPlanks })
	Kit.block(m, wreck * CFrame.new(-1, 1.2, 0) * CFrame.Angles(0, 0, 0.9), Vector3.new(0.25, 3.5, 0.25), Color3.fromRGB(60, 42, 28), { Material = Enum.Material.Wood })

	-- Boias com luz.
	for _, b in { { Vector2.new(330, -215), Color3.fromRGB(77, 255, 115) }, { Vector2.new(-330, -95), Color3.fromRGB(255, 77, 64) },
		{ Vector2.new(470, 255), Color3.fromRGB(255, 77, 64) } } do
		local buoy = Kit.ball(m, Kit.at(b[1].X, b[1].Y, 0.3), 1, b[2], { Material = Enum.Material.Neon })
		Kit.light(buoy, b[2], 6, 1)
	end
end
