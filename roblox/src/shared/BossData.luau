-- Números dos 15 chefes, relíquias, horários e fúria (iguais a
-- scripts/core/balance.gd do Godot). A mecânica de cada um fica em
-- server/Bosses/<id>.luau; o desenho em client/Art/Bosses.luau.
--
-- Efeito de cada relíquia (o NÚCLEO aplica, no farol do time; "feixe" = todos
-- os feixes dos jogadores; os multiplicadores se somam aos que já existem):
--   leviathan  vida máxima +40 e cura total
--   kraken     alcance do feixe ×1,2
--   jotunn     lentidão de quem está iluminado ×0,7 (LIT_SLOW fica menor = mais lento)
--   fenrir     velocidade de giro ×1,3 e dano da luz ×1,15
--   iara       raio de atração das brasas ×1,5 e regeneração +0,5/s
--   boitata    dano da luz ×1,25
--   cuca       recarga das habilidades ×0,7
--   umibozu    +1 lente extra (como a melhoria Lente extra) em cada feixe
--   kyubi      dano da luz ×1,2 e giro ×1,15
--   sphinx     +1 nível de Pulso de luz
--   apep       lentidão de quem está iluminado ×0,75 e alcance ×1,1
--   scylla     +1 nível de Farolete giratório
--   medusa     vida máxima +30, cura 30 e lentidão de quem está iluminado ×0,8
--   balor      largura do feixe ×1,15 e dano da luz ×1,2
--   cailleach  raio de atração das brasas ×1,3 e recarga das habilidades ×0,85

local BossData = {}

BossData.TIMES = { 300, 540 } -- momentos dos chefes na noite (o mapa diz quem aparece)
BossData.EXTRA_TIME = 420 -- chefe extra no Impossível
BossData.WARNING = 8 -- segundos de aviso antes de um chefe surgir
BossData.HEAL = 25 -- vida recuperada ao derrotar um chefe
BossData.ENRAGE_AT = 0.5 -- fração da vida em que enfurece (dificuldades com "enrage")
BossData.ENRAGE_SPEED = 1.4 -- ritmo e velocidade do chefe enfurecido
BossData.STUN_FACTOR = 0.25 -- chefes resistem ao atordoamento
BossData.LIT_SLOW_FACTOR = 0.5 -- a luz freia chefes só pela metade

-- Modo Chefões
BossData.RUSH_PAUSE = 6
BossData.RUSH_START_PICKS = 6
BossData.RUSH_PAR = 1200
BossData.SCORE_RUSH_PER_SECOND = 10

BossData.BOSSES = {
	leviathan = { hp = 650, speed = 0.32, radius = 30, damage = 10, xp = 30,
		diveEvery = 9, diveTime = 2.6, startRadius = 430, approach = 16, diveSpin = 1.4 },
	kraken = { hp = 900, speed = 40, radius = 46, damage = 10, xp = 40,
		stand = 310, spawnEvery = 3, inkEvery = 11, inkTime = 3.5, inkRange = 0.55 },
	jotunn = { hp = 760, speed = 22, radius = 36, damage = 14, xp = 30,
		stand = 250, throwEvery = 3.2, advance = 18 },
	fenrir = { hp = 820, speed = 0.9, radius = 30, damage = 18, xp = 40,
		circle = 270, chargeEvery = 6.5, telegraph = 1.1, dashSpeed = 520, dodgeAfter = 0.6, dodgeCooldown = 2.5 },
	iara = { hp = 700, speed = 0.3, radius = 26, damage = 0, xp = 30,
		stand = 285, singEvery = 9, singTime = 4, pull = 1.7, spawnEvery = 1.1 },
	boitata = { hp = 820, speed = 0.42, radius = 28, damage = 16, xp = 40,
		startRadius = 430, blazeTime = 6.5, dimTime = 3.5, wispEvery = 1.8, dimDamage = 1.6, approach = 12 },
	cuca = { hp = 850, speed = 40, radius = 30, damage = 0, xp = 40,
		stand = 290, castEvery = 7, castTime = 2.4, interrupt = 0.08, sleepTime = 4.5, sleepPower = 0.35, vanishTime = 1.2 },
	umibozu = { hp = 760, speed = 18, radius = 44, damage = 18, xp = 30,
		stand = 320, reveal = 0.8, waveEvery = 4, advance = 14 },
	kyubi = { hp = 760, speed = 0.38, radius = 28, damage = 0, xp = 40,
		stand = 290, illusionEvery = 10, decoys = 3, fireEvery = 2.6 },
	sphinx = { hp = 820, speed = 30, radius = 40, damage = 0, xp = 30,
		stand = 300, riddleEvery = 9, riddleTime = 6, answer = 1.1, weakTime = 5,
		weakDamage = 2, strongDamage = 0.5, punishStones = 4, glyphRadius = 210 },
	apep = { hp = 900, speed = 0.36, radius = 30, damage = 16, xp = 40,
		startRadius = 430, approach = 11, eatRange = 0.4, spawnEvery = 2.8, bodyOffset = 120 },
	scylla = { hp = 820, speed = 30, radius = 40, damage = 12, xp = 30, -- damage = mordida de cada cabeça
		stand = 330, heads = 6, strikeEvery = 1.8, strikeTime = 2.6, headHp = 1, headDamage = 0.03, bodyDamage = 0.6,
		rockEvery = 3, neck = 70 },
	medusa = { hp = 900, speed = 0.34, radius = 30, damage = 0, xp = 40,
		stand = 290, gazeEvery = 7, gazeWarn = 1.3, gazeTime = 3, stoneTime = 3, stoneTurn = 0.12, snakeEvery = 1 },
	balor = { hp = 880, speed = 26, radius = 46, damage = 0, xp = 30,
		stand = 330, openEvery = 8, openWarn = 1.5, openTime = 4, closedDamage = 0.2, openDamage = 2.2,
		glare = 1, glareDps = 7, glareRange = 0.6, spawnEvery = 3.2 },
	cailleach = { hp = 860, speed = 0.3, radius = 30, damage = 0, xp = 40,
		stand = 300, stormEvery = 10, stormTime = 5, push = 110, stoneEvery = 1.6, hailEvery = 4 },
}

-- Ordem do Modo Chefões (mapa por mapa) e chefes de cada mapa estão em Maps.
BossData.ORDER = { "leviathan", "kraken", "jotunn", "fenrir", "iara", "boitata", "cuca", "umibozu", "kyubi",
	"sphinx", "apep", "scylla", "medusa", "balor", "cailleach" }

-- Ids de arte usados pelos chefes: os próprios chefes e as partes que a
-- simulação cria como criaturas (CONTEÚDO concatena em Maps.ARTS).
BossData.ARTS = {
	"leviathan", "kraken", "jotunn", "fenrir", "iara", "boitata", "cuca", "umibozu", "kyubi",
	"sphinx", "apep", "scylla", "medusa", "balor", "cailleach",
	"scylla_head", -- cabeça de Cila (parte do chefe, posicionada por ele)
	"sphinx_glyph", -- símbolo do enigma em volta do farol (parte do chefe)
}

BossData.RELICS = {
	leviathan = { name = "Escama do Leviatã", desc = "+40 de vida máxima e cura total." },
	kraken = { name = "Olho do Kraken", desc = "Feixe alcança 20% mais longe." },
	jotunn = { name = "Coração de Gelo", desc = "Criaturas iluminadas ficam ainda mais lentas." },
	fenrir = { name = "Presa de Fenrir", desc = "Feixe gira 30% mais rápido e causa 15% mais dano." },
	iara = { name = "Pérola da Iara", desc = "Brasas são puxadas de 50% mais longe e o farol regenera 0,5 de vida por segundo." },
	boitata = { name = "Olho do Boitatá", desc = "Toda a luz causa 25% mais dano." },
	cuca = { name = "Caldeirão da Cuca", desc = "Habilidades recarregam 30% mais rápido." },
	umibozu = { name = "Balde sem fundo", desc = "Ganha mais um feixe ao redor do farol." },
	kyubi = { name = "Hoshi no tama", desc = "A luz causa 20% mais dano e gira 15% mais rápido." },
	sphinx = { name = "Olho de Hórus", desc = "Ganha um nível de Pulso de luz." },
	apep = { name = "Escama de Apep", desc = "Criaturas iluminadas ficam 25% mais lentas e o feixe alcança 10% mais longe." },
	scylla = { name = "Colar de Cila", desc = "Ganha um nível de Farolete giratório." },
	medusa = { name = "Égide", desc = "+30 de vida máxima e criaturas iluminadas ficam 20% mais lentas." },
	balor = { name = "Olho de Balor", desc = "O feixe fica 15% mais largo e causa 20% mais dano." },
	cailleach = { name = "Cajado da Cailleach", desc = "Brasas são puxadas de 30% mais longe e habilidades recarregam 15% mais rápido." },
}

-- Utilidades dos scripts de chefe -------------------------------------------

local LIGHTHOUSE_RADIUS = 30 -- igual a Balance.LIGHTHOUSE_RADIUS (sem require circular)
BossData.LIGHTHOUSE_RADIUS = LIGHTHOUSE_RADIUS
BossData.ATTACK_INTERVAL = 1

function BossData.moveToward(from: number, to: number, step: number): number
	if math.abs(to - from) <= step then
		return to
	end
	return from + math.sign(to - from) * step
end

function BossData.angleDiff(a: number, b: number): number
	return (b - a + math.pi) % (2 * math.pi) - math.pi
end

-- Distância de alcance ao farol (encostado na ilha).
function BossData.reach(e): number
	return e.radius + LIGHTHOUSE_RADIUS
end

function BossData.dist(e): number
	return math.sqrt(e.x * e.x + e.y * e.y)
end

-- Põe o chefe a `d` do farol no ângulo `a`.
function BossData.place(e, a: number, d: number)
	e.x, e.y = math.cos(a) * d, math.sin(a) * d
end

-- Aproxima do farol (ou afasta) ao longo da linha até ele.
function BossData.approach(e, target: number, step: number)
	local d = BossData.dist(e)
	if d < 1e-6 then
		return
	end
	local nd = BossData.moveToward(d, target, step)
	e.x, e.y = e.x / d * nd, e.y / d * nd
end

-- Mordida comum: encostado no farol e visível, ataca a cada ATTACK_INTERVAL.
function BossData.melee(sim, e, dt: number)
	if e.hidden or BossData.dist(e) > BossData.reach(e) + 0.5 then
		return
	end
	e._biteCd = (e._biteCd or 0) - dt
	if e._biteCd <= 0 then
		e._biteCd = BossData.ATTACK_INTERVAL
		sim:damageLighthouse(e.damage)
	end
end

-- O chefe foi tocado pela luz há pouco? (marcado em lightFactor)
function BossData.lit(sim, e): boolean
	return e._litAt ~= nil and sim.t - e._litAt <= 0.12
end

-- Feixes principais dos jogadores que cobrem o ponto (x, y) com folga `pad`.
-- Cada feixe principal sai do faroleiro (beam.ox, beam.oy), não do farol.
function BossData.mainBeamOn(sim, x: number, y: number, pad: number): boolean
	for _, beam in sim:beamSources() do
		if beam.main then
			local dx, dy = x - (beam.ox or 0), y - (beam.oy or 0)
			local d = math.sqrt(dx * dx + dy * dy)
			if d < 1 or (d <= beam.range + pad
				and math.abs(BossData.angleDiff(beam.angle, math.atan2(dy, dx))) <= beam.half + math.atan2(pad, d)) then
				return true
			end
		end
	end
	return false
end

return BossData
