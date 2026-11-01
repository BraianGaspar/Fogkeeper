class_name Boitata
extends Boss
## A cobra de fogo. Enquanto arde, a luz não a fere (ela é feita de fogo) e
## cospe fogos-fátuos. De tempos em tempos a chama baixa: escura e cheia de
## brasas, fica vulnerável e leva dano extra. O Clarão apaga a chama na hora.
## Rasteja em espiral até a ilha e morde ao chegar.

const SEGMENTS := 16
const STEP := 3

var _angle := 0.0
var _orbit := 0.0
var _blaze := true
var _phase_t := 0.0
var _wisp_cd := 1.0
var _trail: Array[Vector2] = []
var _heading := Vector2.RIGHT
var _flare := 0.0


func begin(at_angle: float) -> void:
	_angle = at_angle
	_orbit = data["start_radius"]
	_phase_t = data["blaze_time"]
	position = Vector2.from_angle(_angle) * _orbit
	for i in SEGMENTS * STEP:
		_trail.append(position + Vector2.from_angle(_angle - PI / 2.0) * i * 5.0)


func blazing() -> bool:
	return _blaze and not dying


func immune_to_light() -> bool:
	return blazing()


func take_light(amount: float, reflect: bool = false) -> void:
	if blazing():
		_flare = 0.15
		return
	super.take_light(amount * float(data["dim_damage"]), reflect)


## O Clarão apaga o fogo e abre a janela de dano.
func stun(seconds: float) -> void:
	super.stun(seconds)
	if _blaze:
		_set_blaze(false)


func _set_blaze(on: bool) -> void:
	_blaze = on
	_phase_t = data["blaze_time"] if on else data["dim_time"]
	Sfx.play(&"ignite" if on else &"splash", 1.0 if on else 0.7)


func _move(delta: float) -> void:
	var prev := position
	var r := rate()
	_flare = maxf(0.0, _flare - delta)
	_phase_t -= delta * (r if _blaze else 1.0)
	if _phase_t <= 0.0:
		_set_blaze(not _blaze)
	if _blaze:
		_wisp_cd -= delta * r
		if _wisp_cd <= 0.0:
			_wisp_cd = data["wisp_every"]
			spawn_request.emit("boulder", position + _heading * radius)
	var slow := 1.0 if _blaze else 0.5
	_angle += speed * r * slow * delta
	_orbit = move_toward(_orbit, reach(), float(data["approach"]) * r * slow * delta)
	position = Vector2.from_angle(_angle) * _orbit
	if position.distance_to(prev) > 0.01:
		_heading = (position - prev).normalized()
	if _trail.is_empty() or _trail[0].distance_to(position) >= 5.0:
		_trail.push_front(position)
		if _trail.size() > SEGMENTS * STEP:
			_trail.pop_back()


func facing() -> Vector2:
	return _heading


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	draw_enrage_aura(radius)
	var fire := blazing()
	var flick := 0.8 + 0.2 * sin(_time * 22.0)
	for i in range(SEGMENTS - 1, -1, -1):
		var idx := mini(i * STEP, _trail.size() - 1)
		var p := _trail[idx] - position
		var w := radius * (1.0 - i * 0.045)
		if fire:
			draw_circle(p, w * 1.7, Color(1.0, 0.45, 0.1, 0.12 * alpha * flick))
			draw_circle(p, w, Color(1.0, 0.45 + 0.1 * sin(_time * 9.0 + i), 0.1, alpha))
			draw_circle(p, w * 0.55, Color(1.0, 0.9, 0.5, alpha))
			# Chamas lambendo para trás.
			var back := (p - (_trail[maxi(0, idx - STEP)] - position)).normalized() if i > 0 else -_heading
			draw_colored_polygon(PackedVector2Array([p + back.orthogonal() * w * 0.6, p + back * w * (1.4 + 0.4 * sin(_time * 15.0 + i)), p - back.orthogonal() * w * 0.6]),
				Color(1.0, 0.65, 0.15, 0.7 * alpha))
		else:
			draw_circle(p, w, CreatureArt.c(Color(0.16, 0.1, 0.08), lit, alpha))
			for k in 2:
				var a := i * 1.7 + k * 2.6
				draw_circle(p + Vector2.from_angle(a) * w * 0.45, w * 0.18, Color(1.0, 0.45, 0.1, (0.5 + 0.4 * sin(_time * 4.0 + i)) * alpha))
	# Cabeça com os olhos enormes da lenda.
	draw_set_transform(Vector2.ZERO, _heading.angle())
	var r := radius
	var head := Color(1.0, 0.55, 0.12, alpha) if fire else CreatureArt.c(Color(0.2, 0.12, 0.09), lit, alpha)
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.7, -r * 0.8), Vector2(r * 1.0, -r * 0.5), Vector2(r * 1.5, 0), Vector2(r * 1.0, r * 0.5), Vector2(-r * 0.7, r * 0.8)]), head)
	var eye := Color(1.0, 1.0, 0.85, alpha) if fire else Color(1.0, 0.6, 0.2, alpha)
	for s: float in [-1.0, 1.0]:
		draw_circle(Vector2(r * 0.5, s * r * 0.42), r * 0.42, Color(eye, 0.2 * alpha))
		draw_circle(Vector2(r * 0.5, s * r * 0.42), r * 0.28, eye)
		draw_circle(Vector2(r * 0.58, s * r * 0.42), r * 0.1, Color(0.2, 0.05, 0.0, alpha))
	draw_line(Vector2(r * 1.4, 0), Vector2(r * 1.9, -r * 0.15 * sin(_time * 12.0)), Color(1.0, 0.85, 0.3, alpha), 2.0)
	draw_set_transform(Vector2.ZERO)
	if _flare > 0.0:
		# A luz bate e é engolida pelo fogo.
		draw_circle(Vector2.ZERO, r * 1.6, Color(1.0, 0.8, 0.4, 0.25 * _flare / 0.15))
