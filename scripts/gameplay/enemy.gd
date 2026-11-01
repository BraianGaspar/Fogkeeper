class_name Enemy
extends Node2D
## Criatura da névoa: avança até o farol e o ataca ao encostar.
## Os atributos vêm de Balance.ENEMIES[kind].

signal killed(enemy: Enemy)

const DEATH_TIME := 0.3

var kind := "mist"
var max_hp := 10.0
var hp := 10.0
var speed := 50.0
var radius := 12.0
var damage := 4.0
var xp_value := 1
var color := Color(0.3, 0.2, 0.4)
var dying := false
var lighthouse: Lighthouse

var _lit := 0.0
var _attack_cd := 0.0
var _phase := 0.0
var _lateral := 0.0
var _death_t := 0.0
var _time := 0.0


func setup(enemy_kind: String, hp_mult: float, damage_mult: float, rng: RandomNumberGenerator) -> void:
	kind = enemy_kind
	var data: Dictionary = Balance.ENEMIES[kind]
	if data.get("boss", false):
		hp_mult = 1.0 + (hp_mult - 1.0) * 0.5
	max_hp = float(data["hp"]) * hp_mult
	hp = max_hp
	speed = float(data["speed"]) * rng.randf_range(0.9, 1.1)
	radius = float(data["radius"])
	damage = float(data["damage"]) * damage_mult
	xp_value = int(data["xp"])
	color = data["color"]
	_phase = rng.randf() * TAU
	_lateral = rng.randf_range(-1.0, 1.0)


func take_light(amount: float) -> void:
	if dying:
		return
	hp -= amount
	_lit = 0.12
	if hp <= 0.0:
		dying = true
		killed.emit(self)


## Some sem dar XP nem pontos (usado quando amanhece).
func dissolve() -> void:
	dying = true


func _process(delta: float) -> void:
	_time += delta
	if dying:
		_death_t += delta
		if _death_t >= DEATH_TIME:
			queue_free()
		queue_redraw()
		return

	_lit = maxf(0.0, _lit - delta)
	var dist := position.length()
	var reach := radius + Balance.LIGHTHOUSE_RADIUS
	if dist > reach:
		var dir := -position / dist
		var side := dir.orthogonal() * sin(_time * 2.0 + _phase) * 0.4 * _lateral
		var spd := speed * (Balance.LIT_SLOW if _lit > 0.0 else 1.0)
		position += (dir + side).normalized() * spd * delta
		if position.length() < reach:
			position = position.normalized() * reach
	else:
		_attack_cd -= delta
		if _attack_cd <= 0.0:
			_attack_cd = Balance.ATTACK_INTERVAL
			if lighthouse:
				lighthouse.take_damage(damage)
	queue_redraw()


func _draw() -> void:
	var t := _death_t / DEATH_TIME if dying else 0.0
	var r := radius * (1.0 + t * 0.8)
	var a := 1.0 - t
	var body := color
	if _lit > 0.0 or dying:
		body = body.lerp(Color(1.0, 0.55, 0.2), 0.55 + 0.25 * sin(_time * 40.0))

	var pts := PackedVector2Array()
	for i in 14:
		var ang := TAU * i / 14.0
		var wob := 1.0 + 0.12 * sin(ang * 3.0 + _time * 4.0 + _phase)
		pts.append(Vector2.from_angle(ang) * r * wob)
	draw_colored_polygon(pts, Color(body, 0.92 * a))
	pts.append(pts[0])
	draw_polyline(pts, Color(body.lightened(0.35), 0.8 * a), 1.5)

	var face := (-position).normalized() if position.length() > 1.0 else Vector2.RIGHT
	var side := face.orthogonal()
	var eye := Color(1.0, 1.0, 0.8, a) if _lit > 0.0 else Color(0.75, 0.95, 1.0, a)
	for s in [-1.0, 1.0]:
		draw_circle(face * r * 0.35 + side * r * 0.3 * s, maxf(1.5, r * 0.13), eye)

	if max_hp >= 60.0 and not dying and hp < max_hp:
		draw_rect(Rect2(-r, -r - 9.0, 2.0 * r, 3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-r, -r - 9.0, 2.0 * r * hp / max_hp, 3.0), Color(1.0, 0.6, 0.2))
