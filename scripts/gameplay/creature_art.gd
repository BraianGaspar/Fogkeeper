class_name CreatureArt
extends RefCounted
## Desenho das criaturas comuns de cada mapa, em código.
## Coordenadas locais girando com `face`: +x aponta para o farol.
## `lit` (0..1) puxa as cores para o laranja da queima; `alpha` some na morte.

const BURN := Color(1.0, 0.55, 0.2)


static func draw(ci: CanvasItem, art: String, r: float, t: float, phase: float, face: Vector2, lit: float, alpha: float) -> void:
	ci.draw_set_transform(Vector2.ZERO, face.angle())
	match art:
		"wraith":
			_wraith(ci, r, t, phase, lit, alpha)
		"siren":
			_siren(ci, r, t, phase, lit, alpha)
		"crab":
			_crab(ci, r, t, phase, lit, alpha)
		"draugr":
			_draugr(ci, r, t, phase, lit, alpha)
		"ice_wolf":
			wolf(ci, r, t, phase, lit, alpha, Color(0.78, 0.86, 0.95), Color(0.45, 0.55, 0.68), Color(0.5, 0.95, 1.0))
		"troll":
			_troll(ci, r, t, phase, lit, alpha)
		"tentacle":
			_tentacle(ci, r, t, phase, lit, alpha)
		"boulder":
			_boulder(ci, r, t, phase, lit, alpha)
		_:
			ci.draw_circle(Vector2.ZERO, r, Color(0.4, 0.3, 0.5, alpha))
	ci.draw_set_transform(Vector2.ZERO)


static func c(col: Color, lit: float, alpha: float) -> Color:
	var out := col.lerp(BURN, lit * 0.6)
	out.a = col.a * alpha
	return out


static func eyes(ci: CanvasItem, at: Vector2, gap: float, size: float, col: Color, lit: float, alpha: float) -> void:
	var e := Color(1.0, 1.0, 0.8, alpha) if lit > 0.0 else Color(col, alpha)
	for s: float in [-1.0, 1.0]:
		ci.draw_circle(at + Vector2(0, gap * s), size * 1.8, Color(e, 0.25 * alpha))
		ci.draw_circle(at + Vector2(0, gap * s), size, e)


## Corpo cônico ao longo de uma espinha que ondula (caudas, tentáculos).
static func tail(ci: CanvasItem, from_x: float, length: float, width: float, t: float, phase: float, wave: float, col: Color, steps: int = 10) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var spine := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var x := from_x - length * k
		var y := sin(t * 6.0 + phase + k * 4.0) * wave * k
		var w := width * (1.0 - k * 0.9)
		spine.append(Vector2(x, y))
		top.append(Vector2(x, y - w))
		bottom.append(Vector2(x, y + w))
	bottom.reverse()
	top.append_array(bottom)
	ci.draw_colored_polygon(top, col)
	return spine


static func _wraith(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var body := c(Color(0.5, 0.45, 0.72, 0.85), lit, alpha)
	tail(ci, -r * 0.2, r * 2.6, r * 0.75, t, phase, r * 0.6, Color(body, body.a * 0.6))
	ci.draw_circle(Vector2.ZERO, r * 1.35, Color(body, 0.15 * alpha))
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, c(Color(0.8, 0.75, 1.0, 0.7), lit, alpha), 1.5)
	# Boca escura e olhos frios.
	ci.draw_arc(Vector2(r * 0.25, 0), r * 0.35, -0.9, 0.9, 8, Color(0.05, 0.03, 0.1, 0.7 * alpha), 2.0)
	eyes(ci, Vector2(r * 0.35, 0), r * 0.32, maxf(1.5, r * 0.14), Color(0.75, 0.95, 1.0), lit, alpha)


static func _siren(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var scales := c(Color(0.12, 0.45, 0.5), lit, alpha)
	var skin := c(Color(0.55, 0.72, 0.68), lit, alpha)
	var hair := c(Color(0.08, 0.2, 0.24), lit, alpha)
	var spine := tail(ci, -r * 0.2, r * 2.3, r * 0.55, t * 1.6, phase, r * 0.7, scales)
	var end := spine[spine.size() - 1]
	var fin := c(Color(0.25, 0.7, 0.72), lit, alpha)
	ci.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.7, -r * 0.8), end + Vector2(-r * 0.35, 0)]), fin)
	ci.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.35, 0), end + Vector2(-r * 0.7, r * 0.8)]), fin)
	ci.draw_circle(Vector2.ZERO, r * 0.62, skin)
	# Cabelo esvoaçando para trás.
	tail(ci, r * 0.45, r * 1.5, r * 0.5, t * 2.0, phase + 1.0, r * 0.4, hair, 6)
	ci.draw_circle(Vector2(r * 0.55, 0), r * 0.42, skin)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(0, r * 0.45 * s), Vector2(r * 0.9, r * 0.75 * s), skin, maxf(1.5, r * 0.22))
	eyes(ci, Vector2(r * 0.75, 0), r * 0.16, maxf(1.2, r * 0.1), Color(0.6, 1.0, 0.9), lit, alpha)


static func _crab(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var shell := c(Color(0.55, 0.2, 0.14), lit, alpha)
	var dark := c(Color(0.32, 0.1, 0.08), lit, alpha)
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var x := -r * 0.5 + i * r * 0.45
			var swing := sin(t * 9.0 + phase + i * 1.3) * r * 0.25
			var knee := Vector2(x + swing, s * r * 1.15)
			ci.draw_line(Vector2(x, s * r * 0.5), knee, dark, maxf(1.5, r * 0.14))
			ci.draw_line(knee, knee + Vector2(-r * 0.3, s * r * 0.45), dark, maxf(1.2, r * 0.1))
		# Pinças à frente.
		var arm := Vector2(r * 1.05, s * r * 0.65)
		ci.draw_line(Vector2(r * 0.5, s * r * 0.4), arm, dark, maxf(2.0, r * 0.18))
		var open := 0.3 + 0.25 * sin(t * 4.0 + phase + s)
		ci.draw_circle(arm, r * 0.38, shell)
		ci.draw_colored_polygon(PackedVector2Array([arm, arm + Vector2(r * 0.75, s * r * (0.05 + open)), arm + Vector2(r * 0.4, s * r * 0.1)]), shell)
		ci.draw_colored_polygon(PackedVector2Array([arm, arm + Vector2(r * 0.7, -s * r * open * 0.5), arm + Vector2(r * 0.35, -s * r * 0.05)]), shell)
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		pts.append(Vector2(cos(a) * r * 0.85, sin(a) * r * 1.05))
	ci.draw_colored_polygon(pts, shell)
	ci.draw_circle(Vector2(-r * 0.15, 0), r * 0.5, c(Color(0.7, 0.3, 0.2), lit, alpha))
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(r * 0.6, s * r * 0.25), Vector2(r * 0.95, s * r * 0.3), dark, 1.5)
	eyes(ci, Vector2(r * 0.98, 0), r * 0.3, maxf(1.5, r * 0.11), Color(1.0, 0.9, 0.5), lit, alpha)


static func _draugr(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var cloak := c(Color(0.16, 0.2, 0.26), lit, alpha)
	var armor := c(Color(0.38, 0.42, 0.46), lit, alpha)
	var skin := c(Color(0.45, 0.55, 0.58), lit, alpha)
	var step := sin(t * 5.0 + phase) * r * 0.15
	# Capa rasgada atrás.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 0.9), Vector2(-r * 1.3, -r * 0.7 + step), Vector2(-r * 1.1, 0), Vector2(-r * 1.4, r * 0.6 - step), Vector2(0, r * 0.9)]), cloak)
	var shoulders := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		shoulders.append(Vector2(cos(a) * r * 0.55, sin(a) * r * 0.95))
	ci.draw_colored_polygon(shoulders, armor)
	# Braço com machado.
	ci.draw_line(Vector2(0, r * 0.7), Vector2(r * 0.8 + step, r * 0.95), skin, maxf(1.5, r * 0.2))
	var axe := Vector2(r * 0.8 + step, r * 0.95)
	ci.draw_line(axe + Vector2(-r * 0.6, 0), axe + Vector2(r * 0.5, 0), c(Color(0.35, 0.25, 0.15), lit, alpha), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([axe + Vector2(r * 0.3, 0), axe + Vector2(r * 0.6, r * 0.45), axe + Vector2(r * 0.65, -r * 0.1)]), c(Color(0.6, 0.65, 0.7), lit, alpha))
	ci.draw_line(Vector2(0, -r * 0.7), Vector2(r * 0.7 - step, -r * 0.85), skin, maxf(1.5, r * 0.2))
	# Elmo com chifres curtos.
	ci.draw_circle(Vector2(r * 0.1, 0), r * 0.48, c(Color(0.5, 0.52, 0.55), lit, alpha))
	ci.draw_line(Vector2(r * 0.1, 0), Vector2(r * 0.58, 0), c(Color(0.3, 0.32, 0.35), lit, alpha), 2.0)
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.05, s * r * 0.35), Vector2(-r * 0.2, s * r * 0.9), Vector2(r * 0.25, s * r * 0.42)]), c(Color(0.85, 0.82, 0.7), lit, alpha))
	eyes(ci, Vector2(r * 0.45, 0), r * 0.18, maxf(1.3, r * 0.1), Color(0.4, 0.85, 1.0), lit, alpha)


## Lobo visto de cima; usado pelo lobo de gelo e por Fenrir (cores diferentes).
static func wolf(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, fur: Color, back: Color, eye: Color) -> void:
	var f := c(fur, lit, alpha)
	var b := c(back, lit, alpha)
	var gait := t * 11.0 + phase
	for i in 4:
		var x := r * (0.55 if i < 2 else -0.6)
		var s := -1.0 if i % 2 == 0 else 1.0
		var swing := sin(gait + i * PI * 0.5) * r * 0.35
		ci.draw_line(Vector2(x, s * r * 0.35), Vector2(x + swing, s * r * 0.75), b, maxf(1.5, r * 0.2))
	tail(ci, -r * 1.0, r * 1.2, r * 0.28, t * 0.8, phase, r * 0.35, f, 6)
	var body := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		body.append(Vector2(cos(a) * r * 1.2, sin(a) * r * 0.55))
	ci.draw_colored_polygon(body, f)
	ci.draw_line(Vector2(-r * 0.9, 0), Vector2(r * 0.7, 0), b, maxf(2.0, r * 0.3))
	var head := Vector2(r * 1.15, 0)
	ci.draw_circle(head, r * 0.45, f)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.2, -r * 0.25), head + Vector2(r * 0.8, 0), head + Vector2(r * 0.2, r * 0.25)]), f)
	ci.draw_circle(head + Vector2(r * 0.78, 0), r * 0.08, Color(0.05, 0.05, 0.08, alpha))
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-r * 0.25, s * r * 0.2), head + Vector2(-r * 0.45, s * r * 0.55), head + Vector2(0, s * r * 0.38)]), b)
	eyes(ci, head + Vector2(r * 0.25, 0), r * 0.18, maxf(1.2, r * 0.09), eye, lit, alpha)


static func _troll(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.38, 0.48, 0.52), lit, alpha)
	var dark := c(Color(0.22, 0.28, 0.32), lit, alpha)
	var sway := sin(t * 2.5 + phase) * 0.15
	# Clava arrastada de lado.
	var club := Vector2(-r * 0.2, r * 1.25)
	ci.draw_line(Vector2(r * 0.3, r * 0.75), club, c(Color(0.35, 0.24, 0.15), lit, alpha), maxf(2.0, r * 0.18))
	ci.draw_circle(club, r * 0.38, c(Color(0.4, 0.28, 0.18), lit, alpha))
	ci.draw_circle(Vector2(0, 0), r, skin)
	ci.draw_circle(Vector2(-r * 0.25, 0), r * 0.75, dark)
	# Manchas de gelo e musgo nas costas.
	for i in 4:
		var a := phase + i * 1.6
		ci.draw_circle(Vector2(-r * 0.3 + cos(a) * r * 0.4, sin(a) * r * 0.5), r * 0.16, c(Color(0.75, 0.88, 0.95, 0.8), lit, alpha))
	ci.draw_line(Vector2(0, -r * 0.8), Vector2(r * 0.8, -r * (0.7 + sway)), skin, maxf(2.0, r * 0.28))
	var head := Vector2(r * 0.7, 0)
	ci.draw_circle(head, r * 0.42, skin)
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.25, s * r * 0.15), head + Vector2(r * 0.65, s * r * 0.3), head + Vector2(r * 0.3, s * r * 0.3)]), c(Color(0.92, 0.9, 0.8), lit, alpha))
	eyes(ci, head + Vector2(r * 0.2, 0), r * 0.17, maxf(1.3, r * 0.08), Color(1.0, 0.75, 0.3), lit, alpha)


static func _tentacle(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var col := c(Color(0.5, 0.14, 0.25), lit, alpha)
	var spine := tail(ci, r * 1.0, r * 3.2, r * 0.8, t * 1.4, phase, r * 0.9, col, 12)
	for i in range(2, spine.size(), 2):
		ci.draw_circle(spine[i], maxf(1.0, r * 0.18 * (1.0 - float(i) / spine.size())), c(Color(0.85, 0.55, 0.6), lit, alpha))
	ci.draw_circle(Vector2(r * 0.9, 0), r * 0.3, col)


static func _boulder(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	ci.draw_set_transform(Vector2.ZERO, t * 3.0 + phase)
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * i / 9.0
		pts.append(Vector2.from_angle(a) * r * (0.8 + 0.25 * sin(a * 3.0 + phase)))
	ci.draw_circle(Vector2.ZERO, r * 1.4, Color(0.7, 0.9, 1.0, 0.12 * alpha))
	ci.draw_colored_polygon(pts, c(Color(0.62, 0.8, 0.92), lit, alpha))
	ci.draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.3, c(Color(0.9, 0.97, 1.0), lit, alpha))
	ci.draw_line(Vector2(-r * 0.4, r * 0.1), Vector2(r * 0.3, r * 0.35), c(Color(0.35, 0.5, 0.62), lit, alpha), 1.5)
