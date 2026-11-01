class_name JapanBackground
extends Background
## Mar dos Yōkai: mar escuro sob uma lua grande, um torii vermelho dentro
## d'água, rochedos com cordas sagradas, lanternas de papel do Obon descendo
## à deriva e a ilha do farol com santuário, lanternas de pedra e pinheiros.

const TORII_POS := Vector2(330, -175)
const ROCKS := [Vector2(-420, 150), Vector2(-470, 175), Vector2(470, 200)]

var _lanterns: Array[Vector3] = [] # x, y = base; z = fase
var _pines: Array[Vector3] = []
var _sakura: Array[Vector3] = []


func _ready() -> void:
	z_index = -10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	for i in 64:
		var a := TAU * i / 64.0
		_island.append(Vector2.from_angle(a) * _island_radius(a))
	for i in 26:
		_lanterns.append(Vector3(rng.randf_range(-1000, 1000), rng.randf_range(-480, 480), rng.randf() * TAU))
	for p: Vector2 in [Vector2(-62, -40), Vector2(-74, 18), Vector2(64, 30), Vector2(-40, 62)]:
		_pines.append(Vector3(p.x, p.y, rng.randf_range(10.0, 13.0)))
	for p: Vector2 in [Vector2(30, -70), Vector2(72, -24)]:
		_sakura.append(Vector3(p.x, p.y, rng.randf_range(13.0, 16.0)))
	for i in COUNTS["waves"][2]:
		_waves.append(Vector3(rng.randf_range(-0.5, 0.5) * WAVE_AREA.x, rng.randf_range(-0.5, 0.5) * WAVE_AREA.y, rng.randf_range(6.0, 16.0)))
	var moon_dir := Vector2(-0.6, -0.8).normalized()
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
	_side_glow(view, -1.0, p["dusk"], Color(1.0, 0.45, 0.4))
	_side_glow(view, 1.0, p["dawn"], Color(1.0, 0.7, 0.5))
	_draw_moon(view, p["moon"])
	_draw_stars(q, night * (1.0 - storm))
	_draw_glints(q, p["moon"])
	_draw_waves(q, wave, storm)
	for i in 4:
		draw_circle(Vector2.ZERO, 175.0 - i * 18.0, Color(wave, 0.025))
	for r: Vector2 in ROCKS:
		_draw_wedded_rock(r, wave)
	_draw_torii(wave)
	for l in _lanterns:
		_draw_lantern(l, night)
	_draw_island(wave, night, storm, q)


## Reflexo grande da lua cheia na água.
func _draw_moon(view: Rect2, moon: float) -> void:
	if moon <= 0.02:
		return
	var c := view.position + Vector2(view.size.x * 0.22, view.size.y * 0.2)
	for i in 5:
		draw_circle(c, 60.0 + i * 26.0, Color(1.0, 0.95, 0.85, 0.035 * moon))
	draw_circle(c, 48.0, Color(1.0, 0.97, 0.88, 0.22 * moon))


## Rochedos casados (meoto iwa) unidos pela corda sagrada.
func _draw_wedded_rock(pos: Vector2, wave: Color) -> void:
	draw_circle(pos, 30.0, Color(wave, 0.05))
	draw_circle(pos + Vector2(3, 4), 20.0, Color(0, 0, 0, 0.25))
	draw_circle(pos, 20.0, _tint(Color(0.26, 0.26, 0.28)))
	draw_circle(pos + Vector2(-5, -5), 9.0, _tint(Color(0.36, 0.36, 0.38)))
	if pos.x < 0.0:
		draw_line(pos, pos + Vector2(-50, 25), _tint(Color(0.95, 0.9, 0.75)), 3.0)
		for i in 4:
			var k := (i + 1) / 5.0
			draw_line(pos.lerp(pos + Vector2(-50, 25), k), pos.lerp(pos + Vector2(-50, 25), k) + Vector2(0, 7), _tint(Color(0.95, 0.95, 0.9)), 1.5)


## Torii vermelho em pé dentro d'água, visto de cima.
func _draw_torii(wave: Color) -> void:
	draw_set_transform(TORII_POS, -0.25)
	for x: float in [-26.0, 26.0]:
		draw_arc(Vector2(x, 0), 12.0, 0.0, TAU, 16, Color(wave, 0.2), 1.5)
		draw_circle(Vector2(x, 0), 5.0, _tint(Color(0.75, 0.15, 0.1)))
	draw_rect(Rect2(-44 + 4, -6 + 5, 88, 12), Color(0, 0, 0, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-48, -8), Vector2(48, -8), Vector2(42, 4), Vector2(-42, 4)]), _tint(Color(0.82, 0.18, 0.12)))
	draw_rect(Rect2(-48, -10, 96, 4), _tint(Color(0.12, 0.1, 0.1)))
	draw_rect(Rect2(-34, 7, 68, 4), _tint(Color(0.7, 0.14, 0.1)))
	draw_set_transform(Vector2.ZERO)


## Lanterna de papel do Obon descendo devagar com a correnteza.
func _draw_lantern(l: Vector3, night: float) -> void:
	var x := fposmod(l.x + _time * 9.0 + 1000.0, 2000.0) - 1000.0
	var pos := Vector2(x, l.y + sin(_time * 0.6 + l.z) * 5.0)
	if pos.length() < 150.0:
		return
	var glow := (0.4 + 0.6 * night) * (0.8 + 0.2 * sin(_time * 3.0 + l.z))
	draw_circle(pos, 16.0, Color(1.0, 0.6, 0.25, 0.08 * glow))
	draw_rect(Rect2(pos - Vector2(5, 5), Vector2(10, 10)), _tint(Color(0.35, 0.22, 0.15)))
	draw_rect(Rect2(pos - Vector2(3.5, 3.5), Vector2(7, 7)), Color(1.0, 0.75, 0.4, 0.5 + 0.5 * glow))


func _draw_island(wave: Color, night: float, storm: float, q: int) -> void:
	var shallow := PackedVector2Array()
	for v in _island:
		shallow.append(v * 1.26)
	draw_colored_polygon(shallow, Color(wave, 0.07))
	_draw_foam(_island, Vector2.ZERO, 0.8, wave, 0.0)
	var inner := PackedVector2Array()
	for v in _island:
		inner.append(v * 0.86)
	draw_colored_polygon(_island, _tint(Color(0.42, 0.4, 0.38)))
	draw_colored_polygon(inner, _tint(Color(0.22, 0.3, 0.2)))
	# Caminho de pedras até o pequeno santuário.
	for i in 5:
		draw_rect(Rect2(-4.0 + sin(i) * 2.0, 34.0 + i * 11.0, 8, 6), _tint(Color(0.55, 0.53, 0.5)))
	_draw_shrine()
	for p: Vector2 in [Vector2(-30, 40), Vector2(30, 46)]:
		_draw_stone_lantern(p, night)
	for t in _pines:
		_draw_pine(Vector2(t.x, t.y), t.z)
	for s in _sakura:
		_draw_sakura(Vector2(s.x, s.y), s.z)
	var warm := clampf(night * 0.8 + storm * 0.3, 0.0, 1.0)
	for i in 5:
		draw_circle(Vector2.ZERO, 40.0 + i * 18.0, Color(1.0, 0.75, 0.4, 0.035 * warm))


func _draw_shrine() -> void:
	draw_set_transform(Vector2(-6, 88), 0.0)
	draw_rect(Rect2(-15 + 4, -10 + 5, 30, 20), Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -12), Vector2(18, -12), Vector2(14, 12), Vector2(-14, 12)]), _tint(Color(0.2, 0.18, 0.18)))
	draw_line(Vector2(-16, 0), Vector2(16, 0), _tint(Color(0.55, 0.5, 0.45)), 2.0)
	draw_rect(Rect2(-4, 8, 8, 6), _tint(Color(0.8, 0.2, 0.12)))
	draw_set_transform(Vector2.ZERO)


func _draw_stone_lantern(p: Vector2, night: float) -> void:
	draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), _tint(Color(0.55, 0.54, 0.52)))
	draw_circle(p, 3.0, Color(1.0, 0.75, 0.4, 0.3 + 0.7 * night))
	draw_circle(p, 10.0, Color(1.0, 0.75, 0.4, 0.07 * night))


func _draw_pine(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(4, 5), r, Color(0, 0, 0, 0.25))
	for i in 3:
		draw_circle(c + Vector2.from_angle(i * 2.1) * r * 0.45, r * 0.6, _tint(Color(0.1, 0.22, 0.15)))
	draw_circle(c, r * 0.35, _tint(Color(0.15, 0.3, 0.18)))


## Cerejeira em flor; as pétalas caem pela camada de névoa.
func _draw_sakura(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(4, 5), r, Color(0, 0, 0, 0.22))
	for i in 6:
		draw_circle(c + Vector2.from_angle(i * 1.05) * r * 0.5, r * 0.55, _tint(Color(0.95, 0.68, 0.78)))
	draw_circle(c, r * 0.4, _tint(Color(1.0, 0.82, 0.88)))
