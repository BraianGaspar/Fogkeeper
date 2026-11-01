class_name BurnFx
extends Node2D
## Faíscas de uma criatura queimando. Puramente visual: usa o randf() global
## para não mexer na semente da partida.

const LIFE := 0.45

var color := Color(1.0, 0.6, 0.25)
var count := 6
var radius := 12.0

var _t := 0.0
var _sparks: Array[Vector3] = [] # x = ângulo, y = velocidade, z = tamanho


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 6
	for i in count:
		_sparks.append(Vector3(randf() * TAU, randf_range(50.0, 150.0), randf_range(1.5, 3.2)))


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	draw_circle(Vector2.ZERO, radius * (1.0 + k * 1.5), Color(color, 0.22 * (1.0 - k)))
	for s in _sparks:
		var p := Vector2.from_angle(s.x) * s.y * _t * (1.0 - k * 0.5)
		draw_circle(p, s.z * (1.0 - k), Color(color.lightened(0.3), 1.0 - k))
