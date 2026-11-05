-- Farol de Alexandria (scripts/world/desert_background.gd): mar de um lado e
-- o litoral do deserto do outro, com dunas e pirâmides, colunas afundadas,
-- um obelisco tombado, palmeiras e uma feluca ancorada.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.06, 0.1, 0.17))
	Kit.island(m, Color3.fromRGB(200, 170, 118), Color3.fromRGB(173, 143, 97), Enum.Material.Sand)

	local sand = Color3.fromRGB(184, 148, 97)
	-- Litoral de areia à direita (SHORE_X = 360) com dunas.
	Kit.block(m, CFrame.new(Kit.at(360 + 400, 0, 0.3)), Vector3.new(80, 0.6, 140), sand, { Material = Enum.Material.Sand })
	local rng = Random.new(97)
	for _ = 1, 9 do
		local r = rng:NextNumber(60, 120)
		Kit.ball(m, Kit.at(rng:NextNumber(420, 1000), rng:NextNumber(-500, 500), 0.4), Vector3.new(r * Kit.S * 2, 1.2, r * Kit.S),
			Color3.fromRGB(209, 173, 115), { Material = Enum.Material.Sand })
	end
	-- Pirâmides (pirâmide de 4 cunhas por lado).
	for _, p in { Vector3.new(540, -235, 62), Vector3.new(615, -160, 48), Vector3.new(490, -135, 34) } do
		local c = Kit.at(p.X, p.Y, 0.6)
		local s = p.Z * Kit.S * 2
		for i = 0, 3 do
			Kit.wedge(m, CFrame.new(c) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, s * 0.3, -s / 4),
				Vector3.new(s, s * 0.6, s / 2), if i % 2 == 0 then Color3.fromRGB(199, 161, 102) else Color3.fromRGB(140, 107, 66),
				{ Material = Enum.Material.Sandstone })
		end
	end
	-- Colunas de templo afundadas na água rasa.
	for _, c in { Vector2.new(-170, 140), Vector2.new(-205, 120), Vector2.new(-150, 175), Vector2.new(180, -150), Vector2.new(150, -175) } do
		Kit.cylinder(m, Kit.at(c.X, c.Y, -0.5), 1.8, 1.8, Color3.fromRGB(199, 178, 140), { Material = Enum.Material.Sandstone })
	end
	-- Feluca ancorada, de vela triangular.
	Kit.boat(m, -430, -170, 0.5, 6, Color3.fromRGB(115, 77, 46), Color3.fromRGB(235, 225, 200), "triangle")
	-- Ruínas do farol antigo e obelisco tombado na ilha.
	for _, b in { Vector3.new(-40, 70, 0.3), Vector3.new(-20, 78, -0.2), Vector3.new(55, -55, 0.6), Vector3.new(70, -36, 0.1) } do
		Kit.block(m, CFrame.new(Kit.at(b.X, b.Y, 1)) * CFrame.Angles(0, b.Z, 0), Vector3.new(1.8, 0.9, 1.2), Color3.fromRGB(217, 199, 158),
			{ Material = Enum.Material.Sandstone })
	end
	local obelisk = CFrame.new(Kit.at(30, 70, 1)) * CFrame.Angles(0, 0.4, 0)
	Kit.block(m, obelisk, Vector3.new(6, 0.8, 1), Color3.fromRGB(158, 128, 92), { Material = Enum.Material.Sandstone, CastShadow = true })
	Kit.wedge(m, obelisk * CFrame.new(3.4, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(1, 0.8, 0.8), Color3.fromRGB(158, 128, 92), { Material = Enum.Material.Sandstone })
	-- Palmeiras na ilha e na margem.
	for i, p in { Vector2.new(-60, -44), Vector2.new(68, 24), Vector2.new(-48, 58), Vector2.new(400, 150), Vector2.new(430, -250) } do
		Kit.palm(m, p.X, p.Y, i * 1.1, if p.X > 300 then 0.6 else 0.7)
	end
end
