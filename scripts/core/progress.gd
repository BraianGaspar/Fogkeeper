class_name Progress
extends RefCounted
## Progressão entre partidas, salva em user://progress.json: óleo do farol,
## melhorias permanentes da oficina (Balance.META), desbloqueios
## (Balance.UNLOCKS), conquistas, totais e se o tutorial já foi feito.
##
## Desligada (`enabled = false`) no autoplay e nas capturas: tudo fica
## liberado, as melhorias permanentes valem zero e nada é salvo.

const PATH := "user://progress.json"

static var enabled := true
static var read_only := false ## Capturas (--ui): lê o progresso, mas não grava.
static var oil := 0
static var oil_total := 0
static var meta: Dictionary = {} ## id -> nível
static var unlocked: Array[String] = []
static var achievements: Dictionary = {} ## id -> data unix
static var stats: Dictionary = {} ## kills, runs, wins, thieves
static var tutorial_done := false


static func load_progress() -> void:
	if not enabled:
		return
	if not FileAccess.file_exists(PATH):
		_migrate()
		save()
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary:
		push_warning("progress.json inválido; começando do zero.")
		return
	oil = int(data.get("oil", 0))
	oil_total = int(data.get("oil_total", oil))
	meta = {}
	for k: String in data.get("meta", {}):
		meta[k] = int(data["meta"][k])
	unlocked.clear()
	for u: Variant in data.get("unlocked", []):
		unlocked.append(str(u))
	achievements = {}
	for k: String in data.get("achievements", {}):
		achievements[k] = int(data["achievements"][k])
	stats = {}
	for k: String in data.get("stats", {}):
		stats[k] = int(data["stats"][k])
	tutorial_done = bool(data.get("tutorial_done", false))


static func save() -> void:
	if not enabled or read_only:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Não foi possível salvar o progresso: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify({
		"oil": oil, "oil_total": oil_total, "meta": meta, "unlocked": unlocked,
		"achievements": achievements, "stats": stats, "tutorial_done": tutorial_done,
	}, "\t"))


## Primeira vez com progressão: as partidas antigas do histórico rendem o
## óleo e as metas que teriam rendido, e o farol já escolhido continua liberado.
static func _migrate() -> void:
	for run in Records.runs():
		add_oil(oil_for(int(run["score"])), false)
		check_goals(run)
		stats["runs"] = stat("runs") + 1
		stats["kills"] = stat("kills") + int(run["kills"])
		_grant(["first_light"])
		if run["victory"]:
			stats["wins"] = stat("wins") + 1
			_grant(["dawn"])
			if run["difficulty"] in ["hard", "impossible"]:
				_grant(["hard_dawn"])
			if run["difficulty"] == "impossible":
				_grant(["impossible_dawn"])
		for boss: String in run["relics"]:
			_grant(["boss_" + boss])
	if Settings.keeper != "classic" and not unlocked.has(Settings.keeper):
		unlocked.append(Settings.keeper)
	tutorial_done = not Records.runs().is_empty()


## Conquistas de partidas antigas, sem aviso na tela.
static func _grant(ids: Array) -> void:
	for id: String in ids:
		if not achievements.has(id):
			achievements[id] = int(Time.get_unix_time_from_system())


static func stat(key: String) -> int:
	return int(stats.get(key, 0))


static func add_stat(key: String, amount: int = 1) -> void:
	stats[key] = stat(key) + amount


# --- Óleo e oficina ---------------------------------------------------------------

## Óleo que uma partida rende (a Sorte do pescador aumenta).
static func oil_for(score: int) -> int:
	return maxi(Balance.OIL_MIN, roundi(score * Balance.OIL_PER_SCORE * (1.0 + 0.1 * level("fisher"))))


static func add_oil(amount: int, persist: bool = true) -> void:
	if not enabled:
		return
	oil += amount
	oil_total += amount
	if persist:
		save()


static func meta_entry(id: String) -> Dictionary:
	for m: Dictionary in Balance.META:
		if m["id"] == id:
			return m
	return {}


## Nível de uma melhoria permanente (0 com a progressão desligada).
static func level(id: String) -> int:
	return int(meta.get(id, 0)) if enabled else 0


## Custo do próximo nível; -1 se já está no máximo.
static func next_cost(id: String) -> int:
	var m := meta_entry(id)
	var lv := int(meta.get(id, 0))
	if m.is_empty() or lv >= int(m["max"]):
		return -1
	return int(m["cost"]) * (lv + 1)


static func buy_meta(id: String) -> bool:
	var cost := next_cost(id)
	if cost < 0 or oil < cost:
		return false
	oil -= cost
	meta[id] = int(meta.get(id, 0)) + 1
	save()
	return true


# --- Desbloqueios ------------------------------------------------------------------

static func unlock_entry(id: String) -> Dictionary:
	for u: Dictionary in Balance.UNLOCKS:
		if u["id"] == id:
			return u
	return {}


## Mapas, faróis e cartas fora de Balance.UNLOCKS estão sempre liberados.
static func is_unlocked(id: String) -> bool:
	return not enabled or unlock_entry(id).is_empty() or unlocked.has(id)


static func buy_unlock(id: String) -> bool:
	var u := unlock_entry(id)
	if u.is_empty() or unlocked.has(id) or oil < int(u["cost"]):
		return false
	oil -= int(u["cost"])
	unlocked.append(id)
	save()
	return true


## Libera de graça o que tem meta cumprida por esta partida; devolve os ids.
static func check_goals(run: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for u: Dictionary in Balance.UNLOCKS:
		var id: String = u["id"]
		if unlocked.has(id):
			continue
		var met := false
		var dawn: bool = run["victory"] and run.get("mode", "normal") != "boss_rush"
		match u["goal"]:
			"midnight":
				met = float(run["duration"]) >= Balance.RUN_DURATION / 2.0
			"boss":
				met = int(run["bosses"]) > 0
			"dawn":
				met = dawn
			"dawn_medium":
				met = dawn and run["difficulty"] in ["medium", "hard", "impossible"]
		if met:
			unlocked.append(id)
			out.append(id)
	return out


## Texto da meta de um desbloqueio ("" se só se compra com óleo).
static func goal_text(id: String) -> String:
	match unlock_entry(id).get("goal", ""):
		"midnight":
			return TranslationServer.translate("Sobreviva até a meia-noite em qualquer mapa")
		"boss":
			return TranslationServer.translate("Derrote um chefe em qualquer mapa")
		"dawn":
			return TranslationServer.translate("Veja o amanhecer em qualquer mapa")
		"dawn_medium":
			return TranslationServer.translate("Veja o amanhecer no Médio ou acima")
	return ""


## Nome visível de um desbloqueio (mapa, farol ou carta).
static func unlock_name(id: String) -> String:
	match unlock_entry(id).get("kind", ""):
		"map":
			return TranslationServer.translate(Maps.get_map(id)["name"])
		"keeper":
			return TranslationServer.translate(Keepers.get_keeper(id)["name"])
		"upgrade":
			return TranslationServer.translate(Upgrades.find(id)["name"])
		"hero":
			return TranslationServer.translate(Balance.HEROES[id]["name"])
		"ability":
			return TranslationServer.translate(Abilities.find(id)["name"])
	return id
