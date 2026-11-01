class_name Fenrir
extends Boss
## O grande lobo. Corre em círculos longe da ilha e foge da luz: se ficar
## iluminado por um instante, salta para o lado. De tempos em tempos para,
## marca uma linha vermelha até o farol e investe; mire na linha para recebê-lo.

enum Phase { CIRCLE, TELEGRAPH, DASH, RETREAT }

var _phase_state := Phase.CIRCLE
var _angle := 0.0
var _dir := 1.0
var _lit_time := 0.0
var _dodge_cd := 0.0
var _charge_cd := 0.0
var _telegraph := 0.0


func begin(at_angle: float) -> void:
	_angle = at_angle
	position = Vector2.from_angle(_angle) * 430.0
	_charge_cd = data["charge_every"]


func _move(delta: float) -> void:
	var r := rate()
	match _phase_state:
		Phase.CIRCLE:
			var circle: float = data["circle"]
			_angle += speed * _dir * r * delta
			var d := move_toward(position.length(), circle, 160.0 * delta)
			position = Vector2.from_angle(_angle) * d
			_dodge_cd -= delta
			_lit_time = _lit_time + delta if _lit > 0.0 else 0.0
			if _lit_time >= float(data["dodge_after"]) and _dodge_cd <= 0.0:
				_angle += 0.9 * _dir
				_dir = -_dir
				_dodge_cd = data["dodge_cooldown"]
				_lit_time = 0.0
				Sfx.play(&"hover", 0.5, 6.0)
			_charge_cd -= delta * r
			if _charge_cd <= 0.0:
				_phase_state = Phase.TELEGRAPH
				_telegraph = float(data["telegraph"]) / r
				Sfx.play(&"growl")
		Phase.TELEGRAPH:
			_telegraph -= delta
			if _telegraph <= 0.0:
				_phase_state = Phase.DASH
		Phase.DASH:
			var d := position.length()
			var nd := move_toward(d, reach(), float(data["dash_speed"]) * delta)
			position = position.normalized() * nd
			if nd <= reach() + 0.5:
				if lighthouse:
					lighthouse.take_damage(damage)
				_phase_state = Phase.RETREAT
		Phase.RETREAT:
			var circle: float = data["circle"]
			var d := move_toward(position.length(), circle, float(data["dash_speed"]) * 0.5 * delta)
			position = position.normalized() * d
			if d >= circle - 0.5:
				_angle = position.angle()
				_phase_state = Phase.CIRCLE
				_charge_cd = data["charge_every"]


func _can_melee() -> bool:
	return false


func facing() -> Vector2:
	if _phase_state == Phase.CIRCLE:
		return Vector2.from_angle(_angle + PI / 2.0 * _dir)
	if _phase_state == Phase.RETREAT:
		return position.normalized()
	return super.facing()


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	if _phase_state == Phase.TELEGRAPH and not dying:
		var k := 0.5 + 0.5 * sin(_time * 20.0)
		var to_center := -position
		draw_line(Vector2.ZERO, to_center.normalized() * (to_center.length() - reach()), Color(1.0, 0.2, 0.15, 0.35 + 0.35 * k), 6.0)
	draw_enrage_aura(radius)
	_draw_body(lit, alpha)


func _draw_body(lit: float, alpha: float) -> void:
	var face := facing()
	draw_set_transform(Vector2.ZERO, face.angle())
	CreatureArt.wolf(self, radius, _time * (1.6 if _phase_state == Phase.DASH else 1.0), 0.0, lit, alpha,
		Color(0.24, 0.24, 0.28), Color(0.1, 0.1, 0.13), Color(1.0, 0.3, 0.2))
	# Elos da corrente Gleipnir arrastando atrás.
	for i in 4:
		var p := Vector2(-radius * (1.3 + i * 0.35), sin(_time * 6.0 + i) * radius * 0.15)
		draw_arc(p, radius * 0.12, 0.0, TAU, 10, Color(0.75, 0.75, 0.8, 0.8 * alpha), 2.0)
	draw_set_transform(Vector2.ZERO)
