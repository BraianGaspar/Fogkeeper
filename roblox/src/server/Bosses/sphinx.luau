-- Esfinge: para longe da ilha e propõe enigmas. Três símbolos surgem em volta
-- do farol (partes "sphinx_glyph") e ela mostra, acima da cabeça, qual deles
-- é a resposta. Segurar um feixe principal no símbolo certo por um instante
-- responde: ela fica vulnerável e a luz a fere em dobro. Errar ou demorar faz
-- pedras rolarem contra o farol. Fora dessa janela, a luz a fere só pela metade.
-- Esfinge   visual: 0 calma; 1+g = enigma com resposta g (0 ankh, 1 olho, 2 pena). aux: 1 vulnerável.
-- Símbolo   visual: g (0 ankh, 1 olho, 2 pena). aux: progresso da resposta (0..255).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

local function clearGlyphs(e)
	for _, g in e.glyphs or {} do
		g.hp = 0
	end
	e.glyphs = {}
end

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	B.place(e, angle, d.stand + 150)
	e.riddleCd = d.riddleEvery * 0.5
	e.riddleT = 0
	e.weakT = 0
	e.glyphs = {}
	e.slots = {}
	e.answer = 1
	e.hold = 0
	e.holdSlot = 0
	e.visual = 0
	e.aux = 0
end

function Boss.lightFactor(sim, e, beam): number
	return if e.weakT > 0 then e.boss.weakDamage else e.boss.strongDamage
end

-- Símbolo sob algum feixe principal (0 = nenhum).
local function slotUnderBeam(sim, e): number
	local r = e.boss.glyphRadius
	for i, a in e.slots do
		-- Os feixes saem dos faroleiros: confere o ponto do símbolo, não só o ângulo.
		if B.mainBeamOn(sim, math.cos(a) * r, math.sin(a) * r, r * 0.08) then
			return i
		end
	end
	return 0
end

local function startRiddle(sim, e)
	local d = e.boss
	local base = sim.rng:NextNumber() * 2 * math.pi
	local kinds = { 0, 1, 2 }
	for i = 3, 2, -1 do
		local j = sim.rng:NextInteger(1, i)
		kinds[i], kinds[j] = kinds[j], kinds[i]
	end
	e.slots = {}
	clearGlyphs(e)
	for i = 1, 3 do
		local a = base + 2 * math.pi * (i - 1) / 3
		e.slots[i] = a
		local g = sim:spawnArt("sphinx_glyph", "basic", math.cos(a) * d.glyphRadius, math.sin(a) * d.glyphRadius)
		g.parent = e
		g.noScore = true
		g.xp = 0
		g.score = 0
		g.damage = 0
		g.visual = kinds[i]
		g.aux = 0
		g.facing = a
		e.glyphs[i] = g
	end
	e.answer = sim.rng:NextInteger(1, 3)
	e.riddleT = d.riddleTime
	e.hold = 0
	e.holdSlot = 0
	sim:fx("sfx", { id = "announce", x = e.x, y = e.y })
end

local function endRiddle(e)
	e.riddleT = 0
	e.riddleCd = e.boss.riddleEvery
	clearGlyphs(e)
end

local function solve(sim, e)
	endRiddle(e)
	e.weakT = e.boss.weakTime
	sim:fx("sfx", { id = "relic", x = e.x, y = e.y })
end

local function punish(sim, e)
	endRiddle(e)
	local n = e.boss.punishStones
	for i = 0, n - 1 do
		local a = 2 * math.pi * i / n
		sim:spawnMinion("boulder", e.x + math.cos(a) * e.radius, e.y + math.sin(a) * e.radius)
	end
	sim:fx("sfx", { id = "roar", x = e.x, y = e.y })
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	e.weakT = math.max(0, e.weakT - dt)
	e.aux = if e.weakT > 0 then 1 else 0
	-- Partes não queimam nem somem sozinhas.
	for _, g in e.glyphs do
		g.hp = g.maxHp
	end
	if B.dist(e) > d.stand + 0.5 then
		B.approach(e, d.stand, e.speed * dt)
		return
	end
	if e.riddleT > 0 then
		e.riddleT -= dt
		local slot = slotUnderBeam(sim, e)
		if slot > 0 and slot == e.holdSlot then
			e.hold += dt
		else
			e.holdSlot = slot
			e.hold = 0
		end
		for i, g in e.glyphs do
			g.aux = if i == e.holdSlot then math.clamp(e.hold / d.answer, 0, 1) * 255 else 0
		end
		e.visual = 1 + (if e.glyphs[e.answer] then e.glyphs[e.answer].visual else 0)
		if e.hold >= d.answer then
			if slot == e.answer then
				solve(sim, e)
			else
				punish(sim, e)
			end
		elseif e.riddleT <= 0 then
			punish(sim, e)
		end
		if e.riddleT <= 0 then
			e.visual = 0
		end
		return
	end
	e.visual = 0
	if e.weakT > 0 then
		return
	end
	e.riddleCd -= dt * e.rate()
	if e.riddleCd <= 0 then
		startRiddle(sim, e)
	end
end

function Boss.died(sim, e)
	clearGlyphs(e)
end

return Boss
