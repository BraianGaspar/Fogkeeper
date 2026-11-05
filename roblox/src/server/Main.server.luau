-- Servidor do Fogkeeper no Roblox: saguão (anfitrião escolhe mapa, farol,
-- dificuldade, maré e modo; cada um escolhe faroleiro e habilidades),
-- história do mapa, partida cooperativa (até 4 faroleiros), votação para
-- seguir noite adentro, recompensas, progresso e rankings. Contratos em
-- roblox/ARCHITECTURE.md.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Keepers = require(Shared:WaitForChild("Keepers"))
local Maps = require(Shared:WaitForChild("Maps"))
local Net = require(Shared:WaitForChild("Net"))
local Simulation = require(script.Parent:WaitForChild("Simulation"))
local World = require(script.Parent:WaitForChild("World"))
local Scores = require(script.Parent:WaitForChild("Scores"))
local Progress = require(script.Parent:WaitForChild("Progress"))
local Monetization = require(script.Parent:WaitForChild("Monetization"))
local MonetizationCatalog = require(Shared:WaitForChild("Monetization"))

Monetization.start()

-- Avatares andam pela ilha (Avatars.server.luau cuida deles).
Players.CharacterAutoLoads = true

local state = Net.state()
local MODES = { normal = true, daily = true, boss_rush = true }
local GOLD = Color3.fromRGB(240, 200, 110)
local DAILY = Color3.fromRGB(128, 217, 255)

local sim = nil
local run = nil -- dados da partida em andamento (modo, chave do ranking, recompensas já pagas)
local slots: { [number]: Player? } = {}
local accumulator = 0
local snapshotTimer = 0
local currentWorld = ""
local topCache: { [string]: { at: number, json: string } } = {}
local lastCommand: { [Player]: { tokens: number, at: number } } = {}
local endToken = 0 -- muda a cada fim de partida (descarta voltas ao saguão antigas)
local votes: { [Player]: boolean } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function today()
	return Scores.dailyRules(os.date("!*t"))
end

local function setWorld(mapId: string, keeper: string)
	local key = mapId .. "|" .. keeper
	if key ~= currentWorld then
		currentWorld = key
		World.build(mapId, keeper)
	end
end

-- Estado inicial do saguão.
state:SetAttribute("Phase", "lobby")
state:SetAttribute("Mode", "normal")
state:SetAttribute("Map", "bay")
state:SetAttribute("Keeper", "classic")
state:SetAttribute("Difficulty", "normal")
state:SetAttribute("Tide", 0)
state:SetAttribute("DailyJson", HttpService:JSONEncode(today()))
if World.setupLighting then
	World.setupLighting()
end
setWorld("bay", "classic")

-- Jogadores e anfitrião ------------------------------------------------------------

local function freeSlot(): number?
	for i = 1, Balance.MAX_PLAYERS do
		if not slots[i] then
			return i
		end
	end
	return nil
end

-- Anfitrião: quem ocupa a menor vaga.
local function host(): Player?
	for i = 1, Balance.MAX_PLAYERS do
		if slots[i] then
			return slots[i]
		end
	end
	return nil
end

local function seated(): { Player }
	local out = {}
	for i = 1, Balance.MAX_PLAYERS do
		if slots[i] then
			table.insert(out, slots[i] :: Player)
		end
	end
	return out
end

local function loadoutOf(player: Player): { string }
	local ids = string.split(player:GetAttribute("Loadout") or "", ",")
	if #ids ~= 3 then
		return table.clone(Balance.DEFAULT_LOADOUT)
	end
	return ids
end

-- Garante que faroleiro e habilidades do jogador estão liberados para ele.
local function validatePlayer(player: Player)
	local hero = player:GetAttribute("Hero")
	if not Balance.HEROES[hero] or not Progress.isUnlocked(player, hero) then
		player:SetAttribute("Hero", "keeper")
	end
	local ids = loadoutOf(player)
	for i = 1, 3 do
		if not Balance.findAbility(ids[i]) or not Progress.isUnlocked(player, ids[i]) or table.find(ids, ids[i]) ~= i then
			ids[i] = Balance.DEFAULT_LOADOUT[i]
		end
	end
	-- Padrões repetidos depois da troca: refaz com os padrões.
	if ids[1] == ids[2] or ids[2] == ids[3] or ids[1] == ids[3] then
		ids = table.clone(Balance.DEFAULT_LOADOUT)
	end
	player:SetAttribute("Loadout", table.concat(ids, ","))
end

-- As escolhas do saguão precisam estar liberadas para o anfitrião atual.
local function validateLobby()
	local h = host()
	if not h then
		return
	end
	if not Progress.isUnlocked(h, state:GetAttribute("Map")) then
		state:SetAttribute("Map", "bay")
	end
	if not Progress.isUnlocked(h, state:GetAttribute("Keeper")) then
		state:SetAttribute("Keeper", "classic")
	end
	local maxTide = math.min(#Balance.TIDES, Progress.stat(h, "tide_max"))
	if state:GetAttribute("Tide") > maxTide then
		state:SetAttribute("Tide", maxTide)
	end
	if state:GetAttribute("Phase") == "lobby" then
		setWorld(state:GetAttribute("Map"), state:GetAttribute("Keeper"))
	end
end

-- No desafio diário todos jogam em pé de igualdade: a oficina (que também
-- recebe óleo comprado com Robux) não vale, só as regras do dia.
local function infoFor(player: Player, forcedHero: string?)
	local fair = run ~= nil and run.mode == "daily"
	return {
		hero = forcedHero or player:GetAttribute("Hero"),
		loadout = loadoutOf(player),
		meta = if fair then {} else Progress.get(player).meta,
		unlocked = function(id: string): boolean
			return Progress.isUnlocked(player, id)
		end,
	}
end

-- Põe o jogador na partida e publica as habilidades que ele de fato leva
-- (o tutorial força as padrão; o HUD desenha a partir de Loadout).
local function addToRun(player: Player, slot: number)
	sim:addPlayer(player.UserId, slot, infoFor(player, run.forcedHero))
	local b = sim.beams[player.UserId]
	if b then
		local ids = {}
		for i, a in b.abilities do
			ids[i] = a.id
		end
		player:SetAttribute("Loadout", table.concat(ids, ","))
	end
end

local function onPlayerAdded(player: Player)
	local slot = freeSlot()
	if not slot then
		return -- o limite real fica em Game Settings > Places; quem sobra assiste
	end
	slots[slot] = player
	player:SetAttribute("Slot", slot)
	player:SetAttribute("Hero", player:GetAttribute("Hero") or "keeper")
	player:SetAttribute("Loadout", player:GetAttribute("Loadout") or table.concat(Balance.DEFAULT_LOADOUT, ","))
	player:SetAttribute("Ready", false)
	task.spawn(function()
		Progress.load(player)
		if player.Parent == nil or slots[slot] ~= player then
			return
		end
		validatePlayer(player)
		validateLobby()
		local phase = state:GetAttribute("Phase")
		if sim and run and (phase == "playing" or phase == "story") and run.mode ~= "tutorial" then
			addToRun(player, slot)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	local slot = player:GetAttribute("Slot")
	if slot and slots[slot] == player then
		slots[slot] = nil
	end
	if sim then
		sim:removePlayer(player.UserId)
	end
	Progress.save(player, true) -- grava e solta a trava de sessão
	Progress.forget(player)
	lastCommand[player] = nil
	votes[player] = nil
	-- Vaga aberta: quem estava só assistindo entra.
	for _, other in Players:GetPlayers() do
		if other ~= player and not other:GetAttribute("Slot") then
			onPlayerAdded(other)
			break
		end
	end
	validateLobby()
end)

-- Rankings ---------------------------------------------------------------------

local function showRanking(key: string, force: boolean?)
	state:SetAttribute("TopKey", key)
	local cached = topCache[key]
	if cached and not force and os.clock() - cached.at < Balance.TOP_CACHE then
		state:SetAttribute("TopJson", cached.json)
		return
	end
	topCache[key] = { at = os.clock(), json = if cached then cached.json else "[]" }
	state:SetAttribute("TopJson", topCache[key].json) -- nunca mostra a lista de outro ranking
	task.spawn(function()
		local json = HttpService:JSONEncode(Scores.top(key))
		topCache[key] = { at = os.clock(), json = json }
		if state:GetAttribute("TopKey") == key then
			state:SetAttribute("TopJson", json)
		end
	end)
end

local function lobbyRankingKey(): string
	local mode = state:GetAttribute("Mode")
	if mode == "daily" then
		return Scores.key("daily", "", "", today().date)
	end
	return Scores.key(mode, state:GetAttribute("Map"), state:GetAttribute("Difficulty"))
end

-- Partida ----------------------------------------------------------------------

-- Pausa: qualquer faroleiro pausa a noite para todos e qualquer um retoma.
-- Enquanto pausada, a simulação para e o relógio não corre (RunStart é
-- adiantado na volta). Em grupo, a pausa acaba sozinha em PAUSE_MAX.
local paused = false
local pausedAt = 0
local pauseToken = 0

local function setPaused(on: boolean, player: Player?)
	if on == paused then
		return
	end
	pauseToken += 1
	if on then
		paused = true
		pausedAt = now()
		state:SetAttribute("PausedBy", if player then player.DisplayName else "")
		if #seated() > 1 then
			local token = pauseToken
			task.delay(Balance.PAUSE_MAX, function()
				if pauseToken == token then
					setPaused(false, nil)
				end
			end)
		end
	else
		paused = false
		state:SetAttribute("RunStart", (state:GetAttribute("RunStart") or now()) + (now() - pausedAt))
		accumulator = 0
	end
	state:SetAttribute("Paused", paused)
end

-- Reacender o farol (Developer Product "revive"): quando a luz se apaga no
-- modo Normal, a noite congela por REVIVE_WINDOW segundos e qualquer
-- faroleiro pode comprar. Uma vez por partida; a partida sai do ranking.
local reviving = false
local reviveStart = 0

local function canRevive(): boolean
	local product = MonetizationCatalog.product("revive")
	return product ~= nil and product.id ~= 0 and run ~= nil and run.mode == "normal" and not run.revived
end

local function setReviving(on: boolean)
	reviving = on
	state:SetAttribute("Reviving", on)
	if on then
		reviveStart = now()
		state:SetAttribute("ReviveUntil", now() + Balance.REVIVE_WINDOW)
	end
end

Monetization.onRevive = function(player: Player): boolean
	if not reviving or not sim or sim.finished ~= "defeat" then
		return false
	end
	setReviving(false)
	sim.finished = nil
	sim.hp = sim.maxHp * Balance.REVIVE_HP
	for _, e in sim.enemies do
		e.stun = math.max(e.stun or 0, Balance.REVIVE_STUN)
	end
	run.revived = true
	run.key = nil -- partida reacendida não entra no ranking mundial
	state:SetAttribute("RunStart", (state:GetAttribute("RunStart") or now()) + (now() - reviveStart))
	accumulator = 0
	Net.event("Announce"):FireAllClients("%s reacendeu o farol!", { player.DisplayName }, GOLD, true)
	Net.event("Fx"):FireAllClients("flash", { radius = 400 })
	return true
end

local function backToLobby()
	setPaused(false, nil)
	setReviving(false)
	sim = nil
	run = nil
	table.clear(votes)
	endToken += 1
	state:SetAttribute("Phase", "lobby")
	-- "tutorial" não é um modo do saguão: "start" depois de um tutorial
	-- começaria outro tutorial (e o ranking "tutorial|..." não existe).
	if not MODES[state:GetAttribute("Mode")] then
		state:SetAttribute("Mode", "normal")
	end
	state:SetAttribute("BossName", "")
	state:SetAttribute("Endless", false)
	state:SetAttribute("TutorialJson", nil)
	state:SetAttribute("TutorialStep", nil)
	state:SetAttribute("DailyJson", HttpService:JSONEncode(today()))
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Offer", "")
		player:SetAttribute("Pending", 0)
		player:SetAttribute("BeamsJson", "[]")
		player:SetAttribute("Ready", false)
	end
	validateLobby()
	setWorld(state:GetAttribute("Map"), state:GetAttribute("Keeper"))
	showRanking(lobbyRankingKey(), true)
end

local function beginNight()
	if not sim or state:GetAttribute("Phase") == "playing" then
		return
	end
	sim:start()
	accumulator = 0
	snapshotTimer = 0
	state:SetAttribute("RunStart", now())
	state:SetAttribute("Phase", "playing")
	if run.mode == "daily" then
		Net.event("Announce"):FireAllClients("Desafio diário de %s", { run.daily }, DAILY, true)
	elseif run.mode == "normal" then
		Net.event("Announce"):FireAllClients("%s  —  %s", { Maps.get(sim.mapId).name, "Resista até o amanhecer" }, GOLD, true)
	end
end

local function startRun(mode: string)
	if state:GetAttribute("Phase") ~= "lobby" or #seated() == 0 then
		return
	end
	local config = {
		mode = mode, mapId = state:GetAttribute("Map"), keeper = state:GetAttribute("Keeper"),
		difficulty = state:GetAttribute("Difficulty"), tide = state:GetAttribute("Tide"),
		seed = math.floor(os.clock() * 1000) % 2147483647,
	}
	local forcedHero = nil
	local daily = nil
	if mode == "daily" then
		local rules = today()
		config.mapId, config.tide, config.seed, config.difficulty = rules.map, rules.tide, rules.seed, "normal"
		forcedHero = rules.hero
		daily = rules.date
	elseif mode == "boss_rush" then
		config.mapId, config.difficulty = Maps.ORDER[1], "normal"
	elseif mode == "tutorial" then
		config.mapId, config.difficulty, config.tide = "bay", "easy", 0
	end
	sim = Simulation.new(config)
	run = {
		mode = mode, map = config.mapId, daily = daily, forcedHero = forcedHero,
		key = if mode == "tutorial" then nil else Scores.key(mode, config.mapId, config.difficulty, daily),
		oilPaid = {}, history = {}, recorded = {}, kills = {},
	}
	for _, player in seated() do
		addToRun(player, player:GetAttribute("Slot"))
	end
	state:SetAttribute("Mode", if mode == "tutorial" then "tutorial" else mode)
	state:SetAttribute("Map", config.mapId)
	state:SetAttribute("Difficulty", config.difficulty)
	state:SetAttribute("Tide", config.tide)
	state:SetAttribute("Result", nil)
	state:SetAttribute("ResultJson", nil)
	state:SetAttribute("Relics", "")
	state:SetAttribute("Endless", false)
	state:SetAttribute("RunSeconds", 0)
	state:SetAttribute("CycleSeconds", 0)
	setWorld(config.mapId, config.keeper)
	if mode == "tutorial" then
		beginNight()
	else
		state:SetAttribute("StoryEnd", now() + Balance.STORY_TIME)
		state:SetAttribute("Phase", "story")
	end
end

-- Estado replicado -----------------------------------------------------------------

local function publishState()
	state:SetAttribute("Hp", math.ceil(math.max(0, sim.hp)))
	state:SetAttribute("MaxHp", math.ceil(sim.maxHp))
	state:SetAttribute("Level", sim.level)
	state:SetAttribute("Xp", math.floor(sim.xp))
	state:SetAttribute("XpNeeded", sim.xpNeeded)
	state:SetAttribute("Kills", sim.kills)
	state:SetAttribute("Score", sim:score(true).total)
	state:SetAttribute("Endless", sim.endless)
	state:SetAttribute("Night", if sim.endless then sim.nights + 2 else 1)
	state:SetAttribute("Ink", sim.inkT > 0)
	state:SetAttribute("Petrified", sim.stoneT > 0)
	state:SetAttribute("Asleep", sim.sleepT > 0)
	state:SetAttribute("Charmed", sim.charmT > 0)
	state:SetAttribute("RunSeconds", sim.t)
	state:SetAttribute("CycleSeconds", sim:cycleSeconds())
	state:SetAttribute("Relics", table.concat(sim.relics, ","))
	local boss = nil
	for _, e in sim.enemies do
		if e.boss and e.hp > 0 then
			boss = e
			break
		end
	end
	state:SetAttribute("BossName", if boss then boss.kind else "")
	state:SetAttribute("BossHp", if boss then math.max(0, boss.hp) / boss.maxHp else 0)
	local nextBoss = sim:nextBoss()
	state:SetAttribute("NextBoss", if nextBoss then nextBoss.boss else "")
	state:SetAttribute("NextBossAt", if nextBoss then (state:GetAttribute("RunStart") or now()) + nextBoss.t else 0)
	if sim.tutorial and sim.tutorial.dirty then
		sim.tutorial.dirty = false
		state:SetAttribute("TutorialStep", sim.tutorial.step)
		state:SetAttribute("TutorialJson", HttpService:JSONEncode(sim.tutorial.text))
	end
	local t = now()
	for _, player in Players:GetPlayers() do
		local b = sim.beams[player.UserId]
		if b then
			for _, src in sim:beamSources() do
				if src.owner == player.UserId and src.main then
					player:SetAttribute("BeamHalf", src.half)
					player:SetAttribute("BeamRange", src.range)
				end
			end
			local _, _, _, turn = sim:beamStats(b)
			player:SetAttribute("AimAngle", b.angle)
			player:SetAttribute("TurnSpeed", turn)
			player:SetAttribute("Overcharge", b.overchargeT > 0)
			player:SetAttribute("BeamsJson", HttpService:JSONEncode(sim:extraBeams(player.UserId)))
			-- Hora em que fica pronta; só muda de verdade ao usar (evita
			-- replicar três atributos a cada envio por causa de arredondamento).
			for i = 1, 3 do
				local ready = if b.cooldowns[i] > 0 then t + b.cooldowns[i] else 0
				local old = player:GetAttribute("Cd" .. i) or 0
				if (ready == 0) ~= (old == 0) or math.abs(ready - old) > 0.25 then
					player:SetAttribute("Cd" .. i, ready)
				end
			end
			player:SetAttribute("Pending", b.pending)
			player:SetAttribute("Offer", if b.offer then table.concat(b.offer, ",") else "")
			player:SetAttribute("Rerolls", b.rerolls)
			player:SetAttribute("Banishes", b.banishes)
		end
	end
end

local function playerById(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function flushEvents()
	for _, ev in sim.events do
		if ev.kind == "announce" then
			Net.event("Announce"):FireAllClients(ev.text, ev.args, ev.color, ev.big)
		elseif ev.kind == "fx" then
			if ev.name == "map" then
				setWorld(ev.data.map, sim.keeper)
				state:SetAttribute("Map", ev.data.map)
			end
			Net.event("Fx"):FireAllClients(ev.name, ev.data)
		elseif ev.kind == "achievement" then
			if ev.userId then
				local p = playerById(ev.userId)
				if p then
					Progress.unlockAchievement(p, ev.id)
				end
			else
				for _, p in seated() do
					Progress.unlockAchievement(p, ev.id)
				end
			end
		end
	end
	table.clear(sim.events)
end

-- Fim de partida ----------------------------------------------------------------

-- Recompensas e progresso de um jogador. No modo sem fim a mesma partida pode
-- ser gravada de novo: o óleo e as estatísticas pagam só a diferença.
local function reward(player: Player, result, score)
	local id = player.UserId
	local out = { oil = 0, unlocks = {}, achievements = {}, tide = 0 }
	local first = not run.recorded[id]
	run.recorded[id] = true
	if first then
		Progress.addStat(player, "runs")
		if result.victory then
			Progress.addStat(player, "wins")
		end
	end
	local killsDelta = sim.kills - (run.kills[id] or 0)
	run.kills[id] = sim.kills
	Progress.addStat(player, "kills", killsDelta)
	-- Chefes também pagam só a diferença (o modo sem fim traz mais chefes).
	run.bosses = run.bosses or {}
	Progress.addStat(player, "bosses", sim.bossesDefeated - (run.bosses[id] or 0))
	run.bosses[id] = sim.bossesDefeated
	-- Melhor do dia (a tela do desafio diário lê stats.daily_best).
	if result.mode == "daily" and result.daily then
		local stats = Progress.get(player).stats
		local best = stats.daily_best
		if type(best) ~= "table" or best.date ~= result.daily or (tonumber(best.score) or 0) < score.total then
			stats.daily_best = { date = result.daily, score = score.total }
		end
	end
	for art in sim.seenArts do
		Progress.see(player, art)
	end
	local earned = math.round(Progress.oilFor(player, score.total) * Monetization.oilMultiplier(player)) -- VIP dobra
	local oil = math.max(0, earned - (run.oilPaid[id] or 0))
	run.oilPaid[id] = (run.oilPaid[id] or 0) + oil
	Progress.addOil(player, oil)
	out.oil = oil
	-- Ver o amanhecer na maré mais alta libera a próxima (Normal ou acima).
	local dawn = result.victory and result.mode ~= "boss_rush"
	if dawn and first then
		Progress.addStat(player, "dawns")
	end
	if dawn and result.difficulty ~= "easy" and result.tide >= Progress.stat(player, "tide_max") and result.tide < #Balance.TIDES then
		Progress.get(player).stats.tide_max = result.tide + 1
		out.tide = result.tide + 1 -- a interface mostra "Maré %d" liberada
	end
	for _, unlockId in Progress.checkGoals(player, result) do
		table.insert(out.unlocks, Progress.unlockName(unlockId))
	end
	out.achievements = Progress.checkRunAchievements(player, result, (sim.shared.walls or 0) > 0)
	-- Histórico: a mesma entrada é atualizada se a noite continuar.
	local entry = run.history[id]
	if not entry then
		entry = {}
		run.history[id] = entry
		Progress.addHistory(player, entry)
	end
	entry.date = os.date("!%Y-%m-%d")
	entry.map, entry.mode, entry.difficulty, entry.tide = result.map, result.mode, result.difficulty, result.tide
	entry.score, entry.victory, entry.seconds, entry.level = score.total, result.victory, math.floor(sim.t), sim.level
	Progress.publish(player)
	Progress.save(player)
	if run.key then
		task.spawn(function()
			Scores.submit(id, run.key, score.total)
			player:SetAttribute("Best", math.max(score.total, Scores.best(id, run.key)))
		end)
	end
	return out
end

-- O tutorial é treino: não dá óleo nem pontos, não entra no histórico nem no
-- ranking; só marca que foi feito e libera a conquista.
local function finishTutorial()
	for _, player in seated() do
		Progress.get(player).stats.tutorial_done = true
		Progress.unlockAchievement(player, "apprentice")
		Progress.publish(player)
		Progress.save(player)
		state:SetAttribute("ResultJson", HttpService:JSONEncode({
			victory = true, mode = "tutorial", map = "bay", difficulty = "easy", tide = 0, seconds = sim.t, nights = 0,
			kills = sim.kills, level = sim.level, bosses = sim.bossesDefeated, relics = sim.relics,
			damage = sim:damageRanked(), embers = { sim.embersCollected, sim.embersLost },
			rewards = { [tostring(player.UserId)] = { oil = 0, unlocks = {}, achievements = {} } },
		}))
	end
	state:SetAttribute("Result", "tutorial")
	state:SetAttribute("ReturnAt", now() + Balance.LOBBY_RETURN)
	state:SetAttribute("Phase", "ended")
	-- Sem isto o servidor ficava preso na tela final depois do tutorial.
	endToken += 1
	local token = endToken
	task.delay(Balance.LOBBY_RETURN, function()
		if endToken == token and state:GetAttribute("Phase") == "ended" then
			backToLobby()
		end
	end)
end

local function finishRun()
	if sim.finished == "tutorial" then
		finishTutorial()
		return
	end
	local score = sim:score()
	local result = {
		victory = sim:won(), map = sim.mapId, mode = run.mode, difficulty = sim.difficulty, tide = sim.tide,
		seconds = sim.t, nights = sim.nights, kills = sim.kills, level = sim.level, bosses = sim.bossesDefeated,
		relics = sim.relics, score = score, damage = sim:damageRanked(), embers = { sim.embersCollected, sim.embersLost },
		hpFraction = sim.hp / math.max(1, sim.maxHp), rushTotal = sim:rushTotal(), daily = run.daily,
		revived = run.revived == true, -- reacendida com Robux: fora do ranking mundial
	}
	result.canContinue = sim.finished == "victory" and not sim.endless and run.mode ~= "boss_rush"
	local rewards = {}
	for _, player in seated() do
		rewards[tostring(player.UserId)] = reward(player, result, score)
	end
	result.rewards = rewards
	table.clear(votes)
	state:SetAttribute("EndlessVotes", 0)
	state:SetAttribute("Result", if result.victory then "victory" else "defeat")
	state:SetAttribute("RunSeconds", sim.t)
	state:SetAttribute("ResultJson", HttpService:JSONEncode(result))
	state:SetAttribute("ReturnAt", now() + (if result.canContinue then Balance.ENDLESS_VOTE else Balance.LOBBY_RETURN))
	state:SetAttribute("Phase", "ended")
	publishState()
	-- A ficha muda a cada fim: uma volta agendada antes de "seguir noite
	-- adentro" não encurta a tela final de um fim posterior.
	endToken += 1
	local token = endToken
	local wait = if result.canContinue then Balance.ENDLESS_VOTE else Balance.LOBBY_RETURN
	task.delay(wait, function()
		if endToken == token and state:GetAttribute("Phase") == "ended" then
			backToLobby()
		end
	end)
end

-- A maioria quer seguir noite adentro: a partida continua.
local function countVotes()
	local yes = 0
	for p, v in votes do
		if v and p.Parent then
			yes += 1
		end
	end
	state:SetAttribute("EndlessVotes", yes)
	-- Só depois de um amanhecer (derrota ou tutorial não continuam).
	local canContinue = sim ~= nil and run ~= nil and sim.finished == "victory" and not sim.endless and run.mode ~= "boss_rush"
	if yes * 2 > #seated() and canContinue and state:GetAttribute("Phase") == "ended" then
		endToken += 1
		table.clear(votes)
		sim:continueEndless()
		state:SetAttribute("Endless", true)
		state:SetAttribute("Phase", "playing")
		Net.event("Announce"):FireAllClients("Modo sem fim: a névoa volta e as noites seguem, cada vez mais difíceis. Os pontos continuam somando nesta partida.",
			{}, GOLD, false)
	end
end

RunService.Heartbeat:Connect(function(dt)
	local phase = state:GetAttribute("Phase")
	if phase == "story" then
		if now() >= (state:GetAttribute("StoryEnd") or 0) then
			beginNight()
		end
		return
	end
	if not sim or phase ~= "playing" then
		return
	end
	if #seated() == 0 then
		backToLobby()
		return
	end
	if paused then
		return
	end
	if reviving then
		-- Noite congelada esperando alguém reacender o farol.
		if now() >= (state:GetAttribute("ReviveUntil") or 0) then
			setReviving(false)
			finishRun()
		end
		return
	end
	-- O feixe principal de cada um sai de onde o avatar está.
	for _, player in seated() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			sim:setOrigin(player.UserId, root.Position.X / Balance.STUDS_PER_UNIT, root.Position.Z / Balance.STUDS_PER_UNIT)
		end
	end
	accumulator = math.min(accumulator + dt, 0.25)
	while accumulator >= Balance.TICK and not sim.finished do
		accumulator -= Balance.TICK
		sim:step(Balance.TICK)
	end
	flushEvents()
	snapshotTimer -= dt
	if snapshotTimer <= 0 or sim.finished then
		snapshotTimer = 1 / Balance.SNAPSHOT_RATE
		Net.event("Snapshot"):FireAllClients(Net.encode(sim.enemies, sim.embers, sim.deaths))
		table.clear(sim.deaths)
		publishState()
	end
	if sim.finished == "defeat" and canRevive() then
		setReviving(true)
		Net.event("Announce"):FireAllClients("A luz se apagou", {}, Color3.fromRGB(232, 86, 72), true)
		return
	end
	if sim.finished then
		finishRun()
	end
end)

-- Comandos dos jogadores ---------------------------------------------------------

-- Limite de comandos por jogador: um balde de fichas que enche uma a cada
-- LOBBY_COOLDOWN, com folga para rajadas legítimas (o cliente manda, por
-- exemplo, "mode" e "start" em seguida).
local THROTTLE_BURST = 6
local function throttled(player: Player): boolean
	local clock = os.clock()
	local bucket = lastCommand[player]
	if not bucket then
		bucket = { tokens = THROTTLE_BURST, at = clock }
		lastCommand[player] = bucket
	end
	bucket.tokens = math.min(THROTTLE_BURST, bucket.tokens + (clock - bucket.at) / Balance.LOBBY_COOLDOWN)
	bucket.at = clock
	if bucket.tokens < 1 then
		return true
	end
	bucket.tokens -= 1
	return false
end

Net.event("Aim").OnServerEvent:Connect(function(player, angle)
	if sim and typeof(angle) == "number" then
		sim:setAim(player.UserId, angle)
	end
end)

Net.event("Ability").OnServerEvent:Connect(function(player, index)
	if sim and not paused and not reviving and state:GetAttribute("Phase") == "playing" and (index == 1 or index == 2 or index == 3) then
		if sim:useAbility(player.UserId, index) then
			flushEvents()
		end
	end
end)

Net.event("Pick").OnServerEvent:Connect(function(player, id)
	if sim and typeof(id) == "string" and sim:pick(player.UserId, id) then
		flushEvents()
		publishState()
	end
end)

Net.event("Reroll").OnServerEvent:Connect(function(player)
	if sim and not throttled(player) and sim:reroll(player.UserId) then
		publishState()
	end
end)

Net.event("Banish").OnServerEvent:Connect(function(player, id)
	if sim and typeof(id) == "string" and not throttled(player) and sim:banish(player.UserId, id) then
		flushEvents()
		publishState()
	end
end)

local HOST_ACTIONS = { map = true, keeper = true, difficulty = true, tide = true, mode = true, start = true, tutorial = true }

Net.event("Lobby").OnServerEvent:Connect(function(player, action, value, extra)
	if typeof(action) ~= "string" or throttled(player) then
		return
	end
	local phase = state:GetAttribute("Phase")
	local h = host()
	if HOST_ACTIONS[action] and (player ~= h or phase ~= "lobby") then
		return
	end
	if action == "map" then
		if typeof(value) == "string" and Maps.LIST[value] and Progress.isUnlocked(player, value) then
			state:SetAttribute("Map", value)
			setWorld(value, state:GetAttribute("Keeper"))
			showRanking(lobbyRankingKey())
		end
	elseif action == "keeper" then
		if typeof(value) == "string" and Keepers.LIST[value] and Progress.isUnlocked(player, value) then
			state:SetAttribute("Keeper", value)
			setWorld(state:GetAttribute("Map"), value)
		end
	elseif action == "difficulty" then
		if typeof(value) == "string" and Balance.DIFFICULTIES[value] then
			state:SetAttribute("Difficulty", value)
			showRanking(lobbyRankingKey())
		end
	elseif action == "tide" then
		if typeof(value) == "number" and value == math.floor(value) then
			local maxTide = math.min(#Balance.TIDES, Progress.stat(player, "tide_max"))
			state:SetAttribute("Tide", math.clamp(value, 0, maxTide))
		end
	elseif action == "mode" then
		if typeof(value) == "string" and MODES[value] then
			state:SetAttribute("Mode", value)
			showRanking(lobbyRankingKey())
		end
	elseif action == "start" then
		startRun(state:GetAttribute("Mode"))
	elseif action == "tutorial" then
		if #seated() == 1 then
			startRun("tutorial")
		end
	elseif action == "hero" then
		if phase == "lobby" and typeof(value) == "string" and Balance.HEROES[value] and Progress.isUnlocked(player, value) then
			player:SetAttribute("Hero", value)
		end
	elseif action == "loadout" then
		if phase == "lobby" and (value == 1 or value == 2 or value == 3) and typeof(extra) == "string"
			and Balance.findAbility(extra) and Progress.isUnlocked(player, extra) then
			local ids = loadoutOf(player)
			local other = table.find(ids, extra)
			if other then
				ids[other] = ids[value] -- já estava em outra vaga: troca as duas
			end
			ids[value] = extra
			player:SetAttribute("Loadout", table.concat(ids, ","))
		end
	elseif action == "ready" then
		player:SetAttribute("Ready", value == true)
	elseif action == "cosmetic" then
		if value == "beam" then
			Monetization.setBeamColor(player, extra)
		end
	elseif action == "pause" then
		if phase == "playing" and not reviving and slots[player:GetAttribute("Slot") or 0] == player then
			setPaused(value == true, player)
		end
	elseif action == "quit" then
		-- Sair para o menu: só o anfitrião encerra a noite (para todos). A
		-- partida abandonada não dá recompensas nem entra no ranking.
		if player == h and (phase == "playing" or phase == "story") then
			backToLobby()
		end
	elseif action == "skip_story" then
		if phase == "story" then
			beginNight()
		end
	elseif action == "endless" then
		if phase == "ended" and slots[player:GetAttribute("Slot") or 0] == player then
			votes[player] = value ~= false
			countVotes()
		end
	elseif action == "buy" then
		if phase == "lobby" and typeof(value) == "string" and Progress.buyUnlock(player, value) then
			Net.event("Fx"):FireClient(player, "unlock", { id = value, name = Progress.unlockName(value) })
		end
	elseif action == "meta" then
		if phase == "lobby" and typeof(value) == "string" and Progress.buyMeta(player, value) then
			Net.event("Fx"):FireClient(player, "meta", { id = value, level = Progress.metaLevel(player, value) })
		end
	elseif action == "settings" then
		if typeof(value) == "string" and #value < 2000 then
			Progress.setSettings(player, value)
		end
	elseif action == "ranking" then
		-- Só chaves que existem: cada chave nova abre um DataStore e entra no cache.
		if typeof(value) == "string" and #value <= 60 and Scores.validKey(value) then
			showRanking(value)
		end
	end
end)

-- Servidor fechando: grava todo mundo e espera as gravações terminarem.
game:BindToClose(function()
	Progress.flush(Players:GetPlayers())
end)

-- Gravação automática: protege o progresso se o servidor cair e renova a
-- trava de sessão de quem está jogando.
task.spawn(function()
	while true do
		task.wait(Balance.AUTOSAVE_EVERY)
		Progress.autosave(Players:GetPlayers())
	end
end)

showRanking(lobbyRankingKey())
