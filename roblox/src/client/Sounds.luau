-- Sons e música. No Godot tudo era sintetizado em código; o Roblox não gera
-- áudio, então cada som é um asset. PREENCHA os ids abaixo com áudios do
-- Creator Store (create.roblox.com/store/audio) que tenham licença de uso
-- na sua experiência, ou com áudios enviados por você. Id vazio = silêncio.
-- Formato: "rbxassetid://123456789".

local SoundService = game:GetService("SoundService")

local Sounds = {}

Sounds.IDS = {
	-- Interface
	menu_open = "", menu_back = "", pick = "", denied = "", ability_ready = "",
	-- Partida
	flash = "", pulse = "", hit = "", splash = "", ink = "", tide = "", beacon = "", level = "", relic = "",
	achievement = "", unlock = "", petrify = "", boss_warning = "", boss_down = "", burn = "", victory = "", defeat = "",
	-- Chefes (Fx "sfx")
	throw = "", hover = "", growl = "", song = "", ignite = "", spell = "", announce = "", roar = "", burn_big = "",
	warning = "", thunder = "",
}

-- Trilha calma de cada mapa, tensão e batalha de chefe.
Sounds.MUSIC = {
	bay = "", fjord = "", amazon = "", japan = "", egypt = "", greece = "", celtic = "",
	lobby = "", boss = "", tense = "",
}

-- Volume de cada som (alguns são naturalmente mais altos).
Sounds.VOLUME = { hit = 0.6, burn = 0.4, pick = 0.7 }

local musicVolume = 0.8
local sfxVolume = 1.0
local folder = Instance.new("Folder")
folder.Name = "FogkeeperSounds"
folder.Parent = SoundService
local music: Sound? = nil
local musicId = ""
local lastPlay: { [string]: number } = {}

function Sounds.setVolumes(musicV: number, sfxV: number)
	musicVolume = musicV
	sfxVolume = sfxV
	if music then
		music.Volume = 0.5 * musicVolume
	end
end

-- Toca um som pelo nome (ignora nomes sem id e repetições em menos de 60 ms).
function Sounds.play(name: string)
	local id = Sounds.IDS[name]
	if not id or id == "" or sfxVolume <= 0 then
		return
	end
	local now = os.clock()
	if lastPlay[name] and now - lastPlay[name] < 0.06 then
		return
	end
	lastPlay[name] = now
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = (Sounds.VOLUME[name] or 1) * sfxVolume
	s.Parent = folder
	s.Ended:Connect(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(15, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

-- Troca a música (mapa, chefe, saguão); a mesma não recomeça.
function Sounds.music(key: string)
	local id = Sounds.MUSIC[key] or ""
	if id == musicId then
		return
	end
	musicId = id
	if music then
		music:Destroy()
		music = nil
	end
	if id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = true
	s.Volume = 0.5 * musicVolume
	s.Parent = folder
	s:Play()
	music = s
end

return Sounds
