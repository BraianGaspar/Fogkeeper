-- Progresso de cada jogador (DataStore "FogkeeperProgress"): óleo, oficina,
-- desbloqueios, conquistas, bestiário, estatísticas, configurações e as 20
-- últimas partidas. Formato em ARCHITECTURE.md (ProgressJson). Porta de
-- scripts/core/progress.gd e achievements.gd, por jogador.
-- Sem acesso a DataStores (Studio sem API Services), tudo funciona na memória
-- e simplesmente não é salvo.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))
local Achievements = require(Shared:WaitForChild("Achievements"))
local Maps = require(Shared:WaitForChild("Maps"))
local Bestiary = require(Shared:WaitForChild("Bestiary"))
local Keepers = require(Shared:WaitForChild("Keepers"))
local Net = require(Shared:WaitForChild("Net"))

local Progress = {}

local STORE_NAME = "FogkeeperProgress"
local LOAD_TRIES = 3
local SETTINGS_KEYS = { locale = "string", colorblind = "number", text_scale = "number", reduce_flashes = "boolean",
	music = "number", sfx = "number", shake = "boolean" }

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local data: { [number]: any } = {} -- userId -> progresso
local loaded: { [number]: boolean } = {}

local function blank()
	return {
		oil = 0, oil_total = 0, meta = {}, unlocked = {}, achievements = {}, seen = {},
		stats = { runs = 0, wins = 0, kills = 0, bosses = 0, dawns = 0, tide_max = 0, tutorial_done = false },
		settings = { locale = "", colorblind = 0, text_scale = 0, reduce_flashes = false, music = 80, sfx = 100, shake = true },
		history = {},
		receipts = {}, -- compras de Robux já entregues (PurchaseId -> true); fica fora do ProgressJson
	}
end

-- Completa campos que faltam (dados antigos ou corrompidos).
local function normalize(d)
	local base = blank()
	if type(d) ~= "table" then
		return base
	end
	for k, v in base do
		if type(d[k]) ~= type(v) then
			d[k] = v
		end
	end
	for k, v in base.stats do
		if type(d.stats[k]) ~= type(v) then
			d.stats[k] = v
		end
	end
	for k, v in base.settings do
		if type(d.settings[k]) ~= type(v) then
			d.settings[k] = v
		end
	end
	-- Conquistas são `true` (ARCHITECTURE: ProgressJson); versões antigas guardavam a hora.
	for id, v in d.achievements do
		d.achievements[id] = if v then true else nil
	end
	return d
end

function Progress.get(player: Player)
	local d = data[player.UserId]
	if not d then
		d = blank()
		data[player.UserId] = d
	end
	return d
end

-- Publica o progresso nos atributos do jogador (Oil e ProgressJson).
function Progress.publish(player: Player)
	local d = Progress.get(player)
	player:SetAttribute("Oil", d.oil)
	local receipts = d.receipts
	d.receipts = nil
	player:SetAttribute("ProgressJson", HttpService:JSONEncode(d))
	d.receipts = receipts
end

-- Compras de Robux: registro de recibos entregues e gravação imediata.

function Progress.isLoaded(player: Player): boolean
	return loaded[player.UserId] == true
end

function Progress.hasReceipt(player: Player, purchaseId: string): boolean
	return Progress.get(player).receipts[purchaseId] == true
end

-- Grava agora e espera o resultado (o recibo só é confirmado ao Roblox depois
-- de salvo). Sem DataStore (Studio sem API Services), retorna true: as compras
-- de teste do Studio são de mentira e o progresso já não é salvo.
function Progress.saveNow(player: Player, purchaseId: string?): boolean
	local d = Progress.get(player)
	if purchaseId then
		d.receipts[purchaseId] = true
	end
	if not store then
		return true
	end
	if not loaded[player.UserId] then
		if purchaseId then
			d.receipts[purchaseId] = nil
		end
		return false
	end
	local ok = pcall(function()
		store:UpdateAsync(tostring(player.UserId), function()
			return d
		end)
	end)
	if not ok and purchaseId then
		d.receipts[purchaseId] = nil
	end
	return ok
end

function Progress.load(player: Player)
	local key = tostring(player.UserId)
	local result = nil
	local success = store == nil
	if store then
		for _ = 1, LOAD_TRIES do
			local ok, value = pcall(function()
				return store:GetAsync(key)
			end)
			if ok then
				result = value
				success = true
				break
			end
			task.wait(1)
		end
	end
	data[player.UserId] = normalize(result)
	-- Se a leitura falhou, nunca grava por cima do progresso salvo.
	loaded[player.UserId] = success
	if not success then
		warn("[Fogkeeper] progresso de " .. key .. " não carregou; esta sessão não será salva")
	end
	Progress.publish(player)
end

function Progress.save(player: Player)
	local d = data[player.UserId]
	if not store or not d or not loaded[player.UserId] then
		return
	end
	task.spawn(function()
		pcall(function()
			store:UpdateAsync(tostring(player.UserId), function()
				return d
			end)
		end)
	end)
end

function Progress.forget(player: Player)
	data[player.UserId] = nil
	loaded[player.UserId] = nil
end

-- Estatísticas e óleo -----------------------------------------------------------

function Progress.stat(player: Player, key: string): number
	return tonumber(Progress.get(player).stats[key]) or 0
end

function Progress.addStat(player: Player, key: string, amount: number?)
	local stats = Progress.get(player).stats
	stats[key] = (tonumber(stats[key]) or 0) + (amount or 1)
end

function Progress.metaLevel(player: Player, id: string): number
	return tonumber(Progress.get(player).meta[id]) or 0
end

function Progress.oilFor(player: Player, score: number): number
	local fisher = Progress.metaLevel(player, "fisher") * Balance.META_EFFECTS.fisher
	return math.max(Balance.OIL_MIN, math.round(score * Balance.OIL_PER_SCORE * (1 + fisher)))
end

function Progress.addOil(player: Player, amount: number)
	local d = Progress.get(player)
	d.oil += amount
	d.oil_total += amount
	if d.oil_total >= 1000 then
		Progress.unlockAchievement(player, "oil_1000")
	end
end

-- Desbloqueios ----------------------------------------------------------------

-- Desbloqueios vindos de Game Pass (server/Monetization preenche; devolve
-- true/false para ids de passe e nil para os outros).
Progress.passUnlock = nil :: ((Player, string) -> boolean?)?

-- Liberado por padrão: o que não está em Balance.UNLOCKS.
function Progress.isUnlocked(player: Player, id: string): boolean
	if Progress.passUnlock then
		local byPass = Progress.passUnlock(player, id)
		if byPass ~= nil then
			return byPass
		end
	end
	if not Balance.findUnlock(id) then
		return true
	end
	return Progress.get(player).unlocked[id] == true
end

function Progress.unlockName(id: string): string
	local u = Balance.findUnlock(id)
	local kind = if u then u.kind else ""
	if kind == "map" then
		return Maps.get(id).name
	elseif kind == "keeper" then
		return Keepers.get(id).name
	elseif kind == "upgrade" then
		return Upgrades.find(id).name
	elseif kind == "hero" then
		return Balance.HEROES[id].name
	elseif kind == "ability" then
		local a = Balance.findAbility(id)
		return if a then a.name else id
	end
	return id
end

function Progress.buyUnlock(player: Player, id: string): boolean
	local u = Balance.findUnlock(id)
	local d = Progress.get(player)
	if not u or d.unlocked[id] or d.oil < u.cost then
		return false
	end
	d.oil -= u.cost
	d.unlocked[id] = true
	Progress.publish(player)
	Progress.save(player)
	return true
end

function Progress.nextMetaCost(player: Player, id: string): number?
	local m = Balance.findMeta(id)
	if not m then
		return nil
	end
	local lvl = Progress.metaLevel(player, id)
	if lvl >= m.max then
		return nil
	end
	return m.cost * (lvl + 1)
end

function Progress.buyMeta(player: Player, id: string): boolean
	local cost = Progress.nextMetaCost(player, id)
	local d = Progress.get(player)
	if not cost or d.oil < cost then
		return false
	end
	d.oil -= cost
	d.meta[id] = Progress.metaLevel(player, id) + 1
	Progress.publish(player)
	Progress.save(player)
	return true
end

-- Metas de desbloqueio cumpridas pela partida; devolve os ids novos.
function Progress.checkGoals(player: Player, run): { string }
	local out = {}
	local d = Progress.get(player)
	local dawn = run.victory and run.mode ~= "boss_rush"
	for _, u in Balance.UNLOCKS do
		if not d.unlocked[u.id] then
			local met = false
			if u.goal == "midnight" then
				met = run.seconds >= Balance.RUN_DURATION / 2
			elseif u.goal == "boss" then
				met = run.bosses > 0
			elseif u.goal == "dawn" then
				met = dawn
			elseif u.goal == "dawn_medium" then
				met = dawn and (run.difficulty == "medium" or run.difficulty == "hard" or run.difficulty == "impossible")
			end
			if met then
				d.unlocked[u.id] = true
				table.insert(out, u.id)
			end
		end
	end
	return out
end

-- Conquistas -----------------------------------------------------------------

-- Desbloqueia e avisa só este jogador; devolve true se for nova.
function Progress.unlockAchievement(player: Player, id: string, announce: boolean?): boolean
	local d = Progress.get(player)
	local entry = Achievements.find(id)
	if not entry or d.achievements[id] then
		return false
	end
	d.achievements[id] = true
	if announce ~= false then
		Net.event("Fx"):FireClient(player, "achievement", { id = id, name = entry.name })
	end
	return true
end

-- Bestiário: marca a arte como vista; completa a conquista quando todas abrem.
function Progress.see(player: Player, art: string)
	local d = Progress.get(player)
	if d.seen[art] or not Bestiary.has(art) then
		return
	end
	d.seen[art] = true
	local opened, all = Bestiary.count(d.seen)
	if opened >= all then
		Progress.unlockAchievement(player, "bestiary")
	end
end

-- Conquistas que dependem do resultado da partida (sem aviso: a tela final as lista).
function Progress.checkRunAchievements(player: Player, run, pickedWalls: boolean): { string }
	local d = Progress.get(player)
	local candidates = { "first_light" }
	local dawn = run.victory and run.mode ~= "boss_rush"
	if dawn then
		table.insert(candidates, "dawn")
		if run.difficulty == "hard" or run.difficulty == "impossible" then
			table.insert(candidates, "hard_dawn")
		end
		if run.difficulty == "impossible" then
			table.insert(candidates, "impossible_dawn")
		end
		if (run.hpFraction or 0) >= 0.9 then
			table.insert(candidates, "untouched")
		end
		if not pickedWalls then
			table.insert(candidates, "no_walls")
		end
		d.stats["won_" .. run.map] = true
		local all = true
		for _, m in Maps.ORDER do
			if not d.stats["won_" .. m] then
				all = false
			end
		end
		if all then
			table.insert(candidates, "three_seas")
		end
		if run.tide >= #Balance.TIDES then
			table.insert(candidates, "tide_10")
		end
	end
	if run.mode == "daily" then
		table.insert(candidates, "daily")
	end
	if run.mode == "boss_rush" and run.victory then
		table.insert(candidates, "boss_rush")
	end
	if Progress.stat(player, "kills") >= 5000 then
		table.insert(candidates, "kills_5000")
	end
	local out = {}
	for _, id in candidates do
		if Progress.unlockAchievement(player, id, false) then
			table.insert(out, Achievements.find(id).name)
		end
	end
	return out
end

-- Configurações e histórico ---------------------------------------------------------

-- Aceita só as chaves conhecidas, com o tipo certo.
function Progress.setSettings(player: Player, json: string)
	local ok, incoming = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(incoming) ~= "table" then
		return
	end
	local settings = Progress.get(player).settings
	for k, kind in SETTINGS_KEYS do
		local v = incoming[k]
		if type(v) == kind then
			if kind == "number" then
				v = math.clamp(v, 0, 100)
			elseif kind == "string" then
				v = string.sub(v, 1, 8)
			end
			settings[k] = v
		end
	end
	Progress.publish(player)
	Progress.save(player)
end

function Progress.addHistory(player: Player, entry)
	local history = Progress.get(player).history
	table.insert(history, 1, entry)
	while #history > Balance.HISTORY_SIZE do
		table.remove(history)
	end
end

return Progress
