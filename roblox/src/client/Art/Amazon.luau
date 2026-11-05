-- Criaturas do Rio Encantado (creature_art.gd): folclore brasileiro.

local ArtKit = require(script.Parent.Parent:WaitForChild("ArtKit"))
local T = ArtKit.T

local build, animate = {}, {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

-- Corpo-seco: magro, pele ressecada, olhos em brasa.
ArtKit.use(build, animate, "corpo_seco", function(m, r)
	T.biped(m, r, rgb(0.62, 0.57, 0.48), rgb(0.45, 0.4, 0.33), rgb(1.0, 0.35, 0.2), { width = 0.8, head = 0.85 })
	ArtKit.block(m, Vector3.new(r * 0.8, r * 0.1, r * 0.1), CFrame.new(-r * 0.1, r * 0.3, 0), rgb(0.25, 0.21, 0.17))
end, T.bipedAnim)

-- Curupira: guardião da mata com cabelo de fogo e pés virados para trás.
ArtKit.use(build, animate, "curupira", function(m, r)
	T.biped(m, r, rgb(0.3, 0.45, 0.25), rgb(0.22, 0.32, 0.18), rgb(1.0, 0.9, 0.3), { width = 0.85 })
	for i = 0, 4 do
		ArtKit.anim(ArtKit.glow(m, r * (0.55 - i * 0.07), CFrame.new(r * 0.05 - i * r * 0.22, r * 0.95, (i % 2 - 0.5) * r * 0.3),
			if i % 2 == 0 then rgb(1.0, 0.45, 0.1) else rgb(1.0, 0.75, 0.2), 0.05), "Hair")
	end
	for _, s in { -1, 1 } do
		ArtKit.wedge(m, Vector3.new(r * 0.3, r * 0.15, r * 0.4), CFrame.new(-r * 0.6, -r * 0.55, s * r * 0.4) * CFrame.Angles(0, math.rad(90), 0),
			rgb(0.22, 0.32, 0.18))
	end
end, function(model, ent, t)
	T.bipedAnim(model, ent, t)
	ArtKit.pose(model, "Hair", function(p)
		local x = (p:GetAttribute("Offset") :: CFrame).Position.X
		return CFrame.new(0, math.sin(t * 12 + x * 4) * 0.1, 0)
	end)
end)

-- Mapinguari: gigante peludo de um olho só e boca na barriga.
ArtKit.use(build, animate, "mapinguari", function(m, r)
	T.biped(m, r, rgb(0.42, 0.22, 0.14), rgb(0.25, 0.12, 0.08), rgb(0.9, 0.85, 0.75), { width = 1.25, head = 0.75, eyes = false })
	-- Olho único (substitui o par): um grande ao centro.
	ArtKit.glow(m, r * 0.4, CFrame.new(r * 0.7, r * 0.75, 0), rgb(1.0, 0.85, 0.3))
	ArtKit.block(m, Vector3.new(r * 0.1, r * 0.25, r * 0.8), CFrame.new(r * 0.5, r * 0.05, 0), rgb(0.6, 0.1, 0.08), { Material = Enum.Material.Neon })
end, T.bipedAnim)

-- Saci (ladrão): uma perna só, gorro vermelho, cachimbo e redemoinho.
ArtKit.use(build, animate, "saci", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 0.9, r * 0.9, r * 1.2), CFrame.new(), rgb(0.36, 0.22, 0.15))
	ArtKit.ball(m, r * 0.75, CFrame.new(r * 0.3, r * 0.55, 0), rgb(0.55, 0.3, 0.2))
	ArtKit.wedge(m, Vector3.new(r * 0.7, r * 0.6, r * 0.6), CFrame.new(r * 0.15, r * 1.05, 0), rgb(0.85, 0.12, 0.1))
	ArtKit.block(m, Vector3.new(r * 0.25, r * 0.6, r * 0.25), CFrame.new(-r * 0.05, -r * 0.6, 0), rgb(0.4, 0.26, 0.15))
	ArtKit.block(m, Vector3.new(r * 0.5, r * 0.08, r * 0.08), CFrame.new(r * 0.75, r * 0.45, r * 0.15), rgb(0.95, 0.9, 0.85))
	ArtKit.glow(m, r * 0.12, CFrame.new(r * 1.0, r * 0.5, r * 0.15), rgb(1.0, 0.5, 0.2))
	ArtKit.eyes(m, r * 0.65, r * 0.65, r * 0.16, r * 0.14, rgb(1.0, 1.0, 0.9))
	for i = 0, 2 do
		ArtKit.anim(ArtKit.block(m, Vector3.new(r * 1.4, r * 0.05, r * 0.1),
			CFrame.Angles(0, i * 2.1, 0) * CFrame.new(0, -r * 0.8 + i * 0.05, r * (1 + i * 0.22)), rgb(0.8, 0.7, 0.55), { Transparency = 0.5 }), "Whirl")
	end
	ArtKit.carry(m, r)
end, function(model, ent, t)
	-- O redemoinho gira em volta do Saci (eixo do modelo), não de cada fita.
	ArtKit.poseModel(model, "Whirl", CFrame.Angles(0, -t * 9, 0))
	ArtKit.showCarry(model, ent.aux or 0)
end)

-- Jabuti encantado (espelho): casco que fecha e reflete.
ArtKit.use(build, animate, "jabuti", function(m, r)
	for _, s in { -1, 1 } do
		for _, x in { r * 0.55, -r * 0.55 } do
			ArtKit.ball(m, r * 0.4, CFrame.new(x, -r * 0.2, s * r * 0.75), rgb(0.45, 0.4, 0.25))
		end
	end
	ArtKit.ball(m, r * 0.55, CFrame.new(r * 1.0, 0, 0), rgb(0.45, 0.4, 0.25))
	ArtKit.eyes(m, r * 1.2, r * 0.15, r * 0.12, r * 0.1, rgb(1.0, 0.9, 0.4))
	ArtKit.ball(m, Vector3.new(r * 1.8, r * 0.5, r * 1.6), CFrame.new(0, -r * 0.05, 0), rgb(0.5, 0.35, 0.15))
	ArtKit.anim(ArtKit.ball(m, Vector3.new(r * 1.8, r * 0.7, r * 1.6), CFrame.new(0, r * 0.25, 0), rgb(0.68, 0.5, 0.2), { Reflectance = 0.25 }), "Lid")
	for i = 0, 2 do
		ArtKit.anim(ArtKit.block(m, Vector3.new(r * 0.4, r * 0.06, r * 0.4), CFrame.new(-r * 0.45 + i * r * 0.45, r * 0.6, 0) * CFrame.Angles(0, 0.78, 0),
			rgb(0.75, 0.58, 0.25)), "Lid")
	end
end, T.shellAnim)

-- Mula sem cabeça (mariposa): corpo de mula com fogo no pescoço.
ArtKit.use(build, animate, "mula", function(m, r)
	T.wolf(m, r, rgb(0.32, 0.2, 0.12), rgb(0.18, 0.11, 0.07), rgb(1.0, 0.6, 0.2))
	for _, p in m:GetChildren() do
		-- Sem cabeça: troca a cabeça e o focinho por chamas.
		if p:IsA("BasePart") and p.Position.X >= r * 0.75 then
			p:Destroy()
		end
	end
	for i = 0, 3 do
		ArtKit.anim(ArtKit.glow(m, r * (0.8 - i * 0.15), CFrame.new(r * (0.8 + i * 0.2), r * (0.2 + i * 0.25), 0),
			if i % 2 == 0 then rgb(1.0, 0.45, 0.1) else rgb(1.0, 0.8, 0.25), 0.1), "Flame")
	end
end, function(model, ent, t)
	T.wolfAnim(model, ent, t)
	ArtKit.pose(model, "Flame", function(p)
		local y = (p:GetAttribute("Offset") :: CFrame).Position.Y
		return CFrame.new(0, math.sin(t * 14 + y * 6) * 0.12, 0)
	end)
	ArtKit.scale(model, ent.scale or 1)
end)

-- Névoa da Matinta.
ArtKit.use(build, animate, "fog_amazon", function(m, r)
	T.fogbank(m, r, rgb(0.1, 0.18, 0.12), rgb(1.0, 0.85, 0.3))
end, T.fogbankAnim)

-- Boto encantado: golfinho rosa com chapéu branco.
ArtKit.use(build, animate, "boto", function(m, r)
	ArtKit.ball(m, Vector3.new(r * 2, r * 0.7, r * 0.9), CFrame.new(), rgb(0.92, 0.6, 0.66))
	ArtKit.ball(m, Vector3.new(r * 0.7, r * 0.3, r * 0.35), CFrame.new(r * 1.1, -r * 0.05, 0), rgb(0.92, 0.6, 0.66))
	ArtKit.anim(ArtKit.wedge(m, Vector3.new(r * 0.12, r * 0.4, r * 0.9), CFrame.new(-r * 1.15, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
		rgb(0.88, 0.55, 0.6)), "Fin")
	ArtKit.cyl(m, r * 0.08, r * 1.3, CFrame.new(r * 0.15, r * 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.96, 0.95, 0.92))
	ArtKit.cyl(m, r * 0.35, r * 0.7, CFrame.new(r * 0.15, r * 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.96, 0.95, 0.92))
	ArtKit.cyl(m, r * 0.08, r * 0.72, CFrame.new(r * 0.15, r * 0.48, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0.25, 0.1, 0.12))
	ArtKit.eyes(m, r * 0.8, r * 0.2, r * 0.25, r * 0.12, rgb(0.3, 0.3, 0.32))
end, function(model, ent, t)
	ArtKit.pose(model, "Fin", CFrame.Angles(0, math.sin(t * 8 + (ent.id or 0)) * 0.5, 0))
end)

-- Fogo-fátuo.
ArtKit.use(build, animate, "wisp", function(m, r)
	T.wisp(m, r, rgb(0.35, 0.95, 0.85), rgb(0.9, 1.0, 0.95))
end, T.wispAnim)

return { build = build, animate = animate }
