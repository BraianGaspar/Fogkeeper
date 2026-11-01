class_name Leviathan
extends Boss
## Serpente marinha segmentada. Circula a ilha em espiral, cada vez mais perto,
## e mergulha de tempos em tempos (invulnerável) para ressurgir mais adiante.
## Só a cabeça recebe dano; ela morde quando chega ao farol.

const SEGMENTS := 14
const STEP := 3 ## Posições do rastro entre um segmento e o próximo.

var _angle := 0.0
var _orbit := 0.0
var _dive_cd := 0.0
var _dive_t := 0.0
var _trail: Array[Vector2] = []
var _heading := Vector2.RIGHT


func begin(at_angle: float) -> void:
	_angle = at_angle
	_orbit = data["start_radius"]
	_dive_cd = data["dive_every"]
	position = Vector2.from_angle(_angle) * _orbit
	for i in SEGMENTS * STEP:
		_trail.append(position + Vector2.from_angle(_angle - PI / 2.0) * i * 5.0)


func _move(delta: float) -> void:
	var prev := position
	var r := rate()
	if _dive_t > 0.0:
		_dive_t -= delta
		_angle += 1.4 * delta * r
		if _dive_t <= 0.0:
			invulnerable = false
			Sfx.play(&"splash")
	else:
		_dive_cd -= delta * r
		if _dive_cd <= 0.0 and _orbit > reach() + 30.0:
			_dive_cd = data["dive_every"]
			_dive_t = data["dive_time"]
			invulnerable = true
			Sfx.play(&"splash", 0.8)
		var slow := lit_factor()
		_angle += speed * r * slow * delta
		_orbit = move_toward(_orbit, reach(), 16.0 * r * slow * delta)
	position = Vector2.from_angle(_angle) * _orbit
	if position.distance_to(prev) > 0.01:
		_heading = (position - prev).normalized()
	if _trail.is_empty() or _trail[0].distance_to(position) >= 5.0:
		_trail.push_front(position)
		if _trail.size() > SEGMENTS * STEP:
			_trail.pop_back()


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	if invulnerable and not dying:
		# Submerso: só a sombra e as ondulações.
		for i in range(0, _trail.size(), STEP):
			draw_circle(_trail[i] - position, radius * (0.9 - i * 0.012), Color(0, 0, 0, 0.22))
		for k in 3:
			var rr := 18.0 + fmod(_time * 40.0 + k * 20.0, 60.0)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color(0.8, 0.9, 1.0, 0.35 * (1.0 - rr / 78.0)), 2.0)
		return
	draw_enrage_aura(radius)
	var body := CreatureArt.c(Color(0.1, 0.25, 0.3), lit, alpha)
	var belly := CreatureArt.c(Color(0.25, 0.5, 0.48), lit, alpha)
	var spike := CreatureArt.c(Color(0.55, 0.75, 0.7), lit, alpha)
	for i in range(SEGMENTS - 1, 0, -1):
		var idx := mini(i * STEP, _trail.size() - 1)
		var p := _trail[idx] - position
		var w := radius * (0.95 - i * 0.05)
		var nxt := _trail[maxi(0, idx - STEP)] - position
		var dir := (nxt - p).normalized() if nxt.distance_to(p) > 0.1 else _heading
		draw_circle(p, w, body)
		draw_circle(p - dir.orthogonal() * w * 0.2, w * 0.55, belly)
		draw_colored_polygon(PackedVector2Array([p + dir.orthogonal() * w * 0.3, p + dir.orthogonal() * w * 1.25 - dir * w * 0.4, p - dir * w * 0.5]), spike)
	# Cabeça com mandíbula que abre e fecha.
	draw_set_transform(Vector2.ZERO, _heading.angle())
	var r := radius
	var bite := 0.25 + 0.25 * sin(_time * 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.8, -r * 0.7), Vector2(r * 0.9, -r * (0.3 + bite)), Vector2(r * 1.7, -r * bite * 0.6), Vector2(r * 0.9, 0), Vector2(-r * 0.6, 0)]), body)
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.8, r * 0.7), Vector2(r * 0.9, r * (0.3 + bite)), Vector2(r * 1.6, r * bite * 0.6), Vector2(r * 0.9, 0), Vector2(-r * 0.6, 0)]), body)
	draw_colored_polygon(PackedVector2Array([Vector2(r * 0.2, 0), Vector2(r * 1.5, -r * bite * 0.4), Vector2(r * 1.5, r * bite * 0.4)]), Color(0.3, 0.02, 0.05, alpha))
	for i in 5:
		var x := r * (0.5 + i * 0.22)
		draw_colored_polygon(PackedVector2Array([Vector2(x, -r * bite * 0.35), Vector2(x + r * 0.08, 0), Vector2(x + r * 0.16, -r * bite * 0.35)]), Color(0.95, 0.92, 0.85, alpha))
	for s: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.3, s * r * 0.6), Vector2(-r * 1.2, s * r * 1.4), Vector2(-r * 0.8, s * r * 0.5)]), spike)
	CreatureArt.eyes(self, Vector2(r * 0.35, 0), r * 0.45, r * 0.12, Color(1.0, 0.85, 0.3), lit, alpha)
	draw_set_transform(Vector2.ZERO)
