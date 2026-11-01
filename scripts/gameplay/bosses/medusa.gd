class_name Medusa
extends Boss
## A górgona. Circula a ilha soltando as serpentes dos cabelos e, de tempos
## em tempos, ergue o rosto: os olhos acendem (aviso) e depois o olhar
## petrifica. Se o feixe principal tocar nela durante o olhar, o farol vira
## pedra e quase não gira por alguns segundos, e ela não se fere. Desvie a
## luz enquanto ela encara; fora disso, ela queima normalmente.

var _angle := 0.0
var _gaze_cd := 0.0
var _warn_t := 0.0
var _gaze_t := 0.0
var _snake_cd := 1.5


func begin(at_angle: float) -> void:
	_angle = at_angle
	position = Vector2.from_angle(_angle) * (float(data["stand"]) + 160.0)
	_gaze_cd = float(data["gaze_every"]) * 0.6


func warning() -> bool:
	return _warn_t > 0.0 and not dying


func gazing() -> bool:
	return _gaze_t > 0.0 and not dying


## Durante o olhar a luz não a fere: o bot mira em outra criatura.
func immune_to_light() -> bool:
	return gazing()


func take_light(amount: float, reflect: bool = false) -> void:
	if gazing():
		_lit = 0.12
		if reflect and lighthouse and not lighthouse.petrified():
			lighthouse.petrify(data["stone_time"], data["stone_turn"])
			Sfx.play(&"denied", 0.5)
		return
	super.take_light(amount, reflect)


func _move(delta: float) -> void:
	var r := rate()
	var d := move_toward(position.length(), float(data["stand"]), 90.0 * delta)
	if not gazing():
		_angle += speed * r * lit_factor() * delta
	position = Vector2.from_angle(_angle) * d
	if _warn_t > 0.0:
		_warn_t -= delta
		if _warn_t <= 0.0:
			_gaze_t = data["gaze_time"]
			Sfx.play(&"spell", 0.7)
	elif _gaze_t > 0.0:
		_gaze_t -= delta
	else:
		_gaze_cd -= delta * r
		if _gaze_cd <= 0.0:
			_gaze_cd = data["gaze_every"]
			_warn_t = data["gaze_warn"]
			Sfx.play(&"warning", 1.4)
	_snake_cd -= delta * r
	if _snake_cd <= 0.0:
		_snake_cd = data["snake_every"]
		spawn_request.emit("tentacle", position - position.normalized() * radius)


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	var face := facing()
	draw_set_transform(Vector2.ZERO, face.angle())
	# Corpo de serpente enrolado atrás.
	var coil := CreatureArt.c(Color(0.28, 0.42, 0.25), lit, alpha)
	CreatureArt.tail(self, -r * 0.4, r * 2.6, r * 0.6, _time * 0.8, 0.0, r * 0.6, coil, 10)
	draw_circle(Vector2.ZERO, r * 0.85, CreatureArt.c(Color(0.55, 0.62, 0.5), lit, alpha))
	# Cabelo de serpentes, cada uma ondulando.
	for i in 9:
		var a := PI + (i - 4) * 0.36
		var tip := CreatureArt.tail_at(self, Vector2.from_angle(a) * r * 0.45, a, r * 1.0, r * 0.16, _time * 2.0, i * 0.9, r * 0.35, coil, 6)
		draw_circle(tip, r * 0.1, CreatureArt.c(Color(0.4, 0.6, 0.3), lit, alpha))
	draw_circle(Vector2(r * 0.2, 0), r * 0.5, CreatureArt.c(Color(0.6, 0.7, 0.55), lit, alpha))
	# Olhos: frios em repouso, acendendo no aviso, ofuscantes no olhar.
	var eye := Color(0.6, 1.0, 0.6)
	var size := r * 0.09
	if warning():
		var k := 1.0 - _warn_t / float(data["gaze_warn"])
		size = r * (0.09 + 0.06 * k)
		draw_arc(Vector2(r * 0.4, 0), r * (2.2 - 1.2 * k), 0.0, TAU, 32, Color(0.6, 1.0, 0.6, 0.6 * k * alpha), 3.0)
	if gazing():
		eye = Color(0.9, 1.0, 0.8)
		size = r * 0.16
		var pulse := 0.6 + 0.4 * sin(_time * 10.0)
		draw_circle(Vector2(r * 0.4, 0), r * 1.3, Color(0.6, 1.0, 0.6, 0.18 * pulse * alpha))
		# Raios do olhar apontando para o farol.
		for s: float in [-1.0, 0.0, 1.0]:
			draw_line(Vector2(r * 0.6, s * r * 0.25), Vector2(r * 3.2, s * r * 0.9), Color(0.7, 1.0, 0.7, 0.35 * pulse * alpha), 2.0)
	for s: float in [-1.0, 1.0]:
		draw_circle(Vector2(r * 0.45, s * r * 0.2), size * 2.0, Color(eye, 0.3 * alpha))
		draw_circle(Vector2(r * 0.45, s * r * 0.2), size, Color(eye, alpha))
	draw_set_transform(Vector2.ZERO)
