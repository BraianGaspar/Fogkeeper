class_name Background
extends Node2D
## Mar, ilha do farol e o cenário em volta: rochedos, naufrágio, boias, cais,
## casa do faroleiro. As cores seguem DayCycle.p e o detalhe segue
## Settings.quality. Puramente visual: roda até com o jogo pausado.

const WAVE_AREA := Vector2(1900, 1150)
const WIND := Vector2(14.0, 5.0)
const HOUSE_POS := Vector2(50, -50)
const HOUSE_ROT := 0.4
const WRECK_POS := Vector2(-440, 205)
const BUOYS := [
	{"pos": Vector2(330, -215), "color": Color(0.3, 1.0, 0.45)},
	{"pos": Vector2(-330, -95), "color": Color(1.0, 0.3, 0.25)},
	{"pos": Vector2(470, 255), "color": Color(1.0, 0.3, 0.25)},
]
const COUNTS := { # por qualidade: baixa, média, alta
	"waves": [60, 120, 180], "glints": [0, 50, 90], "stars": [0, 60, 100],
}

var _time := 0.0
var _land := Color.WHITE
var _island := PackedVector2Array()
var _grass: Array[Vector3] = [] # x, y = posição; z = raio
var _rocks: Array[Vector3] = []
var _trees: Array[Vector3] = []
var _islets: Array[Dictionary] = []
var _waves: Array[Vector3] = [] # x, y = posição base; z = tamanho
var _glints: Array[Vector3] = [] # x, y = posição; z = fase
var _stars: Array[Vector3] = []


func _ready() -> void:
	z_index = -10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 64:
		var a := TAU * i / 64.0
		_island.append(Vector2.from_angle(a) * _island_radius(a))
	for i in 9:
		var a := rng.randf() * TAU
		var d := rng.randf_range(20.0, 62.0)
		_grass.append(Vector3(cos(a) * d, sin(a) * d, rng.randf_range(10.0, 20.0)))
	for i in 12:
		var a := rng.randf() * TAU
		var d := rng.randf_range(70.0, 92.0)
		_rocks.append(Vector3(cos(a) * d, sin(a) * d, rng.randf_range(3.0, 7.0)))
	for p: Vector2 in [Vector2(-62, -42), Vector2(-74, 16), Vector2(-28, -76), Vector2(70, 22), Vector2(-50, 55)]:
		_trees.append(Vector3(p.x, p.y, rng.randf_range(9.0, 13.0)))
	for spec: Vector3 in [Vector3(-380, -195, 26), Vector3(420, 140, 20), Vector3(250, -285, 14),
			Vector3(-250, 270, 18), Vector3(570, -250, 30), Vector3(-575, 30, 22), Vector3(150, 300, 12)]:
		var pts := PackedVector2Array()
		for j in 9:
			pts.append(Vector2.from_angle(TAU * j / 9.0 + rng.randf_range(-0.2, 0.2)) * spec.z * rng.randf_range(0.75, 1.1))
		_islets.append({"pos": Vector2(spec.x, spec.y), "r": spec.z, "pts": pts, "phase": rng.randf() * TAU})
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


static func _island_radius(a: float) -> float:
	return 100.0 + 9.0 * sin(3.0 * a + 1.0) + 5.0 * sin(7.0 * a + 2.0) + 3.0 * sin(11.0 * a)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var p := DayCycle.p
	var q := clampi(Settings.quality, 0, 2)
	var view := visible_rect(self).grow(40.0)
	var sea: Color = p["sea"]
	var wave: Color = p["wave"]
	var storm: float = p["storm"]
	_land = p["land"]

	draw_rect(view, sea)
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.42, 0.3))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.72, 0.38))
	_draw_stars(q, p["night"] * (1.0 - storm))
	_draw_glints(q, p["moon"])
	_draw_waves(q, wave, storm)

	# Água rasa e ondulação em volta da ilha.
	for i in 4:
		draw_circle(Vector2.ZERO, 175.0 - i * 18.0, Color(wave, 0.025))
	var step := 60.0
	for i in 8:
		var r := 125.0 + i * step + fmod(_time * 8.0, step)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(wave, 0.07 * (1.0 - i / 8.0)), 1.5)

	for islet in _islets:
		_draw_islet(islet, wave)
	_draw_wreck(wave)
	for b: Dictionary in BUOYS:
		_draw_buoy(b["pos"], b["color"], p["night"])
	_draw_island(wave, p["night"], storm, q)


func _tint(c: Color) -> Color:
	return Color(c.r * _land.r, c.g * _land.g, c.b * _land.b, c.a)


## Área do mundo visível pela câmera (a câmera se desloca no menu principal).
static func visible_rect(ci: CanvasItem) -> Rect2:
	var inv := ci.get_viewport().get_canvas_transform().affine_inverse()
	return Rect2(inv * Vector2.ZERO, ci.get_viewport_rect().size)


## Brilho do sol baixo numa das bordas: side = -1 esquerda (poente), 1 direita (nascente).
func _side_glow(view: Rect2, side: float, amount: float, col: Color) -> void:
	if amount <= 0.01:
		return
	var edge := view.end.x if side > 0.0 else view.position.x
	var inner := edge - side * view.size.x * 0.8 * amount
	var top := view.position.y
	var bottom := view.end.y
	var pts := PackedVector2Array([Vector2(edge, top), Vector2(inner, top), Vector2(inner, bottom), Vector2(edge, bottom)])
	var a := Color(col, 0.5 * amount)
	var z := Color(col, 0.0)
	draw_polygon(pts, PackedColorArray([a, z, z, a]))


func _draw_stars(q: int, night: float) -> void:
	if night <= 0.01:
		return
	for i in mini(_stars.size(), COUNTS["stars"][q]):
		var s := _stars[i]
		var tw := 0.35 + 0.65 * absf(sin(_time * s.z + s.x))
		draw_rect(Rect2(s.x, s.y, 2.0, 2.0), Color(0.85, 0.9, 1.0, 0.35 * tw * night))


func _draw_glints(q: int, moon: float) -> void:
	if moon <= 0.01:
		return
	for i in mini(_glints.size(), COUNTS["glints"][q]):
		var g := _glints[i]
		var k := pow(maxf(0.0, sin(_time * 1.7 + g.z * 3.0)), 6.0)
		if k < 0.05:
			continue
		var w := 4.0 + 6.0 * k
		draw_line(Vector2(g.x - w, g.y), Vector2(g.x + w, g.y), Color(0.85, 0.92, 1.0, 0.55 * k * moon), 1.5)


func _draw_waves(q: int, wave: Color, storm: float) -> void:
	var drift := WIND * _time * (1.0 + storm * 1.5)
	var alpha := 0.1 + 0.1 * storm
	for i in mini(_waves.size(), COUNTS["waves"][q]):
		var w := _waves[i]
		var pos := Vector2(
			fposmod(w.x + drift.x + WAVE_AREA.x * 0.5, WAVE_AREA.x) - WAVE_AREA.x * 0.5,
			fposmod(w.y + drift.y + WAVE_AREA.y * 0.5, WAVE_AREA.y) - WAVE_AREA.y * 0.5)
		if pos.length() < 150.0:
			continue
		var bob := 0.6 + 0.4 * sin(_time * 1.3 + w.x * 0.05)
		draw_arc(pos, w.z * (1.0 + storm * 0.5), -PI * 0.85, -PI * 0.15, 6, Color(wave, alpha * bob), 1.5)


func _draw_foam(pts: PackedVector2Array, center: Vector2, grow: float, wave: Color, phase: float) -> void:
	var ring := PackedVector2Array()
	for i in pts.size() + 1:
		var v := pts[i % pts.size()]
		var k := 1.0 + grow * (0.6 + 0.4 * sin(_time * 1.6 + i * 0.9 + phase)) / maxf(1.0, v.length()) * 10.0
		ring.append(center + v * k)
	draw_polyline(ring, Color(wave.lightened(0.3), 0.28), 2.5)


func _draw_islet(islet: Dictionary, wave: Color) -> void:
	var pos: Vector2 = islet["pos"]
	var r: float = islet["r"]
	var pts: PackedVector2Array = islet["pts"]
	draw_circle(pos, r * 1.5, Color(wave, 0.04))
	_draw_foam(pts, pos, 0.5, wave, islet["phase"])
	var shifted := PackedVector2Array()
	for v in pts:
		shifted.append(pos + v)
	draw_colored_polygon(shifted, _tint(Color(0.2, 0.2, 0.22)))
	draw_circle(pos + Vector2(-r * 0.2, -r * 0.25), r * 0.45, _tint(Color(0.32, 0.31, 0.32)))
	draw_circle(pos + Vector2(-r * 0.3, -r * 0.35), r * 0.18, _tint(Color(0.45, 0.43, 0.42)))


func _draw_wreck(wave: Color) -> void:
	draw_set_transform(WRECK_POS, -0.6)
	var hull := PackedVector2Array([Vector2(-48, 0), Vector2(-36, -14), Vector2(30, -16), Vector2(48, 0), Vector2(30, 16), Vector2(-36, 14)])
	_draw_foam(hull, Vector2.ZERO, 0.4, wave, 1.0)
	draw_colored_polygon(hull, _tint(Color(0.24, 0.16, 0.11)))
	var deck := PackedVector2Array([Vector2(-40, 0), Vector2(-32, -10), Vector2(26, -11), Vector2(40, 0), Vector2(26, 11), Vector2(-32, 10)])
	draw_colored_polygon(deck, _tint(Color(0.34, 0.24, 0.16)))
	for x in range(-28, 26, 8):
		draw_line(Vector2(x, -10), Vector2(x, 10), _tint(Color(0.2, 0.13, 0.09)), 1.0)
	# Casco partido: o mar entra pelo rombo.
	draw_colored_polygon(PackedVector2Array([Vector2(8, -17), Vector2(20, -6), Vector2(14, 5), Vector2(22, 17), Vector2(2, 17)]), Color(DayCycle.p["sea"], 0.92))
	draw_line(Vector2(-6, 0), Vector2(46, 34), _tint(Color(0.3, 0.21, 0.14)), 3.0)
	draw_line(Vector2(30, 23), Vector2(36, 42), _tint(Color(0.55, 0.5, 0.42)), 1.0)
	draw_set_transform(Vector2.ZERO)


func _draw_buoy(pos: Vector2, light: Color, night: float) -> void:
	var p := pos + Vector2(0, sin(_time * 1.4 + pos.x) * 2.0)
	draw_arc(p, 11.0 + sin(_time * 2.0 + pos.y) * 1.5, 0.0, TAU, 20, Color(1, 1, 1, 0.12), 1.5)
	draw_circle(p + Vector2(2, 3), 7.0, Color(0, 0, 0, 0.3))
	draw_circle(p, 7.0, _tint(Color(0.55, 0.12, 0.1) if light.r > light.g else Color(0.12, 0.42, 0.2)))
	draw_circle(p, 3.0, _tint(Color(0.85, 0.82, 0.75)))
	var blink := clampf(sin(_time * 2.2 + pos.x) * 3.0 - 1.5, 0.0, 1.0)
	if blink > 0.0:
		var glow := 0.4 + 0.6 * night
		for i in 3:
			draw_circle(p, 6.0 + i * 7.0, Color(light, 0.12 * blink * glow))
		draw_circle(p, 2.5, Color(light.lightened(0.5), blink))


func _draw_island(wave: Color, night: float, storm: float, q: int) -> void:
	var shallow := PackedVector2Array()
	for v in _island:
		shallow.append(v * 1.28)
	draw_colored_polygon(shallow, Color(wave, 0.07))
	_draw_foam(_island, Vector2.ZERO, 0.9, wave, 0.0)

	var inner := PackedVector2Array()
	for v in _island:
		inner.append(v * 0.86)
	draw_colored_polygon(_island, _tint(Color(0.6, 0.53, 0.4)))
	draw_colored_polygon(inner, _tint(Color(0.27, 0.27, 0.24)))
	for g in _grass:
		draw_circle(Vector2(g.x, g.y), g.z, _tint(Color(0.2, 0.3, 0.18)))
		draw_circle(Vector2(g.x - 2, g.y - 2), g.z * 0.6, _tint(Color(0.25, 0.37, 0.22)))
	for rock in _rocks:
		draw_circle(Vector2(rock.x + 1.5, rock.y + 2), rock.z, Color(0, 0, 0, 0.25))
		draw_circle(Vector2(rock.x, rock.y), rock.z, _tint(Color(0.36, 0.34, 0.32)))
		draw_circle(Vector2(rock.x - 1, rock.y - 1), rock.z * 0.55, _tint(Color(0.5, 0.47, 0.44)))

	# Caminho de pedras até o cais.
	for i in 6:
		var y := 36.0 + i * 10.0
		draw_circle(Vector2(sin(i * 1.7) * 3.0, y), 3.5, _tint(Color(0.5, 0.47, 0.42)))
	_draw_pier(wave)
	_draw_house(q)
	for t in _trees:
		draw_circle(Vector2(t.x + 4, t.y + 5), t.z, Color(0, 0, 0, 0.3))
		draw_circle(Vector2(t.x, t.y), t.z, _tint(Color(0.12, 0.24, 0.14)))
		draw_circle(Vector2(t.x - t.z * 0.25, t.y - t.z * 0.25), t.z * 0.55, _tint(Color(0.18, 0.33, 0.19)))

	# Poça de luz quente do farol no chão (mais forte à noite e na tempestade).
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.75, 0.4, 0.035 * warm))


func _draw_pier(wave: Color) -> void:
	var top := 88.0
	var bottom := 190.0
	draw_rect(Rect2(-8 + 3, top + 4, 16, bottom - top), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-8, top, 16, bottom - top), _tint(Color(0.42, 0.3, 0.2)))
	var y := top
	while y < bottom:
		draw_line(Vector2(-8, y), Vector2(8, y), _tint(Color(0.28, 0.19, 0.12)), 1.0)
		y += 6.0
	for py: float in [top + 20.0, top + 55.0, bottom - 4.0]:
		draw_circle(Vector2(-9, py), 2.5, _tint(Color(0.22, 0.15, 0.1)))
		draw_circle(Vector2(9, py), 2.5, _tint(Color(0.22, 0.15, 0.1)))
	# Barquinho amarrado, balançando.
	var bob := sin(_time * 1.2) * 0.08
	draw_set_transform(Vector2(26, 168), PI / 2.0 + bob)
	var hull := PackedVector2Array([Vector2(-15, 0), Vector2(-10, -6), Vector2(11, -6), Vector2(17, 0), Vector2(11, 6), Vector2(-10, 6)])
	_draw_foam(hull, Vector2.ZERO, 0.3, wave, 2.0)
	draw_colored_polygon(hull, _tint(Color(0.55, 0.25, 0.18)))
	draw_rect(Rect2(-9, -4, 18, 8), _tint(Color(0.38, 0.27, 0.18)))
	draw_line(Vector2(-2, -4), Vector2(-2, 4), _tint(Color(0.25, 0.17, 0.11)), 2.0)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(8, 160), Vector2(14, 166), _tint(Color(0.7, 0.65, 0.55)), 1.0)


func _draw_house(q: int) -> void:
	draw_set_transform(HOUSE_POS, HOUSE_ROT)
	draw_rect(Rect2(-16 + 4, -11 + 5, 32, 22), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-16, -11, 32, 11), _tint(Color(0.52, 0.22, 0.18)))
	draw_rect(Rect2(-16, 0, 32, 11), _tint(Color(0.4, 0.16, 0.13)))
	draw_line(Vector2(-16, 0), Vector2(16, 0), _tint(Color(0.65, 0.32, 0.25)), 1.5)
	draw_rect(Rect2(6, -15, 6, 7), _tint(Color(0.35, 0.33, 0.32)))
	draw_set_transform(Vector2.ZERO)
	if q == 0:
		return
	var chimney := HOUSE_POS + Vector2(9, -11).rotated(HOUSE_ROT)
	for i in 5:
		var k := fmod(_time * 0.22 + i / 5.0, 1.0)
		draw_circle(chimney + Vector2(k * 34.0, -k * 30.0), 3.0 + k * 9.0, Color(0.75, 0.75, 0.8, 0.18 * (1.0 - k)))
