class_name Settings
extends RefCounted
## Preferências do jogador, salvas em user://settings.cfg.
## Volumes vão de 0 a 100; 0 silencia o canal.

const PATH := "user://settings.cfg"
const QUALITY_LOW := 0
const QUALITY_MEDIUM := 1
const QUALITY_HIGH := 2
const WINDOWED := 0
const BORDERLESS := 1 ## Tela cheia em janela sem borda.
const EXCLUSIVE := 2 ## Tela cheia exclusiva.
const RESOLUTIONS := ["1280x720", "1600x900", "1920x1080", "2560x1440"]
const FOG_LEVELS := [0.7, 1.0, 1.3] ## Leve, normal, densa.
const TEXT_SCALES := [1.0, 1.12, 1.25]
const DEFAULT_NAME := "Faroleiro"

static var locale := "pt_BR"
static var player_name := ""
static var difficulty := "normal"
static var map := "bay"
static var keeper := "classic"
static var hero := "keeper" ## Faroleiro jogável (Balance.HEROES).
static var loadout: Array = ["flash", "overcharge", "bell"] ## As três habilidades equipadas.
static var tide := 0 ## Maré escolhida (0 = sem maré).
static var colorblind := 0 ## 0 desligado, 1 protanopia, 2 deuteranopia, 3 tritanopia.
static var text_scale := 0 ## Índice de TEXT_SCALES.
static var reduce_flashes := false ## Menos clarões e piscadas (fotossensibilidade).
static var quality := QUALITY_HIGH
static var window_mode := WINDOWED
static var resolution := "1280x720"
static var vsync := true
static var screen_shake := true
static var hit_stop := true ## Pausa curta nos golpes fortes.
static var show_story := true ## História do mapa antes da partida.
static var particles := true
static var weather := true
static var lightning_flash := true
static var fog_level := 1
static var master_volume := 80
static var music_volume := 60
static var sfx_volume := 80
static var damage_volume := 80
static var output_device := "Default"
static var sounds: Dictionary = {} ## grupo de som -> ligado (ver Sfx.GROUPS)
static var controls: Dictionary = {} ## ação -> [tecla principal, alternativa]


static func load_settings() -> void:
	locale = _system_locale()
	if OS.has_feature("mobile"):
		# Celular: texto maior e efeitos mais leves por padrão.
		text_scale = 1
		quality = QUALITY_MEDIUM
	controls = GameInput.default_controls()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	locale = cfg.get_value("general", "locale", locale)
	player_name = cfg.get_value("general", "player_name", "")
	difficulty = cfg.get_value("general", "difficulty", "normal")
	map = cfg.get_value("general", "map", "bay")
	keeper = cfg.get_value("general", "keeper", "classic")
	hero = cfg.get_value("general", "hero", "keeper")
	loadout = cfg.get_value("general", "loadout", loadout)
	tide = cfg.get_value("general", "tide", 0)
	colorblind = cfg.get_value("accessibility", "colorblind", 0)
	text_scale = cfg.get_value("accessibility", "text_scale", text_scale)
	reduce_flashes = cfg.get_value("accessibility", "reduce_flashes", false)
	quality = cfg.get_value("graphics", "quality", quality)
	window_mode = cfg.get_value("graphics", "window_mode", WINDOWED)
	resolution = cfg.get_value("graphics", "resolution", "1280x720")
	vsync = cfg.get_value("graphics", "vsync", true)
	screen_shake = cfg.get_value("graphics", "screen_shake", true)
	hit_stop = cfg.get_value("graphics", "hit_stop", true)
	show_story = cfg.get_value("general", "show_story", true)
	particles = cfg.get_value("graphics", "particles", true)
	weather = cfg.get_value("graphics", "weather", true)
	lightning_flash = cfg.get_value("graphics", "lightning_flash", true)
	fog_level = cfg.get_value("graphics", "fog_level", 1)
	master_volume = cfg.get_value("audio", "master", 80)
	music_volume = cfg.get_value("audio", "music", 60)
	sfx_volume = cfg.get_value("audio", "sfx", 80)
	damage_volume = cfg.get_value("audio", "damage", 80)
	output_device = cfg.get_value("audio", "output_device", "Default")
	sounds = cfg.get_value("audio", "sounds", {})
	var saved: Dictionary = cfg.get_value("controls", "keys", {})
	for action: String in saved:
		if controls.has(action):
			controls[action] = saved[action]
	if not I18n.LANGUAGE_NAMES.has(locale):
		locale = "pt_BR"
	if not Balance.DIFFICULTIES.has(difficulty):
		difficulty = "normal"
	if not Maps.LIST.has(map):
		map = "bay"
	if not Keepers.LIST.has(keeper):
		keeper = "classic"
	if not Balance.HEROES.has(hero):
		hero = "keeper"
	if loadout.size() != 3:
		loadout = ["flash", "overcharge", "bell"]


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	cfg.set_value("general", "player_name", player_name)
	cfg.set_value("general", "difficulty", difficulty)
	cfg.set_value("general", "map", map)
	cfg.set_value("general", "keeper", keeper)
	cfg.set_value("general", "hero", hero)
	cfg.set_value("general", "loadout", loadout)
	cfg.set_value("general", "tide", tide)
	cfg.set_value("accessibility", "colorblind", colorblind)
	cfg.set_value("accessibility", "text_scale", text_scale)
	cfg.set_value("accessibility", "reduce_flashes", reduce_flashes)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("graphics", "window_mode", window_mode)
	cfg.set_value("graphics", "resolution", resolution)
	cfg.set_value("graphics", "vsync", vsync)
	cfg.set_value("graphics", "screen_shake", screen_shake)
	cfg.set_value("graphics", "hit_stop", hit_stop)
	cfg.set_value("general", "show_story", show_story)
	cfg.set_value("graphics", "particles", particles)
	cfg.set_value("graphics", "weather", weather)
	cfg.set_value("graphics", "lightning_flash", lightning_flash)
	cfg.set_value("graphics", "fog_level", fog_level)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "damage", damage_volume)
	cfg.set_value("audio", "output_device", output_device)
	cfg.set_value("audio", "sounds", sounds)
	cfg.set_value("controls", "keys", controls)
	cfg.save(PATH)


static func sound_enabled(group: String) -> bool:
	return bool(sounds.get(group, true))


## Aplica idioma, áudio, controles e janela.
static func apply() -> void:
	TranslationServer.set_locale(locale)
	Sfx.apply_volumes()
	if output_device in AudioServer.get_output_device_list():
		AudioServer.output_device = output_device
	GameInput.apply_controls(controls)
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		return
	var mode := DisplayServer.WINDOW_MODE_WINDOWED
	if window_mode == BORDERLESS:
		mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	elif window_mode == EXCLUSIVE:
		mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		var size := resolution_size()
		if DisplayServer.window_get_size() != size:
			DisplayServer.window_set_size(size)
			var screen := DisplayServer.screen_get_usable_rect()
			DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


static func resolution_size() -> Vector2i:
	var parts := resolution.split("x")
	if parts.size() != 2:
		return Vector2i(1280, 720)
	return Vector2i(int(parts[0]), int(parts[1]))


static func display_name() -> String:
	return player_name if player_name != "" else DEFAULT_NAME


static func _system_locale() -> String:
	match OS.get_locale_language():
		"pt":
			return "pt_BR"
		"zh":
			return "zh_CN"
		"es", "fr", "de", "ru", "ja", "ko":
			return OS.get_locale_language()
		_:
			return "en"


## Tamanho de fonte ajustado pela opção de acessibilidade "Tamanho do texto".
static func font(size: int) -> int:
	return roundi(size * float(TEXT_SCALES[clampi(text_scale, 0, TEXT_SCALES.size() - 1)]))
