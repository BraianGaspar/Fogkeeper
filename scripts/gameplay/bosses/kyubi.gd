class_name Kyubi
extends Boss
## A raposa de nove caudas. Circula a ilha e, de tempos em tempos, some num
## clarão e reaparece entre ilusões idênticas que circulam com ela. A
## verdadeira é a única que projeta sombra na água; as ilusões se desfazem
## com pouca luz. Lança fogos-fátuos (hitodama) contra o farol.

var _angle := 0.0
var _illusion_cd := 0.0
var _fire_cd := 1.5
var _puff := 0.0


func begin(at_angle: float) -> void:
	_angle = at_angle
	position = Vector2.from_angle(_angle) * (float(data["stand"]) + 160.0)
	_illusion_cd = float(data["illusion_every"]) * 0.4


func _move(delta: float) -> void:
	var r := rate()
	_puff = maxf(0.0, _puff - delta * 2.0)
	var d := move_toward(position.length(), float(data["stand"]), 90.0 * delta)
	_angle += speed * r * lit_factor() * delta
	position = Vector2.from_angle(_angle) * d
	_fire_cd -= delta * r
	if _fire_cd <= 0.0:
		_fire_cd = data["fire_every"]
		spawn_request.emit("tentacle", position - position.normalized() * radius)
	_illusion_cd -= delta * r
	if _illusion_cd <= 0.0:
		_illusion_cd = data["illusion_every"]
		_split(d)


## Divide-se: a raposa vai para uma posição sorteada e as ilusões ocupam as outras.
func _split(d: float) -> void:
	var n: int = data["decoys"]
	var real := randi() % (n + 1)
	var base := _angle
	for j in n + 1:
		var a := base + TAU * j / (n + 1)
		if j == real:
			_angle = a
		else:
			spawn_request.emit("decoy", Vector2.from_angle(a) * d)
	position = Vector2.from_angle(_angle) * d
	_puff = 1.0
	Sfx.play(&"spell", 1.4)


func _can_melee() -> bool:
	return false


func facing() -> Vector2:
	return Vector2.from_angle(_angle + PI / 2.0)


func _draw() -> void:
	var alpha := death_alpha()
	draw_enrage_aura(radius)
	# A sombra na água é o que denuncia a raposa verdadeira.
	draw_set_transform(Vector2(radius * 0.35, radius * 0.5), 0.0, Vector2(1.6, 0.8))
	draw_circle(Vector2.ZERO, radius * 0.9, Color(0.0, 0.0, 0.0, 0.35 * alpha))
	draw_set_transform(Vector2.ZERO)
	CreatureArt.draw(self, "kyubi", radius, _time, 0.0, facing(), lit_amount(), alpha)
	if _puff > 0.0:
		draw_circle(Vector2.ZERO, radius * (1.5 + (1.0 - _puff) * 1.5), Color(0.8, 0.85, 1.0, 0.35 * _puff))
