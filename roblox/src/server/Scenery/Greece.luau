-- Mar Egeu (scripts/world/greece_background.gd): o estreito entre dois
-- rochedos brancos, o redemoinho de Caríbdis, colunas de templos afundadas e
-- a ilha com as ruínas de um templo, oliveiras e uma trirreme ancorada.

return function(m: Model, Kit)
	Kit.sea(m, Color3.new(0.04, 0.09, 0.2))
	Kit.island(m, Color3.fromRGB(225, 215, 190), Color3.fromRGB(150, 155, 95), Enum.Material.Ground)

	local marble = Color3.fromRGB(230, 226, 215)
	-- Rochedos brancos do estreito (CLIFFS).
	for _, c in { Vector3.new(560, -250, 120), Vector3.new(-560, 260, 130) } do
		local d = c.Z * Kit.S * 2
		Kit.ball(m, Kit.at(c.X, c.Y, 0), Vector3.new(d, d * 0.5, d * 0.8), Color3.fromRGB(215, 210, 200), { Material = Enum.Material.Limestone })
		Kit.ball(m, Kit.at(c.X * 0.92, c.Y * 0.9, 1), Vector3.new(d * 0.5, d * 0.45, d * 0.5), Color3.fromRGB(235, 230, 222),
			{ Material = Enum.Material.Limestone })
	end
	-- Redemoinho de Caríbdis (WHIRL): anéis escuros concêntricos.
	for i = 0, 4 do
		Kit.disc(m, Kit.at(-520, -230), 9 - i * 1.7, 0.05, 0.08 + i * 0.01,
			if i % 2 == 0 then Color3.fromRGB(10, 25, 50) else Color3.fromRGB(60, 100, 150), { Material = Enum.Material.Neon, Transparency = 0.2 })
	end
	-- Colunas afundadas (algumas tombadas).
	for i, c in { Vector2.new(-180, 150), Vector2.new(-150, 178), Vector2.new(190, -140), Vector2.new(225, -120), Vector2.new(160, 190) } do
		if i % 3 == 0 then
			Kit.part(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.5, 1.4, 1.4),
				CFrame = CFrame.new(Kit.at(c.X, c.Y, 0.2)) * CFrame.Angles(0, i, 0), Color = marble, Material = Enum.Material.Marble })
		else
			Kit.cylinder(m, Kit.at(c.X, c.Y, -0.5), 2.2, 1.4, marble, { Material = Enum.Material.Marble })
			Kit.block(m, CFrame.new(Kit.at(c.X, c.Y, 1.8)), Vector3.new(1.8, 0.35, 1.8), marble, { Material = Enum.Material.Marble })
		end
	end
	-- Templo em ruínas na ilha (TEMPLE): quatro colunas e o frontão.
	for _, p in { Vector2.new(-34, -40), Vector2.new(-12, -48), Vector2.new(10, -48), Vector2.new(32, -40) } do
		Kit.cylinder(m, Kit.at(p.X, p.Y - 20, 0.7), 2.6, 0.7, marble, { Material = Enum.Material.Marble })
	end
	Kit.block(m, CFrame.new(Kit.at(-1, -64, 3.5)), Vector3.new(7.6, 0.4, 1.4), marble, { Material = Enum.Material.Marble })
	Kit.wedge(m, CFrame.new(Kit.at(-1, -64, 4.05)) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(1.4, 0.7, 7.6), marble,
		{ Material = Enum.Material.Marble })
	-- Oliveiras.
	for _, t in { Vector3.new(-62, 30, 11), Vector3.new(60, 30, 10), Vector3.new(30, 70, 9) } do
		Kit.tree(m, t.X, t.Y, t.Z, Color3.fromRGB(110, 130, 85))
	end
	-- Trirreme ancorada: casco longo, olho na proa e vela quadrada.
	Kit.boat(m, 420, 180, -0.4, 8, Color3.fromRGB(95, 55, 35), Color3.fromRGB(225, 210, 175))
	Kit.ball(m, Kit.at(420 + math.cos(-0.4) * 36, 180 + math.sin(-0.4) * 36, 0.5), 0.5, Color3.fromRGB(30, 60, 140))
end
