class_name RiverBackground
extends Background
## Rio Encantado: rio largo e barrento correndo entre duas margens de mata
## fechada, vitórias-régias, troncos à deriva, e a ilhota do farol com praia,
## açaizeiros, uma palafita e a canoa que trouxe o faroleiro até aqui.

const CURRENT := Vector2(26.0, 0.0)
const STILT_POS := Vector2(-58, 46)
const PADS := [Vector3(-330, -150, 30), Vector3(260, -210, 24), Vector3(-460, 120, 36), Vector3(420, 150, 28),
	Vector3(180, 250, 20), Vector3(-200, 230, 22), Vector3(560, -60, 26), Vector3(-560, -230, 22), Vector3(330, -40, 16)]

var _bank_top: Array[Vector3] = [] # x, y = copa; z = raio
var _bank_bottom: Array[Vector3] = []
var _palms: Array[Vector3] = []
var _logs: Array[Vector3] = [] # x, y = base; z = fase


func _ready() -> void:
	z_index = -10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	for i in 64:
		var a := TAU * i / 64.0
		_island.append(Vector2.from_angle(a) * _island_radius(a))
	var x := -1100.0
	while x < 1100.0:
		_bank_top.append(Vector3(x, -rng.randf_range(330.0, 380.0), rng.randf_range(26.0, 48.0)))
		_bank_bottom.append(Vector3(x + rng.randf_range(-10, 10), rng.randf_range(330.0, 380.0), rng.randf_range(26.0, 48.0)))
		x += rng.randf_range(28.0, 46.0)
	for p: Vector2 in [Vector2(-60, -40), Vector2(-20, -74), Vector2(62, -30), Vector2(70, 26), Vector2(30, 66)]:
		_palms.append(Vector3(p.x, p.y, rng.randf_range(0.0, TAU)))
	for i in 4:
		_logs.append(Vector3(rng.randf_range(-900, 900), rng.randf_range(-260, 260), rng.randf() * TAU))
	for i in COUNTS["waves"][2]:
		_waves.append(Vector3(rng.randf_range(-0.5, 0.5) * WAVE_AREA.x, rng.randf_range(-0.5, 0.5) * WAVE_AREA.y, rng.randf_range(6.0, 16.0)))
	var moon_dir := Vector2(0.55, -0.83).normalized()
	for i in COUNTS["glints"][2]:
		var along := rng.randf_range(150.0, 950.0)
		var side := rng.randf_range(-1.0, 1.0) * (20.0 + along * 0.14)
		var p := moon_dir * along + moon_dir.orthogonal() * side
		_glints.append(Vector3(p.x, p.y, rng.randf() * TAU))
	for i in COUNTS["stars"][2]:
		_stars.append(Vector3(rng.randf_range(-1000, 1000), rng.randf_range(-450, 450), rng.randf_range(0.5, 2.0)))


func _draw() -> void:
	var p := DayCycle.p
	var q := clampi(Settings.quality, 0, 2)
	var view := visible_rect(self).grow(40.0)
	var water: Color = p["sea"]
	var wave: Color = p["wave"]
	var storm: float = p["storm"]
	var night: float = p["night"]
	_land = p["land"]

	draw_rect(view, water)
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.5, 0.25))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.7, 0.45))
	_draw_stars(q, night * (1.0 - storm) * 0.5)
	_draw_glints(q, p["moon"])
	_draw_current(q, wave, storm)
	for l in _logs:
		_draw_log(l, wave)
	for pad: Vector3 in PADS:
		_draw_pad(pad, wave)
	for i in 4:
		draw_circle(Vector2.ZERO, 170.0 - i * 18.0, Color(wave, 0.03))
	_draw_island(wave, night, storm, q)
	_draw_bank(_bank_top, -1.0, view)
	_draw_bank(_bank_bottom, 1.0, view)


## Correnteza: traços curtos que descem o rio da esquerda para a direita.
func _draw_current(q: int, wave: Color, storm: float) -> void:
	var drift := CURRENT * _time * (1.0 + storm)
	for i in mini(_waves.size(), COUNTS["waves"][q]):
		var w := _waves[i]
		var pos := Vector2(
			fposmod(w.x + drift.x * (0.6 + w.z * 0.05) + WAVE_AREA.x * 0.5, WAVE_AREA.x) - WAVE_AREA.x * 0.5,
			w.y + sin(_time * 0.6 + w.x * 0.01) * 4.0)
		if pos.length() < 150.0 or absf(pos.y) > 320.0:
			continue
		draw_line(pos, pos + Vector2(w.z * 1.6, 0), Color(wave, 0.12 + 0.08 * storm), 1.5)


func _draw_log(l: Vector3, wave: Color) -> void:
	var x := fposmod(l.x + _time * 14.0 + 1100.0, 2200.0) - 1100.0
	var pos := Vector2(x, l.y + sin(_time * 0.5 + l.z) * 6.0)
	if pos.length() < 170.0:
		return
	draw_set_transform(pos, 0.3 * sin(l.z))
	draw_rect(Rect2(-34 + 3, -6 + 4, 68, 12), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(-34, -6, 68, 12), _tint(Color(0.32, 0.22, 0.14)))
	draw_line(Vector2(-30, -2), Vector2(28, -2), _tint(Color(0.42, 0.3, 0.2)), 1.5)
	draw_circle(Vector2(34, 0), 6.0, _tint(Color(0.5, 0.38, 0.24)))
	draw_arc(Vector2(34, 0), 3.0, 0.0, TAU, 10, _tint(Color(0.32, 0.22, 0.14)), 1.0)
	draw_line(Vector2(-10, -6), Vector2(-18, -16), _tint(Color(0.32, 0.22, 0.14)), 2.0)
	draw_set_transform(Vector2.ZERO)
	draw_arc(pos, 40.0, -0.4, 0.4, 8, Color(wave, 0.18), 1.5)


## Vitória-régia: folha redonda de borda virada, às vezes com flor.
func _draw_pad(pad: Vector3, wave: Color) -> void:
	var pos := Vector2(pad.x, pad.y) + Vector2(sin(_time * 0.4 + pad.x) * 3.0, cos(_time * 0.35 + pad.y) * 2.0)
	var r := pad.z
	draw_circle(pos + Vector2(2, 3), r, Color(0, 0, 0, 0.18))
	draw_circle(pos, r, _tint(Color(0.2, 0.42, 0.18)))
	draw_circle(pos, r * 0.88, _tint(Color(0.26, 0.52, 0.22)))
	draw_arc(pos, r, 0.0, TAU, 28, _tint(Color(0.55, 0.3, 0.25)), 2.5)
	var notch := pad.x * 0.01
	draw_colored_polygon(PackedVector2Array([pos, pos + Vector2.from_angle(notch - 0.12) * r * 1.02, pos + Vector2.from_angle(notch + 0.12) * r * 1.02]),
		Color(DayCycle.p["sea"], 1.0))
	for i in 8:
		var a := TAU * i / 8.0 + notch
		draw_line(pos, pos + Vector2.from_angle(a) * r * 0.85, _tint(Color(0.2, 0.42, 0.18)), 1.0)
	if int(pad.z) % 3 == 0:
		for i in 6:
			var a := TAU * i / 6.0 + _time * 0.1
			draw_circle(pos + Vector2(r * 0.3, -r * 0.2) + Vector2.from_angle(a) * 5.0, 4.0, _tint(Color(1.0, 0.75, 0.82)))
		draw_circle(pos + Vector2(r * 0.3, -r * 0.2), 3.0, _tint(Color(1.0, 0.92, 0.6)))


## Margem de mata fechada no alto (side = -1) ou embaixo (side = 1) da tela.
func _draw_bank(trees: Array[Vector3], side: float, view: Rect2) -> void:
	var edge := view.position.y if side < 0.0 else view.end.y
	var pts := PackedVector2Array()
	for t in trees:
		pts.append(Vector2(t.x, t.y - side * t.z * 0.6))
	pts.append(Vector2(trees[-1].x, edge))
	pts.append(Vector2(trees[0].x, edge))
	draw_colored_polygon(pts, _tint(Color(0.07, 0.15, 0.08)))
	# Raízes de mangue entrando na água.
	for i in range(0, trees.size(), 2):
		var t := trees[i]
		var root := Vector2(t.x, t.y - side * t.z * 0.5)
		draw_arc(root + Vector2(0, -side * 8.0), 12.0, 0.0 if side < 0.0 else PI, PI if side < 0.0 else TAU, 8, _tint(Color(0.25, 0.18, 0.12)), 2.0)
	for t in trees:
		var c := Vector2(t.x, t.y)
		draw_circle(c + Vector2(5, 7), t.z, Color(0, 0, 0, 0.25))
		draw_circle(c, t.z, _tint(Color(0.1, 0.24, 0.12)))
		draw_circle(c + Vector2(-t.z * 0.25, -t.z * 0.2), t.z * 0.62, _tint(Color(0.14, 0.32, 0.15)))
		draw_circle(c + Vector2(-t.z * 0.35, -t.z * 0.3), t.z * 0.28, _tint(Color(0.2, 0.42, 0.2)))


func _draw_island(wave: Color, night: float, storm: float, q: int) -> void:
	var shallow := PackedVector2Array()
	for v in _island:
		shallow.append(v * 1.25)
	draw_colored_polygon(shallow, Color(wave, 0.08))
	_draw_foam(_island, Vector2.ZERO, 0.6, wave, 0.0)
	var inner := PackedVector2Array()
	for v in _island:
		inner.append(v * 0.84)
	draw_colored_polygon(_island, _tint(Color(0.72, 0.6, 0.42)))
	draw_colored_polygon(inner, _tint(Color(0.16, 0.3, 0.14)))
	for i in 10:
		var a := i * 0.63 + 0.2
		draw_circle(Vector2.from_angle(a) * 55.0, 12.0, _tint(Color(0.2, 0.38, 0.17)))
	_draw_stilt_house()
	_draw_canoe(wave)
	for palm in _palms:
		_draw_palm(Vector2(palm.x, palm.y), palm.z)
	# Lamparina na palafita e a luz quente do farol no chão.
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.75, 0.4, 0.035 * warm))
	if q > 0:
		var lamp := STILT_POS + Vector2(-12, -10)
		var flick := 0.8 + 0.2 * sin(_time * 9.0)
		draw_circle(lamp, 14.0, Color(1.0, 0.7, 0.3, 0.15 * warm * flick))
		draw_circle(lamp, 2.5, Color(1.0, 0.85, 0.5, 0.4 + 0.6 * warm))


## Palafita: casinha de madeira sobre estacas, com telhado de palha.
func _draw_stilt_house() -> void:
	draw_set_transform(STILT_POS, -0.25)
	for x: float in [-16.0, -6.0, 6.0, 16.0]:
		draw_circle(Vector2(x, 14), 2.0, _tint(Color(0.3, 0.2, 0.12)))
	draw_rect(Rect2(-18 + 4, -14 + 5, 36, 26), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-18, -14, 36, 26), _tint(Color(0.52, 0.36, 0.2)))
	draw_colored_polygon(PackedVector2Array([Vector2(-21, -16), Vector2(21, -16), Vector2(21, -1), Vector2(-21, -1)]), _tint(Color(0.78, 0.66, 0.36)))
	draw_colored_polygon(PackedVector2Array([Vector2(-21, -1), Vector2(21, -1), Vector2(21, 14), Vector2(-21, 14)]), _tint(Color(0.66, 0.54, 0.28)))
	for i in 7:
		var y := -14.0 + i * 4.0
		draw_line(Vector2(-21, y), Vector2(21, y), _tint(Color(0.6, 0.48, 0.25)), 1.0)
	draw_line(Vector2(-21, -1), Vector2(21, -1), _tint(Color(0.45, 0.35, 0.18)), 1.5)
	draw_set_transform(Vector2.ZERO)


## Canoa que trouxe o faroleiro, amarrada na beira.
func _draw_canoe(wave: Color) -> void:
	var bob := sin(_time * 1.1) * 0.06
	draw_set_transform(Vector2(30, 112), 0.2 + bob)
	var hull := PackedVector2Array([Vector2(-30, 0), Vector2(-20, -7), Vector2(22, -7), Vector2(32, 0), Vector2(22, 7), Vector2(-20, 7)])
	_draw_foam(hull, Vector2.ZERO, 0.3, wave, 2.0)
	draw_colored_polygon(hull, _tint(Color(0.38, 0.24, 0.13)))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-17, -4), Vector2(19, -4), Vector2(26, 0), Vector2(19, 4), Vector2(-17, 4)]), _tint(Color(0.24, 0.15, 0.08)))
	draw_line(Vector2(-6, -12), Vector2(14, 12), _tint(Color(0.6, 0.45, 0.26)), 2.0)
	draw_circle(Vector2(14, 12), 3.5, _tint(Color(0.6, 0.45, 0.26)))
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(6, 104), Vector2(-4, 90), _tint(Color(0.75, 0.68, 0.5)), 1.0)


## Açaizeiro visto de cima: folhas compridas em estrela, balançando.
func _draw_palm(c: Vector2, phase: float) -> void:
	var sway := sin(_time * 0.9 + phase) * 0.08
	draw_circle(c + Vector2(5, 6), 13.0, Color(0, 0, 0, 0.25))
	for i in 7:
		var a := TAU * i / 7.0 + phase + sway
		var tip := c + Vector2.from_angle(a) * 17.0
		var side := Vector2.from_angle(a + PI / 2.0) * 3.5
		draw_colored_polygon(PackedVector2Array([c + side, tip, c - side]), _tint(Color(0.16, 0.36, 0.16) if i % 2 == 0 else Color(0.22, 0.45, 0.2)))
	draw_circle(c, 3.5, _tint(Color(0.35, 0.15, 0.3)))
