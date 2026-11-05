-- Medusa, a górgona. Circula a ilha soltando as serpentes dos cabelos e, de
-- tempos em tempos, ergue o rosto: os olhos acendem (aviso) e depois o olhar
-- petrifica. Se um feixe principal tocar nela durante o olhar, o farol vira
-- pedra e quase não gira por alguns segundos, e ela não se fere. Desvie a
-- luz enquanto ela encara; fora disso, ela queima normalmente.
-- visual: 0 normal, 1 aviso (olhos acendendo), 2 olhar.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.angle = angle
	B.place(e, angle, d.stand + 160)
	e.gazeCd = d.gazeEvery * 0.6
	e.warnT = 0
	e.gazeT = 0
	e.snakeCd = 1.5
	e.stoneUntil = 0
	e.visual = 0
end

function Boss.lightFactor(sim, e, beam): number
	if e.gazeT > 0 then
		if beam.main and sim.t >= e.stoneUntil then
			local d = e.boss
			e.stoneUntil = sim.t + d.stoneTime
			sim:petrify(d.stoneTime, d.stoneTurn)
			sim:fx("petrify", { x = e.x, y = e.y })
		end
		return 0
	end
	return 1
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local dist = B.moveToward(B.dist(e), d.stand, 90 * dt)
	if e.gazeT <= 0 then
		e.angle += e.speed * r * e.litFactor() * dt
	end
	B.place(e, e.angle, dist)
	if e.warnT > 0 then
		e.warnT -= dt
		if e.warnT <= 0 then
			e.gazeT = d.gazeTime
			sim:fx("sfx", { id = "spell", x = e.x, y = e.y })
		end
	elseif e.gazeT > 0 then
		e.gazeT -= dt
	else
		e.gazeCd -= dt * r
		if e.gazeCd <= 0 then
			e.gazeCd = d.gazeEvery
			e.warnT = d.gazeWarn
			sim:fx("sfx", { id = "warning", x = e.x, y = e.y })
		end
	end
	e.snakeCd -= dt * r
	if e.snakeCd <= 0 then
		e.snakeCd = d.snakeEvery
		sim:spawnMinion("tentacle", e.x - e.x / dist * e.radius, e.y - e.y / dist * e.radius)
	end
	e.visual = if e.gazeT > 0 then 2 elseif e.warnT > 0 then 1 else 0
	e.facing = if e.visual > 0 then math.atan2(-e.y, -e.x) else e.angle + math.pi / 2
end

return Boss
