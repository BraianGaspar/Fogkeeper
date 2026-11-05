-- Umibōzu, o monge do mar: uma cabeça enorme e escura que se ergue das ondas.
-- Na névoa ele é quase invisível e a luz de passagem não o fere: só depois
-- de alguns instantes sob o feixe ele se revela e passa a queimar. Lança
-- ondas que precisam ser quebradas pela luz antes de chegar à ilha, e avança
-- a cada uma.
-- visual: o quanto está visível (0..255). aux: progresso da revelação (0..255).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local function revealed(e): boolean
	return e.litTime >= e.boss.reveal
end

function Boss.begin(sim, e, angle: number)
	B.place(e, angle, 470)
	e.stand = e.boss.stand
	e.waveCd = 2.5
	e.litTime = 0
	e.shown = 0
	e.visual = 0
	e.aux = 0
end

-- Antes de se revelar, a luz só conta o tempo; não queima.
function Boss.lightFactor(sim, e, beam): number
	e._litAt = sim.t
	return if revealed(e) then 1 else 0
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	if B.lit(sim, e) then
		e.litTime = math.min(e.litTime + dt, d.reveal + 1.2)
	else
		e.litTime = math.max(0, e.litTime - dt * 1.5)
	end
	local target = if revealed(e) then 1 else math.clamp(e.litTime / d.reveal, 0, 1) * 0.6
	e.shown = B.moveToward(e.shown, target, dt * 4)
	e.visual = e.shown * 255
	e.aux = math.clamp(e.litTime / d.reveal, 0, 1) * 255
	local dist = B.dist(e)
	if dist > e.stand + 0.5 then
		B.approach(e, math.max(e.stand, B.reach(e)), e.speed * e.rate() * e.litFactor() * dt)
	else
		e.waveCd -= dt * e.rate()
		if e.waveCd <= 0 then
			e.waveCd = d.waveEvery
			local fx, fy = -e.x / dist, -e.y / dist
			sim:spawnMinion("boulder", e.x + fx * e.radius, e.y + fy * e.radius)
			sim:fx("splash", { x = e.x, y = e.y })
			e.stand = math.max(B.reach(e), e.stand - d.advance)
		end
	end
	B.melee(sim, e, dt)
end

return Boss
