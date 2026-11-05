-- Simulação de uma partida, só lógica (sem Instances). O servidor chama
-- step(dt) num passo fixo e lê enemies, embers, deaths e events. Cada jogador
-- tem os próprios feixes (principal, lentes, faroletes e habilidades) girando
-- em volta do mesmo farol; brasas, nível e vida são do time.
-- As regras seguem o Fogkeeper em Godot (scripts/core e scripts/gameplay);
-- a API pública usada pelos chefes está em roblox/ARCHITECTURE.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local BossData = require(Shared:WaitForChild("BossData"))
local Maps = require(Shared:WaitForChild("Maps"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Sim = {}
Sim.__index = Sim

local TAU = 2 * math.pi
local DANGER = Color3.fromRGB(232, 86, 72)
local GOLD = Color3.fromRGB(240, 200, 110)
local GOOD = Color3.fromRGB(120, 230, 140)
local RELIC = Color3.fromRGB(180, 230, 255)
local EVOLUTION = Color3.fromRGB(217, 179, 255)
local DIM = Color3.fromRGB(160, 160, 172)
local HIT_FX_GAP = 0.15 -- intervalo mínimo entre avisos de dano ao farol (efeito na tela)
-- Intervalo mínimo entre efeitos de combustão enviados aos clientes: numa
-- cadeia de explosões eram dezenas de Fx (rede) e anéis (peças) por segundo.
-- Só o efeito visual é cortado; o dano de cada explosão continua.
local COMBUSTION_FX_GAP = 0.1

-- Mecânicas dos chefes: todo ModuleScript de server/Bosses, pelo nome (id).
local BOSS_MODULES: { [string]: any } = {}
do
	local folder = script.Parent:WaitForChild("Bosses")
	for _, m in folder:GetChildren() do
		if m:IsA("ModuleScript") then
			local ok, mod = pcall(require, m)
			if ok then
				BOSS_MODULES[m.Name] = mod
			else
				warn("[Fogkeeper] chefe com erro: " .. m.Name .. ": " .. tostring(mod))
			end
		end
	end
end

local function angleDiff(a: number, b: number): number
	return (b - a + math.pi) % TAU - math.pi
end

local function moveToward(from: number, to: number, step: number): number
	if math.abs(to - from) <= step then
		return to
	end
	return from + math.sign(to - from) * step
end

local function dist(x: number, y: number): number
	return math.sqrt(x * x + y * y)
end

-- Cobertura de um feixe sobre um ponto com raio r (igual a Beam.covers). O
-- feixe sai de (src.ox, src.oy): o principal sai do faroleiro, o resto do farol.
local function covers(src, x: number, y: number, r: number): boolean
	x -= src.ox or 0
	y -= src.oy or 0
	-- Corte barato primeiro (sem raiz nem atan2): a maioria das criaturas
	-- fica fora do alcance de cada feixe (feixes × criaturas, 30 vezes por s).
	local reach = src.range + r
	local d2 = x * x + y * y
	if d2 > reach * reach then
		return false
	end
	local d = math.sqrt(d2)
	if d < 1 then
		return true
	end
	return math.abs(angleDiff(src.angle, math.atan2(y, x))) <= src.half + math.atan2(r, d)
end

local function average(list: { number }, default: number): number
	if #list == 0 then
		return default
	end
	local s = 0
	for _, v in list do
		s += v
	end
	return s / #list
end

-- Criação --------------------------------------------------------------------

-- config: {mode, mapId, keeper, difficulty, tide, seed}
-- mode: "normal", "daily", "boss_rush" ou "tutorial".
function Sim.new(config)
	local self = setmetatable({}, Sim)
	self.mode = config.mode or "normal"
	self.mapId = config.mapId or "bay"
	self.keeper = config.keeper or "classic"
	self.difficulty = config.difficulty or "normal"
	self.tide = if self.mode == "tutorial" then 0 else (config.tide or 0)
	self.rng = Random.new(config.seed or os.time())
	self.t = 0
	self.started = false
	self.finished = nil -- "victory", "defeat" ou "tutorial"
	self.endless = false
	self.nights = 0
	-- Farol do time
	self.maxHp = Balance.LIGHTHOUSE_MAX_HP
	self.hp = self.maxHp
	self.regen = 0
	self.magnetMult = 1
	self.litSlow = Balance.LIT_SLOW
	self.combustion = 0
	self.emberHeal = 0
	self.emberTide = false
	self.emberLife = Balance.DIFFICULTIES[self.difficulty].emberLife
	self.heroPulse = 0
	-- Relíquias: multiplicadores para todos os feixes e níveis extras.
	self.relics = {}
	self.relic = { dps = 1, range = 1, half = 1, turn = 1, cooldown = 1, lens = 0, sweeper = 0, pulse = 0 }
	-- Progresso da partida
	self.level = 1
	self.xp = 0
	self.xpNeeded = 1
	self.killPoints = 0
	self.kills = 0
	self.bossesDefeated = 0
	self.bossesAlive = 0
	self.enemies = {}
	self.embers = {}
	self.deaths = {} -- {x, y, big}: queimadas desde o último envio
	self.events = {} -- avisos, efeitos e conquistas para o servidor repassar
	self.seenArts = {} -- artes queimadas (bestiário)
	self.damage = {} -- fonte -> dano causado
	self.embersCollected = 0
	self.embersLost = 0
	self.beams = {} -- userId -> feixe do jogador
	self.shared = {} -- níveis das melhorias compartilhadas
	-- Efeitos dos chefes sobre os feixes
	self.inkT, self.inkRange = 0, 1
	self.stoneT, self.stoneTurn = 0, 1
	self.sleepT, self.sleepPower = 0, 1
	self.charmT, self.charmAngle, self.charmPull = 0, 0, 0
	-- Internos
	self.spawning = self.mode ~= "tutorial"
	self.tutorial = nil
	self._history = {}
	self._sources = {}
	self._nextId = 1
	self._spawnTimer = 1
	self._fogTimer = Balance.FOGBANK_START
	self._pulseTimer = 0
	self._pulses = {}
	self._explosions = {}
	self._schedule = {}
	self._eventIndex = 1
	self._hitFxAt = -math.huge
	self._rush = nil
	return self
end

-- Jogadores ------------------------------------------------------------------

function Sim:playerCount(): number
	local n = 0
	for _ in self.beams do
		n += 1
	end
	return math.max(1, n)
end

-- info: {hero, loadout = {3 ids}, meta = {id -> nível}, unlocked = function(id) -> bool}
-- Quem entra no meio da partida recebe as escolhas dos níveis que perdeu;
-- quem sai e volta recupera o próprio feixe.
function Sim:addPlayer(id: number, slot: number, info)
	local saved = self._history[id]
	if saved then
		saved.slot = slot
		self.beams[id] = saved
		saved.pending = math.max(0, self.level - 1 - saved.picks)
		self:_refreshOffer(saved)
		self:_updateXpNeeded()
		return
	end
	local heroId = if Balance.HEROES[info.hero] then info.hero else "keeper"
	local hero = Balance.HEROES[heroId]
	local meta = info.meta or {}
	local b = {
		id = id, slot = slot, hero = heroId, meta = meta, unlocked = info.unlocked or function() return true end,
		angle = self.rng:NextNumber() * TAU, target = nil,
		ox = 0, oy = 0, -- onde o faroleiro está (unidades); o feixe principal sai daqui
		own = {}, picks = 0, pending = 0, offer = nil,
		rerolls = math.max(0, Balance.BASE_REROLLS + (meta.reroll or 0) + Balance.tide(self.tide, "reroll")),
		banishes = Balance.BASE_BANISHES + (meta.banish or 0),
		banished = {},
		cards = Balance.BASE_CARDS + (meta.fourth_card or 0),
		mult = {
			dps = (hero.dps or 1) * (1 + Balance.META_EFFECTS.polish * (meta.polish or 0)),
			range = hero.range or 1,
			half = hero.width or 1,
			turn = 1 + Balance.META_EFFECTS.fine_gears * (meta.fine_gears or 0),
		},
		lens = hero.lens or 0,
		abilities = {}, cooldowns = { 0, 0, 0 }, full = { 1, 1, 1 },
		overchargeT = 0, mirrorT = 0, beaconT = 0, beaconAngle = 0, sweeperAngle = 0,
	}
	b.target = b.angle
	local loadout = info.loadout or Balance.DEFAULT_LOADOUT
	if self.mode == "tutorial" then
		loadout = Balance.DEFAULT_LOADOUT
	end
	for i = 1, 3 do
		local a = Balance.findAbility(loadout[i] or Balance.DEFAULT_LOADOUT[i]) or Balance.findAbility(Balance.DEFAULT_LOADOUT[i])
		b.abilities[i] = a
		b.full[i] = a.cooldown
	end
	b.pending = math.max(0, self.level - 1)
	self.beams[id] = b
	self._history[id] = b
	self:_refreshOffer(b)
	self:_updateXpNeeded()
end

function Sim:removePlayer(id: number)
	self.beams[id] = nil
	self:_updateXpNeeded()
end

function Sim:setAim(id: number, angle: number)
	local b = self.beams[id]
	-- Descarta NaN e infinitos (deixariam o feixe sem ângulo para sempre).
	if b and angle == angle and math.abs(angle) < 1e4 then
		b.target = angle % TAU
	end
end

-- Posição do faroleiro (unidades), lida do avatar pelo servidor. Fora da ilha
-- (mais a folga), fica na borda: ninguém mira de longe da ilha.
function Sim:setOrigin(id: number, x: number, y: number)
	local b = self.beams[id]
	if not b or x ~= x or y ~= y then
		return
	end
	local d = dist(x, y)
	local limit = Balance.ISLAND_RADIUS + Balance.ORIGIN_MARGIN
	if d > limit then
		x, y = x / d * limit, y / d * limit
	end
	b.ox, b.oy = x, y
end

function Sim:_updateXpNeeded()
	local xps = {}
	for _, b in self.beams do
		table.insert(xps, Balance.HEROES[b.hero].xp or 1)
	end
	self.xpNeeded = Balance.xpForLevel(self.level, self.difficulty, self:playerCount(), average(xps, 1))
end

-- Começo da partida: farol do time com dificuldade, maré, oficina e faroleiros.
function Sim:start()
	local d = Balance.DIFFICULTIES[self.difficulty]
	local hpBonus, magnets, wicks = {}, {}, {}
	local pulse = 0
	for _, b in self.beams do
		local hero = Balance.HEROES[b.hero]
		table.insert(hpBonus, Balance.META_EFFECTS.granite * (b.meta.granite or 0) + (hero.hp or 0))
		table.insert(magnets, (1 + Balance.META_EFFECTS.copper * (b.meta.copper or 0)) * (hero.magnet or 1))
		table.insert(wicks, Balance.META_EFFECTS.long_wick * (b.meta.long_wick or 0))
		pulse = math.max(pulse, hero.pulse or 0)
	end
	self.maxHp = math.max(Balance.MIN_LIGHTHOUSE_HP,
		Balance.LIGHTHOUSE_MAX_HP * d.lighthouseHp * Balance.tide(self.tide, "lighthouse") + average(hpBonus, 0))
	self.hp = self.maxHp
	self.magnetMult = average(magnets, 1)
	self.emberLife = (d.emberLife + average(wicks, 0)) * Balance.tide(self.tide, "ember")
	self.heroPulse = pulse
	self.started = true
	self:_buildSchedule()
	self:_updateXpNeeded()
	if self.mode == "boss_rush" then
		self:_startRush()
	elseif self.mode == "tutorial" then
		self.regen = Balance.TUTORIAL_REGEN
		local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
		self.tutorial = Tutorial.new(self)
		self.tutorial:begin()
	end
	-- Oficina: "Pavio aceso" começa com uma melhoria aleatória.
	for _, b in self.beams do
		if (b.meta.head_start or 0) > 0 and self.mode ~= "tutorial" then
			local ids = Upgrades.roll(b.own, self.shared, self.rng, 1, b.banished, b.unlocked)
			self:_applyUpgrade(b, ids[1])
			self:announce("Pavio aceso: %s", { Upgrades.find(ids[1]).name }, GOLD, false)
		end
	end
end

-- Feixes -----------------------------------------------------------------------

-- Atributos do feixe principal de um jogador (sem a Sobrecarga).
function Sim:beamStats(b)
	local own = b.own
	local half = Balance.BEAM_HALF_ANGLE * b.mult.half * 1.2 ^ (own.wide_lens or 0) * (if own.fan then 1.5 else 1) * self.relic.half
	local range = Balance.BEAM_RANGE * b.mult.range * 1.15 ^ (own.long_lens or 0) * (if own.fresnel then 1.25 else 1) * self.relic.range
	local dps = Balance.BEAM_DPS * b.mult.dps * 1.25 ^ (own.intense_flame or 0) * (if own.fresnel then 1.3 else 1) * self.relic.dps
	local turn = Balance.TURN_SPEED * b.mult.turn * 1.25 ^ (own.gears or 0) * self.relic.turn
	if self.inkT > 0 then
		range *= self.inkRange
	end
	if self.sleepT > 0 then
		dps *= self.sleepPower
	end
	if self.stoneT > 0 then
		turn *= self.stoneTurn
	end
	return half, range, dps, turn
end

function Sim:lensCount(b): number
	return 1 + (b.own.twin_lens or 0) + b.lens + self.relic.lens
end

function Sim:sweeperLevel(b): number
	return (b.own.sweeper or 0) + self.relic.sweeper
end

-- Monta a lista de feixes ativos (recalculada a cada passo).
function Sim:_buildSources()
	local list = {}
	for id, b in self.beams do
		local half, range, dps = self:beamStats(b)
		local over = b.overchargeT > 0
		local oc = Balance.findAbility("overcharge")
		table.insert(list, {
			owner = id, main = true, kind = "beam", source = "beam", angle = b.angle, ox = b.ox, oy = b.oy,
			half = if over then half * oc.angle else half,
			range = if over then range * oc.range else range,
			dps = if over then dps * oc.dps else dps,
		})
		local lenses = self:lensCount(b)
		for i = 1, lenses - 1 do
			table.insert(list, { owner = id, main = false, kind = "lens", source = "lens", angle = (b.angle + TAU * i / lenses) % TAU,
				half = half, range = range, dps = dps * (if b.own.crown then 1 else Balance.SECONDARY_LENS_FACTOR) })
		end
		local lvl = self:sweeperLevel(b)
		if lvl > 0 then
			local arms = if b.own.crown then 2 else 1
			for i = 0, arms - 1 do
				table.insert(list, { owner = id, main = false, kind = "sweeper", source = "sweeper",
					angle = (b.sweeperAngle + math.pi * i) % TAU, half = half * Balance.SWEEPER_WIDTH,
					range = range * Balance.SWEEPER_RANGE, dps = dps * (0.35 + 0.15 * lvl) })
			end
		end
		if b.mirrorT > 0 then
			table.insert(list, { owner = id, main = false, kind = "mirror", source = "ability",
				angle = (b.angle + math.pi) % TAU, ox = b.ox, oy = b.oy, half = half, range = range, dps = dps })
		end
		if b.beaconT > 0 then
			local bc = Balance.findAbility("beacon")
			for i = 0, 1 do
				table.insert(list, { owner = id, main = false, kind = "beacon", source = "ability",
					angle = (b.beaconAngle + math.pi * i) % TAU, half = half * bc.angle, range = range * bc.range, dps = dps * bc.dps })
			end
		end
	end
	self._sources = list
end

-- Feixes ativos de todos os jogadores: {owner, main, kind, source, angle, ox, oy, half, range, dps}
-- (ox, oy = origem; ausente = o farol).
function Sim:beamSources()
	return self._sources
end

-- Feixes extras de um jogador, para o atributo BeamsJson ({a, h, r, k}).
function Sim:extraBeams(id: number)
	local out = {}
	for _, s in self._sources do
		if s.owner == id and not s.main then
			table.insert(out, { a = math.round(s.angle * 1000) / 1000, h = math.round(s.half * 1000) / 1000,
				r = math.round(s.range), k = s.kind })
		end
	end
	return out
end

-- API dos chefes ---------------------------------------------------------------

function Sim:announce(text: string, args: { any }?, color: Color3?, big: boolean?)
	table.insert(self.events, { kind = "announce", text = text, args = args or {}, color = color or GOLD, big = big == true })
end

function Sim:fx(name: string, data: { [string]: any }?)
	table.insert(self.events, { kind = "fx", name = name, data = data or {} })
end

-- Conquista para um jogador (userId) ou para todos (nil).
function Sim:_achieve(userId: number?, id: string)
	table.insert(self.events, { kind = "achievement", userId = userId, id = id })
end

function Sim:damageLighthouse(amount: number, quiet: boolean?)
	if amount <= 0 or self.finished then
		return
	end
	self.hp -= amount
	if not quiet and self.t - self._hitFxAt >= HIT_FX_GAP then
		self._hitFxAt = self.t
		self:fx("hit", { amount = amount, fraction = amount / math.max(1, self.maxHp) })
	end
end

function Sim:heal(amount: number)
	self.hp = math.min(self.maxHp, self.hp + amount)
end

-- Tinta do Kraken (e parecidos): encurta o alcance de todos os feixes.
function Sim:ink(seconds: number, rangeFactor: number)
	self.inkT = math.max(self.inkT, seconds)
	self.inkRange = rangeFactor
end

-- Olhar da Medusa: o farol vira pedra e os feixes quase não giram.
function Sim:petrify(seconds: number, turnFactor: number)
	self.stoneT = math.max(self.stoneT, seconds)
	self.stoneTurn = turnFactor
	self:fx("petrify", { seconds = seconds })
end

-- Feitiço da Cuca: a luz adormece e perde força.
function Sim:sleep(seconds: number, power: number)
	self.sleepT = math.max(self.sleepT, seconds)
	self.sleepPower = power
end

-- Canto da Iara: puxa os feixes principais na direção dela. Com (x, y), cada
-- feixe mira o ponto a partir do próprio faroleiro; sem eles, vale `toward`.
function Sim:charm(seconds: number, toward: number, pull: number, x: number?, y: number?)
	self.charmT = math.max(self.charmT, seconds)
	self.charmAngle = toward
	self.charmX, self.charmY = x, y
	self.charmPull = pull
end

-- Empurra as brasas soltas para longe de (x, y) (ou da ilha, sem ponto).
function Sim:pushEmbers(force: number, x: number?, y: number?)
	for _, m in self.embers do
		if not m.pulled then
			local dx, dy = m.x - (x or 0), m.y - (y or 0)
			local d = math.max(dist(dx, dy), 1)
			m.x += dx / d * force
			m.y += dy / d * force
		end
	end
end

function Sim:_newEnemy(role: string, art: string, x: number, y: number, elite: boolean)
	local data = Balance.ENEMIES[role] or Balance.ENEMIES.basic
	local t = self:_spawnTime()
	local e = {
		id = self._nextId, kind = role, art = art, x = x, y = y,
		maxHp = data.hp * Balance.hpMultiplier(t) * self:_value("enemyHp") * (1 + Balance.COOP_ENEMY_HP * (self:playerCount() - 1)),
		speed = data.speed * self:_value("enemySpeed") * self.rng:NextNumber(0.9, 1.1),
		radius = data.radius, damage = data.damage * self:_value("enemyDamage"),
		xp = data.xp, score = data.score, elite = elite,
		lit = 0, stun = 0, attackCd = 0, hidden = false, time = 0,
		phase = self.rng:NextNumber() * TAU, lateral = if role == "boulder" then 0 else self.rng:NextNumber(-1, 1),
		carry = 0, fleeing = false, reflecting = false, cycle = 0, open = 0, growth = 0, driftX = 0, driftY = 0,
		visual = 0, aux = 0, scale = 1,
	}
	if elite then
		e.maxHp *= Balance.ELITE.hp
		e.damage *= Balance.ELITE.damage
		e.radius *= Balance.ELITE.radius
		e.xp *= Balance.ELITE.xp
		e.score *= Balance.ELITE.score
		e.scale = Balance.ELITE.radius
	end
	e.hp = e.maxHp
	e.baseRadius, e.baseDamage, e.baseXp = e.radius, e.damage, e.xp
	if role == "mirror" then
		e.reflecting = true
		e.cycle = self.rng:NextNumber(0.5, Balance.MIRROR_CLOSED)
	elseif role == "fogbank" then
		-- Atravessa o mapa passando perto da ilha.
		local a = self.rng:NextNumber() * TAU
		local r = self.rng:NextNumber(100, 240)
		local tx, ty = math.cos(a) * r - x, math.sin(a) * r - y
		local d = math.max(dist(tx, ty), 1)
		e.driftX, e.driftY = tx / d, ty / d
	end
	self._nextId += 1
	table.insert(self.enemies, e)
	return e
end

-- Lacaio com o papel dado e a arte do mapa atual.
function Sim:spawnMinion(role: string, x: number, y: number)
	return self:_newEnemy(role, Maps.artFor(self.mapId, role) or role, x, y, false)
end

-- Criatura (ou parte de chefe) com arte própria.
function Sim:spawnArt(art: string, role: string, x: number, y: number)
	return self:_newEnemy(role, art, x, y, false)
end

function Sim:spawnRing(role: string, distance: number?)
	local a = self.rng:NextNumber() * TAU
	local r = distance or Balance.SPAWN_RING
	local canElite = role ~= "tentacle" and role ~= "boulder" and role ~= "fogbank"
	local elite = canElite and self.rng:NextNumber() < self:_value("elite")
	return self:_newEnemy(role, Maps.artFor(self.mapId, role) or role, math.cos(a) * r, math.sin(a) * r, elite)
end

function Sim:stun(e, seconds: number)
	if e.boss then
		seconds *= BossData.STUN_FACTOR
		local mod = BOSS_MODULES[e.kind]
		if mod and mod.stunned then
			mod.stunned(self, e, seconds)
		end
	end
	e.stun = math.max(e.stun, seconds)
	if e.kind == "mirror" then
		-- O Clarão abre o espelho.
		e.reflecting = false
		e.cycle = math.max(e.cycle, seconds + Balance.MIRROR_OPEN)
	end
end

-- Dano de luz numa criatura vindo de `src` (feixe, pulso, habilidade...).
-- Espelhos fechados devolvem parte do feixe principal; chefes podem resistir.
function Sim:_light(e, amount: number, src)
	if e.hidden or e.hp <= 0 then
		return
	end
	e.lit = Balance.LIT_TIME
	if e.parent then
		return -- partes de chefe: o chefe decide o que a luz faz
	end
	if e.boss then
		e._litAt = self.t
		local mod = BOSS_MODULES[e.kind]
		if mod and mod.lightFactor then
			amount *= mod.lightFactor(self, e, src)
		end
	elseif e.reflecting then
		if src.main then
			self:damageLighthouse(amount * Balance.MIRROR_REFLECT, true)
			e.reflectFx = 0.15
		end
		return
	end
	if amount <= 0 then
		return
	end
	e.hp -= amount
	self.damage[src.source] = (self.damage[src.source] or 0) + amount
end

-- Chefes ----------------------------------------------------------------------

function Sim:spawnBoss(id: string)
	local data = BossData.BOSSES[id]
	local mod = BOSS_MODULES[id]
	if not data or not mod then
		warn("[Fogkeeper] chefe desconhecido: " .. tostring(id))
		return nil
	end
	local t = self:_spawnTime()
	local hpMult = Balance.hpMultiplier(t) * self:_value("enemyHp")
	local e = self:_newEnemy("basic", id, 0, 0, false)
	e.kind = id
	e.boss = data
	e.maxHp = data.hp * (1 + (hpMult - 1) * 0.5) * (1 + Balance.COOP_BOSS_HP * (self:playerCount() - 1))
	if self.mode == "tutorial" then
		e.maxHp *= Balance.TUTORIAL_BOSS_HP
	end
	e.hp = e.maxHp
	e.speed = data.speed * self:_value("enemySpeed")
	e.radius = data.radius
	e.damage = data.damage * self:_value("enemyDamage")
	e.xp = data.xp
	e.score = 0
	e.lateral = 0
	e.enraged = false
	e.canEnrage = Balance.DIFFICULTIES[self.difficulty].enrage or self.tide >= Balance.TIDE_ALWAYS_ENRAGE
	e.enrageAt = Balance.tide(self.tide, "enrage")
	e.rate = function(): number
		return if e.enraged then BossData.ENRAGE_SPEED else 1
	end
	e.litFactor = function(): number
		if e.lit <= 0 then
			return 1
		end
		return 1 + (self.litSlow - 1) * BossData.LIT_SLOW_FACTOR
	end
	mod.begin(self, e, self.rng:NextNumber() * TAU)
	self.bossesAlive += 1
	self:announce("%s emergiu!", { Maps.CREATURE_NAMES[id] or id }, DANGER, true)
	self:fx("boss", { id = id, x = e.x, y = e.y })
	return e
end

-- Relíquia deixada por um chefe derrotado (efeitos em BossData.RELICS).
function Sim:applyRelic(id: string)
	table.insert(self.relics, id)
	local r = self.relic
	if id == "leviathan" then
		self.maxHp += 40
		self.hp = self.maxHp
	elseif id == "kraken" then
		r.range *= 1.2
	elseif id == "jotunn" then
		self.litSlow *= 0.7
	elseif id == "fenrir" then
		r.turn *= 1.3
		r.dps *= 1.15
	elseif id == "iara" then
		self.magnetMult *= 1.5
		self.regen += 0.5
	elseif id == "boitata" then
		r.dps *= 1.25
	elseif id == "cuca" then
		r.cooldown *= 0.7
	elseif id == "umibozu" then
		r.lens += 1
	elseif id == "kyubi" then
		r.dps *= 1.2
		r.turn *= 1.15
	elseif id == "sphinx" then
		r.pulse += 1
	elseif id == "apep" then
		self.litSlow *= 0.75
		r.range *= 1.1
	elseif id == "scylla" then
		r.sweeper += 1
	elseif id == "medusa" then
		self.maxHp += 30
		self:heal(30)
		self.litSlow *= 0.8
	elseif id == "balor" then
		r.half *= 1.15
		r.dps *= 1.2
	elseif id == "cailleach" then
		self.magnetMult *= 1.3
		r.cooldown *= 0.85
	end
end

function Sim:_bossKilled(e)
	self.bossesDefeated += 1
	self.bossesAlive = math.max(0, self.bossesAlive - 1)
	local mod = BOSS_MODULES[e.kind]
	if mod and mod.died then
		mod.died(self, e)
	end
	self:applyRelic(e.kind)
	if Balance.tide(self.tide, "noHeal") <= 0 then
		self:heal(Balance.BOSS_HEAL)
	end
	local relic = BossData.RELICS[e.kind] or { name = e.kind, desc = "" }
	self:announce("%s derrotado! Relíquia: %s — %s", { Maps.CREATURE_NAMES[e.kind] or e.kind, relic.name, relic.desc }, RELIC, false)
	self:fx("boss_down", { id = e.kind, x = e.x, y = e.y })
	self:fx("relic", { id = e.kind })
	self:_achieve(nil, "boss_" .. e.kind)
	if self._rush then
		self._rush.wait = Balance.BOSS_RUSH_PAUSE
	end
end

-- Agenda e modos -----------------------------------------------------------------

-- Valor de uma regra da dificuldade, com a maré (igual a Spawner._value).
function Sim:_value(key: string): number
	local t = self:_spawnTime()
	local v = Balance.difficultyValue(self.difficulty, key, t)
	if key == "enemySpeed" then
		v *= Balance.tide(self.tide, "speed")
	elseif key == "enemyHp" then
		v *= Balance.tide(self.tide, "hp")
	elseif key == "elite" and t >= Balance.ELITE_START then
		v += Balance.tide(self.tide, "elite")
	end
	return v
end

-- "Tempo" que define a força das criaturas comuns (no Modo Chefões cresce por chefe).
function Sim:_spawnTime(): number
	if self._rush then
		return math.min(Balance.BOSS_RUSH_BASE_TIME + Balance.BOSS_RUSH_TIME_PER_BOSS * self.bossesDefeated, Balance.BOSS_RUSH_MAX_TIME)
	end
	return self.t
end

function Sim:_buildSchedule()
	self._schedule = {}
	if self.mode == "boss_rush" or self.mode == "tutorial" then
		return
	end
	for i, at in BossData.TIMES do
		local t = math.max(Balance.BOSS_EARLIEST, at - Balance.tide(self.tide, "bossEarly"))
		table.insert(self._schedule, { t = t, boss = Maps.bossAt(self.mapId, i), warned = false, spawned = false })
	end
	if Balance.DIFFICULTIES[self.difficulty].extraBoss then
		table.insert(self._schedule, { t = BossData.EXTRA_TIME, boss = Maps.bossAt(self.mapId, 3), warned = false, spawned = false })
	end
	table.sort(self._schedule, function(a, b)
		return a.t < b.t
	end)
end

-- Próximo chefe ainda por vir: {boss, t} ou nil.
function Sim:nextBoss()
	for _, s in self._schedule do
		if not s.spawned then
			return s
		end
	end
	return nil
end

-- Modo Chefões: todos os chefes, mapa por mapa.
function Sim:_startRush()
	local queue = {}
	for _, m in Maps.ORDER do
		for _, boss in Maps.get(m).bosses do
			table.insert(queue, { map = m, boss = boss })
		end
	end
	self._rush = { queue = queue, wait = Balance.BOSS_RUSH_FIRST, total = #queue }
	self.level = 1 + Balance.BOSS_RUSH_START_PICKS
	self:_updateXpNeeded()
	for _, b in self.beams do
		b.pending = math.max(0, self.level - 1 - b.picks) -- as escolhas iniciais contam como os níveis 2..7
		self:_refreshOffer(b)
	end
	self:announce("Modo Chefões: %d chefes até o fim", { #queue }, DANGER, true)
end

function Sim:rushTotal(): number
	return if self._rush then self._rush.total else 0
end

function Sim:_rushStep(dt: number)
	local rush = self._rush
	if self.bossesAlive > 0 then
		return
	end
	if #rush.queue == 0 then
		if self.bossesDefeated > 0 then
			self.finished = "victory"
		end
		return
	end
	rush.wait -= dt
	if rush.wait > 0 then
		return
	end
	local nextBoss = table.remove(rush.queue, 1)
	if nextBoss.map ~= self.mapId then
		self.mapId = nextBoss.map
		self:fx("map", { map = nextBoss.map })
		self:announce(Maps.get(nextBoss.map).name, nil, GOLD, false)
	end
	self:announce("%s se aproxima!", { Maps.CREATURE_NAMES[nextBoss.boss] or nextBoss.boss }, DANGER, true)
	self:spawnBoss(nextBoss.boss)
	rush.wait = Balance.BOSS_RUSH_PAUSE
end

-- Depois do amanhecer: a névoa volta e a partida segue noite adentro.
function Sim:continueEndless()
	self.endless = true
	self.finished = nil
	self._eventIndex = 1
	self._fogTimer = math.min(self._fogTimer, self.t + Balance.ENDLESS_FOGBANK_EVERY)
	self._schedule = {}
	local bosses = Maps.get(self.mapId).bosses
	for i = 0, 39 do
		table.insert(self._schedule, { t = self.t + Balance.ENDLESS_BOSS_FIRST + i * Balance.ENDLESS_BOSS_EVERY,
			boss = bosses[i % #bosses + 1], warned = false, spawned = false })
	end
end

-- Hora do ciclo do dia (segundos de noite, 0..600) para o céu e o relógio.
function Sim:cycleSeconds(): number
	if self.mode == "tutorial" then
		return Balance.TUTORIAL_CLOCK
	elseif self.mode == "boss_rush" then
		return Balance.BOSS_RUSH_CLOCK
	elseif self.endless then
		return (self.t - Balance.RUN_DURATION) % Balance.RUN_DURATION
	end
	return math.min(self.t, Balance.RUN_DURATION)
end

-- Comandos dos jogadores ------------------------------------------------------------

function Sim:useAbility(id: number, index: number): boolean
	local b = self.beams[id]
	local a = b and b.abilities[index]
	if not a or b.cooldowns[index] > 0 or self.finished then
		return false
	end
	b.full[index] = a.cooldown * self.relic.cooldown
	b.cooldowns[index] = b.full[index]
	local src = { owner = id, main = false, kind = "ability", source = "ability", angle = 0, half = math.pi, range = math.huge, dps = 0 }
	if a.id == "flash" then
		for _, e in table.clone(self.enemies) do
			if dist(e.x, e.y) - e.radius <= a.radius then
				-- Atordoa antes do dano: o Clarão apaga o Boitatá e abre o espelho.
				self:stun(e, a.stun)
				self:_light(e, a.damage, src)
			end
		end
		self:fx("flash", { radius = a.radius })
	elseif a.id == "overcharge" then
		b.overchargeT = a.duration
		self:fx("overcharge", { owner = id })
	elseif a.id == "bell" then
		for _, m in self.embers do
			m.pulled = true
		end
		self:heal(a.heal)
		self:fx("bell", {})
	elseif a.id == "mirror" then
		b.mirrorT = a.duration
		self:fx("mirror", { owner = id })
	elseif a.id == "tide" then
		for _, e in self.enemies do
			local d = dist(e.x, e.y)
			if not e.parent and d - e.radius <= a.radius and d > 1 then
				-- Chefes resistem: são empurrados só um pouco.
				local push = a.push * (if e.boss then Balance.BOSS_PUSH else 1)
				e.x += e.x / d * push
				e.y += e.y / d * push
				self:stun(e, a.stun)
			end
		end
		self:fx("tide", { radius = a.radius })
	elseif a.id == "beacon" then
		b.beaconT = a.duration
		b.beaconAngle = b.angle
		self:fx("beacon", { owner = id })
	end
	if self.tutorial then
		self.tutorial:onAbility(index)
	end
	return true
end

-- Retorna true se a escolha valeu.
function Sim:pick(id: number, upgradeId: string): boolean
	local b = self.beams[id]
	if not b or b.pending <= 0 or not b.offer or not table.find(b.offer, upgradeId) then
		return false
	end
	local u = Upgrades.find(upgradeId)
	if Upgrades.level(upgradeId, b.own, self.shared) >= u.max then
		-- Outro jogador levou esta melhoria do time ao máximo: sorteia de novo.
		b.offer = nil
		self:_refreshOffer(b)
		return true
	end
	self:_applyUpgrade(b, upgradeId)
	b.pending -= 1
	b.picks += 1
	b.offer = nil
	self:_refreshOffer(b)
	-- Ofertas dos outros com uma melhoria do time já no máximo são refeitas.
	if u.scope == "shared" and (self.shared[upgradeId] or 0) >= u.max then
		for _, other in self.beams do
			if other.offer and table.find(other.offer, upgradeId) then
				other.offer = nil
				self:_refreshOffer(other)
			end
		end
	end
	if self.tutorial then
		self.tutorial:onUpgrade()
	end
	return true
end

function Sim:reroll(id: number): boolean
	local b = self.beams[id]
	if not b or b.rerolls <= 0 or b.pending <= 0 then
		return false
	end
	b.rerolls -= 1
	b.offer = nil
	self:_refreshOffer(b)
	return true
end

function Sim:banish(id: number, upgradeId: string): boolean
	local b = self.beams[id]
	if not b or b.banishes <= 0 or b.pending <= 0 or not b.offer or not table.find(b.offer, upgradeId)
		or Upgrades.isEvolution(upgradeId) or upgradeId == Upgrades.FALLBACK.id then
		return false
	end
	b.banishes -= 1
	b.banished[upgradeId] = true
	self:announce("%s banida desta partida.", { Upgrades.find(upgradeId).name }, DIM, false)
	b.offer = nil
	self:_refreshOffer(b)
	return true
end

function Sim:_refreshOffer(b)
	if b.pending > 0 and not b.offer then
		b.offer = Upgrades.roll(b.own, self.shared, self.rng, b.cards, b.banished, b.unlocked)
	end
end

function Sim:_applyUpgrade(b, id: string)
	local u = Upgrades.find(id)
	if not u then
		return
	end
	if u.scope == "own" then
		b.own[id] = (b.own[id] or 0) + 1
	elseif id ~= Upgrades.FALLBACK.id then
		self.shared[id] = (self.shared[id] or 0) + 1
	end
	if id == "walls" then
		self.maxHp += 25
		self:heal(25)
	elseif id == "repairs" then
		self.regen += 0.6
	elseif id == "magnet" then
		self.magnetMult *= 1.4
	elseif id == "combustion" then
		self.combustion += 1
	elseif id == "vital_embers" then
		self.emberHeal += Balance.VITAL_EMBER_HEAL
	elseif id == "fresh_oil" then
		self:heal(30)
	elseif id == "ember_tide" then
		self.emberTide = true
	elseif id == "bastion" then
		self.maxHp += 50
		self.hp = self.maxHp
		self.regen = math.max(1, self.regen * 2)
	elseif id == "fan" then
		self.litSlow *= 0.75
	end
	if Upgrades.isEvolution(id) then
		self:announce("Evolução: %s!", { u.name }, EVOLUTION, true)
		self:_achieve(b.id, "evolution")
		self:fx("evolution", { owner = b.id, id = id })
	end
end

-- Passo da simulação -----------------------------------------------------------

function Sim:step(dt: number)
	if self.finished or not self.started then
		return
	end
	self.t += dt
	if self.regen > 0 then
		self:heal(self.regen * dt)
	end
	self.inkT = math.max(0, self.inkT - dt)
	self.stoneT = math.max(0, self.stoneT - dt)
	self.sleepT = math.max(0, self.sleepT - dt)
	self.charmT = math.max(0, self.charmT - dt)
	self:_beamsStep(dt)
	self:_buildSources()
	if self._rush then
		self:_rushStep(dt)
	end
	if self.spawning then
		self:_spawnStep(dt)
	end
	self:_lightStep(dt)
	self:_pulseStep(dt)
	self:_enemiesStep(dt)
	self:_deathsStep()
	self:_explosionsStep()
	self:_deathsStep()
	self:_embersStep(dt)
	self:_levelStep()
	if self.tutorial then
		self.tutorial:tick(dt)
	else
		self:_dayEvents()
	end
	self:_checkEnd()
end

function Sim:_checkEnd()
	if self.finished then
		return
	end
	if self.hp <= 0 then
		if self.tutorial then
			self.hp = self.maxHp
			self:announce("O farol foi reacendido. Tente de novo!", nil, GOLD, false)
			return
		end
		self.hp = 0
		self.finished = "defeat"
		return
	end
	if self.mode == "boss_rush" or self.tutorial then
		return
	end
	if self.endless then
		if self.t >= Balance.RUN_DURATION * (self.nights + 2) then
			self.nights += 1
			self._eventIndex = 1
			self:announce("Noite %d sobrevivida! +%s pontos", { self.nights + 1, "4.000" }, GOOD, true)
			self:_achieve(nil, "endless")
		end
	elseif self.t >= Balance.RUN_DURATION then
		self.finished = "victory"
		-- O sol nasce: as criaturas se desfazem.
		table.clear(self.enemies)
		self.bossesAlive = 0
	end
end

-- Avisos de clima do mapa (Maps.EVENTS) conforme a noite passa.
function Sim:_dayEvents()
	if self.mode == "boss_rush" then
		return
	end
	local events = Maps.EVENTS and Maps.EVENTS[self.mapId]
	if not events then
		return
	end
	local f = self:cycleSeconds() / Balance.RUN_DURATION
	while self._eventIndex <= #events and f >= events[self._eventIndex].at do
		self:announce(events[self._eventIndex].text, nil, GOLD, false)
		self._eventIndex += 1
	end
end

function Sim:_spawnStep(dt: number)
	local t = self:_spawnTime()
	self._spawnTimer -= dt
	if self._spawnTimer <= 0 then
		local rate = self:_value("spawn") * (1 + Balance.COOP_SPAWN * (self:playerCount() - 1))
		self._spawnTimer += Balance.spawnInterval(t) / rate
		for _ = 1, Balance.groupSize(t) do
			if #self.enemies < Balance.MAX_ENEMIES then
				self:spawnRing(self:_pickRole(t))
			end
		end
	end
	if t >= self._fogTimer then
		self._fogTimer = t + (if self.endless then Balance.ENDLESS_FOGBANK_EVERY else Balance.FOGBANK_EVERY)
		self:spawnRing("fogbank")
	end
	for _, s in self._schedule do
		if not s.warned and self.t >= s.t - BossData.WARNING then
			s.warned = true
			self:announce("%s se aproxima!", { Maps.CREATURE_NAMES[s.boss] or s.boss }, DANGER, true)
			self:fx("boss_warning", { id = s.boss })
		end
		if not s.spawned and self.t >= s.t then
			s.spawned = true
			self:spawnBoss(s.boss)
		end
	end
end

function Sim:_pickRole(t: number): string
	local w = Balance.spawnWeights(t)
	local total = 0
	for _, v in w do
		total += v
	end
	local r = self.rng:NextNumber() * total
	for kind, v in w do
		r -= v
		if r <= 0 then
			return kind
		end
	end
	return "basic"
end

function Sim:_beamsStep(dt: number)
	local spin = Balance.SWEEPER_SPEED
	local beacon = Balance.findAbility("beacon")
	for _, b in self.beams do
		for i = 1, 3 do
			b.cooldowns[i] = math.max(0, b.cooldowns[i] - dt)
		end
		b.overchargeT = math.max(0, b.overchargeT - dt)
		b.mirrorT = math.max(0, b.mirrorT - dt)
		b.beaconT = math.max(0, b.beaconT - dt)
		if b.beaconT > 0 then
			b.beaconAngle = (b.beaconAngle + beacon.spin * dt) % TAU
		end
		local lvl = self:sweeperLevel(b)
		if lvl > 0 then
			b.sweeperAngle = (b.sweeperAngle + spin * (1 + 0.25 * (lvl - 1)) * dt) % TAU
		end
		-- O cliente gira o feixe na hora; o servidor segue, até um limite de velocidade.
		local _, _, _, turn = self:beamStats(b)
		local step = turn * Balance.AIM_TOLERANCE * dt
		b.angle = (b.angle + math.clamp(angleDiff(b.angle, b.target), -step, step)) % TAU
		if self.charmT > 0 then
			-- Canto da Iara: a mira é puxada para ela.
			local pull = self.charmPull * dt
			local toward = self.charmAngle
			if self.charmX and self.charmY then
				toward = math.atan2(self.charmY - b.oy, self.charmX - b.ox)
			end
			b.angle = (b.angle + math.clamp(angleDiff(b.angle, toward), -pull, pull)) % TAU
			b.target = b.angle
		end
	end
end

function Sim:_lightStep(dt: number)
	for _, e in self.enemies do
		e.lit = math.max(0, e.lit - dt)
		e.reflectFx = math.max(0, (e.reflectFx or 0) - dt)
	end
	for _, src in self._sources do
		for _, e in self.enemies do
			if not e.hidden and e.hp > 0 and covers(src, e.x, e.y, e.radius) then
				self:_light(e, src.dps * dt, src)
			end
		end
		for _, m in self.embers do
			if not m.pulled and covers(src, m.x, m.y, 6) then
				m.pulled = true
			end
		end
	end
	-- Fúria dos chefes com metade (ou mais, nas marés altas) da vida.
	for _, e in self.enemies do
		if e.boss and e.canEnrage and not e.enraged and e.hp > 0 and e.hp < e.maxHp * e.enrageAt then
			e.enraged = true
			self:announce("%s está enfurecido!", { Maps.CREATURE_NAMES[e.kind] or e.kind }, DANGER, false)
			self:fx("enrage", { id = e.kind, x = e.x, y = e.y })
		end
	end
end

-- Pulso de luz: onda que se expande do farol e atinge cada criatura uma vez.
function Sim:pulseLevel(): number
	return (self.shared.pulse or 0) + self.heroPulse + self.relic.pulse
end

function Sim:_pulseStep(dt: number)
	local lvl = self:pulseLevel()
	if lvl > 0 then
		self._pulseTimer -= dt
		if self._pulseTimer <= 0 then
			self._pulseTimer = Balance.pulseCooldown(lvl)
			local radius = Balance.PULSE_RADIUS + Balance.PULSE_RADIUS_PER_LEVEL * lvl
			local damage = Balance.PULSE_DAMAGE * (1 + Balance.PULSE_DAMAGE_PER_LEVEL * (lvl - 1)) * self.relic.dps
			table.insert(self._pulses, { t = 0, radius = radius, damage = damage, hit = {} })
			if self.emberTide then
				for _, m in self.embers do
					m.pulled = true
				end
			end
			self:fx("pulse", { radius = radius })
		end
	end
	local src = { owner = nil, main = false, kind = "pulse", source = "pulse", angle = 0, half = math.pi, range = math.huge, dps = 0 }
	for i = #self._pulses, 1, -1 do
		local p = self._pulses[i]
		p.t += dt
		local r = p.radius * math.min(1, p.t / Balance.PULSE_DURATION)
		for _, e in self.enemies do
			if not p.hit[e.id] and dist(e.x, e.y) - e.radius <= r then
				p.hit[e.id] = true
				self:_light(e, p.damage, src)
			end
		end
		if p.t >= Balance.PULSE_DURATION then
			table.remove(self._pulses, i)
		end
	end
end

function Sim:_enemiesStep(dt: number)
	-- Cópia: chefes criam lacaios durante o laço.
	for _, e in table.clone(self.enemies) do
		if e.hp <= 0 then
			continue
		end
		e.time += dt
		self:_roleStep(e, dt)
		if e.parent then
			continue -- partes de chefe: o chefe posiciona
		end
		if e.stun > 0 then
			e.stun -= dt
			continue
		end
		if e.boss then
			local mod = BOSS_MODULES[e.kind]
			mod.step(self, e, dt)
			continue
		end
		if e.kind == "thief" then
			self:_thiefStep(e, dt)
		elseif e.kind == "decoy" then
			-- Ilusão da Kyūbi: circula como ela, sem se aproximar.
			local d = dist(e.x, e.y)
			local a = math.atan2(e.y, e.x) + e.speed * dt
			e.x, e.y = math.cos(a) * d, math.sin(a) * d
			e.facing = a + math.pi / 2
		elseif e.kind == "fogbank" then
			e.x += e.driftX * e.speed * dt
			e.y += e.driftY * e.speed * dt
			e.facing = math.atan2(e.driftY, e.driftX)
			if dist(e.x, e.y) > Balance.ESCAPE_DIST and e.x * e.driftX + e.y * e.driftY > 0 then
				e.escaped = true
				e.hp = 0
			end
		else
			self:_approach(e, dt)
		end
		self:_melee(e, dt)
	end
end

-- Estado de cada papel especial (igual a Enemy._update_role).
function Sim:_roleStep(e, dt: number)
	if e.kind == "mirror" then
		e.cycle -= dt
		if e.cycle <= 0 then
			e.reflecting = not e.reflecting
			e.cycle = if e.reflecting then Balance.MIRROR_CLOSED else Balance.MIRROR_OPEN
		end
		e.open = moveToward(e.open, if e.reflecting then 0 else 1, dt * 5)
		e.visual = e.open * 255
		e.aux = if (e.reflectFx or 0) > 0 then 1 else 0
	elseif e.kind == "moth" then
		if e.lit > 0 then
			e.growth = math.min(Balance.MOTH_MAX, e.growth + Balance.MOTH_GROW * dt)
		end
		e.radius = e.baseRadius * (1 + 0.35 * e.growth)
		e.damage = e.baseDamage * (1 + 0.6 * e.growth)
		e.xp = math.round(e.baseXp * (1 + e.growth * 1.5))
		e.scale = e.radius / Balance.ENEMIES.moth.radius
		e.visual = e.growth / Balance.MOTH_MAX * 255
	elseif e.kind == "fogbank" then
		e.radius = e.baseRadius * (0.35 + 0.65 * math.max(0, e.hp) / e.maxHp)
		e.scale = e.radius / e.baseRadius
		e.visual = math.max(0, e.hp) / e.maxHp * 255
		for _, m in self.embers do
			if not m.pulled and dist(m.x - e.x, m.y - e.y) < e.radius then
				m.life -= dt * (Balance.FOGBANK_DRAIN - 1)
			end
		end
	elseif e.kind == "thief" then
		e.aux = e.carry
	end
end

-- Movimento padrão: avança até o farol, ondulando para os lados. A luz
-- desacelera, menos a mariposa, que acelera.
function Sim:_approach(e, dt: number)
	local d = dist(e.x, e.y)
	local reach = e.radius + Balance.LIGHTHOUSE_RADIUS
	if d <= reach then
		return
	end
	local dx, dy = -e.x / d, -e.y / d
	local wave = math.sin(e.time * 2 + e.phase) * 0.4 * e.lateral
	local mx, my = dx - dy * wave, dy + dx * wave
	local m = math.max(dist(mx, my), 1e-6)
	local speed = e.speed * (if e.lit > 0 then self.litSlow else 1)
	if e.kind == "moth" and e.lit > 0 then
		speed = e.speed * Balance.MOTH_LIT_SPEED
	end
	e.x += mx / m * speed * dt
	e.y += my / m * speed * dt
	local nd = dist(e.x, e.y)
	if nd < reach then
		e.x, e.y = e.x / nd * reach, e.y / nd * reach
	end
end

function Sim:_melee(e, dt: number)
	if Balance.NO_MELEE[e.kind] or e.escaped then
		return
	end
	if dist(e.x, e.y) > e.radius + Balance.LIGHTHOUSE_RADIUS + 0.5 then
		return
	end
	e.attackCd -= dt
	if e.attackCd <= 0 then
		e.attackCd = Balance.ATTACK_INTERVAL
		self:damageLighthouse(e.damage)
		if e.kind == "boulder" then
			e.escaped = true -- a pedra se despedaça ao acertar (sem recompensa)
			e.hp = 0
		end
	end
end

-- A ladra busca a brasa solta mais próxima; com o bolso cheio (ou sem
-- paciência) foge para a névoa levando tudo.
function Sim:_thiefStep(e, dt: number)
	local slow = if e.lit > 0 then self.litSlow else 1
	if not e.fleeing and (e.carry >= Balance.THIEF_CARRY or e.time > Balance.THIEF_PATIENCE) then
		e.fleeing = true
	end
	local d = math.max(dist(e.x, e.y), 1)
	if e.fleeing then
		e.x += e.x / d * e.speed * 1.15 * slow * dt
		e.y += e.y / d * e.speed * 1.15 * slow * dt
		e.facing = math.atan2(e.y, e.x)
		if dist(e.x, e.y) > Balance.ESCAPE_DIST then
			e.escaped = true
			e.hp = 0
			if e.carry > 0 then
				self.embersLost += e.carry
				self:announce("%s fugiu com %d brasas!", { Maps.CREATURE_NAMES[e.art] or e.art, e.carry }, DIM, false)
			end
			if self.tutorial then
				self.tutorial:onEscape(e)
			end
		end
		return
	end
	local best, bestD = nil, Balance.THIEF_SIGHT
	for _, m in self.embers do
		if not m.pulled and not m.taken then
			local md = dist(m.x - e.x, m.y - e.y)
			if md < bestD then
				best, bestD = m, md
			end
		end
	end
	if not best then
		-- Sem brasas à vista: ronda a ilha esperando.
		local radial = math.clamp((d - 300) / 60, -1, 1)
		local tx, ty = -e.y / d * 0.7 - e.x / d * radial, e.x / d * 0.7 - e.y / d * radial
		local tm = math.max(dist(tx, ty), 1e-6)
		e.x += tx / tm * e.speed * 0.6 * slow * dt
		e.y += ty / tm * e.speed * 0.6 * slow * dt
		return
	end
	if bestD <= e.radius + 8 then
		best.taken = true
		e.carry += best.value
		self:fx("steal", { x = best.x, y = best.y })
		return
	end
	e.x += (best.x - e.x) / bestD * e.speed * slow * dt
	e.y += (best.y - e.y) / bestD * e.speed * slow * dt
end

function Sim:_dropEmbers(x: number, y: number, pieces: number, values: { number })
	for i = 1, pieces do
		if #self.embers >= Balance.MAX_EMBERS then
			return
		end
		local ox, oy = 0, 0
		if pieces > 1 then
			local a = TAU * (i - 1) / pieces
			ox, oy = math.cos(a) * 30, math.sin(a) * 30
		end
		local a = self.rng:NextNumber() * TAU
		table.insert(self.embers, {
			id = self._nextId, x = x + ox, y = y + oy, value = values[i] or 1,
			life = self.emberLife, pulled = false, vx = math.cos(a) * 30, vy = math.sin(a) * 30,
		})
		self._nextId += 1
	end
end

-- Criaturas queimadas: pontos, brasas, bestiário, relíquias e combustão.
function Sim:_deathsStep()
	for i = #self.enemies, 1, -1 do
		local e = self.enemies[i]
		if e.hp <= 0 then
			table.remove(self.enemies, i)
			if not e.escaped and not e.noScore then
				self:_killed(e)
			end
		end
	end
end

function Sim:_killed(e)
	self.kills += 1
	self.seenArts[e.art] = true
	if #self.deaths < 64 then
		table.insert(self.deaths, { x = e.x, y = e.y, big = e.boss ~= nil or e.elite or e.radius >= 18 })
	end
	if e.boss then
		self:_bossKilled(e)
	else
		self.killPoints += e.score
	end
	local pieces = if e.boss then Balance.BOSS_EMBERS else 1
	local values = {}
	if e.kind == "thief" and e.carry > 0 then
		pieces = 1 + math.min(e.carry, 10)
		self:_achieve(nil, "thief")
	end
	for k = 1, pieces do
		if e.boss then
			values[k] = math.max(1, e.xp // pieces)
		else
			values[k] = if k == 1 then e.xp else 1
		end
	end
	if e.xp > 0 or pieces > 1 then
		self:_dropEmbers(e.x, e.y, pieces, values)
	end
	if self.combustion > 0 then
		table.insert(self._explosions, { x = e.x, y = e.y, level = self.combustion })
	end
	if self.tutorial then
		self.tutorial:onKill(e)
	end
end

-- Combustão: a criatura queimada explode e fere as vizinhas.
function Sim:_explosionsStep()
	if #self._explosions == 0 then
		return
	end
	local list = self._explosions
	self._explosions = {}
	local src = { owner = nil, main = false, kind = "combustion", source = "combustion", angle = 0, half = math.pi, range = math.huge, dps = 0 }
	for _, x in list do
		local r = Balance.COMBUSTION_RADIUS + Balance.COMBUSTION_RADIUS_PER_LEVEL * x.level
		local dmg = Balance.COMBUSTION_DAMAGE * x.level * self.relic.dps
		for _, e in self.enemies do
			if not e.boss and not e.parent and e.hp > 0 and dist(e.x - x.x, e.y - x.y) <= r + e.radius then
				self:_light(e, dmg, src)
			end
		end
		if self.t - (self._combustionFxAt or -math.huge) >= COMBUSTION_FX_GAP then
			self._combustionFxAt = self.t
			self:fx("combustion", { x = x.x, y = x.y, radius = r })
		end
	end
end

function Sim:_embersStep(dt: number)
	local magnet = Balance.MAGNET_RADIUS * self.magnetMult
	for i = #self.embers, 1, -1 do
		local m = self.embers[i]
		local d = dist(m.x, m.y)
		if m.taken then
			table.remove(self.embers, i)
		elseif not m.pulled and d < magnet then
			m.pulled = true
		end
		if m.taken then
			continue
		end
		if m.pulled then
			local k = math.min(1, dt * 6)
			local dx, dy = -m.x / math.max(d, 1), -m.y / math.max(d, 1)
			m.vx += (dx * Balance.EMBER_PULL_SPEED - m.vx) * k
			m.vy += (dy * Balance.EMBER_PULL_SPEED - m.vy) * k
			m.x += m.vx * dt
			m.y += m.vy * dt
			if dist(m.x, m.y) < Balance.LIGHTHOUSE_RADIUS then
				table.remove(self.embers, i)
				self:_collect(m.value)
			end
		else
			local speed = dist(m.vx, m.vy)
			if speed > 0 then
				local ns = math.max(0, speed - 40 * dt)
				m.vx, m.vy = m.vx / speed * ns, m.vy / speed * ns
			end
			m.x += m.vx * dt
			m.y += m.vy * dt
			m.life -= dt
			if m.life <= 0 then
				table.remove(self.embers, i)
				self.embersLost += m.value
			end
		end
	end
end

function Sim:_collect(value: number)
	self.embersCollected += value
	self.xp += value
	if self.emberHeal > 0 then
		self:heal(self.emberHeal)
	end
	if self.tutorial then
		self.tutorial:onEmber()
		if not self.tutorial:allowsLevelUp() then
			self.xp = math.min(self.xp, self.xpNeeded - 1)
		end
	end
end

function Sim:_levelStep()
	while self.xp >= self.xpNeeded do
		self.xp -= self.xpNeeded
		self:levelUp()
	end
end

-- Um nível a mais: cada jogador ganha uma escolha.
function Sim:levelUp()
	self.level += 1
	self:_updateXpNeeded()
	for _, b in self.beams do
		b.pending += 1
		self:_refreshOffer(b)
	end
	self:fx("level", { level = self.level })
end

-- Resultado ---------------------------------------------------------------------

-- Venceu: viu o amanhecer (ou passou dele, no modo sem fim).
function Sim:won(): boolean
	return self.finished == "victory" or self.endless
end

function Sim:score(live: boolean?)
	local hpFraction = if live then 0 else self.hp / math.max(1, self.maxHp)
	return Balance.scoreBreakdown(self.killPoints, self.bossesDefeated, self.t, if live then self.endless else self:won(),
		hpFraction, self.difficulty, self.tide, self.mode == "boss_rush")
end

-- Dano por fonte, do maior para o menor: {{fonte, fração}}.
function Sim:damageRanked()
	local total = 0
	for _, v in self.damage do
		total += v
	end
	local out = {}
	if total <= 0 then
		return out
	end
	for k, v in self.damage do
		table.insert(out, { k, math.round(v / total * 1000) / 1000 })
	end
	table.sort(out, function(a, b)
		return a[2] > b[2]
	end)
	return out
end

return Sim
