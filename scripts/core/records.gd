class_name Records
extends RefCounted
## Histórico de partidas e ranking local, salvos em user://records.json.
## O ranking é deste computador; o online virá com as leaderboards da Steam.
##
## Cada partida é um Dictionary com: id, date (unix), name, difficulty, victory,
## duration, level, kills, score, breakdown (ver Balance.score_breakdown) e
## upgrades (ids na ordem em que foram escolhidos).

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


## Partidas ordenadas da melhor para a pior. difficulty vazio = todas.
static func ranking(difficulty: String = "") -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for r in runs():
		if difficulty == "" or r["difficulty"] == difficulty:
			list.append(r)
	list.sort_custom(_better)
	return list


## Posição (1 = primeiro) de uma partida no ranking; 0 se não estiver nele.
static func position_of(id: String, difficulty: String = "") -> int:
	var list := ranking(difficulty)
	for i in list.size():
		if list[i]["id"] == id:
			return i + 1
	return 0


## Melhor posição de um jogador no ranking; 0 se ele não tiver partidas.
static func best_position_of(player: String, difficulty: String = "") -> int:
	var list := ranking(difficulty)
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


## JSON devolve todo número como float; restaura os tipos esperados.
static func _normalize(r: Dictionary) -> Dictionary:
	var upgrades: Array[String] = []
	for u: Variant in r.get("upgrades", []):
		upgrades.append(str(u))
	var breakdown: Dictionary = r.get("breakdown", {})
	return {
		"id": str(r.get("id", "")),
		"date": int(r.get("date", 0)),
		"name": str(r.get("name", Settings.DEFAULT_NAME)),
		"difficulty": str(r.get("difficulty", "normal")),
		"victory": bool(r.get("victory", false)),
		"duration": float(r.get("duration", 0.0)),
		"level": int(r.get("level", 1)),
		"kills": int(r.get("kills", 0)),
		"score": int(r.get("score", 0)),
		"breakdown": {
			"kills": int(breakdown.get("kills", 0)),
			"survival": int(breakdown.get("survival", 0)),
			"victory": int(breakdown.get("victory", 0)),
			"health": int(breakdown.get("health", 0)),
			"multiplier": float(breakdown.get("multiplier", 1.0)),
			"total": int(breakdown.get("total", r.get("score", 0))),
		},
		"upgrades": upgrades,
	}


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
	if Settings.locale == "en":
		return "%04d-%02d-%02d %02d:%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"]]
	return "%02d/%02d/%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


static func format_number(n: int) -> String:
	var sep := "," if Settings.locale == "en" else "."
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
