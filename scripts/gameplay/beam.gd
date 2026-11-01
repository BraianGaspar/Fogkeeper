class_name Beam
extends Node2D
## Um cone de luz que queima inimigos e puxa brasas.
## Filho do Lighthouse; ângulos são absolutos no mundo.

const ARC_STEPS := 20

var offset := 0.0 ## Deslocamento em relação à mira principal (lentes extras).
var angle := 0.0
var range_px := 300.0
var half_angle := 0.25
var dps := 10.0
var intensity := 1.0
var color := Color(1.0, 0.9, 0.62)


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 5


func _process(_delta: float) -> void:
	queue_redraw()


func apply(delta: float, enemies: Array[Node], embers: Array[Node]) -> void:
	var origin := global_position
	for node in enemies:
		var e := node as Enemy
		if e == null or e.dying:
			continue
		if covers(e.global_position - origin, e.radius):
			e.take_light(dps * delta)
	for node in embers:
		var m := node as Ember
		if m and covers(m.global_position - origin, 6.0):
			m.attract()


func covers(rel: Vector2, radius: float) -> bool:
	var d := rel.length()
	if d > range_px + radius:
		return false
	if d < 1.0:
		return true
	var diff := absf(angle_difference(angle, rel.angle()))
	return diff <= half_angle + atan2(radius, d)


func _draw() -> void:
	_draw_cone(half_angle, range_px, 0.45 * intensity)
	_draw_cone(half_angle * 0.35, range_px * 0.92, 0.3 * intensity)


func _draw_cone(half: float, length: float, alpha: float) -> void:
	var pts := PackedVector2Array([Vector2.ZERO])
	var cols := PackedColorArray([Color(color, alpha)])
	for i in ARC_STEPS + 1:
		var a := angle - half + 2.0 * half * i / ARC_STEPS
		pts.append(Vector2.from_angle(a) * length)
		cols.append(Color(color, 0.0))
	draw_polygon(pts, cols)
