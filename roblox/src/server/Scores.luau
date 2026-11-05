-- Rankings mundiais (DataStores ordenados) e as regras do desafio diário.
-- Chave de ranking: "modo|mapa|dificuldade" (ex.: "normal|bay|hard",
-- "boss_rush||normal") ou "daily|AAAA-MM-DD". No Studio só funciona com
-- "Enable Studio Access to API Services"; sem isso, falha em silêncio.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Maps = require(Shared:WaitForChild("Maps"))

local Scores = {}

local TOP_SIZE = 10
local MAX_TIDE_DAILY = 3

function Scores.key(mode: string, map: string, difficulty: string, daily: string?): string
	if mode == "daily" then
		return "daily|" .. (daily or "")
	elseif mode == "boss_rush" then
		return "boss_rush||normal"
	end
	return string.format("%s|%s|%s", mode, map, difficulty)
end

-- Chave pedida pelo cliente (Lobby "ranking"): só as que Scores.key gera.
function Scores.validKey(key: string): boolean
	if key == "boss_rush||normal" then
		return true
	end
	if string.match(key, "^daily|%d%d%d%d%-%d%d%-%d%d$") then
		-- Só hoje e ontem (UTC): datas livres abririam um DataStore e uma
		-- entrada de cache por data pedida.
		local date = string.sub(key, 7)
		return date == os.date("!%Y-%m-%d") or date == os.date("!%Y-%m-%d", os.time() - 86400)
	end
	local mode, map, difficulty = string.match(key, "^(%w+)|([%w_]+)|(%w+)$")
	return mode == "normal" and Maps.LIST[map] ~= nil and Balance.DIFFICULTIES[difficulty] ~= nil
end

-- Nome do DataStore de uma chave (só letras, números e _).
local function storeName(key: string): string
	return "FkTop_" .. string.gsub(key, "[^%w]", "_")
end

local function ordered(key: string): any
	local ok, ds = pcall(function()
		return DataStoreService:GetOrderedDataStore(storeName(key))
	end)
	return if ok then ds else nil
end

-- Grava a pontuação se for o recorde do jogador nesta chave.
function Scores.submit(userId: number, key: string, score: number)
	-- OrderedDataStore só aceita inteiros; NaN, infinito e zero não entram.
	if type(score) ~= "number" or score ~= score or score <= 0 or score == math.huge then
		return
	end
	score = math.floor(score)
	local top = ordered(key)
	if not top then
		return
	end
	local ok, err = pcall(function()
		top:UpdateAsync(tostring(userId), function(old)
			if type(old) == "number" and old >= score then
				return nil -- retornar nil cancela a gravação
			end
			return score
		end)
	end)
	if not ok then
		warn("[Fogkeeper] ranking " .. key .. " não gravou: " .. tostring(err))
	end
end

-- Melhor pontuação do jogador nesta chave (0 se não houver).
function Scores.best(userId: number, key: string): number
	local top = ordered(key)
	local best = 0
	if top then
		pcall(function()
			best = top:GetAsync(tostring(userId)) or 0
		end)
	end
	return best
end

-- Top 10: lista de {name, score}.
function Scores.top(key: string): { { name: string, score: number } }
	local out = {}
	local top = ordered(key)
	if not top then
		return out
	end
	local ok, pages = pcall(function()
		return top:GetSortedAsync(false, TOP_SIZE)
	end)
	if not ok then
		return out
	end
	local page = pages:GetCurrentPage()
	-- Nome de exibição (DisplayName) de todos numa consulta só; se falhar, o
	-- nome de usuário, um por um.
	local ids = {}
	for _, entry in page do
		local id = tonumber(entry.key)
		if id then
			table.insert(ids, id)
		end
	end
	local display: { [number]: string } = {}
	pcall(function()
		for _, info in UserService:GetUserInfosByUserIdsAsync(ids) do
			display[info.Id] = info.DisplayName
		end
	end)
	for _, entry in page do
		local id = tonumber(entry.key)
		local name = if id then display[id] else nil
		if not name then
			name = "?"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(id)
			end)
		end
		table.insert(out, { name = name, score = entry.value })
	end
	return out
end

-- Hash simples e estável de uma string (o mesmo em qualquer servidor).
local function hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

-- Regras do desafio do dia: mesmo mapa, faroleiro, maré e semente para todos.
-- `date` = os.date("!*t") (data em UTC, igual em todos os servidores).
function Scores.dailyRules(date)
	local seed = date.year * 10000 + date.month * 100 + date.day
	local h = hash(tostring(seed))
	return {
		date = string.format("%04d-%02d-%02d", date.year, date.month, date.day),
		seed = seed,
		map = Maps.ORDER[h % #Maps.ORDER + 1],
		hero = Balance.HERO_ORDER[(h // 7) % #Balance.HERO_ORDER + 1],
		tide = 1 + (h // 49) % MAX_TIDE_DAILY,
	}
end

return Scores
