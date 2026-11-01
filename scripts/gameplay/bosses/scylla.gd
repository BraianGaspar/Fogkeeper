class_name Scylla
extends Boss
## Cila, o terror do estreito. Fica presa ao seu rochedo e estica seis
## pescoços compridos contra o farol, um de cada vez: cada cabeça que chega à
## ilha morde. Segure o feixe principal numa cabeça que avança para fazê-la
## recuar; cada cabeça repelida fere a própria Cila. O corpo, protegido pelo
## rochedo, sente pouco a luz. Do rochedo caem blocos de mármore que rolam até
## o farol.

const NECK := 70.0 ## Distância das cabeças em repouso até o corpo.

var _heads: Array[Dictionary] = [] ## progress (0..1 avanço), light (tempo sob a luz), recoil, phase
var _strike_cd := 2.0
var _rock_cd := 3.0


func begin(at_angle: float) -> void:
	position = Vector2.from_angle(at_angle) * (float(data["stand"]) + 150.0)
	for i in int(data["heads"]):
		_heads.append({"progress": 0.0, "striking": false, "light": 0.0, "recoil": 0.0, "phase": i * 1.3})


## Posição de uma cabeça (em coordenadas do mundo).
func head_position(i: int) -> Vector2:
	var h: Dictionary = _heads[i]
	var spread := (i - (_heads.size() - 1) / 2.0) * 0.32
	var rest := position + (-position.normalized()).rotated(spread) * NECK + Vector2(0, sin(_time * 2.0 + float(h["phase"])) * 6.0)
	var target := position.normalized() * (Balance.LIGHTHOUSE_RADIUS + 12.0)
	return rest.lerp(target, ease(float(h["progress"]), 0.6))


## A cabeça que avança mais perto do farol (o bot mira nela, como um jogador atento).
func threat_angle() -> float:
	var best := -1
	for i in _heads.size():
		if _heads[i]["striking"] and (best < 0 or float(_heads[i]["progress"]) > float(_heads[best]["progress"])):
			best = i
	return head_position(best).angle() if best >= 0 else NAN


func take_light(amount: float, reflect: bool = false) -> void:
	super.take_light(amount * float(data["body_damage"]), reflect)


func _move(delta: float) -> void:
	var stand: float = data["stand"]
	var d := position.length()
	if d > stand + 0.5:
		position = position.normalized() * move_toward(d, stand, speed * delta)
		return
	var r := rate()
	_strike_cd -= delta * r
	if _strike_cd <= 0.0:
		_strike_cd = data["strike_every"]
		var idle: Array[int] = []
		for i in _heads.size():
			if not _heads[i]["striking"] and float(_heads[i]["recoil"]) <= 0.0:
				idle.append(i)
		if not idle.is_empty():
			var h: Dictionary = _heads[idle[randi() % idle.size()]]
			h["striking"] = true
			h["light"] = 0.0
			Sfx.play(&"growl", 1.3)
	for i in _heads.size():
		_update_head(i, delta * r)
	_rock_cd -= delta * r
	if _rock_cd <= 0.0:
		_rock_cd = data["rock_every"]
		spawn_request.emit("boulder", position - position.normalized() * radius)


func _update_head(i: int, delta: float) -> void:
	var h: Dictionary = _heads[i]
	h["recoil"] = maxf(0.0, float(h["recoil"]) - delta)
	if not h["striking"]:
		h["progress"] = move_toward(float(h["progress"]), 0.0, delta * 1.5)
		return
	h["progress"] = minf(1.0, float(h["progress"]) + delta / float(data["strike_time"]))
	if _in_beam(head_position(i)):
		h["light"] = float(h["light"]) + delta
		if float(h["light"]) >= float(data["head_hp"]):
			# Repelida: recua e a dor chega ao corpo.
			h["striking"] = false
			h["recoil"] = 1.5
			super.take_light(max_hp * float(data["head_damage"]))
			Sfx.play(&"burn_big", 0.8)
			return
	if float(h["progress"]) >= 1.0:
		h["striking"] = false
		h["recoil"] = 1.0
		if lighthouse:
			lighthouse.take_damage(damage)
		Sfx.play(&"roar", 1.5)


func _in_beam(p: Vector2) -> bool:
	if lighthouse == null:
		return false
	var d := p.length()
	if d > lighthouse.beam_range + 14.0 or d < 1.0:
		return false
	return absf(angle_difference(lighthouse.aim_angle, p.angle())) <= lighthouse.beam_half_angle + atan2(14.0, d)


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	# Rochedo do estreito, com espuma em volta.
	for k in 2:
		draw_arc(Vector2.ZERO, r * 1.5 + k * 8.0 + sin(_time * 2.0 + k) * 3.0, 0.0, TAU, 36, Color(0.85, 0.92, 1.0, 0.25 * alpha), 2.0)
	var rock := PackedVector2Array()
	for i in 11:
		var a := TAU * i / 11.0
		rock.append(Vector2.from_angle(a) * r * (1.15 + 0.2 * sin(a * 3.0 + 1.0)))
	draw_colored_polygon(rock, CreatureArt.c(Color(0.4, 0.38, 0.36), 0.0, alpha))
	# Pescoços e cabeças: serpentes de focinho de cão.
	var neck_col := CreatureArt.c(Color(0.22, 0.36, 0.32), lit, alpha)
	for i in _heads.size():
		var hp_ := head_position(i) - position
		var root := (-position.normalized()).rotated((i - (_heads.size() - 1) / 2.0) * 0.5) * r * 0.5
		var mid := (root + hp_) * 0.5 + (hp_ - root).orthogonal().normalized() * sin(_time * 3.0 + i) * 10.0
		draw_polyline(PackedVector2Array([root, mid, hp_]), neck_col, 7.0)
		var h: Dictionary = _heads[i]
		var glow := clampf(float(h["light"]) / float(data["head_hp"]), 0.0, 1.0) if h["striking"] else 0.0
		var face := (hp_ - mid).normalized()
		draw_set_transform(hp_, face.angle())
		draw_circle(Vector2.ZERO, 11.0, CreatureArt.c(Color(0.25, 0.4, 0.35), glow, alpha))
		draw_colored_polygon(PackedVector2Array([Vector2(4, -6), Vector2(18, -2), Vector2(18, 2), Vector2(4, 6)]), CreatureArt.c(Color(0.3, 0.45, 0.38), glow, alpha))
		if h["striking"]:
			draw_line(Vector2(8, 0), Vector2(18, 0), Color(0.6, 0.05, 0.05, alpha), 2.0)
			draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 16, Color(1.0, 0.4, 0.3, 0.5 * alpha), 1.5)
		CreatureArt.eyes(self, Vector2(6, 0), 5.0, 2.0, Color(1.0, 0.85, 0.2), glow, alpha)
		draw_set_transform(Vector2.ZERO)
	# Torso de ninfa sobre o rochedo, de cabelos escuros.
	var face_dir := facing()
	draw_set_transform(Vector2.ZERO, face_dir.angle())
	draw_circle(Vector2.ZERO, r * 0.55, CreatureArt.c(Color(0.55, 0.62, 0.58), lit, alpha))
	draw_circle(Vector2(-r * 0.15, 0), r * 0.45, CreatureArt.c(Color(0.1, 0.14, 0.12), lit, alpha))
	draw_circle(Vector2(r * 0.15, 0), r * 0.3, CreatureArt.c(Color(0.7, 0.75, 0.7), lit, alpha))
	CreatureArt.eyes(self, Vector2(r * 0.28, 0), r * 0.12, r * 0.05, Color(0.5, 1.0, 0.8), lit, alpha)
	draw_set_transform(Vector2.ZERO)
