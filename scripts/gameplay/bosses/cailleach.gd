class_name Cailleach
extends Boss
## A Cailleach, a velha do inverno, que fez as montanhas deixando cair pedras
## do avental. Caminha sobre as ondas em volta da ilha e faz rolar pedras de
## ogham contra o farol. De tempos em tempos bate o cajado e chama uma
## tempestade de inverno: o vento sopra para longe as brasas soltas, e as
## pedras caem bem mais depressa. Recolha as brasas antes da tempestade.

var _angle := 0.0
var _storm_cd := 0.0
var _storm_t := 0.0
var _stone_cd := 2.0


func begin(at_angle: float) -> void:
	_angle = at_angle
	position = Vector2.from_angle(_angle) * (float(data["stand"]) + 160.0)
	_storm_cd = float(data["storm_every"]) * 0.6


func storming() -> bool:
	return _storm_t > 0.0 and not dying


func _move(delta: float) -> void:
	var r := rate()
	var d := move_toward(position.length(), float(data["stand"]), 90.0 * delta)
	_angle += speed * r * lit_factor() * delta
	position = Vector2.from_angle(_angle) * d
	if storming():
		_storm_t -= delta
		_blow(delta)
	else:
		_storm_cd -= delta * r
		if _storm_cd <= 0.0:
			_storm_cd = data["storm_every"]
			_storm_t = data["storm_time"]
			Sfx.play(&"thunder", 1.3)
	_stone_cd -= delta * r
	if _stone_cd <= 0.0:
		_stone_cd = data["stone_every"] if storming() else data["hail_every"]
		spawn_request.emit("boulder", position - position.normalized() * radius)


## O vento de inverno empurra as brasas soltas para longe da ilha.
func _blow(delta: float) -> void:
	if embers_root == null:
		return
	var push: float = data["push"]
	for node in embers_root.get_children():
		var m := node as Ember
		if m and not m.attracted() and m.position.length() > 1.0:
			m.position += m.position.normalized() * push * delta


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	if storming():
		# Redemoinho de neve em volta da ilha (desenhado em relação ao farol).
		var center := -position
		for i in 40:
			var a := _time * (1.2 + fmod(i * 0.37, 0.8)) + i * 2.4
			var rr := 70.0 + fmod(i * 53.0 + _time * 90.0, 330.0)
			var p := center + Vector2.from_angle(a) * rr
			draw_line(p, p + Vector2.from_angle(a + 1.2) * 12.0, Color(0.92, 0.97, 1.0, 0.55 * alpha), 2.0)
	var face := facing()
	draw_set_transform(Vector2.ZERO, face.angle())
	# Manto azul-acinzentado arrastando na água, cabelo branco e o cajado.
	var cloak := CreatureArt.c(Color(0.32, 0.4, 0.5), lit, alpha)
	CreatureArt.tail(self, -r * 0.3, r * 2.2, r * 0.9, _time * 0.9, 0.0, r * 0.5, Color(cloak, cloak.a * 0.7), 8)
	draw_circle(Vector2.ZERO, r * 0.9, cloak)
	CreatureArt.tail(self, r * 0.1, r * 1.4, r * 0.55, _time * 1.6, 1.0, r * 0.35, CreatureArt.c(Color(0.92, 0.94, 0.96), lit, alpha), 6)
	var staff_top := Vector2(r * 1.2, r * 0.6)
	draw_line(Vector2(-r * 0.2, r * 0.7), staff_top, CreatureArt.c(Color(0.4, 0.3, 0.2), lit, alpha), 4.0)
	var frost := 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(staff_top, r * (0.22 + (0.15 if storming() else 0.0)), Color(0.7, 0.9, 1.0, (0.4 + 0.5 * frost) * alpha))
	draw_circle(Vector2(r * 0.4, 0), r * 0.42, CreatureArt.c(Color(0.55, 0.65, 0.75), lit, alpha))
	# Um olho só, como nas histórias escocesas.
	CreatureArt.eyes(self, Vector2(r * 0.6, 0), 0.0, r * 0.1, Color(0.5, 0.9, 1.0), lit, alpha)
	draw_set_transform(Vector2.ZERO)
