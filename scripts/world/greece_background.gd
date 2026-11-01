class_name GreeceBackground
extends Background
## Mar Egeu: o estreito entre dois rochedos brancos, o redemoinho de Caríbdis
## ao longe, colunas de templos afundadas na água rasa e a ilha do farol com
## as ruínas de um templo, oliveiras e uma trirreme ancorada.

const CLIFFS := [Vector3(560, -250, 120), Vector3(-560, 260, 130)] ## x, y, tamanho
const WHIRL := Vector2(-520, -230)
const COLUMNS := [Vector2(-180, 150), Vector2(-150, 178), Vector2(190, -140), Vector2(225, -120), Vector2(160, 190)]
const TEMPLE := [Vector2(-34, -40), Vector2(-12, -48), Vector2(10, -48), Vector2(32, -40)]

var _cliff_pts: Array[PackedVector2Array] = []
var _olives: Array[Vector3] = []


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for cl: Vector3 in CLIFFS:
		var pts := PackedVector2Array()
		for j in 12:
			pts.append(Vector2.from_angle(TAU * j / 12.0) * cl.z * rng.randf_range(0.7, 1.1))
		_cliff_pts.append(pts)
	for p: Vector2 in [Vector2(-60, 30), Vector2(58, 34), Vector2(-20, 70), Vector2(40, 68)]:
		_olives.append(Vector3(p.x, p.y, rng.randf() * TAU))


func _draw() -> void:
	var p := DayCycle.p
	var q := clampi(Settings.quality, 0, 2)
	var view := visible_rect(self).grow(40.0)
	var wave: Color = p["wave"]
	var storm: float = p["storm"]
	var night: float = p["night"]
	_land = p["land"]
	draw_rect(view, p["sea"])
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.5, 0.35))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.78, 0.5))
	_draw_stars(q, night * (1.0 - storm))
	_draw_glints(q, p["moon"])
	_draw_waves(q, wave, storm)
	_draw_whirlpool(wave)
	for i in 4:
		draw_circle(Vector2.ZERO, 175.0 - i * 18.0, Color(wave, 0.035))
	for c: Vector2 in COLUMNS:
		_draw_column(c, wave)
	for i in _cliff_pts.size():
		_draw_cliff(_cliff_pts[i], Vector2(CLIFFS[i].x, CLIFFS[i].y), wave)
	_draw_trireme(wave)
	_draw_island(wave, night, storm, q)


## Caríbdis: o redemoinho que engole os navios do outro lado do estreito.
func _draw_whirlpool(wave: Color) -> void:
	for k in 5:
		var r := 30.0 + k * 22.0
		var a0 := -_time * (1.4 - k * 0.2) + k
		draw_arc(WHIRL, r, a0, a0 + 4.2, 24, Color(wave.lightened(0.2), 0.3 - k * 0.04), 2.5)
	draw_circle(WHIRL, 18.0, Color(0.0, 0.0, 0.02, 0.45))


## Rochedo branco do estreito, com sombra e espuma (`pts` em volta de `center`).
func _draw_cliff(pts: PackedVector2Array, center: Vector2, wave: Color) -> void:
	_draw_foam(pts, center, 0.8, wave, center.x)
	var shadow := PackedVector2Array()
	var rock := PackedVector2Array()
	var inner := PackedVector2Array()
	for v in pts:
		shadow.append(center + v + Vector2(10, 12))
		rock.append(center + v)
		inner.append(center + v * 0.6 + Vector2(-8, -8))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.3))
	draw_colored_polygon(rock, _tint(Color(0.8, 0.78, 0.72)))
	draw_colored_polygon(inner, _tint(Color(0.92, 0.9, 0.86)))


## Coluna de mármore afundada, saindo da água rasa.
func _draw_column(c: Vector2, wave: Color) -> void:
	draw_arc(c, 13.0 + sin(_time * 1.5 + c.x) * 1.5, 0.0, TAU, 18, Color(wave, 0.3), 1.5)
	draw_circle(c + Vector2(2, 3), 8.0, Color(0, 0, 0, 0.25))
	draw_circle(c, 8.0, _tint(Color(0.9, 0.88, 0.84)))
	for i in 8:
		var a := TAU * i / 8.0
		draw_line(c + Vector2.from_angle(a) * 3.0, c + Vector2.from_angle(a) * 7.5, _tint(Color(0.7, 0.68, 0.64)), 1.0)


## Trirreme ancorada: casco comprido, três fileiras de remos e vela quadrada.
func _draw_trireme(wave: Color) -> void:
	var bob := sin(_time * 1.0) * 0.05
	draw_set_transform(Vector2(400, 210), -0.35 + bob)
	var hull := PackedVector2Array([Vector2(-60, 0), Vector2(-50, -10), Vector2(48, -10), Vector2(70, -2), Vector2(48, 10), Vector2(-50, 10)])
	_draw_foam(hull, Vector2.ZERO, 0.3, wave, 2.0)
	for i in 9:
		var x := -42.0 + i * 10.0
		for s: float in [-1.0, 1.0]:
			draw_line(Vector2(x, s * 9.0), Vector2(x - 6.0, s * (22.0 + sin(_time * 2.0 + i) * 2.0)), _tint(Color(0.4, 0.3, 0.2)), 1.5)
	draw_colored_polygon(hull, _tint(Color(0.35, 0.22, 0.14)))
	draw_line(Vector2(-50, 0), Vector2(48, 0), _tint(Color(0.55, 0.15, 0.1)), 2.0)
	draw_circle(Vector2(56, -3), 2.5, _tint(Color(0.95, 0.95, 0.9)))
	draw_rect(Rect2(-8, -22, 14, 44), _tint(Color(0.9, 0.84, 0.72)))
	draw_line(Vector2(-1, -24), Vector2(-1, 24), _tint(Color(0.6, 0.2, 0.15)), 2.0)
	draw_set_transform(Vector2.ZERO)


## Ilha do farol: rocha clara, ruínas de templo e oliveiras.
func _draw_island(wave: Color, night: float, storm: float, _q: int) -> void:
	var shallow := PackedVector2Array()
	for v in _island:
		shallow.append(v * 1.28)
	draw_colored_polygon(shallow, Color(wave, 0.1))
	_draw_foam(_island, Vector2.ZERO, 0.8, wave, 0.0)
	var inner := PackedVector2Array()
	for v in _island:
		inner.append(v * 0.86)
	draw_colored_polygon(_island, _tint(Color(0.8, 0.77, 0.7)))
	draw_colored_polygon(inner, _tint(Color(0.55, 0.58, 0.42)))
	# Base do templo e colunas ainda de pé.
	draw_rect(Rect2(-44, -56, 88, 22), _tint(Color(0.85, 0.83, 0.78)))
	draw_rect(Rect2(-44, -38, 88, 4), Color(0, 0, 0, 0.2))
	for c: Vector2 in TEMPLE:
		draw_circle(c + Vector2(2, 3), 6.0, Color(0, 0, 0, 0.3))
		draw_circle(c, 6.0, _tint(Color(0.95, 0.94, 0.9)))
		draw_arc(c, 4.0, 0.0, TAU, 12, _tint(Color(0.75, 0.73, 0.68)), 1.0)
	# Coluna tombada em pedaços.
	draw_set_transform(Vector2(62, -8), 1.2)
	for i in 3:
		draw_rect(Rect2(-24 + i * 17, -5, 14, 10), _tint(Color(0.9, 0.88, 0.84)))
	draw_set_transform(Vector2.ZERO)
	for o in _olives:
		_draw_olive(Vector2(o.x, o.y), o.z)
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.78, 0.45, 0.035 * warm))


func _draw_olive(c: Vector2, phase: float) -> void:
	var sway := sin(_time * 0.7 + phase) * 1.5
	draw_circle(c + Vector2(5, 6), 12.0, Color(0, 0, 0, 0.25))
	for i in 5:
		var a := TAU * i / 5.0 + phase
		draw_circle(c + Vector2.from_angle(a) * 6.0 + Vector2(sway, 0), 7.0, _tint(Color(0.42, 0.5, 0.38) if i % 2 == 0 else Color(0.5, 0.58, 0.45)))
	draw_circle(c, 3.0, _tint(Color(0.4, 0.32, 0.22)))
