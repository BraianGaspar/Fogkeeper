class_name DesertBackground
extends Background
## Farol de Alexandria: mar de um lado e o litoral do deserto do outro, com
## dunas e pirâmides ao longe, colunas de templos afundadas na água rasa, um
## obelisco tombado e a ilha de Faros com as ruínas do farol antigo, palmeiras
## e um feluca ancorado.

const SHORE_X := 360.0 ## Onde a areia começa, à direita.
const COLUMNS := [Vector2(-170, 140), Vector2(-205, 120), Vector2(-150, 175), Vector2(180, -150), Vector2(150, -175)]
const PYRAMIDS := [Vector3(540, -235, 62), Vector3(615, -160, 48), Vector3(490, -135, 34)]

var _dunes: Array[Vector3] = []
var _palms: Array[Vector3] = []
var _shore := PackedVector2Array()


func _ready() -> void:
	z_index = -10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.seed = 97
	for i in 64:
		var a := TAU * i / 64.0
		_island.append(Vector2.from_angle(a) * _island_radius(a))
	for i in 9:
		_dunes.append(Vector3(rng.randf_range(SHORE_X + 60, 1100), rng.randf_range(-500, 500), rng.randf_range(60, 120)))
	for p: Vector2 in [Vector2(-60, -44), Vector2(68, 24), Vector2(-48, 58), Vector2(SHORE_X + 40, 150), Vector2(SHORE_X + 70, -250)]:
		_palms.append(Vector3(p.x, p.y, rng.randf() * TAU))
	var y := -700.0
	while y <= 700.0:
		_shore.append(Vector2(SHORE_X + sin(y * 0.012) * 40.0 + sin(y * 0.031) * 14.0, y))
		y += 40.0
	for i in COUNTS["waves"][2]:
		_waves.append(Vector3(rng.randf_range(-0.5, 0.5) * WAVE_AREA.x, rng.randf_range(-0.5, 0.5) * WAVE_AREA.y, rng.randf_range(6.0, 16.0)))
	var moon_dir := Vector2(-0.55, -0.83).normalized()
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
	var sea: Color = p["sea"]
	var wave: Color = p["wave"]
	var storm: float = p["storm"]
	var night: float = p["night"]
	_land = p["land"]
	draw_rect(view, sea)
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.5, 0.25))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.75, 0.4))
	_draw_stars(q, night * (1.0 - storm))
	_draw_glints(q, p["moon"])
	_draw_waves(q, wave, storm)
	_draw_desert(view, wave)
	for i in 4:
		draw_circle(Vector2.ZERO, 175.0 - i * 18.0, Color(wave, 0.03))
	for c: Vector2 in COLUMNS:
		_draw_column(c, wave)
	_draw_felucca(wave)
	_draw_island(wave, night, storm, q)
	for palm in _palms:
		_draw_palm(Vector2(palm.x, palm.y), palm.z)


## Litoral de areia à direita, com dunas e pirâmides ao longe.
func _draw_desert(view: Rect2, wave: Color) -> void:
	var sand := PackedVector2Array(_shore)
	sand.append(Vector2(view.end.x + 400.0, 700))
	sand.append(Vector2(view.end.x + 400.0, -700))
	draw_colored_polygon(sand, _tint(Color(0.72, 0.58, 0.38)))
	draw_polyline(_shore, Color(wave.lightened(0.3), 0.35), 3.0)
	for d in _dunes:
		draw_arc(Vector2(d.x, d.y), d.z, PI * 1.1, PI * 1.9, 16, _tint(Color(0.82, 0.68, 0.45)), 6.0)
		draw_arc(Vector2(d.x, d.y + 6.0), d.z, PI * 1.1, PI * 1.9, 16, _tint(Color(0.6, 0.47, 0.3)), 3.0)
	for pyr: Vector3 in PYRAMIDS:
		var c := Vector2(pyr.x, pyr.y)
		var s := pyr.z
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.6), c + Vector2(0, -s * 0.6), c + Vector2(s, s * 0.6)]), _tint(Color(0.78, 0.63, 0.4)))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.6), c + Vector2(s, s * 0.6), c + Vector2(s * 0.15, s * 0.6)]), _tint(Color(0.55, 0.42, 0.26)))


## Coluna de templo afundada, saindo da água rasa.
func _draw_column(c: Vector2, wave: Color) -> void:
	draw_arc(c, 14.0 + sin(_time * 1.5 + c.x) * 1.5, 0.0, TAU, 18, Color(wave, 0.3), 1.5)
	draw_circle(c + Vector2(2, 3), 9.0, Color(0, 0, 0, 0.25))
	draw_circle(c, 9.0, _tint(Color(0.78, 0.7, 0.55)))
	for i in 6:
		var a := TAU * i / 6.0
		draw_line(c + Vector2.from_angle(a) * 4.0, c + Vector2.from_angle(a) * 8.0, _tint(Color(0.6, 0.52, 0.4)), 1.0)


## Feluca: barco do Nilo de vela triangular, balançando ancorado.
func _draw_felucca(wave: Color) -> void:
	var bob := sin(_time * 1.1) * 0.06
	draw_set_transform(Vector2(-430, -170), 0.5 + bob)
	var hull := PackedVector2Array([Vector2(-34, 0), Vector2(-24, -8), Vector2(26, -8), Vector2(38, 0), Vector2(26, 8), Vector2(-24, 8)])
	_draw_foam(hull, Vector2.ZERO, 0.4, wave, 1.0)
	draw_colored_polygon(hull, _tint(Color(0.45, 0.3, 0.18)))
	draw_colored_polygon(PackedVector2Array([Vector2(-20, 0), Vector2(30, -6), Vector2(10, 30)]), _tint(Color(0.92, 0.88, 0.78)))
	draw_line(Vector2(-22, 2), Vector2(32, -7), _tint(Color(0.35, 0.24, 0.15)), 2.0)
	draw_set_transform(Vector2.ZERO)


## Ilha de Faros: rocha clara com blocos das ruínas do farol antigo.
func _draw_island(wave: Color, night: float, storm: float, _q: int) -> void:
	var shallow := PackedVector2Array()
	for v in _island:
		shallow.append(v * 1.28)
	draw_colored_polygon(shallow, Color(wave, 0.08))
	_draw_foam(_island, Vector2.ZERO, 0.8, wave, 0.0)
	var inner := PackedVector2Array()
	for v in _island:
		inner.append(v * 0.88)
	draw_colored_polygon(_island, _tint(Color(0.78, 0.66, 0.46)))
	draw_colored_polygon(inner, _tint(Color(0.68, 0.56, 0.38)))
	for b: Vector3 in [Vector3(-40, 70, 0.3), Vector3(-20, 78, -0.2), Vector3(55, -55, 0.6), Vector3(70, -36, 0.1)]:
		draw_set_transform(Vector2(b.x, b.y), b.z)
		draw_rect(Rect2(-9 + 2, -6 + 3, 18, 12), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(-9, -6, 18, 12), _tint(Color(0.85, 0.78, 0.62)))
		draw_set_transform(Vector2.ZERO)
	# Obelisco tombado com hieróglifos.
	draw_set_transform(Vector2(30, 70), -0.4)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, -6), Vector2(26, -5), Vector2(36, 0), Vector2(26, 5), Vector2(-34, 6)]), _tint(Color(0.62, 0.5, 0.36)))
	for i in 5:
		draw_rect(Rect2(-28 + i * 10, -2, 4, 4), _tint(Color(0.4, 0.3, 0.2)))
	draw_set_transform(Vector2.ZERO)
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.75, 0.4, 0.035 * warm))


func _draw_palm(c: Vector2, phase: float) -> void:
	var sway := sin(_time * 0.8 + phase) * 0.08
	draw_circle(c + Vector2(5, 6), 13.0, Color(0, 0, 0, 0.25))
	for i in 6:
		var a := TAU * i / 6.0 + phase + sway
		var tip := c + Vector2.from_angle(a) * 18.0
		var side := Vector2.from_angle(a + PI / 2.0) * 4.0
		draw_colored_polygon(PackedVector2Array([c + side, tip, c - side]), _tint(Color(0.25, 0.42, 0.18) if i % 2 == 0 else Color(0.32, 0.5, 0.22)))
	draw_circle(c, 3.5, _tint(Color(0.45, 0.32, 0.18)))
