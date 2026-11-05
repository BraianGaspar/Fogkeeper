-- Cila, o terror do estreito. Fica presa ao seu rochedo e estica seis
-- pescoços compridos contra o farol, um de cada vez: cada cabeça que chega à
-- ilha morde. Segurar um feixe principal numa cabeça que avança faz ela
-- recuar; cada cabeça repelida fere a própria Cila. O corpo, protegido pelo
-- rochedo, sente pouco a luz. Do rochedo caem blocos de mármore.
-- As cabeças são partes ("scylla_head") posicionadas por ela.
-- Cila     visual: número de cabeças avançando.
-- Cabeça   visual: avanço (0..255). aux: 1 avançando, 2 recuando (repelida).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local HEAD_PAD = 14 -- raio usado para saber se a luz pega a cabeça

-- ease(x, 0.6) do Godot: sai rápido e chega devagar.
local function ease(x: number): number
	return 1 - (1 - math.clamp(x, 0, 1)) ^ (1 / 0.6)
end

local function headPosition(sim, e, i: number)
	local h = e.heads[i]
	local n = #e.heads
	local dist = math.max(B.dist(e), 1e-6)
	local nx, ny = e.x / dist, e.y / dist
	local spread = (i - 1 - (n - 1) / 2) * 0.32
	local c, s = math.cos(spread), math.sin(spread)
	local rx, ry = -nx * c + ny * s, -nx * s - ny * c -- (-normal) girado por spread
	local restX = e.x + rx * e.boss.neck
	local restY = e.y + ry * e.boss.neck + math.sin(sim.t * 2 + h.phase) * 6
	local targetX, targetY = nx * (B.LIGHTHOUSE_RADIUS + 12), ny * (B.LIGHTHOUSE_RADIUS + 12)
	local k = ease(h.progress)
	return restX + (targetX - restX) * k, restY + (targetY - restY) * k
end

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	B.place(e, angle, d.stand + 150)
	e.strikeCd = 2
	e.rockCd = 3
	e.heads = {}
	for i = 1, d.heads do
		local part = sim:spawnArt("scylla_head", "basic", e.x, e.y)
		part.parent = e
		part.noScore = true
		part.xp = 0
		part.score = 0
		part.damage = 0
		part.visual = 0
		part.aux = 0
		e.heads[i] = { progress = 0, striking = false, light = 0, recoil = 0, phase = (i - 1) * 1.3, part = part }
	end
	e.visual = 0
end

function Boss.lightFactor(sim, e, beam): number
	return e.boss.bodyDamage
end

local function updateHead(sim, e, i: number, dt: number)
	local d = e.boss
	local h = e.heads[i]
	h.recoil = math.max(0, h.recoil - dt)
	if not h.striking then
		h.progress = B.moveToward(h.progress, 0, dt * 1.5)
		return
	end
	h.progress = math.min(1, h.progress + dt / d.strikeTime)
	local hx, hy = headPosition(sim, e, i)
	if B.mainBeamOn(sim, hx, hy, HEAD_PAD) then
		h.light += dt
		if h.light >= d.headHp then
			-- Repelida: recua e a dor chega ao corpo.
			h.striking = false
			h.recoil = 1.5
			e.hp -= e.maxHp * d.headDamage
			sim:fx("sfx", { id = "burn_big", x = hx, y = hy })
			return
		end
	end
	if h.progress >= 1 then
		h.striking = false
		h.recoil = 1
		sim:damageLighthouse(e.damage)
		sim:fx("sfx", { id = "roar", x = hx, y = hy })
	end
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	if B.dist(e) > d.stand + 0.5 then
		B.approach(e, d.stand, e.speed * dt)
	else
		local r = e.rate()
		e.strikeCd -= dt * r
		if e.strikeCd <= 0 then
			e.strikeCd = d.strikeEvery
			local idle = {}
			for i, h in e.heads do
				if not h.striking and h.recoil <= 0 then
					table.insert(idle, i)
				end
			end
			if #idle > 0 then
				local h = e.heads[idle[sim.rng:NextInteger(1, #idle)]]
				h.striking = true
				h.light = 0
				sim:fx("sfx", { id = "growl", x = e.x, y = e.y })
			end
		end
		for i = 1, #e.heads do
			updateHead(sim, e, i, dt * r)
		end
		e.rockCd -= dt * r
		if e.rockCd <= 0 then
			e.rockCd = d.rockEvery
			local dist = B.dist(e)
			sim:spawnMinion("boulder", e.x - e.x / dist * e.radius, e.y - e.y / dist * e.radius)
		end
	end
	-- Partes: posição e desenho de cada cabeça.
	local striking = 0
	for i, h in e.heads do
		local part = h.part
		part.x, part.y = headPosition(sim, e, i)
		part.hp = part.maxHp
		part.visual = h.progress * 255
		part.aux = if h.recoil > 0 and not h.striking then 2 elseif h.striking then 1 else 0
		part.facing = math.atan2(-part.y, -part.x)
		if h.striking then
			striking += 1
		end
	end
	e.visual = striking
	e.facing = math.atan2(-e.y, -e.x)
end

function Boss.died(sim, e)
	for _, h in e.heads do
		h.part.hp = 0
	end
end

return Boss
