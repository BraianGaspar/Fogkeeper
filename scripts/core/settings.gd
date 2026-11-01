class_name Settings
extends RefCounted
## Preferências do jogador, salvas em user://settings.cfg.
## Volumes vão de 0 a 100; 0 silencia o canal.

const PATH := "user://settings.cfg"
const QUALITY_LOW := 0
const QUALITY_MEDIUM := 1
const QUALITY_HIGH := 2
const DEFAULT_NAME := "Faroleiro"

static var locale := "pt_BR"
static var player_name := ""
static var difficulty := "normal"
static var quality := QUALITY_HIGH
static var fullscreen := false
static var vsync := true
static var screen_shake := true
static var master_volume := 80
static var music_volume := 60
static var sfx_volume := 80
static var damage_volume := 80


static func load_settings() -> void:
	locale = _system_locale()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	locale = cfg.get_value("general", "locale", locale)
	player_name = cfg.get_value("general", "player_name", "")
	difficulty = cfg.get_value("general", "difficulty", "normal")
	quality = cfg.get_value("graphics", "quality", QUALITY_HIGH)
	fullscreen = cfg.get_value("graphics", "fullscreen", false)
	vsync = cfg.get_value("graphics", "vsync", true)
	screen_shake = cfg.get_value("graphics", "screen_shake", true)
	master_volume = cfg.get_value("audio", "master", 80)
	music_volume = cfg.get_value("audio", "music", 60)
	sfx_volume = cfg.get_value("audio", "sfx", 80)
	damage_volume = cfg.get_value("audio", "damage", 80)
	if not I18n.LANGUAGE_NAMES.has(locale):
		locale = "pt_BR"
	if not Balance.DIFFICULTIES.has(difficulty):
		difficulty = "normal"


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	cfg.set_value("general", "player_name", player_name)
	cfg.set_value("general", "difficulty", difficulty)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("graphics", "fullscreen", fullscreen)
	cfg.set_value("graphics", "vsync", vsync)
	cfg.set_value("graphics", "screen_shake", screen_shake)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "damage", damage_volume)
	cfg.save(PATH)


## Aplica idioma, volumes e modo de janela.
static func apply() -> void:
	TranslationServer.set_locale(locale)
	Sfx.apply_volumes()
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


static func display_name() -> String:
	return player_name if player_name != "" else DEFAULT_NAME


static func _system_locale() -> String:
	match OS.get_locale_language():
		"pt":
			return "pt_BR"
		"es":
			return "es"
		_:
			return "en"
