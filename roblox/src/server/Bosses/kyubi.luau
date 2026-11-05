-- Kyūbi, a raposa de nove caudas. Circula a ilha e, de tempos em tempos,
-- some num clarão e reaparece entre ilusões idênticas (papel "decoy") que
-- circulam com ela. A verdadeira é a única que projeta sombra na água; as
-- ilusões se desfazem com pouca luz. Lança fogos-fátuos contra o farol.
-- visual: clarão da troca de lugar (0..255).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.angle = angle
	B.place(e, angle, d.stand + 160)
	e.illusionCd = d.illusionEvery * 0.4
	e.fireCd = 1.5
	e.puff = 0
	e.visual = 0
	e.facing = angle + math.pi / 2
end

-- Divide-se: a raposa vai para uma posição sorteada e as ilusões ocupam as outras.
-- Desfaz as ilusões ainda vivas (sem pontos nem brasas).
local function clearDecoys(e)
	for _, decoy in e.decoys or {} do
		if decoy.hp > 0 then
			decoy.escaped = true
			decoy.hp = 0
		end
	end
	e.decoys = {}
end

local function split(sim, e, dist: number)
	local n = e.boss.decoys
	local real = sim.rng:NextInteger(0, n)
	local base = e.angle
	clearDecoys(e) -- sem isto as ilusões se acumulavam a cada troca
	for j = 0, n do
		local a = base + 2 * math.pi * j / (n + 1)
		if j == real then
			e.angle = a
		else
			table.insert(e.decoys, sim:spawnMinion("decoy", math.cos(a) * dist, math.sin(a) * dist))
		end
	end
	e.puff = 1
	sim:fx("sfx", { id = "spell", x = e.x, y = e.y })
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	e.puff = math.max(0, e.puff - dt * 2)
	local dist = B.moveToward(B.dist(e), d.stand, 90 * dt)
	e.angle += e.speed * r * e.litFactor() * dt
	B.place(e, e.angle, dist)
	e.fireCd -= dt * r
	if e.fireCd <= 0 then
		e.fireCd = d.fireEvery
		sim:spawnMinion("tentacle", e.x - e.x / dist * e.radius, e.y - e.y / dist * e.radius)
	end
	e.illusionCd -= dt * r
	if e.illusionCd <= 0 then
		e.illusionCd = d.illusionEvery
		split(sim, e, dist)
		B.place(e, e.angle, dist)
	end
	e.facing = e.angle + math.pi / 2
	e.visual = e.puff * 255
end

function Boss.died(sim, e)
	clearDecoys(e)
end

return Boss
