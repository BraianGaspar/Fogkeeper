class_name PulseWave
extends Node2D
## Onda de luz que se expande do farol e atinge cada inimigo uma vez.

var max_radius := 200.0
var damage := 20.0
var duration := 0.45
var enemies_root: Node2D

var _t := 0.0
var _hit := {}


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	var r := max_radius * minf(1.0, _t / duration)
	for node in enemies_root.get_children():
		var e := node as Enemy
		if e == null or e.dying:
			continue
		var id := e.get_instance_id()
		if _hit.has(id):
			continue
		if e.position.length() - e.radius <= r:
			_hit[id] = true
			e.take_light(damage)
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := minf(1.0, _t / duration)
	draw_arc(Vector2.ZERO, max_radius * k, 0.0, TAU, 72, Color(1.0, 0.9, 0.6, 0.6 * (1.0 - k)), 6.0 * (1.0 - k) + 2.0)
