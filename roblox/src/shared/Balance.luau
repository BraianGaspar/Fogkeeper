-- Todos os números da versão Roblox (os dos chefes ficam em BossData). As
-- distâncias estão em "unidades de jogo", as mesmas do Fogkeeper em Godot
-- (scripts/core/balance.gd); o mundo 3D converte com STUDS_PER_UNIT. O farol
-- fica na origem. Os textos são em português (chaves de tradução).

local Balance = {}

-- Escala do mundo: 0,25 stud por unidade deixa a ilha com ~18 studs de raio,
-- espaço para os avatares andarem. Cenários e alturas fixas foram desenhados
-- em 0,1 e são multiplicados por WORLD_SCALE.
Balance.STUDS_PER_UNIT = 0.25
Balance.WORLD_SCALE = Balance.STUDS_PER_UNIT / 0.1

-- Avatares (terceira pessoa)
Balance.ORIGIN_MARGIN = 10 -- unidades além da borda da ilha que ainda contam como origem do feixe
Balance.AVATAR_WALK_SPEED = 16 -- studs por segundo (padrão do Roblox)
Balance.CAMERA_MIN_ZOOM = 12
Balance.CAMERA_MAX_ZOOM = 70
Balance.FALL_RESET_Y = -20 -- abaixo disto (studs), o avatar volta para a ilha

-- Servidor ---------------------------------------------------------------------
Balance.TICK = 1 / 30 -- passo fixo da simulação
Balance.SNAPSHOT_RATE = 12 -- envios de estado por segundo
Balance.LOBBY_RETURN = 15 -- segundos na tela final antes de voltar ao saguão
Balance.ENDLESS_VOTE = 15 -- segundos para votar em continuar noite adentro
Balance.STORY_TIME = 14 -- segundos da história do mapa antes da partida
Balance.PAUSE_MAX = 120 -- com mais de um faroleiro, a pausa acaba sozinha depois disto

-- Compras com Robux (shared/Monetization.luau)
Balance.VIP_OIL = 2 -- multiplicador do óleo ganho com o passe VIP
Balance.REVIVE_WINDOW = 12 -- segundos para alguém reacender o farol quando a luz se apaga
Balance.REVIVE_HP = 0.5 -- fração da vida máxima ao reacender
Balance.REVIVE_STUN = 3 -- segundos de atordoamento nas criaturas ao reacender
Balance.REVIVE_LATE_OIL = 300 -- óleo entregue se a compra chegar depois que a janela fechou
Balance.LOBBY_COOLDOWN = 0.25 -- intervalo mínimo entre comandos do saguão, por jogador
Balance.TOP_CACHE = 60 -- segundos que um ranking fica guardado antes de consultar de novo
Balance.HISTORY_SIZE = 20 -- partidas guardadas no histórico de cada jogador

-- Partida ----------------------------------------------------------------------
Balance.RUN_DURATION = 600 -- segundos até o amanhecer (vitória)

-- Farol
Balance.LIGHTHOUSE_MAX_HP = 100
Balance.LIGHTHOUSE_RADIUS = 30
Balance.ISLAND_RADIUS = 72
Balance.ATTACK_INTERVAL = 1
Balance.LIT_SLOW = 0.55 -- multiplicador de velocidade de quem está sob a luz
Balance.LIT_TIME = 0.12 -- segundos que uma criatura conta como iluminada depois do último toque

-- Feixe principal
Balance.BEAM_RANGE = 340
Balance.BEAM_HALF_ANGLE = math.rad(14)
Balance.BEAM_DPS = 24
Balance.TURN_SPEED = 2.8 -- radianos por segundo
Balance.AIM_TOLERANCE = 1.4 -- o servidor aceita o giro do cliente até este fator da velocidade
Balance.SECONDARY_LENS_FACTOR = 0.6 -- dano das lentes extras em relação à principal

-- Armas secundárias
Balance.SWEEPER_SPEED = 1.6
Balance.SWEEPER_RANGE = 0.6
Balance.SWEEPER_WIDTH = 0.7
Balance.PULSE_RADIUS = 170
Balance.PULSE_RADIUS_PER_LEVEL = 30
Balance.PULSE_DAMAGE = 18
Balance.PULSE_DAMAGE_PER_LEVEL = 0.4 -- fração do dano base somada por nível acima do primeiro
Balance.PULSE_DURATION = 0.45 -- segundos da onda até o raio máximo

-- Brasas (XP)
Balance.MAGNET_RADIUS = 90
Balance.EMBER_PULL_SPEED = 520
Balance.MAX_EMBERS = 220
Balance.BOSS_EMBERS = 6 -- pedaços em que a recompensa de um chefe se divide

-- Criaturas comuns: estatísticas por papel; cada mapa dá a arte de cada papel.
Balance.ENEMIES = {
	basic = { hp = 14, speed = 54, radius = 12, damage = 4, xp = 1, score = 10 },
	fast = { hp = 9, speed = 110, radius = 9, damage = 3, xp = 1, score = 12 },
	brute = { hp = 55, speed = 28, radius = 20, damage = 10, xp = 4, score = 40 },
	thief = { hp = 16, speed = 95, radius = 11, damage = 0, xp = 1, score = 25 },
	mirror = { hp = 30, speed = 38, radius = 15, damage = 8, xp = 3, score = 35 },
	moth = { hp = 26, speed = 44, radius = 13, damage = 6, xp = 2, score = 30 },
	fogbank = { hp = 90, speed = 26, radius = 70, damage = 0, xp = 3, score = 50 },
	tentacle = { hp = 26, speed = 70, radius = 10, damage = 7, xp = 1, score = 15 },
	boulder = { hp = 20, speed = 135, radius = 13, damage = 12, xp = 0, score = 5 },
	decoy = { hp = 30, speed = 0.38, radius = 26, damage = 8, xp = 0, score = 5 },
}
-- Papéis que não atacam o farol encostados nele.
Balance.NO_MELEE = { thief = true, fogbank = true, decoy = true }

-- Elites (Médio em diante): mais fortes e valiosas.
Balance.ELITE = { hp = 3, damage = 1.5, radius = 1.3, xp = 4, score = 3 }
Balance.ELITE_START = 60

-- Criaturas especiais
Balance.THIEF_CARRY = 4
Balance.THIEF_PATIENCE = 12
Balance.THIEF_SIGHT = 700 -- distância máxima em que a ladra enxerga uma brasa
Balance.ESCAPE_DIST = 900 -- distância em que a ladra some com o roubo (e a névoa sai do mapa)
Balance.MIRROR_CLOSED = 2.6
Balance.MIRROR_OPEN = 1.8
Balance.MIRROR_REFLECT = 0.08
Balance.MOTH_GROW = 0.5
Balance.MOTH_MAX = 1.5
Balance.MOTH_LIT_SPEED = 1.15 -- a mariposa acelera sob a luz
Balance.FOGBANK_START = 150
Balance.FOGBANK_EVERY = 70
Balance.FOGBANK_DRAIN = 5
Balance.SPAWN_RING = 760 -- distância em que as criaturas surgem (fora da tela)

-- Chefes (os números de cada mecânica ficam em BossData)
Balance.BOSS_TIMES = { 300, 540 }
Balance.EXTRA_BOSS_TIME = 420
Balance.BOSS_WARNING = 8
Balance.BOSS_HEAL = 25
Balance.BOSS_STUN = 0.25 -- chefes sofrem só esta fração do atordoamento
Balance.BOSS_PUSH = 0.25 -- e são empurrados só esta fração pela Maré
Balance.BOSS_EARLIEST = 60 -- as marés não trazem chefes antes disto

-- Habilidades ativas (cada jogador leva três)
Balance.ABILITIES = {
	{ id = "flash", name = "Clarão", desc = "Explosão de luz que fere e atordoa tudo por perto.",
		cooldown = 24, radius = 230, damage = 60, stun = 2 },
	{ id = "overcharge", name = "Sobrecarga", desc = "O feixe principal fica concentrado e muito mais forte por alguns segundos.",
		cooldown = 20, duration = 5, dps = 2.5, range = 1.3, angle = 0.6 },
	{ id = "bell", name = "Sino da Névoa", desc = "Puxa todas as brasas para o farol e recupera um pouco de vida.",
		cooldown = 30, heal = 10 },
	{ id = "mirror", name = "Espelho", desc = "Um segundo feixe aponta para o lado oposto por alguns segundos.",
		cooldown = 22, duration = 6 },
	{ id = "tide", name = "Maré", desc = "Uma onda empurra para longe as criaturas perto do farol.",
		cooldown = 24, radius = 320, push = 150, stun = 0.6 },
	{ id = "beacon", name = "Sinalizador", desc = "Dois feixes giram sozinhos em volta do farol por alguns segundos.",
		cooldown = 26, duration = 8, spin = 3, dps = 0.6, range = 0.85, angle = 0.8 },
}
Balance.DEFAULT_LOADOUT = { "flash", "overcharge", "bell" }

-- Dificuldades: multiplicadores e regras. "xp" multiplica o XP por nível,
-- "emberLife" é quanto as brasas duram, "elite" a chance de elite, "enrage"
-- faz chefes enfurecerem, "extraBoss" soma um chefe aos 7:00, "fog" deixa a
-- névoa mais densa. "normal" é a referência.
Balance.DIFFICULTY_ORDER = { "easy", "normal", "medium", "hard", "impossible" }
Balance.DIFFICULTIES = {
	easy = { name = "Fácil", enemyHp = 0.8, enemyDamage = 0.7, enemySpeed = 0.95, spawn = 0.9, xp = 1.0, emberLife = 15,
		elite = 0, enrage = false, extraBoss = false, lighthouseHp = 1.15, fog = 0.85, score = 0.5 },
	normal = { name = "Normal", enemyHp = 1.0, enemyDamage = 1.0, enemySpeed = 1.0, spawn = 1.0, xp = 1.0, emberLife = 14,
		elite = 0, enrage = false, extraBoss = false, lighthouseHp = 1.0, fog = 1.0, score = 1.0 },
	medium = { name = "Médio", enemyHp = 1.1, enemyDamage = 1.12, enemySpeed = 1.04, spawn = 1.08, xp = 1.08, emberLife = 11,
		elite = 0.04, enrage = false, extraBoss = false, lighthouseHp = 1.0, fog = 1.1, score = 1.3 },
	hard = { name = "Difícil", enemyHp = 1.25, enemyDamage = 1.3, enemySpeed = 1.08, spawn = 1.2, xp = 1.15, emberLife = 9,
		elite = 0.08, enrage = true, extraBoss = false, lighthouseHp = 1.0, fog = 1.2, score = 1.7 },
	impossible = { name = "Impossível", enemyHp = 1.8, enemyDamage = 2.0, enemySpeed = 1.2, spawn = 1.5, xp = 1.35, emberLife = 6,
		elite = 0.15, enrage = true, extraBoss = true, lighthouseHp = 0.75, fog = 1.45, score = 2.5 },
}
Balance.DIFFICULTY_RAMP = 180 -- segundos até o que dificulta valer por inteiro

-- Modo sem fim (depois do amanhecer)
Balance.ENDLESS_BOSS_FIRST = 60
Balance.ENDLESS_BOSS_EVERY = 150
Balance.ENDLESS_FOGBANK_EVERY = 45
Balance.MAX_ENEMIES = 200 -- teto de criaturas vivas (protege servidor e rede)

-- Pontuação
Balance.SCORE_PER_SECOND = 5
Balance.SCORE_PER_BOSS = 1500
Balance.SCORE_VICTORY = 5000
Balance.SCORE_HEALTH_BONUS = 2000
Balance.SCORE_ENDLESS_PER_SECOND = 10
Balance.SCORE_PER_NIGHT = 4000

-- Melhorias especiais
Balance.VITAL_EMBER_HEAL = 0.4
Balance.COMBUSTION_RADIUS = 70
Balance.COMBUSTION_RADIUS_PER_LEVEL = 15
Balance.COMBUSTION_DAMAGE = 10

-- Progressão entre partidas
Balance.OIL_PER_SCORE = 0.005
Balance.OIL_MIN = 5
Balance.BASE_REROLLS = 1
Balance.BASE_BANISHES = 0
Balance.BASE_CARDS = 3

-- Oficina: melhorias permanentes de cada jogador. Custo do nível n = cost × n.
Balance.META = {
	{ id = "granite", name = "Paredes de granito", desc = "+10 de vida máxima por nível.", max = 5, cost = 60 },
	{ id = "polish", name = "Lente polida", desc = "+5% de dano da luz por nível.", max = 5, cost = 80 },
	{ id = "fine_gears", name = "Engrenagens finas", desc = "+6% de velocidade de giro por nível.", max = 3, cost = 70 },
	{ id = "long_wick", name = "Pavio longo", desc = "Brasas duram 1,5 s a mais por nível.", max = 3, cost = 60 },
	{ id = "copper", name = "Ímã de cobre", desc = "Brasas são puxadas de 10% mais longe por nível.", max = 3, cost = 60 },
	{ id = "reroll", name = "Segunda opinião", desc = "+1 troca de cartas por partida, por nível.", max = 3, cost = 90 },
	{ id = "banish", name = "Lista negra", desc = "+1 banimento de carta por partida, por nível.", max = 2, cost = 120 },
	{ id = "fourth_card", name = "Olhar atento", desc = "Uma carta a mais em cada escolha de melhoria.", max = 1, cost = 400 },
	{ id = "head_start", name = "Pavio aceso", desc = "Começa a partida com uma melhoria aleatória.", max = 1, cost = 250 },
	{ id = "fisher", name = "Sorte do pescador", desc = "+10% de óleo ganho por nível.", max = 3, cost = 100 },
}
Balance.META_EFFECTS = {
	granite = 10, -- vida máxima por nível (somada ao farol: média do time)
	polish = 0.05, -- dano da luz por nível
	fine_gears = 0.06, -- giro por nível
	long_wick = 1.5, -- segundos de brasa por nível (média do time)
	copper = 0.1, -- raio do ímã por nível (média do time)
	fisher = 0.1, -- óleo por nível
}

-- Desbloqueios: por óleo, ou de graça ao cumprir a meta ("goal").
-- Metas: "midnight" (meia-noite), "boss" (um chefe), "dawn" (amanhecer),
-- "dawn_medium" (amanhecer no Médio ou acima).
Balance.UNLOCKS = {
	{ id = "fjord", kind = "map", cost = 150, goal = "midnight" },
	{ id = "amazon", kind = "map", cost = 300, goal = "boss" },
	{ id = "japan", kind = "map", cost = 400, goal = "dawn" },
	{ id = "egypt", kind = "map", cost = 500, goal = "dawn_medium" },
	{ id = "greece", kind = "map", cost = 600, goal = "dawn_medium" },
	{ id = "celtic", kind = "map", cost = 700, goal = "dawn_medium" },
	{ id = "stone", kind = "keeper", cost = 80, goal = "" },
	{ id = "iron", kind = "keeper", cost = 160, goal = "" },
	{ id = "crystal", kind = "keeper", cost = 240, goal = "dawn" },
	{ id = "combustion", kind = "upgrade", cost = 200, goal = "" },
	{ id = "vital_embers", kind = "upgrade", cost = 200, goal = "" },
	{ id = "monk", kind = "hero", cost = 150, goal = "" },
	{ id = "pirate", kind = "hero", cost = 200, goal = "" },
	{ id = "astronomer", kind = "hero", cost = 250, goal = "" },
	{ id = "fisher", kind = "hero", cost = 150, goal = "" },
	{ id = "mirror", kind = "ability", cost = 180, goal = "" },
	{ id = "tide", kind = "ability", cost = 180, goal = "" },
	{ id = "beacon", kind = "ability", cost = 180, goal = "" },
}
Balance.GOAL_TEXTS = {
	midnight = "Sobreviva até a meia-noite em qualquer mapa",
	boss = "Derrote um chefe em qualquer mapa",
	dawn = "Veja o amanhecer em qualquer mapa",
	dawn_medium = "Veja o amanhecer no Médio ou acima",
}

-- Faroleiros jogáveis: regras do feixe e das habilidades de quem joga com
-- ele. Chaves: lens (lentes extras), dps, range, width (largura do feixe), hp
-- (vida somada ao farol: média do time), pulse (nível inicial do Pulso),
-- magnet, xp (XP por nível: média do time).
Balance.HEROES = {
	keeper = { name = "Faroleira", desc = "Equilibrada: nenhuma vantagem, nenhuma desvantagem." },
	monk = { name = "Monge", desc = "Começa com duas lentes extras, mas a luz causa 30% menos dano.", lens = 2, dps = 0.7 },
	pirate = { name = "Pirata", desc = "Feixe curto e forte: 30% menos alcance, 50% mais dano e 30 de vida a mais.", range = 0.7, dps = 1.5, hp = 30 },
	astronomer = { name = "Astrônoma", desc = "Começa com Pulso de luz nível 2, mas o feixe é 30% mais estreito.", pulse = 2, width = 0.7 },
	fisher = { name = "Pescador", desc = "Puxa brasas de muito mais longe e sobe de nível 15% mais rápido, com 20 de vida a menos.",
		magnet = 1.8, xp = 0.85, hp = -20 },
}
Balance.HERO_ORDER = { "keeper", "monk", "pirate", "astronomer", "fisher" }
Balance.MIN_LIGHTHOUSE_HP = 30

-- Marés (níveis de desafio depois de ver o amanhecer). Cumulativas.
Balance.TIDES = {
	{ desc = "Criaturas 10% mais rápidas.", speed = 1.1 },
	{ desc = "Brasas duram 25% menos.", ember = 0.75 },
	{ desc = "Chefes chegam 1 minuto antes.", bossEarly = 60 },
	{ desc = "Mais criaturas de elite.", elite = 0.05 },
	{ desc = "Farol com 15% menos vida.", lighthouse = 0.85 },
	{ desc = "Uma troca de cartas a menos.", reroll = -1 },
	{ desc = "Criaturas com 15% mais vida.", hp = 1.15 },
	{ desc = "Névoa mais densa.", fog = 0.25 },
	{ desc = "Chefes enfurecem com 75% da vida.", enrage = 0.75 },
	{ desc = "Chefes derrotados não curam o farol.", noHeal = 1 },
}
Balance.TIDE_SCORE = 0.15
Balance.TIDE_ALWAYS_ENRAGE = 9 -- a partir desta maré os chefes enfurecem em qualquer dificuldade
Balance.ENRAGE_AT = 0.5 -- fração de vida em que os chefes enfurecem (igual a BossData.ENRAGE_AT)

-- Modo Chefões
Balance.BOSS_RUSH_PAUSE = 6
Balance.BOSS_RUSH_START_PICKS = 6
Balance.BOSS_RUSH_PAR = 1200
Balance.SCORE_RUSH_PER_SECOND = 10
Balance.BOSS_RUSH_FIRST = 3 -- segundos até o primeiro chefe
Balance.BOSS_RUSH_CLOCK = 260 -- hora fixa do céu no Modo Chefões (segundos de noite)
Balance.BOSS_RUSH_BASE_TIME = 90 -- força das criaturas comuns: tempo base...
Balance.BOSS_RUSH_TIME_PER_BOSS = 35 -- ...mais isto por chefe derrotado...
Balance.BOSS_RUSH_MAX_TIME = 480 -- ...até este teto

-- Tutorial
Balance.TUTORIAL_CLOCK = 140
Balance.TUTORIAL_REGEN = 4
Balance.TUTORIAL_BOSS_HP = 0.3
Balance.TUTORIAL_DONE_TIME = 6

-- Cooperativo: quanto cada jogador a mais pesa.
Balance.MAX_PLAYERS = 4
Balance.COOP_SPAWN = 0.5
Balance.COOP_ENEMY_HP = 0.25
Balance.COOP_BOSS_HP = 0.6
Balance.COOP_XP = 0.3

-- Funções -------------------------------------------------------------------

-- Valor de uma regra da dificuldade no tempo t: o que facilita vale desde o
-- início; o que dificulta cresce do Normal até o valor cheio.
function Balance.difficultyValue(difficulty: string, key: string, t: number): number
	local v = Balance.DIFFICULTIES[difficulty][key]
	if key == "elite" then
		return v * math.clamp((t - Balance.ELITE_START) / Balance.DIFFICULTY_RAMP, 0, 1)
	end
	if v <= 1 then
		return v
	end
	return 1 + (v - 1) * math.clamp(t / Balance.DIFFICULTY_RAMP, 0, 1)
end

-- Efeito somado das marés até `level`. Multiplicadores começam em 1, somas em 0.
local MULTIPLY = { speed = true, ember = true, lighthouse = true, hp = true }
function Balance.tide(level: number, key: string): number
	local v = if MULTIPLY[key] then 1 else 0
	if key == "enrage" then
		v = Balance.ENRAGE_AT
	end
	for i = 1, math.min(level, #Balance.TIDES) do
		local t = Balance.TIDES[i][key]
		if t ~= nil then
			if MULTIPLY[key] then
				v *= t
			elseif key == "enrage" then
				v = math.max(v, t)
			else
				v += t
			end
		end
	end
	return v
end

function Balance.hpMultiplier(t: number): number
	return 1 + t / 300 + (t / 520) ^ 2
end

function Balance.spawnInterval(t: number): number
	return math.max(0.2, 0.8 - t * 0.0011)
end

function Balance.groupSize(t: number): number
	return 1 + math.floor(t / 160)
end

function Balance.spawnWeights(t: number): { [string]: number }
	local w = { basic = 10 }
	if t >= 45 then
		w.fast = math.min(6, (t - 45) / 15)
	end
	if t >= 120 then
		w.brute = math.min(3, (t - 120) / 90)
	end
	if t >= 90 then
		w.thief = math.min(1, (t - 90) / 60)
	end
	if t >= 160 then
		w.mirror = math.min(1, (t - 160) / 120)
	end
	if t >= 210 then
		w.moth = math.min(1, (t - 210) / 120)
	end
	return w
end

function Balance.pulseCooldown(level: number): number
	return math.max(2, 6 - level * 0.8)
end

-- XP de um nível; `heroXp` é a média do multiplicador dos faroleiros do time.
function Balance.xpForLevel(level: number, difficulty: string, players: number, heroXp: number?): number
	local base = 6 + level * 6 + math.floor(level * level * 0.3)
	local need = math.ceil(base * Balance.DIFFICULTIES[difficulty].xp)
	return math.max(1, math.round(need * (1 + Balance.COOP_XP * (players - 1)) * (heroXp or 1)))
end

function Balance.findAbility(id: string)
	for _, a in Balance.ABILITIES do
		if a.id == id then
			return a
		end
	end
	return nil
end

function Balance.findMeta(id: string)
	for _, m in Balance.META do
		if m.id == id then
			return m
		end
	end
	return nil
end

function Balance.findUnlock(id: string)
	for _, u in Balance.UNLOCKS do
		if u.id == id then
			return u
		end
	end
	return nil
end

-- Pontuação em partes: criaturas, tempo e bônus; a dificuldade (e a maré)
-- multiplicam. O tempo depois do amanhecer entra em "endless"; no Modo
-- Chefões o tempo conta ao contrário (terminar rápido vale mais).
function Balance.scoreBreakdown(killPoints: number, bosses: number, seconds: number, victory: boolean, hpFraction: number,
	difficulty: string, tideLevel: number?, rush: boolean?)
	local survival = math.floor(math.min(seconds, Balance.RUN_DURATION)) * Balance.SCORE_PER_SECOND
	if rush then
		survival = if victory then math.floor(math.max(0, Balance.BOSS_RUSH_PAR - seconds)) * Balance.SCORE_RUSH_PER_SECOND else 0
	end
	local extra = math.max(0, seconds - Balance.RUN_DURATION)
	local endless = if rush then 0
		else math.floor(extra) * Balance.SCORE_ENDLESS_PER_SECOND + math.floor(extra / Balance.RUN_DURATION) * Balance.SCORE_PER_NIGHT
	local parts = {
		kills = killPoints,
		survival = survival,
		endless = endless,
		bosses = bosses * Balance.SCORE_PER_BOSS,
		victory = if victory then Balance.SCORE_VICTORY else 0,
		health = if victory then math.round(Balance.SCORE_HEALTH_BONUS * math.clamp(hpFraction, 0, 1)) else 0,
	}
	parts.subtotal = parts.kills + parts.survival + parts.endless + parts.bosses + parts.victory + parts.health
	parts.multiplier = Balance.DIFFICULTIES[difficulty].score * (1 + Balance.TIDE_SCORE * (tideLevel or 0))
	parts.total = math.round(parts.subtotal * parts.multiplier)
	return parts
end

return Balance
