-- Sons e música, porta de scripts/audio/sfx.gd. No Godot tudo era sintetizado;
-- o Roblox só toca assets enviados, então cada som é um arquivo de
-- roblox/audio com o id em shared/SoundIds.luau (0 = silêncio, sem erro).
--
-- Canais (SoundGroups em SoundService), como os barramentos do Godot:
--   Geral (master)
--   ├─ Música (music): calma do mapa, tensão e batalha, com transição suave
--   └─ Efeitos (sfx)
--      ├─ Dano (damage): dano no farol
--      └─ Ambiente: o mar em loop, baixo
-- Os 9 grupos do Godot (Balance.SOUND_GROUPS) ligam e desligam famílias de
-- sons. A trilha segue o estado replicado (Sounds.update a cada quadro):
-- calma, tensão nos BOSS_WARNING segundos antes de um chefe, batalha com
-- chefe vivo, nada após a derrota; vitória e derrota tocam o seu tema.
--
-- API: play(name, pitch?, volumeDb?), music(key), setMap(id), setVolumes(music,
-- sfx, master?, damage?), applySettings(settings), update(dt, state),
-- GROUPS, GROUP_NAMES.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local SoundIds = require(Shared:WaitForChild("SoundIds"))

local Sounds = {}

Sounds.GROUPS = Balance.SOUND_GROUPS
Sounds.GROUP_NAMES = {
	ui = "Interface e menus", creatures = "Criaturas queimando", embers = "Brasas coletadas", -- i18n
	damage = "Dano no farol", abilities = "Habilidades e pulso", bosses = "Chefes", -- i18n
	weather = "Trovões", alerts = "Avisos", ambience = "Mar e vento", -- i18n
}

-- Grupo de cada som (SOUND_GROUP do Godot); sem grupo = "ui".
local SOUND_GROUP = {
	hover = "ui", confirm = "ui", back = "ui", level_up = "ui", victory = "ui", defeat = "ui", denied = "ui",
	burn = "creatures", burn_big = "creatures", steal = "creatures", ember = "embers", damage = "damage",
	pulse = "abilities", flash = "abilities", overcharge = "abilities", bell = "abilities",
	boss = "bosses", splash = "bosses", ink = "bosses", throw = "bosses", growl = "bosses", roar = "bosses",
	relic = "bosses", song = "bosses", ignite = "bosses", spell = "bosses",
	thunder = "weather", announce = "alerts", warning = "alerts", achievement = "alerts",
}

-- Nomes que o cliente pede (telas, Fx do servidor) -> som do Godot, com
-- tom e volume (dB) de Main.gd/abilities.gd. `false` = sem som (o servidor
-- já manda outro Fx com o som certo, ou é só visual).
local ALIAS = {
	menu_open = { "confirm" }, menu_back = { "back" }, pick = { "confirm" },
	ability_ready = { "confirm", 1.25, -6 },
	hit = { "damage" }, level = { "level_up" }, evolution = { "level_up", 1.2 },
	boss_warning = { "warning" }, enrage = { "roar" }, combustion = { "burn_big" },
	tide = { "splash", 0.8 }, beacon = { "pulse", 1.4 }, mirror = { "overcharge", 1.3 },
	petrify = { "denied", 0.5 }, unlock = { "relic" }, meta = { "relic" }, purchase = { "achievement" },
	boss_down = false, map = false,
}

-- Intervalo mínimo (s) entre repetições do mesmo som (THROTTLE do Godot).
local THROTTLE = { steal = 0.15, burn = 0.05, ember = 0.035, damage = 0.14, hover = 0.04, pulse = 0.2, denied = 0.2 }
local MIN_REPEAT = 0.03 -- qualquer outro som
local VOICES = 16
local MUSIC_DB = -8
local BOSS_MUSIC_DB = MUSIC_DB + 2
local SEA_DB = -14
local FADE = 2.5 -- segundos de transição entre trilhas

local function dbToVolume(db: number): number
	return 10 ^ (db / 20)
end

local function assetUrl(id: string): string?
	local n = SoundIds[id]
	if type(n) ~= "number" or n <= 0 then
		return nil
	end
	return "rbxassetid://" .. string.format("%d", n)
end

-- Canais ---------------------------------------------------------------------------

local function group(name: string, parent: Instance): SoundGroup
	local g = Instance.new("SoundGroup")
	g.Name = name
	g.Volume = 1
	g.Parent = parent
	return g
end

local masterGroup = group("FkMaster", SoundService)
local musicGroup = group("FkMusic", masterGroup)
local effectsGroup = group("FkEffects", masterGroup)
local damageGroup = group("FkDamage", effectsGroup)
local ambienceGroup = group("FkAmbience", effectsGroup)

local folder = Instance.new("Folder")
folder.Name = "FogkeeperSounds"
folder.Parent = SoundService

local enabled: { [string]: boolean } = {}
for _, g in Sounds.GROUPS do
	enabled[g] = true
end

-- Vozes dos efeitos ------------------------------------------------------------------

local voices: { Sound } = {}
for i = 1, VOICES do
	local s = Instance.new("Sound")
	s.Name = "Voice" .. i
	s.SoundGroup = effectsGroup
	s.Parent = folder
	voices[i] = s
end
local nextVoice = 1
local lastPlay: { [string]: number } = {}

-- Carrega os efeitos curtos antes do primeiro uso (as músicas carregam ao tocar).
task.spawn(function()
	local list = {}
	for id in SOUND_GROUP do
		local url = assetUrl(id)
		if url then
			local s = Instance.new("Sound")
			s.SoundId = url
			table.insert(list, s)
		end
	end
	if #list > 0 then
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end
	for _, s in list do
		s:Destroy()
	end
end)

-- Toca um som pelo nome (id do Godot ou apelido do cliente). Silêncio se o
-- id não tem asset, se o grupo está desligado ou se repetiu cedo demais.
function Sounds.play(name: string, pitch: number?, volumeDb: number?)
	local alias = ALIAS[name]
	if alias == false then
		return
	end
	local id = name
	if alias then
		id = alias[1]
		pitch = pitch or alias[2]
		volumeDb = volumeDb or alias[3]
	end
	local url = assetUrl(id)
	if not url or enabled[SOUND_GROUP[id] or "ui"] == false then
		return
	end
	local now = os.clock()
	if lastPlay[id] and now - lastPlay[id] < (THROTTLE[id] or MIN_REPEAT) then
		return
	end
	lastPlay[id] = now
	local v = voices[nextVoice]
	nextVoice = nextVoice % VOICES + 1
	v:Stop()
	v.SoundId = url
	v.SoundGroup = if id == "damage" then damageGroup else effectsGroup
	v.PlaybackSpeed = pitch or 1
	v.Volume = dbToVolume(volumeDb or 0)
	v.TimePosition = 0
	v:Play()
end

-- Música dinâmica ------------------------------------------------------------------

type Track = { sound: Sound, volume: number, target: number, url: string?, pending: string? }

local function track(name: string): Track
	local s = Instance.new("Sound")
	s.Name = name
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = musicGroup
	s.Parent = folder
	return { sound = s, volume = 0, target = 0, url = nil, pending = nil }
end

local tracks: { [string]: Track } = {
	calm = track("MusicCalm"),
	tension = track("MusicTension"),
	boss = track("MusicBoss"),
}
tracks.tension.pending = assetUrl("music_tension")
tracks.boss.pending = assetUrl("music_boss")

local musicState = "calm"
local mapId = "bay"

local sea = Instance.new("Sound")
sea.Name = "Sea"
sea.Looped = true
sea.Volume = dbToVolume(SEA_DB)
sea.SoundGroup = ambienceGroup
sea.Parent = folder
do
	local url = assetUrl("sea")
	if url then
		sea.SoundId = url
		sea:Play()
	end
end

local function calmUrl(map: string): string?
	return assetUrl("music_" .. map) or assetUrl("music_bay")
end
tracks.calm.pending = calmUrl(mapId)

-- Troca a trilha: "calm", "tension", "boss" ou "none". Também aceita os
-- nomes antigos ("lobby", "tense", ou um id de mapa = calma desse mapa).
function Sounds.music(key: string)
	if key == "lobby" then
		key = "calm"
	elseif key == "tense" then
		key = "tension"
	elseif key ~= "calm" and key ~= "tension" and key ~= "boss" and key ~= "none" then
		Sounds.setMap(key)
		key = "calm"
	end
	musicState = key
end

-- Escolhe a trilha calma do mapa (troca com transição se já estiver tocando).
function Sounds.setMap(id: string)
	if id == mapId then
		return
	end
	mapId = id
	local url = calmUrl(id)
	tracks.calm.pending = if url ~= tracks.calm.url then url else nil
end

local function stepMusic(dt: number)
	local rate = dt * dbToVolume(BOSS_MUSIC_DB) / FADE
	for name, tr in tracks do
		local target = 0
		if name == musicState then
			target = dbToVolume(if name == "boss" then BOSS_MUSIC_DB else MUSIC_DB)
		end
		-- Trilha nova espera a antiga sumir antes de trocar o arquivo.
		local pending = tr.pending
		if pending then
			if tr.volume > 0 and tr.url then
				target = 0
			else
				tr.pending = nil
				tr.url = pending
				tr.sound:Stop()
				tr.sound.SoundId = pending
				tr.sound.TimePosition = 0
			end
		end
		if tr.volume < target then
			tr.volume = math.min(target, tr.volume + rate)
		elseif tr.volume > target then
			tr.volume = math.max(target, tr.volume - rate)
		end
		tr.sound.Volume = tr.volume
		-- Só toca (e gasta) o que está audível ou entrando.
		if tr.volume > 0 and tr.url then
			if not tr.sound.IsPlaying then
				if tr.sound.TimePosition > 0 then
					tr.sound:Resume()
				else
					tr.sound:Play()
				end
			end
		elseif tr.sound.IsPlaying then
			tr.sound:Pause()
		end
	end
end

-- Estado da partida -> trilha, mapa, temas de vitória e derrota.
local lastResult: string? = nil

function Sounds.update(dt: number, state: Instance)
	local phase = state:GetAttribute("Phase") or "lobby"
	local map = state:GetAttribute("Map")
	if type(map) == "string" and map ~= "" then
		Sounds.setMap(map)
	end
	local result = if phase == "ended" then state:GetAttribute("Result") else nil
	if result ~= lastResult then
		lastResult = result
		if result == "victory" then
			Sounds.play("victory")
		elseif result == "defeat" then
			Sounds.play("defeat")
		end
	end
	if phase == "playing" then
		if state:GetAttribute("Paused") == true then
			-- Pausado: mantém a trilha (o relógio do próximo chefe parou).
		elseif state:GetAttribute("Reviving") == true then
			musicState = "none"
		elseif (state:GetAttribute("BossName") or "") ~= "" then
			musicState = "boss"
		else
			local at = state:GetAttribute("NextBossAt")
			local left = if type(at) == "number" and at > 0 then at - workspace:GetServerTimeNow() else math.huge
			musicState = if left >= 0 and left <= Balance.BOSS_WARNING then "tension" else "calm"
		end
	elseif phase == "ended" then
		musicState = if result == "defeat" then "none" else "calm"
	else
		musicState = "calm"
	end
	stepMusic(dt)
end

-- Volumes e grupos -----------------------------------------------------------------

-- Volumes de 0 a 1 (o antigo setVolumes(música, efeitos) continua valendo).
function Sounds.setVolumes(musicV: number, sfxV: number, masterV: number?, damageV: number?)
	musicGroup.Volume = math.clamp(musicV, 0, 1)
	effectsGroup.Volume = math.clamp(sfxV, 0, 1)
	if masterV then
		masterGroup.Volume = math.clamp(masterV, 0, 1)
	end
	if damageV then
		damageGroup.Volume = math.clamp(damageV, 0, 1)
	end
end

-- Aplica as configurações salvas (ProgressJson.settings): volumes 0–100 e
-- sounds = {grupo = bool}.
function Sounds.applySettings(s)
	Sounds.setVolumes((s.music or 80) / 100, (s.sfx or 100) / 100, (s.master or 100) / 100, (s.damage or 80) / 100)
	local groups = if type(s.sounds) == "table" then s.sounds else {}
	for _, g in Sounds.GROUPS do
		enabled[g] = groups[g] ~= false
	end
	ambienceGroup.Volume = if enabled.ambience then 1 else 0
end

return Sounds
