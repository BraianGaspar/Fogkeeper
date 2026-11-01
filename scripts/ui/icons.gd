class_name Icons
extends RefCounted
## Ícones desenhados em código para melhorias e dificuldades.
## `s` é o meio-tamanho do ícone (raio aproximado).


static func draw(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color) -> void:
	var light := col.lightened(0.5)
	match id:
		"wide_lens":
			_cone(ci, c + Vector2(-s * 0.7, 0), 0.0, 0.62, s * 1.55, col)
			ci.draw_circle(c + Vector2(-s * 0.7, 0), s * 0.18, light)
		"long_lens":
			_cone(ci, c + Vector2(-s * 0.9, 0), 0.0, 0.17, s * 1.85, col)
			ci.draw_circle(c + Vector2(-s * 0.9, 0), s * 0.15, light)
		"intense_flame":
			_flame(ci, c + Vector2(0, s * 0.15), s, col)
		"gears":
			_gear(ci, c, s * 0.8, col)
		"twin_lens":
			_cone(ci, c, 0.0, 0.32, s * 1.0, col)
			_cone(ci, c, PI, 0.32, s * 1.0, col)
			ci.draw_circle(c, s * 0.2, light)
		"pulse":
			for i in 3:
				ci.draw_arc(c, s * (0.35 + i * 0.28), 0.0, TAU, 32, Color(col, 1.0 - i * 0.28), 3.0)
			ci.draw_circle(c, s * 0.16, light)
		"sweeper":
			ci.draw_arc(c, s * 0.72, -PI * 0.2, PI * 1.35, 28, col, 3.5)
			var tip := c + Vector2.from_angle(-PI * 0.2) * s * 0.72
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-8, -6), tip + Vector2(8, -3), tip + Vector2(-2, 9)]), col)
			_cone(ci, c, -PI * 0.65, 0.3, s * 0.65, Color(0.65, 0.88, 1.0))
		"walls":
			for row in 3:
				var y := c.y - s * 0.6 + row * s * 0.42
				var off := (s * 0.3) if row % 2 == 1 else 0.0
				for i in 3:
					var x := c.x - s * 0.9 + off + i * s * 0.6
					if x + s * 0.55 > c.x + s * 0.95:
						continue
					ci.draw_rect(Rect2(x, y, s * 0.55, s * 0.36), col)
					ci.draw_rect(Rect2(x, y, s * 0.55, s * 0.12), Color(light, 0.5))
		"repairs":
			ci.draw_arc(c, s * 0.8, 0.0, TAU, 36, Color(col, 0.5), 2.0)
			ci.draw_rect(Rect2(c.x - s * 0.16, c.y - s * 0.55, s * 0.32, s * 1.1), col)
			ci.draw_rect(Rect2(c.x - s * 0.55, c.y - s * 0.16, s * 1.1, s * 0.32), col)
		"magnet":
			ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.5, 0.0, PI, 20, col, s * 0.32)
			for side: float in [-1.0, 1.0]:
				var x := c.x + side * s * 0.5
				ci.draw_line(Vector2(x, c.y + s * 0.1), Vector2(x, c.y - s * 0.55), col, s * 0.32)
				ci.draw_line(Vector2(x, c.y - s * 0.45), Vector2(x, c.y - s * 0.7), light, s * 0.32)
			for i in 3:
				ci.draw_circle(c + Vector2(-s * 0.3 + i * s * 0.3, -s * 0.95), 2.5, Color(1.0, 0.6, 0.2))
		"fresh_oil":
			ci.draw_circle(c + Vector2(0, s * 0.25), s * 0.5, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.46, s * 0.1), c + Vector2(0, -s * 0.85), c + Vector2(s * 0.46, s * 0.1)]), col)
			ci.draw_circle(c + Vector2(-s * 0.15, s * 0.3), s * 0.14, Color(light, 0.7))
		"easy", "normal", "hard":
			var n := ["easy", "normal", "hard"].find(id) + 1
			for i in n:
				var x := c.x + (i - (n - 1) / 2.0) * s * 0.75
				_flame(ci, Vector2(x, c.y + s * 0.2), s * 0.62, col)
		_:
			ci.draw_circle(c, s * 0.5, col)


static func _cone(ci: CanvasItem, origin: Vector2, angle: float, half: float, length: float, col: Color) -> void:
	var pts := PackedVector2Array([origin])
	var cols := PackedColorArray([Color(col, 0.95)])
	for i in 9:
		var a := angle - half + 2.0 * half * i / 8.0
		pts.append(origin + Vector2.from_angle(a) * length)
		cols.append(Color(col, 0.15))
	ci.draw_polygon(pts, cols)


static func _flame(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c, s * 0.45, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.44, -s * 0.08), c + Vector2(s * 0.1, -s * 1.05), c + Vector2(s * 0.44, -s * 0.08)]), col)
	var inner := Color(1.0, 0.95, 0.75)
	ci.draw_circle(c + Vector2(0, s * 0.1), s * 0.22, inner)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.2, s * 0.05), c + Vector2(0, -s * 0.5), c + Vector2(s * 0.2, s * 0.05)]), inner)


static func _gear(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var teeth := 8
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4)
		var rr := r if (i % 4) < 2 else r * 0.74
		pts.append(c + Vector2.from_angle(a) * rr)
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(c, r * 0.32, UiTheme.INK)
	ci.draw_arc(c, r * 0.5, 0.0, TAU, 24, Color(col.lightened(0.4), 0.6), 1.5)
