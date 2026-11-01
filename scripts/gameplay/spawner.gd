class_name Spawner
extends Node
## Cria inimigos na borda da tela conforme o tempo de partida. Ritmo e
## composição vêm de Balance (ajustados pela dificuldade); a aparência e os
## chefes vêm do mapa. Avisa os chefes BOSS_WARNING segundos antes.

signal enemy_spawned(enemy: Enemy)
signal boss_warning(boss_id: String)
signal boss_spawned(boss: Boss)

const BOSS_SCRIPTS := {
	"leviathan": preload("res://scripts/gameplay/bosses/leviathan.gd"),
	"kraken": preload("res://scripts/gameplay/bosses/kraken.gd"),
	"jotunn": preload("res://scripts/gameplay/bosses/jotunn.gd"),
	"fenrir": preload("res://scripts/gameplay/bosses/fenrir.gd"),
}

var enemies_root: Node2D
var lighthouse: Lighthouse
var rng: RandomNumberGenerator
var elapsed := 0.0 ## Definido pelo Main a cada quadro.
var difficulty := "normal"
var map_id := "bay"
var active := false

var _timer := 0.0
var _schedule: Array[Dictionary] = [] # {t, boss, warned, spawned}


func reset() -> void:
	_timer = 1.0
	elapsed = 0.0
	_schedule.clear()
	for i in Balance.BOSS_TIMES.size():
		_schedule.append({"t": Balance.BOSS_TIMES[i], "boss": Maps.boss_at(map_id, i), "warned": false, "spawned": false})
	if _diff()["extra_boss"]:
		_schedule.append({"t": Balance.EXTRA_BOSS_TIME, "boss": Maps.boss_at(map_id, 0), "warned": false, "spawned": false})
	_schedule.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])


func _value(key: String) -> float:
	return Balance.difficulty_value(difficulty, key, elapsed)


func _diff() -> Dictionary:
	return Balance.DIFFICULTIES[difficulty]


func _process(delta: float) -> void:
	if lighthouse == null or not active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += Balance.spawn_interval(elapsed) / _value("spawn")
		for i in Balance.group_size(elapsed):
			spawn(_pick_role())
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
	var e := _make(role, rng.randf() < _value("elite") and role != "tentacle" and role != "boulder")
	e.position = Vector2.from_angle(rng.randf() * TAU) * _ring()
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
	b.setup_boss(id, Balance.hp_multiplier(elapsed) * _value("enemy_hp"), _value("enemy_damage"), _value("enemy_speed"), d["enrage"])
	b.lighthouse = lighthouse
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
