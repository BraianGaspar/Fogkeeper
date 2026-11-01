class_name Enemy
extends Node2D
## Criatura da névoa: avança até o farol e o ataca ao encostar.
## Os atributos vêm de Balance.ENEMIES[role]; a aparência (`art`) vem do mapa
## e é desenhada por CreatureArt. Chefes estendem Boss e sobrescrevem _move().

signal killed(enemy: Enemy)

const DEATH_TIME := 0.3

var kind := "basic" ## Papel (basic, fast, brute...) ou id do chefe.
var art := "wraith"
var max_hp := 10.0
var hp := 10.0
var speed := 50.0
var radius := 12.0
var damage := 4.0
var xp_value := 1
var score_value := 0
var elite := false
var dying := false
var invulnerable := false
var lighthouse: Lighthouse

var _lit := 0.0
var _stun := 0.0
var _attack_cd := 0.0
var _phase := 0.0
var _lateral := 0.0
var _death_t := 0.0
var _time := 0.0


func setup(role: String, art_id: String, hp_mult: float, damage_mult: float, speed_mult: float, rng: RandomNumberGenerator, is_elite: bool = false) -> void:
	kind = role
	art = art_id
	elite = is_elite
	var data: Dictionary = Balance.ENEMIES[role]
	max_hp = float(data["hp"]) * hp_mult
	speed = float(data["speed"]) * speed_mult * rng.randf_range(0.9, 1.1)
	radius = float(data["radius"])
	damage = float(data["damage"]) * damage_mult
	xp_value = int(data["xp"])
	score_value = int(data["score"])
	if elite:
		max_hp *= Balance.ELITE["hp"]
		damage *= Balance.ELITE["damage"]
		radius *= Balance.ELITE["radius"]
		xp_value *= Balance.ELITE["xp"]
		score_value *= Balance.ELITE["score"]
	hp = max_hp
	_phase = rng.randf() * TAU
	_lateral = 0.0 if role == "boulder" else rng.randf_range(-1.0, 1.0)


func is_boss() -> bool:
	return false


func take_light(amount: float) -> void:
	if dying or invulnerable:
		return
	hp -= amount
	_lit = 0.12
	if hp <= 0.0:
		dying = true
		killed.emit(self)


## Paralisa por `seconds` (habilidade Clarão).
func stun(seconds: float) -> void:
	_stun = maxf(_stun, seconds)


## Some sem dar XP nem pontos (usado quando amanhece).
func dissolve() -> void:
	dying = true


func reach() -> float:
	return radius + Balance.LIGHTHOUSE_RADIUS


func _process(delta: float) -> void:
	_time += delta
	if dying:
		_death_t += delta
		if _death_t >= DEATH_TIME:
			queue_free()
		queue_redraw()
		return
	_lit = maxf(0.0, _lit - delta)
	if _stun > 0.0:
		_stun -= delta
		queue_redraw()
		return
	_move(delta)
	if _can_melee() and position.length() <= reach() + 0.5:
		_attack_cd -= delta
		if _attack_cd <= 0.0:
			_attack_cd = Balance.ATTACK_INTERVAL
			if lighthouse:
				lighthouse.take_damage(damage)
			if kind == "boulder":
				dissolve() # A pedra se despedaça ao acertar.
	queue_redraw()


## Movimento padrão: avança até o farol, ondulando para os lados.
func _move(delta: float) -> void:
	var dist := position.length()
	if dist <= reach():
		return
	var dir := -position / dist
	var side := dir.orthogonal() * sin(_time * 2.0 + _phase) * 0.4 * _lateral
	var slow := lighthouse.lit_slow if lighthouse else Balance.LIT_SLOW
	var spd := speed * (slow if _lit > 0.0 else 1.0)
	position += (dir + side).normalized() * spd * delta
	if position.length() < reach():
		position = position.normalized() * reach()


func _can_melee() -> bool:
	return not invulnerable


## 0..1: quanto a criatura está "acesa" (queimando) neste instante.
func lit_amount() -> float:
	if dying:
		return 1.0
	return (0.55 + 0.25 * sin(_time * 40.0)) if _lit > 0.0 else 0.0


func facing() -> Vector2:
	return (-position).normalized() if position.length() > 1.0 else Vector2.RIGHT


func _draw() -> void:
	var t := _death_t / DEATH_TIME if dying else 0.0
	var alpha := 1.0 - t
	var r := radius * (1.0 + t * 0.8)
	if elite and not dying:
		var pulse := 0.6 + 0.4 * sin(_time * 5.0 + _phase)
		draw_circle(Vector2.ZERO, r * 1.9, Color(1.0, 0.35, 0.2, 0.1 * pulse))
		draw_arc(Vector2.ZERO, r * 1.55, 0.0, TAU, 28, Color(1.0, 0.65, 0.25, 0.55 * pulse), 2.0)
	CreatureArt.draw(self, art, r, _time, _phase, facing(), lit_amount(), alpha)
	if _stun > 0.0 and not dying:
		for i in 3:
			var a := _time * 4.0 + i * TAU / 3.0
			UiTheme.diamond(self, Vector2(cos(a) * r * 0.9, -r - 6.0 + sin(a) * 3.0), 3.0, Color(1.0, 0.95, 0.6, 0.9))
	if max_hp >= 60.0 and not dying and hp < max_hp and not is_boss():
		draw_rect(Rect2(-r, -r - 9.0, 2.0 * r, 3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-r, -r - 9.0, 2.0 * r * hp / max_hp, 3.0), Color(1.0, 0.6, 0.2))
