-- Cuca: a velha bruxa da mata, de cabeça de jacaré e cabelo grisalho
-- (folclore, não o visual da TV, que tem dono). Para longe da ilha e conjura
-- um feitiço de sono, marcado por um círculo de runas: se levar dano
-- suficiente enquanto conjura, é interrompida; senão, a luz adormece e
-- enfraquece por alguns segundos. Depois some na névoa e reaparece em outro
-- ponto.
-- visual: progresso do feitiço (0..255; 0 = não conjura). aux: 1 sumindo.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local function vanish(sim, e)
	e.vanishT = e.boss.vanishTime
	e.hidden = true
	e.targetAngle = math.atan2(e.y, e.x) + math.pi * (0.5 + sim.rng:NextNumber())
end

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.targetAngle = angle
	B.place(e, angle, d.stand + 150)
	e.castCd = d.castEvery * 0.5
	e.castT = 0
	e.castHp = e.hp
	e.vanishT = 0
	e.visual = 0
	e.aux = 0
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	e.aux = if e.vanishT > 0 then 1 else 0
	if e.vanishT > 0 then
		e.vanishT -= dt
		if e.vanishT <= d.vanishTime / 2 then
			B.place(e, e.targetAngle, d.stand)
		end
		if e.vanishT <= 0 then
			e.hidden = false
		end
		e.visual = 0
		return
	end
	if B.dist(e) > d.stand + 0.5 then
		B.approach(e, d.stand, e.speed * e.litFactor() * dt)
		return
	end
	if e.castT > 0 then
		-- Dano levado durante a conjuração interrompe o feitiço.
		if e.castHp - e.hp >= e.maxHp * d.interrupt then
			e.castT = 0
			e.visual = 0
			sim:fx("sfx", { id = "denied", x = e.x, y = e.y })
			sim:announce("Feitiço da Cuca interrompido!", nil, Color3.fromRGB(120, 230, 140), false)
			vanish(sim, e)
			return
		end
		e.castT -= dt * r
		e.visual = (1 - math.max(0, e.castT) / d.castTime) * 255
		if e.castT <= 0 then
			sim:sleep(d.sleepTime, d.sleepPower)
			sim:fx("sfx", { id = "spell", x = e.x, y = e.y })
			e.visual = 0
			vanish(sim, e)
		end
		return
	end
	e.castCd -= dt * r
	if e.castCd <= 0 then
		e.castCd = d.castEvery
		e.castT = d.castTime
		e.castHp = e.hp
		sim:fx("sfx", { id = "growl", x = e.x, y = e.y })
	end
end

return Boss
