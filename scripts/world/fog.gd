class_name Fog
extends Node2D
## Camada acima dos inimigos: névoa que deriva, chuva e relâmpagos da
## tempestade, gaivotas no crepúsculo e no amanhecer, e a vinheta escura.
## Cores e intensidades seguem DayCycle.p. Puramente visual.

const AREA := Vector2(2300, 1200)
const BLOBS := [10, 14, 18] ## Por qualidade: baixa, média, alta.
const BLOB_LAYERS := [4, 6, 8]
const RAIN := [60, 140, 240]
const BIRDS := 6

var _blobs: Array[Dictionary] = []
var _rain: Array[Vector3] = [] # x, y = posição base; z = velocidade
var _birds: Array[Vector3] = [] # x, y = posição base; z = fase
var _time := 0.0
var _flash := 0.0
var _next_flash := 3.0
var _rng := RandomNumberGenerator.new()
var density := 1.0 ## Névoa da dificuldade × configuração do jogador.


func _ready() -> void:
	z_index = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 11
	for i in BLOBS[2]:
		_blobs.append({
			"pos": Vector2(_rng.randf_range(-AREA.x, AREA.x), _rng.randf_range(-AREA.y, AREA.y)) * 0.5,
			"vel": Vector2(_rng.randf_range(6.0, 16.0), _rng.randf_range(-4.0, 4.0)),
			"r": _rng.randf_range(90.0, 200.0),
		})
	for i in RAIN[2]:
		_rain.append(Vector3(_rng.randf_range(-0.5, 0.5) * AREA.x, _rng.randf_range(-0.5, 0.5) * AREA.y, _rng.randf_range(700.0, 1000.0)))
	for i in BIRDS:
		_birds.append(Vector3(_rng.randf_range(-0.5, 0.5) * AREA.x, _rng.randf_range(-320.0, 320.0), _rng.randf() * TAU))


func _process(delta: float) -> void:
	_time += delta
	var storm: float = DayCycle.p["storm"]
	for b in _blobs:
		var p: Vector2 = b["pos"] + b["vel"] * delta * (1.0 + storm * 2.0)
		if p.x > AREA.x * 0.5 + 200.0:
			p.x = -AREA.x * 0.5 - 200.0
		b["pos"] = p
	_flash = maxf(0.0, _flash - delta * 2.5)
	# Relâmpagos na tempestade, no temporal e no tufão; no fiorde é nevasca, no Egito é areia.
	if storm > 0.6 and DayCycle.map in ["bay", "amazon", "japan"] and Settings.weather:
		_next_flash -= delta
		if _next_flash <= 0.0:
			_next_flash = _rng.randf_range(3.0, 8.0)
			_flash = 1.0 if Settings.lightning_flash else 0.0
			var pitch := _rng.randf_range(0.85, 1.1)
			get_tree().create_timer(_rng.randf_range(0.2, 0.7), true).timeout.connect(
				func() -> void: Sfx.play(&"thunder", pitch))
	queue_redraw()


func _draw() -> void:
	var p := DayCycle.p
	var q := clampi(Settings.quality, 0, 2)
	var fog_color: Color = p["fog"]
	var fog_a: float = p["fog_a"] * density
	var storm: float = p["storm"]
	var rect := Background.visible_rect(self)

	for i in BLOBS[q]:
		var b: Dictionary = _blobs[i]
		var r: float = b["r"]
		var layers: int = BLOB_LAYERS[q]
		var a := 0.072 / layers * fog_a
		for j in layers:
			draw_circle(b["pos"], r * (1.0 - j * 0.88 / layers), Color(fog_color, a))

	if DayCycle.map == "fjord":
		_draw_aurora(rect, p.get("aurora", 0.0))
		if Settings.weather:
			_draw_snow(q, storm)
	elif DayCycle.map == "japan":
		_draw_petals(q)
		if storm > 0.01 and Settings.weather:
			_draw_rain(q, storm)
	elif DayCycle.map == "egypt":
		if Settings.weather:
			_draw_sand(q, storm)
	elif DayCycle.map == "amazon":
		_draw_fireflies(q, p["night"] * (1.0 - 0.7 * storm))
		if storm > 0.01 and Settings.weather:
			_draw_rain(q, storm)
	else:
		_draw_birds(maxf(p["dusk"], p["dawn"]))
		if storm > 0.01 and Settings.weather:
			_draw_rain(q, storm)

	var view := rect.size
	var edge := maxf(view.length() * 0.5, 600.0)
	var vignette := Color(0.0, 0.0, 0.02).lerp(Color(0.12, 0.06, 0.05), p["dawn"])
	var va: float = (0.06 * (1.0 - 0.5 * p["dawn"]) + 0.03 * storm) * density
	for i in 16:
		draw_arc(rect.get_center(), edge + 80.0 - i * 18.0, 0.0, TAU, 128, Color(vignette, va), 20.0)

	if _flash > 0.0:
		var flicker := _flash * (0.6 + 0.4 * sin(_time * 70.0))
		draw_rect(rect.grow(40.0), Color(0.85, 0.9, 1.0, 0.35 * flicker))


## Cortinas de aurora no topo da tela, ondulando devagar.
func _draw_aurora(rect: Rect2, aurora: float) -> void:
	if aurora <= 0.02:
		return
	for band in 3:
		var col := [Color(0.3, 1.0, 0.6), Color(0.55, 0.4, 1.0), Color(0.3, 0.9, 1.0)][band] as Color
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var steps := 24
		for i in steps + 1:
			var x := rect.position.x + rect.size.x * i / steps
			var y := rect.position.y + 40.0 + band * 26.0 + sin(x * 0.005 + _time * (0.25 + band * 0.07) + band * 2.0) * 34.0
			pts.append(Vector2(x, y))
			cols.append(Color(col, 0.0))
		for i in range(steps, -1, -1):
			var x := rect.position.x + rect.size.x * i / steps
			var y := rect.position.y + 40.0 + band * 26.0 + sin(x * 0.005 + _time * (0.25 + band * 0.07) + band * 2.0) * 34.0
			var shimmer := 0.6 + 0.4 * sin(x * 0.03 + _time * 1.5 + band)
			pts.append(Vector2(x, y + 90.0))
			cols.append(Color(col, 0.16 * aurora * shimmer))
		draw_polygon(pts, cols)


## Neve sempre caindo; na nevasca ela engrossa e o vento a deita.
func _draw_snow(q: int, storm: float) -> void:
	var count := int(RAIN[q] * (0.4 + 0.6 * storm))
	var wind := Vector2(-0.3 - storm * 1.2, 1.0)
	for i in count:
		var r := _rain[i]
		var speed := r.z * (0.08 + storm * 0.25)
		var y := fposmod(r.y + _time * speed + AREA.y * 0.5, AREA.y) - AREA.y * 0.5
		var x := fposmod(r.x + wind.x * _time * speed + sin(_time + r.x) * 10.0 + AREA.x * 0.5, AREA.x) - AREA.x * 0.5
		draw_circle(Vector2(x, y), 1.2 + fmod(r.z, 3.0) * 0.6, Color(1, 1, 1, 0.55 + 0.25 * storm))
	if storm > 0.05:
		var rect := Background.visible_rect(self)
		draw_rect(rect.grow(40.0), Color(0.9, 0.94, 1.0, 0.18 * storm))


func _draw_rain(q: int, storm: float) -> void:
	var fall := Vector2(-0.25, 1.0)
	var col := Color(0.7, 0.8, 0.95, 0.22 * storm)
	for i in RAIN[q]:
		var r := _rain[i]
		var y := fposmod(r.y + _time * r.z + AREA.y * 0.5, AREA.y) - AREA.y * 0.5
		var x := fposmod(r.x + fall.x * _time * r.z + AREA.x * 0.5, AREA.x) - AREA.x * 0.5
		draw_line(Vector2(x, y), Vector2(x, y) + fall * 16.0, col, 1.2)


## Pétalas de cerejeira levadas pelo vento.
func _draw_petals(q: int) -> void:
	if not Settings.particles:
		return
	for i in [14, 30, 50][q]:
		var r := _rain[i]
		var y := fposmod(r.y + _time * (25.0 + fmod(r.z, 20.0)) + AREA.y * 0.5, AREA.y) - AREA.y * 0.5
		var x := fposmod(r.x + _time * 30.0 + sin(_time * 1.3 + r.z) * 30.0 + AREA.x * 0.5, AREA.x) - AREA.x * 0.5
		var spin := _time * 2.0 + r.z
		draw_set_transform(Vector2(x, y), spin)
		draw_rect(Rect2(-3, -1.5, 6, 3), Color(1.0, 0.75, 0.85, 0.75))
	draw_set_transform(Vector2.ZERO)


## Areia do deserto: poeira leve e, na tempestade, rajadas que tingem tudo.
func _draw_sand(q: int, storm: float) -> void:
	var count := int(RAIN[q] * (0.15 + 0.85 * storm))
	for i in count:
		var r := _rain[i]
		var speed := r.z * (0.15 + storm * 0.6)
		var x := fposmod(r.x - _time * speed + AREA.x * 0.5, AREA.x) - AREA.x * 0.5
		var y := r.y + sin(_time * 2.0 + r.x) * 12.0
		draw_line(Vector2(x, y), Vector2(x + 6.0 + storm * 14.0, y), Color(0.95, 0.8, 0.55, 0.25 + 0.3 * storm), 1.5)
	if storm > 0.05:
		draw_rect(Background.visible_rect(self).grow(40.0), Color(0.85, 0.65, 0.4, 0.2 * storm))


## Vaga-lumes piscando sobre a água e a mata do rio.
func _draw_fireflies(q: int, night: float) -> void:
	if night <= 0.05 or not Settings.particles:
		return
	for i in [12, 28, 44][q]:
		var r := _rain[i]
		var pos := Vector2(r.x * 0.55 + sin(_time * 0.3 + r.z) * 40.0, r.y * 0.6 + cos(_time * 0.25 + r.x) * 30.0)
		if pos.length() < 120.0:
			continue
		var blink := clampf(sin(_time * (1.0 + fmod(r.z, 1.7)) + r.x) * 3.0 - 1.8, 0.0, 1.0)
		if blink <= 0.0:
			continue
		draw_circle(pos, 7.0, Color(0.85, 1.0, 0.4, 0.12 * blink * night))
		draw_circle(pos, 1.8, Color(0.95, 1.0, 0.6, 0.9 * blink * night))


func _draw_birds(light: float) -> void:
	if light <= 0.05:
		return
	for b in _birds:
		var x := fposmod(b.x + _time * 38.0 + AREA.x * 0.5, AREA.x) - AREA.x * 0.5
		var pos := Vector2(x, b.y + sin(_time * 0.7 + b.z) * 14.0)
		var flap := sin(_time * 7.0 + b.z) * 4.0
		var shadow := pos + Vector2(14, 22)
		for target: Array in [[shadow, Color(0, 0, 0, 0.18 * light)], [pos, Color(0.12, 0.1, 0.12, 0.85 * light)]]:
			var c: Vector2 = target[0]
			var col: Color = target[1]
			draw_polyline(PackedVector2Array([c + Vector2(-9, -flap), c + Vector2(-3, 1), c, c + Vector2(3, 1), c + Vector2(9, -flap)]), col, 1.8)
