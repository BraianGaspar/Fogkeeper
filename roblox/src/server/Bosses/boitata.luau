-- Boitatá, a cobra de fogo. Enquanto arde, a luz não a fere (ela é feita de
-- fogo) e cospe fogos-fátuos. De tempos em tempos a chama baixa: escura e
-- cheia de brasas, fica vulnerável e leva dano extra. O Clarão apaga a chama
-- na hora. Rasteja em espiral até a ilha e morde ao chegar.
-- visual: 1 em chamas, 0 apagada. aux: clarão da luz batendo no fogo (0..255).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local function setBlaze(sim, e, on: boolean)
	e.blaze = on
	e.phaseT = if on then e.boss.blazeTime else e.boss.dimTime
	sim:fx("sfx", { id = if on then "ignite" else "splash", x = e.x, y = e.y })
end

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	e.angle = angle
	e.orbit = d.startRadius
	e.blaze = true
	e.phaseT = d.blazeTime
	e.wispCd = 1
	e.flare = 0
	e.visual = 1
	B.place(e, angle, e.orbit)
	e.facing = angle + math.pi / 2
end

function Boss.lightFactor(sim, e, beam): number
	if e.blaze then
		e.flare = 0.15 -- a luz bate e é engolida pelo fogo
		return 0
	end
	return e.boss.dimDamage
end

-- O Clarão (atordoamento) apaga o fogo e abre a janela de dano.
function Boss.stunned(sim, e)
	if e.blaze then
		setBlaze(sim, e, false)
	end
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local px, py = e.x, e.y
	-- A simulação não chama step enquanto o chefe está atordoado: um intervalo
	-- maior que um passo desde o último step significa que o Clarão o pegou.
	local skipped = e.lastStep ~= nil and sim.t - e.lastStep > dt * 1.5 + 1e-4
	e.lastStep = sim.t
	if e.blaze and (skipped or (e.stun or 0) > 0) then
		setBlaze(sim, e, false)
	end
	e.flare = math.max(0, e.flare - dt)
	e.phaseT -= dt * (if e.blaze then r else 1)
	if e.phaseT <= 0 then
		setBlaze(sim, e, not e.blaze)
	end
	local hx, hy = math.cos(e.facing or 0), math.sin(e.facing or 0)
	if e.blaze then
		e.wispCd -= dt * r
		if e.wispCd <= 0 then
			e.wispCd = d.wispEvery
			sim:spawnMinion("boulder", e.x + hx * e.radius, e.y + hy * e.radius)
		end
	end
	local slow = if e.blaze then 1 else 0.5
	e.angle += e.speed * r * slow * dt
	e.orbit = B.moveToward(e.orbit, B.reach(e), d.approach * r * slow * dt)
	B.place(e, e.angle, e.orbit)
	if (e.x - px) ^ 2 + (e.y - py) ^ 2 > 1e-4 then
		e.facing = math.atan2(e.y - py, e.x - px)
	end
	e.visual = if e.blaze then 1 else 0
	e.aux = e.flare / 0.15 * 255
	B.melee(sim, e, dt)
end

return Boss
