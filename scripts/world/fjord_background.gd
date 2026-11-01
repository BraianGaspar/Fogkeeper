class_name FjordBackground
extends Background
## Fiorde Congelado: placa de gelo rachada, buracos de água escura, pináculos
## de gelo, drakkar preso no gelo, pedras rúnicas e a ilha nevada. As pegadas
## no gelo contam como o faroleiro chegou à ilha.

const SHIP_POS := Vector2(-440, 200)
const RUNESTONES := [Vector2(-96, -58), Vector2(92, 48), Vector2(-20, 108)]

var _cracks: Array[PackedVector2Array] = []
var _holes: Array[Dictionary] = []
var _spires: Array[Dictionary] = []
var _drifts: Array[Vector3] = []
var _pines: Array[Vector3] = []
var _steps: Array[Vector3] = []


func _ready() -> void:
	z_index = -10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 64:
		var a := TAU * i / 64.0
		_island.append(Vector2.from_angle(a) * _island_radius(a))
	for i in 22:
		var p := Vector2(rng.randf_range(-950, 950), rng.randf_range(-560, 560))
		if p.length() < 170.0:
			continue
		var line := PackedVector2Array([p])
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for j in rng.randi_range(4, 9):
			dir = dir.rotated(rng.randf_range(-0.7, 0.7))
			p += dir * rng.randf_range(18.0, 45.0)
			line.append(p)
		_cracks.append(line)
	for spec: Vector3 in [Vector3(330, -200, 46), Vector3(-300, -250, 34), Vector3(480, 230, 40), Vector3(-560, -40, 30)]:
		var pts := PackedVector2Array()
		for j in 12:
			pts.append(Vector2.from_angle(TAU * j / 12.0) * spec.z * rng.randf_range(0.7, 1.15))
		_holes.append({"pos": Vector2(spec.x, spec.y), "pts": pts, "r": spec.z})
	for spec: Vector3 in [Vector3(-250, 120, 1.0), Vector3(250, -60, 0.8), Vector3(560, -250, 1.2), Vector3(150, 290, 0.9), Vector3(-380, -200, 0.9)]:
		var shards: Array[Vector3] = []
		for j in rng.randi_range(4, 7):
			shards.append(Vector3(rng.randf_range(-22, 22), rng.randf_range(-22, 22), rng.randf_range(10, 26) * spec.z))
		_spires.append({"pos": Vector2(spec.x, spec.y), "shards": shards})
	for i in 40:
		_drifts.append(Vector3(rng.randf_range(-1000, 1000), rng.randf_range(-560, 560), rng.randf_range(30, 90)))
	for p: Vector2 in [Vector2(-62, -42), Vector2(-76, 12), Vector2(-30, -78), Vector2(66, 28), Vector2(-52, 58), Vector2(40, -78), Vector2(78, -18)]:
		_pines.append(Vector3(p.x, p.y, rng.randf_range(10.0, 14.0)))
	# Pegadas do faroleiro: da borda esquerda até a ilha.
	var pos := Vector2(-1000, 120)
	var k := 0
	while pos.x < -105.0:
		var to := (Vector2(-100, 40) - pos).normalized()
		pos += to * 16.0
		_steps.append(Vector3(pos.x, pos.y + (5.0 if k % 2 == 0 else -5.0), to.angle()))
		k += 1
	for i in COUNTS["stars"][2]:
		_stars.append(Vector3(rng.randf_range(-1000, 1000), rng.randf_range(-450, 450), rng.randf_range(0.5, 2.0)))


func _draw() -> void:
	var p := DayCycle.p
	var q := clampi(Settings.quality, 0, 2)
	var view := visible_rect(self).grow(40.0)
	var ice: Color = p["sea"]
	var line: Color = p["wave"]
	var storm: float = p["storm"]
	var night: float = p["night"]
	_land = p["land"]

	draw_rect(view, ice)
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.5, 0.6))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.75, 0.45))
	_draw_aurora_reflection(view, p.get("aurora", 0.0))
	for d in _drifts:
		draw_circle(Vector2(d.x, d.y), d.z, Color(1, 1, 1, 0.045))
	_draw_stars(q, night * (1.0 - storm) * 0.6)
	for c in _cracks:
		draw_polyline(c, Color(line, 0.28), 1.5)
		draw_polyline(c, Color(0, 0, 0, 0.12), 3.5)
	for h in _holes:
		_draw_hole(h, ice, line, night)
	for i in _steps.size():
		var s := _steps[i]
		draw_set_transform(Vector2(s.x, s.y), s.z)
		draw_rect(Rect2(-3, -2, 6, 4), Color(0.1, 0.15, 0.25, 0.22))
		draw_set_transform(Vector2.ZERO)
	_draw_longship(line)
	for sp in _spires:
		_draw_spire(sp)
	_draw_island(line, night, storm, q)
	for r: Vector2 in RUNESTONES:
		_draw_runestone(r, night)


func _draw_aurora_reflection(view: Rect2, aurora: float) -> void:
	if aurora <= 0.02:
		return
	for band in 3:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var col := Color(0.3, 1.0, 0.6) if band != 1 else Color(0.6, 0.4, 1.0)
		var y0 := view.position.y + 120.0 + band * 90.0
		for i in 13:
			var x := view.position.x + view.size.x * i / 12.0
			var y := y0 + sin(x * 0.006 + _time * 0.3 + band) * 50.0
			pts.append(Vector2(x, y - 40.0))
			cols.append(Color(col, 0.0))
		for i in range(12, -1, -1):
			var x := view.position.x + view.size.x * i / 12.0
			var y := y0 + sin(x * 0.006 + _time * 0.3 + band) * 50.0
			pts.append(Vector2(x, y + 30.0))
			cols.append(Color(col, 0.1 * aurora))
		draw_polygon(pts, cols)


func _draw_hole(h: Dictionary, ice: Color, line: Color, night: float) -> void:
	var pos: Vector2 = h["pos"]
	var pts: PackedVector2Array = h["pts"]
	var shifted := PackedVector2Array()
	var rim := PackedVector2Array()
	for v in pts:
		shifted.append(pos + v)
		rim.append(pos + v * 1.15)
	draw_colored_polygon(rim, Color(1, 1, 1, 0.18))
	draw_colored_polygon(shifted, ice.darkened(0.75))
	var r: float = h["r"]
	for i in 3:
		var rr := r * (0.3 + fmod(_time * 0.08 + i * 0.33, 1.0) * 0.6)
		draw_arc(pos, rr, 0.0, TAU, 24, Color(line, 0.12), 1.0)
	# Pedaço de gelo flutuando.
	var floe := pos + Vector2(sin(_time * 0.3 + r) * r * 0.25, cos(_time * 0.25 + r) * r * 0.2)
	draw_circle(floe, r * 0.22, _tint(Color(0.85, 0.92, 0.98)))


func _draw_spire(sp: Dictionary) -> void:
	var pos: Vector2 = sp["pos"]
	for s: Vector3 in sp["shards"]:
		var base := pos + Vector2(s.x, s.y)
		var h := s.z
		draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.3, h * 0.2), base + Vector2(-h * 0.1, -h), base + Vector2(h * 0.35, h * 0.15)]), Color(0, 0, 0, 0.18))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.35, 0), base + Vector2(0, -h * 1.1), base + Vector2(h * 0.35, 0)]), _tint(Color(0.65, 0.85, 0.95)))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.1, 0), base + Vector2(0, -h * 1.1), base + Vector2(h * 0.35, 0)]), _tint(Color(0.85, 0.96, 1.0)))


func _draw_longship(line: Color) -> void:
	draw_set_transform(SHIP_POS, -0.35)
	var hull := PackedVector2Array([Vector2(-70, 0), Vector2(-50, -16), Vector2(50, -16), Vector2(72, 0), Vector2(50, 16), Vector2(-50, 16)])
	draw_colored_polygon(PackedVector2Array([Vector2(-80, 4), Vector2(-50, 26), Vector2(56, 26), Vector2(84, 6)]), Color(0, 0, 0, 0.15))
	draw_colored_polygon(hull, _tint(Color(0.32, 0.22, 0.15)))
	draw_colored_polygon(PackedVector2Array([Vector2(-58, 0), Vector2(-44, -10), Vector2(44, -10), Vector2(60, 0), Vector2(44, 10), Vector2(-44, 10)]), _tint(Color(0.44, 0.32, 0.22)))
	for x in range(-36, 40, 12):
		draw_circle(Vector2(x, -15), 5.0, _tint(Color(0.6, 0.2, 0.16) if (x / 12) % 2 == 0 else Color(0.85, 0.75, 0.4)))
		draw_circle(Vector2(x, 15), 5.0, _tint(Color(0.85, 0.75, 0.4) if (x / 12) % 2 == 0 else Color(0.6, 0.2, 0.16)))
	# Proa em espiral com cabeça de dragão.
	draw_arc(Vector2(78, -6), 8.0, PI * 0.5, PI * 2.0, 12, _tint(Color(0.32, 0.22, 0.15)), 4.0)
	draw_circle(Vector2(86, -8), 4.0, _tint(Color(0.32, 0.22, 0.15)))
	draw_line(Vector2(-8, 0), Vector2(30, -38), _tint(Color(0.38, 0.27, 0.18)), 3.0)
	# Neve acumulada no convés.
	for i in 5:
		draw_circle(Vector2(-40 + i * 20, sin(i * 1.7) * 4.0), 7.0, _tint(Color(0.92, 0.95, 1.0, 0.85)))
	draw_polyline(PackedVector2Array([Vector2(-75, 0), Vector2(-52, -20), Vector2(52, -20), Vector2(78, 0), Vector2(52, 20), Vector2(-52, 20), Vector2(-75, 0)]), Color(line, 0.3), 2.0)
	draw_set_transform(Vector2.ZERO)


func _draw_runestone(pos: Vector2, night: float) -> void:
	draw_circle(pos + Vector2(3, 4), 7.0, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(pos - Vector2(6, 8), Vector2(12, 16)), _tint(Color(0.4, 0.42, 0.45)))
	draw_rect(Rect2(pos - Vector2(6, 8), Vector2(12, 4)), _tint(Color(0.92, 0.95, 1.0)))
	var glow := (0.4 + 0.6 * night) * (0.6 + 0.4 * sin(_time * 1.5 + pos.x))
	draw_line(pos + Vector2(-2, -3), pos + Vector2(2, 5), Color(0.4, 0.95, 1.0, glow), 1.5)
	draw_line(pos + Vector2(2, -3), pos + Vector2(-2, 2), Color(0.4, 0.95, 1.0, glow), 1.5)
	draw_circle(pos, 10.0, Color(0.4, 0.95, 1.0, 0.08 * glow))


func _draw_island(line: Color, night: float, storm: float, q: int) -> void:
	var rim := PackedVector2Array()
	for v in _island:
		rim.append(v * 1.12)
	draw_colored_polygon(rim, Color(1, 1, 1, 0.2))
	draw_colored_polygon(_island, _tint(Color(0.3, 0.32, 0.36)))
	var snow := PackedVector2Array()
	for i in _island.size():
		snow.append(_island[i] * (0.9 + 0.05 * sin(i * 1.3)))
	draw_colored_polygon(snow, _tint(Color(0.9, 0.94, 1.0)))
	for i in 7:
		var a := i * 0.9 + 0.3
		draw_circle(Vector2.from_angle(a) * 60.0, 14.0, _tint(Color(0.78, 0.86, 0.95)))
	# Cabana de pedra com telhado nevado.
	draw_set_transform(Vector2(52, 52), -0.3)
	draw_rect(Rect2(-14 + 4, -10 + 5, 28, 20), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-14, -10, 28, 20), _tint(Color(0.45, 0.42, 0.4)))
	draw_rect(Rect2(-12, -8, 24, 16), _tint(Color(0.95, 0.97, 1.0)))
	draw_line(Vector2(-12, 0), Vector2(12, 0), _tint(Color(0.75, 0.82, 0.92)), 1.5)
	draw_set_transform(Vector2.ZERO)
	if q > 0:
		var chimney := Vector2(52, 52) + Vector2(6, -8)
		for i in 5:
			var k := fmod(_time * 0.22 + i / 5.0, 1.0)
			draw_circle(chimney + Vector2(k * 30.0, -k * 34.0), 3.0 + k * 9.0, Color(0.8, 0.8, 0.85, 0.2 * (1.0 - k)))
	for t in _pines:
		_draw_pine(Vector2(t.x, t.y), t.z)
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.75, 0.4, 0.04 * warm))


func _draw_pine(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(4, 5), r, Color(0, 0, 0, 0.25))
	var star := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		star.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.6))
	draw_colored_polygon(star, _tint(Color(0.1, 0.24, 0.18)))
	draw_circle(c, r * 0.45, _tint(Color(0.92, 0.96, 1.0)))
	draw_circle(c, r * 0.18, _tint(Color(0.2, 0.3, 0.22)))
