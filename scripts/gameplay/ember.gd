class_name Ember
extends Node2D
## Brasa deixada por um inimigo morto. Vale XP quando chega ao farol.
## Só se move até o farol quando tocada pela luz ou dentro do raio de atração.

signal collected(value: int)

var value := 1
var lighthouse: Lighthouse

var lifetime := Balance.EMBER_LIFETIME ## A dificuldade pode encurtar.

var _life := 0.0
var _attracted := false
var _vel := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 2
	_life = lifetime
	_vel = Vector2.from_angle(randf() * TAU) * 30.0


func attract() -> void:
	_attracted = true


func _process(delta: float) -> void:
	_time += delta
	if not _attracted and lighthouse and position.length() < lighthouse.magnet_radius:
		_attracted = true
	if _attracted:
		var dir := -position.normalized()
		_vel = _vel.lerp(dir * Balance.EMBER_PULL_SPEED, minf(1.0, delta * 6.0))
		position += _vel * delta
		if position.length() < Balance.LIGHTHOUSE_RADIUS:
			collected.emit(value)
			queue_free()
			return
	else:
		_vel = _vel.move_toward(Vector2.ZERO, 40.0 * delta)
		position += _vel * delta
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var blink := 1.0
	if not _attracted and _life < 3.0:
		blink = 0.4 + 0.6 * absf(sin(_time * 10.0))
	var s := 3.0 + minf(value, 10) * 0.4
	draw_circle(Vector2.ZERO, s * 3.0, Color(1.0, 0.5, 0.15, 0.12 * blink))
	draw_circle(Vector2.ZERO, s * 1.8, Color(1.0, 0.6, 0.2, 0.3 * blink))
	draw_circle(Vector2.ZERO, s, Color(1.0, 0.85, 0.5, blink))
