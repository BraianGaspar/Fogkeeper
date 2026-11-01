class_name RingFx
extends Node2D
## Anel de luz que se expande a partir do farol. Puramente visual.

var max_radius := 200.0
var color := Color.WHITE
var duration := 0.5
var width := 6.0

var _t := 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / duration
	var r := max_radius * (1.0 - pow(1.0 - k, 3.0))
	draw_circle(Vector2.ZERO, r, Color(color, 0.12 * (1.0 - k)))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(color, 0.8 * (1.0 - k)), width * (1.0 - k) + 1.0)
