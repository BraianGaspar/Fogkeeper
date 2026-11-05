-- Acesso aos dados compartilhados (mapas, faroleiros, oficina, conquistas...)
-- com tolerância: se um módulo ou campo ainda não existir, a interface usa um
-- valor neutro em vez de quebrar. Também guarda formatações de número e hora.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Text = require(Shared:WaitForChild("Text"))

local Data = {}

local function load(name: string): any
	local mod = Shared:FindFirstChild(name) or Shared:WaitForChild(name, 3)
	if not mod then
		return nil
	end
	local ok, result = pcall(require, mod)
	if not ok then
		warn("[Fogkeeper] falha ao carregar " .. name .. ": " .. tostring(result))
		return nil
	end
	return result
end

Data.Balance = load("Balance") or {}
Data.Maps = load("Maps") or {}
Data.Keepers = load("Keepers") or {}
Data.Upgrades = load("Upgrades") or {}
Data.Achievements = load("Achievements") or {}
Data.Bestiary = load("Bestiary") or {}
Data.BossData = load("BossData") or {}
Data.Text = Text

Data.RUN_DURATION = Data.Balance.RUN_DURATION or 600
Data.DIFFICULTY_NAMES = { easy = "Fácil", normal = "Normal", medium = "Médio", hard = "Difícil", impossible = "Impossível" }
Data.MODE_NAMES = { normal = "Normal", daily = "Desafio diário", boss_rush = "Modo Chefões", tutorial = "Tutorial" }
Data.LANGUAGES = {
	{ "", "Padrão do sistema" }, { "pt-br", "Português" }, { "en", "English" }, { "es", "Español" }, { "fr", "Français" },
	{ "de", "Deutsch" }, { "ru", "Русский" }, { "zh-cn", "简体中文" }, { "ja", "日本語" }, { "ko", "한국어" },
}
Data.DAMAGE_NAMES = {
	beam = "Feixe principal", lens = "Lentes extras", sweeper = "Farolete", pulse = "Pulso de luz",
	ability = "Habilidades", combustion = "Combustão",
}

-- Mapas ---------------------------------------------------------------------

local DEFAULT_MAPS = { "bay", "fjord", "amazon", "japan", "egypt", "greece", "celtic" }

function Data.mapOrder(): { string }
	return Data.Maps.ORDER or DEFAULT_MAPS
end

function Data.map(id: string?): { [string]: any }
	local list = Data.Maps.LIST or {}
	return list[id or ""] or { name = id or "?", tagline = "", story = "", bosses = {}, creatures = {} }
end

function Data.creatureName(art: string): string
	local names = Data.Maps.CREATURE_NAMES or {}
	return Text.t(names[art] or art)
end

function Data.bossTitle(id: string): string
	local titles = Data.Maps.BOSS_TITLES or {}
	return if titles[id] then Text.t(titles[id]) else ""
end

-- Raio (unidades do jogo) de cada arte, para o tamanho dos modelos.
local radiusByArt: { [string]: number }? = nil
function Data.artRadius(art: string): number
	if not radiusByArt then
		radiusByArt = {}
		local enemies = Data.Balance.ENEMIES or {}
		for _, id in Data.mapOrder() do
			for role, a in Data.map(id).creatures or {} do
				local r = enemies[role] and enemies[role].radius
				if r and not (radiusByArt :: any)[a] then
					(radiusByArt :: any)[a] = r
				end
			end
		end
		for id, b in Data.bosses() do
			if type(b) == "table" and b.radius then
				(radiusByArt :: any)[id] = b.radius
			end
		end
	end
	return (radiusByArt :: any)[art] or 12
end

-- Chefes e relíquias -----------------------------------------------------------

function Data.bosses(): { [string]: any }
	local bd = Data.BossData
	return bd.BOSSES or bd.LIST or {}
end

function Data.relic(id: string): { [string]: any }
	local relics = Data.BossData.RELICS or Data.Balance.RELICS or {}
	return relics[id] or { name = id, desc = "" }
end

-- Faróis, faroleiros, dificuldades, marés --------------------------------------

function Data.keeperOrder(): { string }
	return Data.Keepers.ORDER or { "classic", "stone", "iron", "crystal" }
end

function Data.keeper(id: string?): { [string]: any }
	return (Data.Keepers.LIST or {})[id or ""] or { name = id or "?", desc = "" }
end

function Data.heroOrder(): { string }
	return Data.Balance.HERO_ORDER or { "keeper" }
end

function Data.hero(id: string?): { [string]: any }
	return (Data.Balance.HEROES or {})[id or ""] or { name = "Faroleira", desc = "" }
end

function Data.difficultyOrder(): { string }
	return Data.Balance.DIFFICULTY_ORDER or { "easy", "normal", "hard" }
end

function Data.difficultyName(id: string?): string
	return Text.t(Data.DIFFICULTY_NAMES[id or ""] or (id or ""))
end

function Data.difficultyMult(id: string): number
	local d = (Data.Balance.DIFFICULTIES or {})[id]
	return if d and d.score then d.score else 1
end

function Data.tides(): { any }
	return Data.Balance.TIDES or {}
end

function Data.tideScore(): number
	return Data.Balance.TIDE_SCORE or 0.15
end

-- Habilidades, melhorias, oficina -----------------------------------------------

function Data.abilities(): { any }
	return Data.Balance.ABILITIES or {}
end

function Data.ability(id: string?): { [string]: any }
	for _, a in Data.abilities() do
		if a.id == id then
			return a
		end
	end
	return { id = id or "", name = id or "", desc = "", cooldown = 20 }
end

function Data.upgrade(id: string): { [string]: any }
	local u = Data.Upgrades.find and Data.Upgrades.find(id)
	return u or { id = id, name = id, desc = "", max = 1 }
end

function Data.isEvolution(id: string): boolean
	if Data.Upgrades.isEvolution then
		return Data.Upgrades.isEvolution(id)
	end
	for _, e in Data.Upgrades.EVOLUTIONS or {} do
		if e.id == id then
			return true
		end
	end
	return false
end

function Data.meta(): { any }
	return Data.Balance.META or {}
end

function Data.unlocks(): { any }
	return Data.Balance.UNLOCKS or {}
end

function Data.unlockEntry(id: string): { [string]: any }?
	for _, u in Data.unlocks() do
		if u.id == id then
			return u
		end
	end
	return nil
end

local GOALS = {
	midnight = "Sobreviva até a meia-noite em qualquer mapa",
	boss = "Derrote um chefe em qualquer mapa",
	dawn = "Veja o amanhecer em qualquer mapa",
	dawn_medium = "Veja o amanhecer no Médio ou acima",
}

function Data.goalText(id: string): string
	local u = Data.unlockEntry(id)
	local g = u and u.goal
	return if g and GOALS[g] then Text.t(GOALS[g]) else ""
end

function Data.unlockName(id: string): string
	local u = Data.unlockEntry(id)
	local kind = u and u.kind
	if kind == "map" then
		return Text.t(Data.map(id).name)
	elseif kind == "keeper" then
		return Text.t(Data.keeper(id).name)
	elseif kind == "hero" then
		return Text.t(Data.hero(id).name)
	elseif kind == "ability" then
		return Text.t(Data.ability(id).name)
	end
	return Text.t(Data.upgrade(id).name)
end

-- Progresso de um jogador (ProgressJson), com cache pela string. -----------------

local cache: { [Player]: { raw: string, value: any } } = {}

function Data.progress(player: Player?): { [string]: any }
	local p = player or Players.LocalPlayer
	local raw = p:GetAttribute("ProgressJson")
	if type(raw) ~= "string" or raw == "" then
		return { oil = p:GetAttribute("Oil") or 0, meta = {}, unlocked = {}, achievements = {}, seen = {}, stats = {}, settings = {}, history = {} }
	end
	local c = cache[p]
	if c and c.raw == raw then
		return c.value
	end
	local ok, value = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(value) ~= "table" then
		value = {}
	end
	for _, k in { "meta", "unlocked", "achievements", "seen", "stats", "settings" } do
		if type(value[k]) ~= "table" then
			value[k] = {}
		end
	end
	if type(value.history) ~= "table" then
		value.history = {}
	end
	value.oil = value.oil or p:GetAttribute("Oil") or 0
	cache[p] = { raw = raw, value = value }
	return value
end

-- Livre se não estiver na lista de desbloqueios ou se já foi liberado.
function Data.isUnlocked(progress: { [string]: any }, id: string): boolean
	if not Data.unlockEntry(id) then
		return true
	end
	return progress.unlocked[id] == true
end

-- Jogadores ------------------------------------------------------------------

-- Anfitrião: o jogador com a menor vaga (Slot).
function Data.host(): Player?
	local best, bestSlot = nil, math.huge
	for _, p in Players:GetPlayers() do
		local slot = p:GetAttribute("Slot")
		if type(slot) == "number" and slot < bestSlot then
			best, bestSlot = p, slot
		end
	end
	return best
end

function Data.isHost(player: Player?): boolean
	return Data.host() == (player or Players.LocalPlayer)
end

-- Formatação ---------------------------------------------------------------------

function Data.number(n: number?): string
	local s = tostring(math.floor(n or 0))
	local neg = string.sub(s, 1, 1) == "-"
	if neg then
		s = string.sub(s, 2)
	end
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1.")))
	out = string.gsub(out, "^%.", "")
	return (if neg then "-" else "") .. out
end

function Data.time(seconds: number?): string
	local s = math.max(0, math.floor(seconds or 0))
	return string.format("%02d:%02d", s // 60, s % 60)
end

-- Hora da história (18:00 → 06:00) para um instante da partida.
function Data.clock(seconds: number): string
	local minutes = 18 * 60 + math.floor(math.clamp(seconds / Data.RUN_DURATION, 0, 1) * 12 * 60)
	return string.format("%02d:%02d", (minutes // 60) % 24, minutes % 60)
end

-- Hora de uma noite do modo sem fim (cada noite repete 18:00 → 06:00).
function Data.nightClock(seconds: number): string
	local t = seconds % Data.RUN_DURATION
	return Data.clock(t)
end

function Data.ordinal(n: number): string
	return string.format("%dº", n)
end

function Data.decode(raw: any): any
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, v = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok then v else nil
end

function Data.encode(v: any): string
	return HttpService:JSONEncode(v)
end

return Data
