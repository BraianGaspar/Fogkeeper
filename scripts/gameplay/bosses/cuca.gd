class_name Cuca
extends Boss
## A velha bruxa da mata, de cabeça de jacaré e cabelo grisalho (folclore,
## não o visual da TV, que tem dono). Para longe da ilha
## e conjura um feitiço de sono, marcado por um círculo de runas: se levar
## dano suficiente enquanto conjura, é interrompida; senão, a luz do farol
## adormece e enfraquece por alguns segundos. Depois some na névoa e
## reaparece em outro ponto.

signal interrupted

var _cast_cd := 0.0
var _cast_t := 0.0
var _cast_damage := 0.0
var _vanish := 0.0 ## > 0: sumindo/reaparecendo (invulnerável).
var _target_angle := 0.0


func begin(at_angle: float) -> void:
	_target_angle = at_angle
	position = Vector2.from_angle(at_angle) * (float(data["stand"]) + 150.0)
	_cast_cd = float(data["cast_every"]) * 0.5


func casting() -> bool:
	return _cast_t > 0.0


## 0..1: quanto falta para o feitiço sair.
func cast_progress() -> float:
	return 1.0 - _cast_t / float(data["cast_time"]) if casting() else 0.0


func take_light(amount: float, reflect: bool = false) -> void:
	var before := hp
	super.take_light(amount, reflect)
	if casting():
		_cast_damage += before - hp
		if _cast_damage >= max_hp * float(data["interrupt"]):
			_cast_t = 0.0
			Sfx.play(&"denied", 0.6)
			interrupted.emit()
			_start_vanish()


func _start_vanish() -> void:
	_vanish = 1.2
	invulnerable = true
	_target_angle = position.angle() + PI * randf_range(0.5, 1.5)


func _move(delta: float) -> void:
	var r := rate()
	var stand: float = data["stand"]
	if _vanish > 0.0:
		_vanish -= delta
		if _vanish <= 0.6 and absf(angle_difference(position.angle(), _target_angle)) > 0.01:
			position = Vector2.from_angle(_target_angle) * stand
		if _vanish <= 0.0:
			invulnerable = false
		return
	var d := position.length()
	if d > stand + 0.5:
		position = position.normalized() * move_toward(d, stand, speed * lit_factor() * delta)
		return
	if casting():
		_cast_t -= delta * r
		if _cast_t <= 0.0:
			if lighthouse:
				lighthouse.sleep(data["sleep_time"], data["sleep_power"])
			Sfx.play(&"spell")
			_start_vanish()
		return
	_cast_cd -= delta * r
	if _cast_cd <= 0.0:
		_cast_cd = data["cast_every"]
		_cast_t = data["cast_time"]
		_cast_damage = 0.0
		Sfx.play(&"growl", 1.4)


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	if _vanish > 0.0 and not dying:
		alpha *= absf(_vanish - 0.6) / 0.6
		for i in 4:
			draw_circle(Vector2.from_angle(_time * 2.0 + i * 1.6) * radius * 0.8, radius * 0.7, Color(0.5, 0.3, 0.6, 0.15))
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	if casting() and not dying:
		# Círculo de runas que se fecha até o feitiço sair; dá para interromper.
		var k := cast_progress()
		var ring := r * (3.2 - 1.6 * k)
		draw_circle(Vector2.ZERO, ring, Color(0.6, 0.2, 0.9, 0.1 + 0.1 * k))
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 48, Color(0.85, 0.5, 1.0, 0.8), 3.0)
		for i in 8:
			var a := _time * 1.5 + i * TAU / 8.0
			UiTheme.diamond(self, Vector2.from_angle(a) * ring, 5.0, Color(1.0, 0.8, 1.0, 0.9))
		var bar := Rect2(-r, -r - 22.0, 2.0 * r, 5.0)
		draw_rect(bar, Color(0, 0, 0, 0.6))
		var need := max_hp * float(data["interrupt"])
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_cast_damage / need, 0.0, 1.0), bar.size.y)), Color(1.0, 0.85, 0.4))
	draw_set_transform(Vector2.ZERO, facing().angle())
	var cloak := CreatureArt.c(Color(0.32, 0.15, 0.4), lit, alpha)
	var scale_col := CreatureArt.c(Color(0.25, 0.45, 0.2), lit, alpha)
	var hair := CreatureArt.c(Color(0.72, 0.72, 0.7), lit, alpha)
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * r * 0.85 - r * 0.25, sin(a) * r * 1.1))
	draw_colored_polygon(pts, cloak)
	# Mãos erguidas para o feitiço.
	var lift := 0.4 if casting() else 0.0
	for s: float in [-1.0, 1.0]:
		var hand := Vector2(r * (0.55 + lift), s * r * (0.95 - lift * 0.5))
		draw_line(Vector2(0, s * r * 0.7), hand, scale_col, r * 0.18)
		draw_circle(hand, r * 0.14, scale_col)
		if casting():
			draw_circle(hand, r * 0.3, Color(0.85, 0.5, 1.0, 0.4 * alpha))
	# Cabelo grisalho desgrenhado e focinho comprido de jacaré.
	for i in 7:
		var a := PI + (i - 3) * 0.35
		draw_circle(Vector2(-r * 0.05, 0) + Vector2.from_angle(a) * r * 0.42, r * 0.2, hair)
	draw_circle(Vector2(r * 0.1, 0), r * 0.42, scale_col)
	draw_colored_polygon(PackedVector2Array([Vector2(r * 0.3, -r * 0.28), Vector2(r * 1.5, -r * 0.14), Vector2(r * 1.55, 0), Vector2(r * 1.5, r * 0.14), Vector2(r * 0.3, r * 0.28)]), scale_col)
	for i in 6:
		var x := r * (0.5 + i * 0.17)
		for s: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(x, s * r * 0.17), Vector2(x + r * 0.05, s * r * 0.27), Vector2(x + r * 0.1, s * r * 0.17)]), Color(0.95, 0.92, 0.8, alpha))
	CreatureArt.eyes(self, Vector2(r * 0.3, 0), r * 0.22, r * 0.08, Color(1.0, 0.85, 0.2), lit, alpha)
	draw_set_transform(Vector2.ZERO)
