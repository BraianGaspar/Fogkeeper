-- Leviatã: serpente marinha segmentada. Circula a ilha em espiral, cada vez
-- mais perto, e mergulha de tempos em tempos (invulnerável) para ressurgir
-- mais adiante. Só a cabeça recebe dano (a entidade é a cabeça; o corpo é
-- desenhado pelo rastro). Morde quando chega ao farol.
-- visual: 0 nadando, 1 mergulhado.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.angle = angle
	e.orbit = d.startRadius
	e.diveCd = d.diveEvery
	e.diveT = 0
	e.visual = 0
	B.place(e, angle, e.orbit)
	e.facing = angle + math.pi / 2
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local reach = B.reach(e)
	local px, py = e.x, e.y
	if e.diveT > 0 then
		e.diveT -= dt
		e.angle += d.diveSpin * dt * r
		if e.diveT <= 0 then
			e.hidden = false
			e.visual = 0
			sim:fx("splash", { x = e.x, y = e.y })
		end
	else
		e.diveCd -= dt * r
		if e.diveCd <= 0 and e.orbit > reach + 30 then
			e.diveCd = d.diveEvery
			e.diveT = d.diveTime
			e.hidden = true
			e.visual = 1
			sim:fx("splash", { x = e.x, y = e.y })
		end
		local slow = e.litFactor()
		e.angle += e.speed * r * slow * dt
		e.orbit = B.moveToward(e.orbit, reach, d.approach * r * slow * dt)
	end
	B.place(e, e.angle, e.orbit)
	if (e.x - px) ^ 2 + (e.y - py) ^ 2 > 1e-4 then
		e.facing = math.atan2(e.y - py, e.x - px)
	end
	B.melee(sim, e, dt)
end

return Boss
