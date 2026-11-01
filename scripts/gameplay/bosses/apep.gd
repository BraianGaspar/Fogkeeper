class_name Apep
extends Boss
## Apep, a serpente do caos que toda noite tenta engolir o sol. Circula a ilha
## em espiral e a boca engole a luz: enquanto o feixe principal passa pela
## cabeça, o alcance despenca. Queime o corpo, longe da boca. Najas nascem
## das escamas e rastejam até o farol; a cabeça morde ao chegar à ilha.

const SEGMENTS := 18
const STEP := 3
const BODY := 8 ## Segmento que recebe a luz (o meio do corpo).

var _angle := 0.0
var _orbit := 0.0
var _head := Vector2.ZERO
var _heading := Vector2.RIGHT
var _trail: Array[Vector2] = []
var _spawn_cd := 2.0
var _bite_cd := 0.0
var _eating := 0.0


func begin(at_angle: float) -> void:
	_angle = at_angle
	_orbit = data["start_radius"]
	_head = Vector2.from_angle(_angle) * _orbit
	for i in SEGMENTS * STEP:
		_trail.append(_head + Vector2.from_angle(_angle - PI / 2.0) * i * 5.0)
	position = _trail[BODY * STEP]


func _head_reach() -> float:
	return radius * 0.8 + Balance.LIGHTHOUSE_RADIUS


func _move(delta: float) -> void:
	var r := rate()
	var slow := lit_factor()
	_angle += speed * r * slow * delta
	_orbit = move_toward(_orbit, _head_reach(), float(data["approach"]) * r * slow * delta)
	var prev := _head
	_head = Vector2.from_angle(_angle) * _orbit
	if _head.distance_to(prev) > 0.01:
		_heading = (_head - prev).normalized()
	if _trail.is_empty() or _trail[0].distance_to(_head) >= 5.0:
		_trail.push_front(_head)
		if _trail.size() > SEGMENTS * STEP:
			_trail.pop_back()
	position = _trail[mini(BODY * STEP, _trail.size() - 1)]
	# A boca engole a luz que passa por ela.
	_eating = maxf(0.0, _eating - delta)
	if lighthouse and _head_in_beam():
		lighthouse.apply_ink(0.4, data["eat_range"])
		_eating = 0.3
	if _head.length() <= _head_reach() + 1.0:
		_bite_cd -= delta
		if _bite_cd <= 0.0 and lighthouse:
			_bite_cd = Balance.ATTACK_INTERVAL
			lighthouse.take_damage(damage)
	_spawn_cd -= delta * r
	if _spawn_cd <= 0.0:
		_spawn_cd = data["spawn_every"]
		spawn_request.emit("tentacle", position)


func _head_in_beam() -> bool:
	var d := _head.length()
	if d > lighthouse.beam_range + radius or d < 1.0:
		return false
	return absf(angle_difference(lighthouse.aim_angle, _head.angle())) <= lighthouse.beam_half_angle + atan2(radius * 0.8, d)


func _can_melee() -> bool:
	return false


func facing() -> Vector2:
	return _heading


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	draw_enrage_aura(radius)
	var body := CreatureArt.c(Color(0.14, 0.08, 0.18), lit, alpha)
	var band := CreatureArt.c(Color(0.85, 0.65, 0.2), lit, alpha)
	for i in range(SEGMENTS - 1, 0, -1):
		var idx := mini(i * STEP, _trail.size() - 1)
		var p := _trail[idx] - position
		var w := radius * (1.0 - absf(i - BODY) * 0.035) * (0.75 if i > SEGMENTS - 4 else 1.0)
		draw_circle(p, w, body)
		if i % 2 == 0:
			draw_arc(p, w * 0.8, 0.0, TAU, 16, band, 2.0)
	# Ponto fraco: o meio do corpo brilha de leve.
	draw_arc(Vector2.ZERO, radius * 1.15, 0.0, TAU, 32, Color(1.0, 0.85, 0.4, 0.35 * alpha), 2.0)
	# Cabeça: uma boca escura que suga a luz.
	var h := _head - position
	draw_set_transform(h, _heading.angle())
	var r := radius
	draw_circle(Vector2.ZERO, r * (1.4 + _eating * 2.0), Color(0.25, 0.0, 0.35, (0.2 + _eating) * alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.6, -r * 0.75), Vector2(r * 0.9, -r * 0.55), Vector2(r * 1.4, -r * 0.15),
		Vector2(r * 1.4, r * 0.15), Vector2(r * 0.9, r * 0.55), Vector2(-r * 0.6, r * 0.75)]), body)
	draw_circle(Vector2(r * 0.95, 0), r * (0.35 + _eating * 0.4), Color(0.02, 0.0, 0.04, alpha))
	CreatureArt.eyes(self, Vector2(r * 0.4, 0), r * 0.42, r * 0.12, Color(0.9, 0.3, 1.0), lit, alpha)
	draw_set_transform(Vector2.ZERO)
