-- Apep, a serpente do caos que toda noite tenta engolir o sol. Circula a
-- ilha em espiral e a boca engole a luz: enquanto um feixe principal passa
-- pela cabeça, o alcance despenca. Queime o corpo, longe da boca (a entidade
-- fica no meio do corpo; a cabeça vai à frente no mesmo círculo). Najas
-- nascem das escamas e rastejam até o farol; a cabeça morde ao chegar.
-- visual: 1 engolindo a luz. aux: quanto a cabeça está à frente do corpo,
-- em ângulo (radianos × 60) no sentido do movimento.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local function headReach(e): number
	return e.radius * 0.8 + B.LIGHTHOUSE_RADIUS
end

local function place(e)
	local offset = math.clamp(e.boss.bodyOffset / math.max(e.orbit, 1), 0, 4)
	B.place(e, e.angle - offset, e.orbit) -- o corpo vem atrás da cabeça
	e.headX, e.headY = math.cos(e.angle) * e.orbit, math.sin(e.angle) * e.orbit
	e.aux = offset * 60
	e.facing = e.angle - offset + math.pi / 2
end

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.angle = angle
	e.orbit = d.startRadius
	e.spawnCd = 2
	e.biteCd = 0
	e.eating = 0
	e.visual = 0
	place(e)
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local slow = e.litFactor()
	e.angle += e.speed * r * slow * dt
	e.orbit = B.moveToward(e.orbit, headReach(e), d.approach * r * slow * dt)
	place(e)
	-- A boca engole a luz que passa por ela.
	e.eating = math.max(0, e.eating - dt)
	if B.mainBeamOn(sim, e.headX, e.headY, e.radius * 0.8) then
		sim:ink(0.4, d.eatRange)
		e.eating = 0.3
	end
	e.visual = if e.eating > 0 then 1 else 0
	if e.orbit <= headReach(e) + 1 then
		e.biteCd -= dt
		if e.biteCd <= 0 then
			e.biteCd = B.ATTACK_INTERVAL
			sim:damageLighthouse(e.damage)
		end
	end
	e.spawnCd -= dt * r
	if e.spawnCd <= 0 then
		e.spawnCd = d.spawnEvery
		sim:spawnMinion("tentacle", e.x, e.y)
	end
end

return Boss
