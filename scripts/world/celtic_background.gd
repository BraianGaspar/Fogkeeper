class_name CelticBackground
extends Background
## Costa Celta: penhascos verdes à esquerda, um círculo de pedras numa ilhota,
## florestas de algas na água, um currach (barco de couro) e a ilha do farol
## com uma cruz alta de pedra, ovelhas e urze.

const SHORE_X := -370.0 ## Onde começa o penhasco, à esquerda.
const RING := Vector2(380, -190) ## Ilhota do círculo de pedras.
const KELP := [Vector2(-200, -170), Vector2(240, 140), Vector2(-120, 230), Vector2(180, -260), Vector2(520, 220)]

var _cliff := PackedVector2Array()
var _heather: Array[Vector3] = []
var _sheep: Array[Vector3] = []


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var y := -700.0
	while y <= 700.0:
		_cliff.append(Vector2(SHORE_X + sin(y * 0.011) * 45.0 + sin(y * 0.037) * 16.0, y))
		y += 40.0
	for i in 26:
		var a := rng.randf() * TAU
		var d := rng.randf_range(25.0, 80.0)
		_heather.append(Vector3(cos(a) * d, sin(a) * d, rng.randf()))
	for p: Vector2 in [Vector2(-50, 40), Vector2(-36, 52), Vector2(55, 40), Vector2(SHORE_X - 60, 120), Vector2(SHORE_X - 90, -200)]:
		_sheep.append(Vector3(p.x, p.y, rng.randf() * TAU))


func _draw() -> void:
	var p := DayCycle.p
	var q := clampi(Settings.quality, 0, 2)
	var view := visible_rect(self).grow(40.0)
	var wave: Color = p["wave"]
	var storm: float = p["storm"]
	var night: float = p["night"]
	_land = p["land"]
	draw_rect(view, p["sea"])
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.55, 0.4))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.8, 0.55))
	_draw_stars(q, night * (1.0 - storm))
	_draw_glints(q, p["moon"])
	_draw_waves(q, wave, storm)
	for k: Vector2 in KELP:
		_draw_kelp(k, wave)
	for i in 4:
		draw_circle(Vector2.ZERO, 175.0 - i * 18.0, Color(wave, 0.03))
	_draw_cliffs(view, wave)
	_draw_ring_islet(wave)
	_draw_currach(wave)
	_draw_island(wave, night, storm, q)


## Penhascos verdes com a borda de rocha escura e ovelhas no pasto.
func _draw_cliffs(view: Rect2, wave: Color) -> void:
	var land := PackedVector2Array(_cliff)
	land.append(Vector2(view.position.x - 400.0, 700))
	land.append(Vector2(view.position.x - 400.0, -700))
	var rock := PackedVector2Array()
	for v in _cliff:
		rock.append(v + Vector2(14, 0))
	draw_polyline(rock, Color(wave.lightened(0.3), 0.35), 4.0)
	draw_colored_polygon(land, _tint(Color(0.3, 0.32, 0.3)))
	var grass := PackedVector2Array()
	for v in _cliff:
		grass.append(v + Vector2(-16, 0))
	grass.append(Vector2(view.position.x - 400.0, 700))
	grass.append(Vector2(view.position.x - 400.0, -700))
	draw_colored_polygon(grass, _tint(Color(0.26, 0.45, 0.24)))
	for s in _sheep:
		if s.x < SHORE_X - 20.0:
			_draw_sheep(Vector2(s.x, s.y), s.z)


## Ilhota com o círculo de pedras em pé.
func _draw_ring_islet(wave: Color) -> void:
	var pts := PackedVector2Array()
	for j in 14:
		pts.append(Vector2.from_angle(TAU * j / 14.0) * (62.0 + 6.0 * sin(j * 2.3)))
	_draw_foam(pts, RING, 0.6, wave, 3.0)
	var land := PackedVector2Array()
	for v in pts:
		land.append(RING + v)
	draw_colored_polygon(land, _tint(Color(0.3, 0.42, 0.26)))
	for i in 9:
		var a := TAU * i / 9.0
		var c := RING + Vector2.from_angle(a) * 38.0
		draw_rect(Rect2(c + Vector2(-3, -2), Vector2(9, 8)), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(c + Vector2(-5, -4), Vector2(9, 8)), _tint(Color(0.6, 0.62, 0.6)))
	var glow := 0.5 + 0.5 * sin(_time * 0.8)
	draw_circle(RING, 14.0, Color(0.55, 1.0, 0.8, 0.08 + 0.08 * glow))


## Floresta de algas balançando sob a água.
func _draw_kelp(c: Vector2, wave: Color) -> void:
	for i in 5:
		var base := c + Vector2(i * 9.0 - 18.0, 0)
		var sway := sin(_time * 1.2 + i + c.x) * 8.0
		draw_polyline(PackedVector2Array([base, base + Vector2(sway * 0.5, -12), base + Vector2(sway, -24)]), Color(0.25, 0.45, 0.3, 0.35), 3.0)
	draw_arc(c, 26.0, 0.0, TAU, 18, Color(wave, 0.08), 1.5)


## Currach: barco de couro escuro, leve, com dois remos.
func _draw_currach(wave: Color) -> void:
	var bob := sin(_time * 1.3) * 0.08
	draw_set_transform(Vector2(-250, -260), 0.7 + bob)
	var hull := PackedVector2Array([Vector2(-28, 0), Vector2(-20, -8), Vector2(22, -8), Vector2(32, 0), Vector2(22, 8), Vector2(-20, 8)])
	_draw_foam(hull, Vector2.ZERO, 0.4, wave, 1.5)
	draw_colored_polygon(hull, _tint(Color(0.12, 0.1, 0.09)))
	for i in 3:
		draw_line(Vector2(-14 + i * 14, -7), Vector2(-14 + i * 14, 7), _tint(Color(0.4, 0.3, 0.2)), 1.5)
	for s: float in [-1.0, 1.0]:
		draw_line(Vector2(0, s * 6.0), Vector2(-8, s * 22.0), _tint(Color(0.45, 0.32, 0.2)), 1.5)
	draw_set_transform(Vector2.ZERO)


## Ilha do farol: grama verde, urze, ovelhas e a cruz alta de pedra.
func _draw_island(wave: Color, night: float, storm: float, _q: int) -> void:
	var shallow := PackedVector2Array()
	for v in _island:
		shallow.append(v * 1.28)
	draw_colored_polygon(shallow, Color(wave, 0.08))
	_draw_foam(_island, Vector2.ZERO, 0.8, wave, 0.0)
	var inner := PackedVector2Array()
	for v in _island:
		inner.append(v * 0.88)
	draw_colored_polygon(_island, _tint(Color(0.42, 0.42, 0.4)))
	draw_colored_polygon(inner, _tint(Color(0.28, 0.46, 0.25)))
	for h in _heather:
		draw_circle(Vector2(h.x, h.y), 3.0 + h.z * 2.0, _tint(Color(0.55, 0.35, 0.55) if h.z > 0.5 else Color(0.35, 0.55, 0.3)))
	# Cruz alta celta, com o anel em volta do cruzamento.
	var cross := Vector2(-48, -46)
	draw_rect(Rect2(cross + Vector2(-2, -15), Vector2(8, 36)), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(cross + Vector2(-4, -18), Vector2(8, 36)), _tint(Color(0.62, 0.62, 0.58)))
	draw_rect(Rect2(cross + Vector2(-13, -10), Vector2(26, 8)), _tint(Color(0.62, 0.62, 0.58)))
	draw_arc(cross + Vector2(0, -6), 9.0, 0.0, TAU, 18, _tint(Color(0.55, 0.55, 0.52)), 2.5)
	for s in _sheep:
		if s.x > SHORE_X:
			_draw_sheep(Vector2(s.x, s.y), s.z)
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.75, 0.45, 0.035 * warm))


func _draw_sheep(c: Vector2, phase: float) -> void:
	var nod := sin(_time * 1.5 + phase) * 1.0
	draw_circle(c + Vector2(2, 3), 6.0, Color(0, 0, 0, 0.25))
	draw_circle(c, 6.0, _tint(Color(0.92, 0.92, 0.88)))
	draw_circle(c + Vector2.from_angle(phase) * (6.0 + nod), 2.5, _tint(Color(0.15, 0.13, 0.12)))
