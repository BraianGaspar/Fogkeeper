-- Iara, a mãe d'água. Nada em volta da ilha e, de tempos em tempos, canta:
-- o canto puxa os feixes na direção dela, uma bolha d'água a protege e botos
-- encantados nadam até o farol vindos de outros lados. Resista ao puxão,
-- queime os botos e ataque a Iara quando o canto acabar.
-- visual: 0 nadando, 1 cantando (bolha).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	e.angle = angle
	B.place(e, angle, e.boss.stand + 160)
	e.singCd = e.boss.singEvery * 0.5
	e.singT = 0
	e.spawnCd = 0
	e.visual = 0
end

-- Dentro da bolha do canto a luz não a fere.
function Boss.lightFactor(sim, e, beam): number
	return if e.singT > 0 then 0 else 1
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local dist = B.moveToward(B.dist(e), d.stand, 90 * dt)
	if e.singT > 0 then
		e.singT -= dt
		e.spawnCd -= dt * r
		if e.spawnCd <= 0 then
			e.spawnCd = d.spawnEvery
			-- Botos chegam do lado oposto ao canto, longe de onde a luz é puxada.
			local a = e.angle + math.pi + (sim.rng:NextNumber() * 2 - 1) * 1.2
			local boto = sim:spawnMinion("tentacle", math.cos(a) * 520, math.sin(a) * 520)
			boto.charmed = true -- flag 16 do Snapshot (enfeitiçada pela Iara)
		end
		sim:charm(0.2, math.atan2(e.y, e.x), d.pull * r, e.x, e.y)
		e.facing = math.atan2(-e.y, -e.x)
	else
		e.angle += e.speed * r * e.litFactor() * dt
		e.singCd -= dt * r
		if e.singCd <= 0 and dist <= d.stand + 1 then
			e.singCd = d.singEvery
			e.singT = d.singTime
			e.spawnCd = 0.3
			sim:fx("sfx", { id = "song", x = e.x, y = e.y })
		end
		e.facing = e.angle + math.pi / 2
	end
	B.place(e, e.angle, dist)
	e.visual = if e.singT > 0 then 1 else 0
end

return Boss
