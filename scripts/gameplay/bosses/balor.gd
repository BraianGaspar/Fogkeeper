class_name Balor
extends Boss
## Balor, rei dos fomorianos, de um olho só que destrói o que encara. De
## olho fechado, a luz quase não o fere. De tempos em tempos a pálpebra se
## ergue (aviso) e o olho fica aberto: então a luz o fere muito, e é preciso
## encará-lo, porque o olhar dele queima o farol e encurta a luz enquanto o
## feixe principal não estiver nele. Péists nascem do mar à sua volta.

var _open_cd := 0.0
var _warn_t := 0.0
var _open_t := 0.0
var _clash := 0.0 ## > 0: o feixe está segurando o olhar.
var _glare := 0.0 ## > 0: o olhar está acertando o farol.
var _spawn_cd := 2.0


func begin(at_angle: float) -> void:
	position = Vector2.from_angle(at_angle) * (float(data["stand"]) + 160.0)
	_open_cd = float(data["open_every"]) * 0.5


func eye_open() -> bool:
	return _open_t > 0.0 and not dying


## 0..1: o quanto a pálpebra está aberta.
func openness() -> float:
	if eye_open():
		return 1.0
	if _warn_t > 0.0:
		return 1.0 - _warn_t / float(data["open_warn"])
	return 0.0


func take_light(amount: float, reflect: bool = false) -> void:
	var mult: float = data["open_damage"] if eye_open() else data["closed_damage"]
	if reflect and eye_open():
		_clash = 0.15
	super.take_light(amount * mult, reflect)


func _move(delta: float) -> void:
	var stand: float = data["stand"]
	var d := position.length()
	if d > stand + 0.5:
		position = position.normalized() * move_toward(d, stand, speed * lit_factor() * delta)
	var r := rate()
	_clash = maxf(0.0, _clash - delta)
	_glare = maxf(0.0, _glare - delta)
	if _warn_t > 0.0:
		_warn_t -= delta
		if _warn_t <= 0.0:
			_open_t = data["open_time"]
			Sfx.play(&"roar", 0.6)
	elif _open_t > 0.0:
		_open_t -= delta
		# Olho aberto: sem o feixe principal nele, o olhar queima o farol.
		if lighthouse and _clash <= 0.0:
			lighthouse.take_damage(float(data["glare_dps"]) * r * delta, true)
			lighthouse.apply_ink(0.3, data["glare_range"])
			_glare = 0.15
	else:
		_open_cd -= delta * r
		if _open_cd <= 0.0:
			_open_cd = data["open_every"]
			_warn_t = data["open_warn"]
			Sfx.play(&"warning", 0.8)
	_spawn_cd -= delta * r
	if _spawn_cd <= 0.0:
		_spawn_cd = data["spawn_every"]
		spawn_request.emit("tentacle", position + position.orthogonal().normalized() * randf_range(-80.0, 80.0))


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	var face := facing()
	# O raio do olhar: vai até o farol, ou se choca com o feixe no meio.
	if eye_open():
		var to := -position
		var reach_k := 0.5 if _clash > 0.0 else 1.0
		var pulse := 0.7 + 0.3 * sin(_time * 18.0)
		draw_line(face * r * 0.8, to * reach_k, Color(1.0, 0.25, 0.1, 0.35 * pulse * alpha), 16.0)
		draw_line(face * r * 0.8, to * reach_k, Color(1.0, 0.75, 0.4, 0.8 * pulse * alpha), 4.0)
		if _clash > 0.0:
			draw_circle(to * reach_k, 22.0 * pulse, Color(1.0, 0.95, 0.7, 0.6 * alpha))
	draw_set_transform(Vector2.ZERO, face.angle())
	# Gigante de pele escura e barba de algas, com a pálpebra enorme.
	var skin := CreatureArt.c(Color(0.28, 0.3, 0.3), lit, alpha)
	for s: float in [-1.0, 1.0]:
		draw_line(Vector2(-r * 0.2, s * r * 0.8), Vector2(r * 0.6, s * r * 1.2), skin, r * 0.35)
		draw_circle(Vector2(r * 0.65, s * r * 1.2), r * 0.22, skin)
	draw_circle(Vector2.ZERO, r, skin)
	draw_circle(Vector2(-r * 0.3, 0), r * 0.7, CreatureArt.c(Color(0.18, 0.2, 0.2), lit, alpha))
	for i in 5:
		var y := (i - 2) * r * 0.2
		draw_line(Vector2(r * 0.6, y), Vector2(r * 1.1, y * 1.3), CreatureArt.c(Color(0.2, 0.4, 0.28), lit, alpha), 3.0)
	# O olho: aberto ele arde; fechado é só uma pálpebra pesada.
	var eye_c := Vector2(r * 0.35, 0)
	var o := openness()
	draw_circle(eye_c, r * 0.42, CreatureArt.c(Color(0.35, 0.36, 0.36), lit, alpha))
	if o > 0.0:
		var h := r * 0.36 * o
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(eye_c + Vector2(cos(a) * h, sin(a) * r * 0.36))
		draw_colored_polygon(pts, Color(1.0, 0.9, 0.7, alpha))
		draw_circle(eye_c + Vector2(h * 0.3, 0), r * 0.16 * o, Color(0.9, 0.15, 0.05, alpha))
		draw_circle(eye_c + Vector2(h * 0.3, 0), r * 0.07 * o, Color(0.1, 0.0, 0.0, alpha))
		if _warn_t > 0.0:
			draw_arc(eye_c, r * (1.6 - 0.8 * o), 0.0, TAU, 32, Color(1.0, 0.5, 0.2, 0.7 * o * alpha), 3.0)
	else:
		draw_line(eye_c + Vector2(0, -r * 0.34), eye_c + Vector2(0, r * 0.34), CreatureArt.c(Color(0.12, 0.12, 0.12), lit, alpha), 3.0)
	draw_set_transform(Vector2.ZERO)
	if _glare > 0.0 and lighthouse:
		draw_circle(-position, 36.0, Color(1.0, 0.3, 0.1, 0.25 * alpha))
