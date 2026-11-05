-- Balor, rei dos fomorianos, de um olho só que destrói o que encara. De olho
-- fechado, a luz quase não o fere. De tempos em tempos a pálpebra se ergue
-- (aviso) e o olho fica aberto: então a luz o fere muito, e é preciso
-- encará-lo, porque o olhar dele queima o farol e encurta a luz enquanto
-- nenhum feixe principal estiver nele. Péists nascem do mar à sua volta.
-- visual: abertura do olho (0..255). aux: 1 olhar queimando o farol, 2 feixe segurando o olhar.

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local CLASH_TIME = 0.15 -- quanto tempo um toque do feixe segura o olhar

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	B.place(e, angle, d.stand + 160)
	e.openCd = d.openEvery * 0.5
	e.warnT = 0
	e.openT = 0
	e.clashAt = -math.huge
	e.spawnCd = 2
	e.visual = 0
	e.aux = 0
end

function Boss.lightFactor(sim, e, beam): number
	local d = e.boss
	if e.openT > 0 then
		if beam.main then
			e.clashAt = sim.t
		end
		return d.openDamage
	end
	return d.closedDamage
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	if B.dist(e) > d.stand + 0.5 then
		B.approach(e, d.stand, e.speed * e.litFactor() * dt)
	end
	local r = e.rate()
	e.aux = 0
	if e.warnT > 0 then
		e.warnT -= dt
		e.visual = (1 - math.max(0, e.warnT) / d.openWarn) * 255
		if e.warnT <= 0 then
			e.openT = d.openTime
			sim:fx("sfx", { id = "roar", x = e.x, y = e.y })
		end
	elseif e.openT > 0 then
		e.openT -= dt
		e.visual = 255
		if sim.t - e.clashAt > CLASH_TIME then
			-- Olho aberto sem feixe nele: o olhar queima o farol e encurta a luz.
			sim:damageLighthouse(d.glareDps * r * dt, true)
			sim:ink(0.3, d.glareRange)
			e.aux = 1
		else
			e.aux = 2
		end
		if e.openT <= 0 then
			e.visual = 0
		end
	else
		e.visual = 0
		e.openCd -= dt * r
		if e.openCd <= 0 then
			e.openCd = d.openEvery
			e.warnT = d.openWarn
			sim:fx("sfx", { id = "warning", x = e.x, y = e.y })
		end
	end
	e.spawnCd -= dt * r
	if e.spawnCd <= 0 then
		e.spawnCd = d.spawnEvery
		local dist = math.max(B.dist(e), 1e-6)
		local side = (sim.rng:NextNumber() * 2 - 1) * 80
		-- Ao lado de Balor, na perpendicular da linha até o farol.
		sim:spawnMinion("tentacle", e.x - e.y / dist * side, e.y + e.x / dist * side)
	end
	e.facing = math.atan2(-e.y, -e.x)
end

return Boss
