class_name Records
extends RefCounted
## Histórico de partidas e ranking local, salvos em user://records.json.
## O ranking é deste computador; o online virá com as leaderboards da Steam.
##
## Cada partida é um Dictionary com: id, date (unix), name, map, keeper,
## difficulty, victory, duration, level, kills, bosses, score, breakdown (ver
## Balance.score_breakdown), upgrades (ids na ordem em que foram escolhidos)
## e relics (chefes derrotados, cujas relíquias foram obtidas).

const PATH := "user://records.json"
const MAX_RUNS := 500

static var _runs: Array[Dictionary] = []
static var _loaded := false


## Partidas da mais antiga para a mais recente.
static func runs() -> Array[Dictionary]:
	if not _loaded:
		_load()
	return _runs


static func add(run: Dictionary) -> void:
	runs().append(run)
	while _runs.size() > MAX_RUNS:
		_runs.pop_front()
	_save()


## Substitui uma partida já salva (modo sem fim continua a partida do amanhecer).
static func update(run: Dictionary) -> void:
	for i in runs().size():
		if _runs[i]["id"] == run["id"]:
			_runs[i] = run
			_save()
			return
	add(run)


## Partidas da melhor para a pior. Filtros vazios = todas.
static func ranking(difficulty: String = "", map: String = "") -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for r in runs():
		if (difficulty == "" or r["difficulty"] == difficulty) and (map == "" or r["map"] == map):
			list.append(r)
	list.sort_custom(_better)
	return list


## Posição (1 = primeiro) de uma partida no ranking; 0 se não estiver nele.
static func position_of(id: String, difficulty: String = "", map: String = "") -> int:
	var list := ranking(difficulty, map)
	for i in list.size():
		if list[i]["id"] == id:
			return i + 1
	return 0


## Melhor posição de um jogador no ranking; 0 se ele não tiver partidas.
static func best_position_of(player: String, difficulty: String = "", map: String = "") -> int:
	var list := ranking(difficulty, map)
	for i in list.size():
		if list[i]["name"] == player:
			return i + 1
	return 0


## Critério: pontos; empate → nível maior; empate → quem fez primeiro.
static func _better(a: Dictionary, b: Dictionary) -> bool:
	if a["score"] != b["score"]:
		return a["score"] > b["score"]
	if a["level"] != b["level"]:
		return a["level"] > b["level"]
	return a["date"] < b["date"]


static func _load() -> void:
	_loaded = true
	_runs.clear()
	if not FileAccess.file_exists(PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Array:
		push_warning("records.json inválido; começando um histórico novo.")
		return
	for item: Variant in data:
		if item is Dictionary:
			_runs.append(_normalize(item))


## JSON devolve todo número como float; restaura os tipos e completa campos
## de partidas antigas (antes dos mapas e faróis).
static func _normalize(r: Dictionary) -> Dictionary:
	var upgrades: Array[String] = []
	for u: Variant in r.get("upgrades", []):
		upgrades.append(str(u))
	var relics: Array[String] = []
	for u: Variant in r.get("relics", []):
		relics.append(str(u))
	var bd: Dictionary = r.get("breakdown", {})
	var survival := int(bd.get("survival", 0))
	var kills_pts := int(bd.get("kills", 0))
	var bosses_pts := int(bd.get("bosses", 0))
	var win := int(bd.get("victory", 0))
	var health := int(bd.get("health", 0))
	var endless := int(bd.get("endless", 0))
	return {
		"id": str(r.get("id", "")),
		"date": int(r.get("date", 0)),
		"name": str(r.get("name", Settings.DEFAULT_NAME)),
		"map": str(r.get("map", "bay")),
		"keeper": str(r.get("keeper", "classic")),
		"difficulty": str(r.get("difficulty", "normal")),
		"victory": bool(r.get("victory", false)),
		"duration": float(r.get("duration", 0.0)),
		"level": int(r.get("level", 1)),
		"kills": int(r.get("kills", 0)),
		"bosses": int(r.get("bosses", 0)),
		"score": int(r.get("score", 0)),
		"breakdown": {
			"kills": kills_pts, "survival": survival, "endless": endless, "bosses": bosses_pts, "victory": win, "health": health,
			"subtotal": int(bd.get("subtotal", kills_pts + survival + endless + bosses_pts + win + health)),
			"multiplier": float(bd.get("multiplier", 1.0)),
			"total": int(bd.get("total", r.get("score", 0))),
		},
		"upgrades": upgrades,
		"relics": relics,
	}


## "1º lugar", "1st place", "1.º puesto", "1er rang", "1. Platz"...
static func ordinal(n: int) -> String:
	match Settings.locale:
		"en":
			var suffix := "th"
			if n % 100 < 11 or n % 100 > 13:
				suffix = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
			return "%d%s place" % [n, suffix]
		"es":
			return "%d.º puesto" % n
		"fr":
			return "%d%s place" % [n, "re" if n == 1 else "e"]
		"de":
			return "%d. Platz" % n
		"ru":
			return "%d-е место" % n
		"zh_CN":
			return "第%d名" % n
		"ja":
			return "%d位" % n
		"ko":
			return "%d위" % n
	return "%dº lugar" % n


## Idiomas que escrevem números e datas no estilo asiático/inglês.
static func _dot_decimal() -> bool:
	return Settings.locale in ["en", "zh_CN", "ja", "ko"]


static func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Não foi possível salvar o histórico: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(_runs, "\t"))


# --- Formatação ------------------------------------------------------------

static func format_date(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	var d := Time.get_datetime_dict_from_unix_time(unix + bias * 60)
	if _dot_decimal():
		return "%04d-%02d-%02d %02d:%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"]]
	if Settings.locale == "de" or Settings.locale == "ru":
		return "%02d.%02d.%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]
	return "%02d/%02d/%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


static func format_number(n: int) -> String:
	var sep := "."
	if _dot_decimal():
		sep = ","
	elif Settings.locale == "fr" or Settings.locale == "ru":
		sep = " "
	var digits := str(absi(n))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += sep
		out += digits[i]
	return ("-" if n < 0 else "") + out


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]
