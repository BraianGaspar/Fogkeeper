class_name Background
extends Node2D
## Mar escuro com ondulações e a ilha rochosa do farol.

var _time := 0.0
var _rocks: Array[Vector3] = [] # x, y = posição; z = raio


func _ready() -> void:
	z_index = -10
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var a := rng.randf() * TAU
		var d := rng.randf_range(38.0, Balance.ISLAND_RADIUS - 6.0)
		_rocks.append(Vector3(cos(a) * d, sin(a) * d, rng.randf_range(4.0, 10.0)))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-3000, -3000, 6000, 6000), Color(0.03, 0.05, 0.09))
	var step := 60.0
	for i in 10:
		var r := Balance.ISLAND_RADIUS + 20.0 + i * step + fmod(_time * 8.0, step)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(0.25, 0.4, 0.55, 0.06 * (1.0 - i / 10.0)), 1.5)
	draw_circle(Vector2.ZERO, Balance.ISLAND_RADIUS + 10.0, Color(0.08, 0.16, 0.2))
	draw_circle(Vector2.ZERO, Balance.ISLAND_RADIUS, Color(0.3, 0.28, 0.25))
	for rock in _rocks:
		draw_circle(Vector2(rock.x, rock.y), rock.z, Color(0.22, 0.21, 0.2))
		draw_circle(Vector2(rock.x - 1.5, rock.y - 1.5), rock.z * 0.6, Color(0.36, 0.34, 0.31))
