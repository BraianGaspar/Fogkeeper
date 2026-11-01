class_name Spawner
extends Node
## Cria inimigos na borda da tela conforme o tempo de partida.
## Ritmo e composição vêm de Balance.

signal enemy_spawned(enemy: Enemy)

var enemies_root: Node2D
var lighthouse: Lighthouse
var rng: RandomNumberGenerator
var elapsed := 0.0 ## Definido pelo Main a cada quadro.

var _timer := 0.0
var _boss_index := 0


func reset() -> void:
	_timer = 1.0
	_boss_index = 0
	elapsed = 0.0


func _process(delta: float) -> void:
	if lighthouse == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += Balance.spawn_interval(elapsed)
		for i in Balance.group_size(elapsed):
			spawn(_pick_kind())
	if _boss_index < Balance.BOSS_TIMES.size() and elapsed >= Balance.BOSS_TIMES[_boss_index]:
		_boss_index += 1
		spawn("leviathan")


func spawn(kind: String) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, Balance.hp_multiplier(elapsed), rng)
	e.lighthouse = lighthouse
	var view := get_viewport().get_visible_rect().size
	if view.length() < 100.0:
		view = Vector2(1280, 720)
	var ring := view.length() * 0.5 + 40.0
	e.position = Vector2.from_angle(rng.randf() * TAU) * ring
	enemies_root.add_child(e)
	enemy_spawned.emit(e)
	return e


func _pick_kind() -> String:
	var weights := Balance.spawn_weights(elapsed)
	var total := 0.0
	for k in weights:
		total += weights[k]
	var roll := rng.randf() * total
	for k in weights:
		roll -= weights[k]
		if roll <= 0.0:
			return k
	return "mist"
