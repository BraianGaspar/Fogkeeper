class_name Enemy
extends Node2D
## Criatura da névoa: avança até o farol e o ataca ao encostar.
## Os atributos vêm de Balance.ENEMIES[role]; a aparência (`art`) vem do mapa
## e é desenhada por CreatureArt. Chefes estendem Boss e sobrescrevem _move().
##
## Papéis especiais:
##   thief    rouba brasas soltas e foge; queimada, devolve o roubo
##   mirror   casca fechada reflete parte da luz no farol; só abre de vez em quando
##   moth     a luz a alimenta: cresce, acelera e vale mais brasas
##   fogbank  névoa que atravessa o mapa apagando as brasas; a luz a dissipa

signal killed(enemy: Enemy)
signal escaped(enemy: Enemy)

const DEATH_TIME := 0.3
const ESCAPE_DIST := 900.0 ## Distância em que a ladra some com o roubo.

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
var embers_root: Node2D
var carried := 0 ## Valor das brasas roubadas (ladra).
var reflecting := false ## Espelho fechado.
var growth := 0.0 ## Quanto a mariposa cresceu na luz.

var _lit := 0.0
var _stun := 0.0
var _attack_cd := 0.0
var _phase := 0.0
var _lateral := 0.0
var _death_t := 0.0
var _time := 0.0
var _base_radius := 12.0
var _base_damage := 4.0
var _base_xp := 1
var _cycle := 0.0
var _open := 0.0
var _reflect_fx := 0.0
var _fleeing := false
var _drift := Vector2.ZERO


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
	_base_radius = radius
	_base_damage = damage
	_base_xp = xp_value
	_phase = rng.randf() * TAU
	_lateral = 0.0 if role == "boulder" else rng.randf_range(-1.0, 1.0)
	if role == "mirror":
		reflecting = true
		_cycle = rng.randf_range(0.5, Balance.MIRROR_CLOSED)


## Névoa devoradora: atravessa o mapa passando perto da ilha.
func begin_drift(rng: RandomNumberGenerator) -> void:
	var target := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(100.0, 240.0)
	_drift = (target - position).normalized()


func is_boss() -> bool:
	return false


## A luz não fere agora (espelho fechado, Boitatá em chamas): o bot mira em outra.
func immune_to_light() -> bool:
	return reflecting


## `reflect`: veio do feixe principal (só ele é refletido pelo espelho fechado).
func take_light(amount: float, reflect: bool = false) -> void:
	if dying or invulnerable:
		return
	if reflecting:
		_lit = 0.12
		if reflect and lighthouse:
			_reflect_fx = 0.15
			lighthouse.take_damage(amount * Balance.MIRROR_REFLECT, true)
		return
	hp -= amount
	_lit = 0.12
	if hp <= 0.0:
		dying = true
		killed.emit(self)


## Paralisa por `seconds` (habilidade Clarão). O espelho se abre.
func stun(seconds: float) -> void:
	_stun = maxf(_stun, seconds)
	if kind == "mirror":
		reflecting = false
		_cycle = maxf(_cycle, seconds + Balance.MIRROR_OPEN)


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
	_reflect_fx = maxf(0.0, _reflect_fx - delta)
	_update_role(delta)
	if _stun > 0.0:
		_stun -= delta
		queue_redraw()
		return
	_move(delta)
	if dying:
		return
	if _can_melee() and position.length() <= reach() + 0.5:
		_attack_cd -= delta
		if _attack_cd <= 0.0:
			_attack_cd = Balance.ATTACK_INTERVAL
			if lighthouse:
				lighthouse.take_damage(damage)
			if kind == "boulder":
				dissolve() # A pedra se despedaça ao acertar.
	queue_redraw()


func _update_role(delta: float) -> void:
	match kind:
		"mirror":
			_cycle -= delta
			if _cycle <= 0.0:
				reflecting = not reflecting
				_cycle = Balance.MIRROR_CLOSED if reflecting else Balance.MIRROR_OPEN
			_open = move_toward(_open, 0.0 if reflecting else 1.0, delta * 5.0)
		"moth":
			if _lit > 0.0:
				growth = minf(Balance.MOTH_MAX, growth + Balance.MOTH_GROW * delta)
			radius = _base_radius * (1.0 + 0.35 * growth)
			damage = _base_damage * (1.0 + 0.6 * growth)
			xp_value = roundi(_base_xp * (1.0 + growth * 1.5))
		"fogbank":
			radius = _base_radius * (0.35 + 0.65 * hp / max_hp)
			if embers_root:
				for node in embers_root.get_children():
					var m := node as Ember
					if m and m.position.distance_to(position) < radius:
						m.drain(delta * (Balance.FOGBANK_DRAIN - 1.0))


func _move(delta: float) -> void:
	match kind:
		"thief":
			_move_thief(delta)
		"decoy":
			# Ilusão da Kyūbi: circula como ela, sem se aproximar.
			position = Vector2.from_angle(position.angle() + speed * delta) * position.length()
		"fogbank":
			position += _drift * speed * delta
			if position.length() > ESCAPE_DIST and position.dot(_drift) > 0.0:
				queue_free()
		_:
			_approach(delta)


## Movimento padrão: avança até o farol, ondulando para os lados. A luz
## desacelera, menos a mariposa, que acelera.
func _approach(delta: float) -> void:
	var dist := position.length()
	if dist <= reach():
		return
	var dir := -position / dist
	var side := dir.orthogonal() * sin(_time * 2.0 + _phase) * 0.4 * _lateral
	var slow := lighthouse.lit_slow if lighthouse else Balance.LIT_SLOW
	var spd := speed * (slow if _lit > 0.0 else 1.0)
	if kind == "moth" and _lit > 0.0:
		spd = speed * 1.15
	position += (dir + side).normalized() * spd * delta
	if position.length() < reach():
		position = position.normalized() * reach()


## A ladra busca a brasa solta mais próxima; com o bolso cheio (ou sem
## paciência) foge para a névoa levando tudo.
func _move_thief(delta: float) -> void:
	var slow := (lighthouse.lit_slow if lighthouse else Balance.LIT_SLOW) if _lit > 0.0 else 1.0
	if not _fleeing and (carried >= Balance.THIEF_CARRY or _time > Balance.THIEF_PATIENCE):
		_fleeing = true
	if _fleeing:
		position += position.normalized() * speed * 1.15 * slow * delta
		if position.length() > ESCAPE_DIST:
			dying = true
			escaped.emit(self)
			queue_free()
		return
	var target := _nearest_ember()
	if target == null:
		# Sem brasas à vista: ronda a ilha esperando.
		var d := position.length()
		var radial := -position.normalized() * clampf((d - 300.0) / 60.0, -1.0, 1.0)
		position += (position.orthogonal().normalized() * 0.7 + radial).normalized() * speed * 0.6 * slow * delta
		return
	var to := target.position - position
	if to.length() <= radius + 8.0:
		carried += target.steal()
		Sfx.play(&"steal")
		return
	position += to.normalized() * speed * slow * delta


func _nearest_ember() -> Ember:
	if embers_root == null:
		return null
	var best: Ember = null
	var best_d := 700.0
	for node in embers_root.get_children():
		var m := node as Ember
		if m == null or m.attracted() or m.is_queued_for_deletion():
			continue
		var d := m.position.distance_to(position)
		if d < best_d:
			best_d = d
			best = m
	return best


func _can_melee() -> bool:
	return not invulnerable and kind not in ["thief", "fogbank", "decoy"]


## 0..1: quanto a criatura está "acesa" (queimando) neste instante.
func lit_amount() -> float:
	if dying:
		return 1.0
	if reflecting:
		return 0.0
	return (0.55 + 0.25 * sin(_time * 40.0)) if _lit > 0.0 else 0.0


func facing() -> Vector2:
	if kind == "thief" and _fleeing:
		return position.normalized()
	if kind == "fogbank":
		return _drift if _drift != Vector2.ZERO else Vector2.RIGHT
	if kind == "decoy":
		return Vector2.from_angle(position.angle() + PI / 2.0)
	return (-position).normalized() if position.length() > 1.0 else Vector2.RIGHT


## Valor extra para a arte: abertura do espelho, crescimento da mariposa,
## brasas da ladra e vida da névoa.
func _art_extra() -> float:
	match kind:
		"mirror":
			return _open
		"moth":
			return growth / Balance.MOTH_MAX
		"thief":
			return float(carried)
		"fogbank":
			return hp / max_hp
	return 0.0


func _draw() -> void:
	var t := _death_t / DEATH_TIME if dying else 0.0
	var alpha := 1.0 - t
	var r := radius * (1.0 + t * 0.8)
	if elite and not dying:
		var pulse := 0.6 + 0.4 * sin(_time * 5.0 + _phase)
		draw_circle(Vector2.ZERO, r * 1.9, Color(1.0, 0.35, 0.2, 0.1 * pulse))
		draw_arc(Vector2.ZERO, r * 1.55, 0.0, TAU, 28, Color(1.0, 0.65, 0.25, 0.55 * pulse), 2.0)
	CreatureArt.draw(self, art, r, _time, _phase, facing(), lit_amount(), alpha, _art_extra())
	if _reflect_fx > 0.0 and not dying:
		# Raio refletido de volta para o farol.
		var back := -position.normalized()
		var k := _reflect_fx / 0.15
		draw_line(back * r, back * minf(140.0, position.length() - 40.0), Color(1.0, 1.0, 0.85, 0.55 * k), 3.0)
		draw_circle(back * r, 5.0, Color(1.0, 1.0, 0.9, 0.7 * k))
	if _lit > 0.0 and not dying and Settings.particles and kind != "fogbank":
		# Faíscas subindo de quem está queimando.
		for i in 3:
			var f := fmod(_time * 2.2 + i * 0.37 + _phase, 1.0)
			var x := sin(_phase * 3.0 + i * 2.1 + _time * 4.0) * r * 0.7
			draw_circle(Vector2(x, -r * 0.4 - f * r * 1.4), 1.8 * (1.0 - f), Color(1.0, 0.75, 0.3, 0.9 * (1.0 - f)))
	if _stun > 0.0 and not dying:
		for i in 3:
			var a := _time * 4.0 + i * TAU / 3.0
			UiTheme.diamond(self, Vector2(cos(a) * r * 0.9, -r - 6.0 + sin(a) * 3.0), 3.0, Color(1.0, 0.95, 0.6, 0.9))
	if max_hp >= 60.0 and not dying and hp < max_hp and not is_boss() and kind != "fogbank":
		draw_rect(Rect2(-r, -r - 9.0, 2.0 * r, 3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-r, -r - 9.0, 2.0 * r * hp / max_hp, 3.0), Color(1.0, 0.6, 0.2))
