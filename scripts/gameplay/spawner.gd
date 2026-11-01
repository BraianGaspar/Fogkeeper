class_name Spawner
extends Node
## Cria inimigos na borda da tela conforme o tempo de partida. Ritmo e
## composição vêm de Balance (ajustados pela dificuldade); a aparência e os
## chefes vêm do mapa. Avisa os chefes BOSS_WARNING segundos antes.
## No modo sem fim, os chefes do mapa voltam em rodízio.

signal enemy_spawned(enemy: Enemy)
signal boss_warning(boss_id: String)
signal boss_spawned(boss: Boss)

const BOSS_SCRIPTS := {
	"leviathan": preload("res://scripts/gameplay/bosses/leviathan.gd"),
	"kraken": preload("res://scripts/gameplay/bosses/kraken.gd"),
	"jotunn": preload("res://scripts/gameplay/bosses/jotunn.gd"),
	"fenrir": preload("res://scripts/gameplay/bosses/fenrir.gd"),
	"iara": preload("res://scripts/gameplay/bosses/iara.gd"),
	"boitata": preload("res://scripts/gameplay/bosses/boitata.gd"),
	"cuca": preload("res://scripts/gameplay/bosses/cuca.gd"),
	"umibozu": preload("res://scripts/gameplay/bosses/umibozu.gd"),
	"kyubi": preload("res://scripts/gameplay/bosses/kyubi.gd"),
	"sphinx": preload("res://scripts/gameplay/bosses/sphinx.gd"),
	"apep": preload("res://scripts/gameplay/bosses/apep.gd"),
}

var enemies_root: Node2D
var embers_root: Node2D
var lighthouse: Lighthouse
var rng: RandomNumberGenerator
var elapsed := 0.0 ## Definido pelo Main a cada quadro.
var difficulty := "normal"
var map_id := "bay"
var active := false
var tide := 0 ## Maré da partida (Balance.TIDES).

var _timer := 0.0
var _fog_timer := 0.0
var _endless := false
var _schedule: Array[Dictionary] = [] # {t, boss, warned, spawned}


func reset() -> void:
	_timer = 1.0
	_fog_timer = Balance.FOGBANK_START
	_endless = false
	elapsed = 0.0
	_schedule.clear()
	for i in Balance.BOSS_TIMES.size():
		var t := maxf(60.0, float(Balance.BOSS_TIMES[i]) - Balance.tide(tide, "boss_early"))
		_schedule.append({"t": t, "boss": Maps.boss_at(map_id, i), "warned": false, "spawned": false})
	if _diff()["extra_boss"]:
		_schedule.append({"t": Balance.EXTRA_BOSS_TIME, "boss": Maps.boss_at(map_id, 2), "warned": false, "spawned": false})
	_schedule.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])


## Modo sem fim: a partir de agora, um chefe a cada ENDLESS_BOSS_EVERY
## segundos, em rodízio por todos os chefes do mapa.
func start_endless(now: float) -> void:
	_endless = true
	active = true
	_fog_timer = minf(_fog_timer, now + Balance.ENDLESS_FOGBANK_EVERY)
	_schedule.clear()
	var bosses: Array = Maps.get_map(map_id)["bosses"]
	for i in 40:
		_schedule.append({"t": now + Balance.ENDLESS_BOSS_FIRST + i * Balance.ENDLESS_BOSS_EVERY,
			"boss": bosses[i % bosses.size()], "warned": false, "spawned": false})


## Momentos dos chefes que ainda faltam (para o relógio da noite).
func boss_times() -> Array[float]:
	var out: Array[float] = []
	for s in _schedule:
		out.append(float(s["t"]))
	return out


## Valor da dificuldade no tempo atual, já com as marés.
func _value(key: String) -> float:
	var v := Balance.difficulty_value(difficulty, key, elapsed)
	match key:
		"enemy_speed":
			v *= Balance.tide(tide, "speed")
		"enemy_hp":
			v *= Balance.tide(tide, "hp")
		"elite":
			if elapsed >= Balance.ELITE_START:
				v += Balance.tide(tide, "elite")
	return v


## Modo Chefões: sem os chefes da noite normal (o Main chama um por um).
func clear_schedule() -> void:
	_schedule.clear()


func _diff() -> Dictionary:
	return Balance.DIFFICULTIES[difficulty]


func _process(delta: float) -> void:
	if lighthouse == null or not active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += Balance.spawn_interval(elapsed) / _value("spawn")
		for i in Balance.group_size(elapsed):
			if enemies_root.get_child_count() < Balance.MAX_ENEMIES:
				spawn(_pick_role())
	if elapsed >= _fog_timer:
		_fog_timer = elapsed + (Balance.ENDLESS_FOGBANK_EVERY if _endless else Balance.FOGBANK_EVERY)
		spawn("fogbank")
	for s in _schedule:
		if not s["warned"] and elapsed >= float(s["t"]) - Balance.BOSS_WARNING:
			s["warned"] = true
			boss_warning.emit(s["boss"])
		if not s["spawned"] and elapsed >= float(s["t"]):
			s["spawned"] = true
			spawn_boss(s["boss"])


## Próximo chefe ainda por vir: {"boss", "t"} ou vazio.
func next_boss() -> Dictionary:
	for s in _schedule:
		if not s["spawned"]:
			return s
	return {}


func spawn(role: String) -> Enemy:
	var can_elite := role not in ["tentacle", "boulder", "fogbank"]
	var e := _make(role, can_elite and rng.randf() < _value("elite"))
	e.position = Vector2.from_angle(rng.randf() * TAU) * _ring()
	if role == "fogbank":
		e.begin_drift(rng)
	_add(e)
	return e


## Lacaio criado por um chefe numa posição específica.
func spawn_at(role: String, at: Vector2) -> Enemy:
	var e := _make(role, false)
	e.position = at
	_add(e)
	return e


func spawn_boss(id: String) -> Boss:
	var d := _diff()
	var b: Boss = BOSS_SCRIPTS[id].new()
	b.setup_boss(id, Balance.hp_multiplier(elapsed) * _value("enemy_hp"), _value("enemy_damage"), _value("enemy_speed"), d["enrage"] or tide >= 9)
	b.enrage_at = Balance.tide(tide, "enrage")
	b.lighthouse = lighthouse
	b.embers_root = embers_root
	b.begin(rng.randf() * TAU)
	b.spawn_request.connect(spawn_at)
	_add(b)
	boss_spawned.emit(b)
	return b


func _make(role: String, elite: bool) -> Enemy:
	var e := Enemy.new()
	var art: String = Maps.get_map(map_id)["creatures"].get(role, "wraith")
	e.setup(role, art, Balance.hp_multiplier(elapsed) * _value("enemy_hp"), _value("enemy_damage"), _value("enemy_speed"), rng, elite)
	e.lighthouse = lighthouse
	e.embers_root = embers_root
	return e


func _add(e: Enemy) -> void:
	enemies_root.add_child(e)
	enemy_spawned.emit(e)


func _ring() -> float:
	var view := get_viewport().get_visible_rect().size
	if view.length() < 100.0:
		view = Vector2(1280, 720)
	return view.length() * 0.5 + 40.0


func _pick_role() -> String:
	var weights := Balance.spawn_weights(elapsed)
	var total := 0.0
	for k in weights:
		total += weights[k]
	var roll := rng.randf() * total
	for k in weights:
		roll -= weights[k]
		if roll <= 0.0:
			return k
	return "basic"
