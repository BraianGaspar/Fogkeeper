class_name Fog
extends Node2D
## Manchas de névoa que derivam lentamente sobre o mar, mais uma vinheta escura.

const COUNT := 18
const AREA := Vector2(1700, 1100)

var _blobs: Array[Dictionary] = []


func _ready() -> void:
	z_index = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in COUNT:
		_blobs.append({
			"pos": Vector2(rng.randf_range(-AREA.x, AREA.x), rng.randf_range(-AREA.y, AREA.y)) * 0.5,
			"vel": Vector2(rng.randf_range(6.0, 16.0), rng.randf_range(-4.0, 4.0)),
			"r": rng.randf_range(90.0, 200.0),
		})


func _process(delta: float) -> void:
	for b in _blobs:
		var p: Vector2 = b["pos"] + b["vel"] * delta
		if p.x > AREA.x * 0.5 + 200.0:
			p.x = -AREA.x * 0.5 - 200.0
		b["pos"] = p
	queue_redraw()


func _draw() -> void:
	for b in _blobs:
		var r: float = b["r"]
		for i in 8:
			draw_circle(b["pos"], r * (1.0 - i * 0.11), Color(0.55, 0.5, 0.68, 0.009))
	var view := get_viewport_rect().size
	var edge := maxf(view.length() * 0.5, 600.0)
	for i in 16:
		draw_arc(Vector2.ZERO, edge + 80.0 - i * 18.0, 0.0, TAU, 128, Color(0.0, 0.0, 0.02, 0.06), 20.0)
