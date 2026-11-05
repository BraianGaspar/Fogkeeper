-- Fenrir: o grande lobo. Corre em círculos longe da ilha e foge da luz: se
-- ficar iluminado por um instante, salta para o lado. De tempos em tempos
-- para, marca uma linha vermelha até o farol e investe; mire na linha para
-- recebê-lo.
-- visual: 0 circulando, 1 marcando a investida (linha vermelha), 2 investindo, 3 recuando.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local CIRCLE, TELEGRAPH, DASH, RETREAT = 0, 1, 2, 3

function Boss.begin(sim, e, angle: number)
	e.angle = angle
	B.place(e, angle, 430)
	e.phase = CIRCLE
	e.dir = 1
	e.litTime = 0
	e.dodgeCd = 0
	e.chargeCd = e.boss.chargeEvery
	e.telegraphT = 0
	e.visual = CIRCLE
end

function Boss.lightFactor(sim, e, beam): number
	e._litAt = sim.t
	return 1
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local reach = B.reach(e)
	if e.phase == CIRCLE then
		e.angle += e.speed * e.dir * r * dt
		B.place(e, e.angle, B.moveToward(B.dist(e), d.circle, 160 * dt))
		e.dodgeCd -= dt
		e.litTime = if B.lit(sim, e) then e.litTime + dt else 0
		if e.litTime >= d.dodgeAfter and e.dodgeCd <= 0 then
			e.angle += 0.9 * e.dir
			e.dir = -e.dir
			e.dodgeCd = d.dodgeCooldown
			e.litTime = 0
			sim:fx("sfx", { id = "hover", x = e.x, y = e.y })
		end
		e.chargeCd -= dt * r
		if e.chargeCd <= 0 then
			e.phase = TELEGRAPH
			e.telegraphT = d.telegraph / r
			sim:fx("sfx", { id = "growl", x = e.x, y = e.y })
		end
		e.facing = e.angle + math.pi / 2 * e.dir
	elseif e.phase == TELEGRAPH then
		e.telegraphT -= dt
		if e.telegraphT <= 0 then
			e.phase = DASH
		end
		e.facing = math.atan2(-e.y, -e.x)
	elseif e.phase == DASH then
		local nd = B.moveToward(B.dist(e), reach, d.dashSpeed * dt)
		B.approach(e, nd, math.huge)
		if nd <= reach + 0.5 then
			sim:damageLighthouse(e.damage)
			e.phase = RETREAT
		end
		e.facing = math.atan2(-e.y, -e.x)
	else
		local nd = B.moveToward(B.dist(e), d.circle, d.dashSpeed * 0.5 * dt)
		B.approach(e, nd, math.huge)
		if nd >= d.circle - 0.5 then
			e.angle = math.atan2(e.y, e.x)
			e.phase = CIRCLE
			e.chargeCd = d.chargeEvery
		end
		e.facing = math.atan2(e.y, e.x)
	end
	e.visual = e.phase
end

return Boss
