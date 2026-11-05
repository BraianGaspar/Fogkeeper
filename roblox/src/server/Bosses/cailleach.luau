-- Cailleach, a velha do inverno, que fez as montanhas deixando cair pedras do
-- avental. Caminha sobre as ondas em volta da ilha e faz rolar pedras de
-- ogham contra o farol. De tempos em tempos bate o cajado e chama uma
-- tempestade de inverno: o vento sopra para longe as brasas soltas, e as
-- pedras caem bem mais depressa. Recolha as brasas antes da tempestade.
-- visual: 1 tempestade.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.angle = angle
	B.place(e, angle, d.stand + 160)
	e.stormCd = d.stormEvery * 0.6
	e.stormT = 0
	e.stoneCd = 2
	e.visual = 0
end

-- O vento de inverno empurra as brasas soltas para longe da ilha.
local function blow(sim, e, dt: number)
	local push = e.boss.push
	for _, m in sim.embers do
		local dist = math.sqrt(m.x * m.x + m.y * m.y)
		if not m.pulled and dist > 1 then
			m.x += m.x / dist * push * dt
			m.y += m.y / dist * push * dt
		end
	end
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local dist = B.moveToward(B.dist(e), d.stand, 90 * dt)
	e.angle += e.speed * r * e.litFactor() * dt
	B.place(e, e.angle, dist)
	if e.stormT > 0 then
		e.stormT -= dt
		blow(sim, e, dt)
	else
		e.stormCd -= dt * r
		if e.stormCd <= 0 then
			e.stormCd = d.stormEvery
			e.stormT = d.stormTime
			sim:fx("sfx", { id = "thunder", x = e.x, y = e.y })
		end
	end
	e.stoneCd -= dt * r
	if e.stoneCd <= 0 then
		e.stoneCd = if e.stormT > 0 then d.stoneEvery else d.hailEvery
		sim:spawnMinion("boulder", e.x - e.x / dist * e.radius, e.y - e.y / dist * e.radius)
	end
	e.visual = if e.stormT > 0 then 1 else 0
	e.facing = e.angle + math.pi / 2
end

return Boss
