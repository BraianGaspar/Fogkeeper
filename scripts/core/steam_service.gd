class_name SteamService
extends RefCounted
## Ponte com a Steam (conquistas, ranking online). Funciona quando o plugin
## GodotSteam está instalado e o jogo roda pela Steam; sem ele, tudo aqui é
## ignorado em silêncio, e o jogo nunca depende da Steam para abrir.
## Instalação: docs/STEAM.md, seção "Integração técnica".

## Id do app no Steamworks (480 = Spacewar, o app de teste da Valve).
const APP_ID := 480

static var _steam: Object = null
static var _boards: Dictionary = {} ## nome -> handle da leaderboard


static func init() -> void:
	if not Engine.has_singleton("Steam"):
		return
	var steam := Engine.get_singleton("Steam")
	var result: Dictionary = steam.call("steamInitEx", false, APP_ID)
	if int(result.get("status", 1)) != 0:
		push_warning("Steam indisponível: %s" % result.get("verbal", ""))
		return
	_steam = steam
	if steam.has_signal("leaderboard_find_result"):
		steam.connect("leaderboard_find_result", _on_board_found)


static func available() -> bool:
	return _steam != null


## Chamar a cada quadro (os callbacks da Steam chegam por aqui).
static func tick() -> void:
	if _steam:
		_steam.call("run_callbacks")


static func achievement(id: String) -> void:
	if _steam:
		_steam.call("setAchievement", id)
		_steam.call("storeStats")


## Envia a pontuação para a leaderboard do mapa e da dificuldade (ou do modo).
static func upload_score(run: Dictionary) -> void:
	if not _steam:
		return
	var board := "fogkeeper_%s_%s" % [run["map"], run["difficulty"]]
	if run.get("mode", "normal") == "boss_rush":
		board = "fogkeeper_boss_rush"
	elif run.get("mode", "normal") == "daily":
		board = "fogkeeper_daily_%s" % str(run.get("daily", "")).replace("-", "")
	_boards[board] = int(run["score"])
	_steam.call("findOrCreateLeaderboard", board, 2, 1) # decrescente, numérico


static func _on_board_found(handle: int, found: int) -> void:
	if found == 0 or _boards.is_empty():
		return
	var score: int = _boards.values()[0]
	_boards.clear()
	_steam.call("uploadLeaderboardScore", score, true, PackedInt32Array(), handle)
