class_name Jotunn
extends Boss
## Gigante de gelo. Para a certa distância e arremessa pedras de gelo, que são
## criaturas: queime-as no ar antes que atinjam o farol. A cada arremesso ele
## dá alguns passos à frente, até alcançar a ilha e esmagá-la de perto.

var _stand := 0.0
var _throw_cd := 2.0


func begin(at_angle: float) -> void:
	position = Vector2.from_angle(at_angle) * 430.0
	_stand = data["stand"]


func _move(delta: float) -> void:
	var d := position.length()
	if d > _stand + 0.5:
		position = position.normalized() * move_toward(d, maxf(_stand, reach()), speed * rate() * lit_factor() * delta)
		return
	_throw_cd -= delta * rate()
	if _throw_cd <= 0.0:
		_throw_cd = data["throw_every"]
		spawn_request.emit("boulder", position + facing() * radius * 1.3)
		Sfx.play(&"throw")
		_stand = maxf(reach(), _stand - float(data["advance"]))


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	draw_enrage_aura(radius)
	var r := radius
	draw_set_transform(Vector2.ZERO, facing().angle())
	var skin := CreatureArt.c(Color(0.55, 0.68, 0.78), lit, alpha)
	var fur := CreatureArt.c(Color(0.35, 0.3, 0.28), lit, alpha)
	var ice := CreatureArt.c(Color(0.8, 0.93, 1.0), lit, alpha)
	var windup := 1.0 - clampf(_throw_cd / float(data["throw_every"]), 0.0, 1.0)
	# Manto de pele e ombros largos.
	var cloak := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		cloak.append(Vector2(cos(a) * r * 0.75 - r * 0.2, sin(a) * r * 1.25))
	draw_colored_polygon(cloak, fur)
	draw_circle(Vector2(0, -r * 0.75), r * 0.42, skin)
	draw_circle(Vector2(0, r * 0.75), r * 0.42, skin)
	# Braço do arremesso recua conforme o golpe se prepara.
	var hand := Vector2(r * (0.9 - windup * 1.4), r * 1.15)
	draw_line(Vector2(0, r * 0.75), hand, skin, r * 0.32)
	if windup > 0.3:
		draw_circle(hand, r * 0.35, ice)
	draw_line(Vector2(0, -r * 0.75), Vector2(r * 0.9, -r * 1.0), skin, r * 0.32)
	# Cabeça com barba congelada e coroa de gelo.
	draw_circle(Vector2(r * 0.15, 0), r * 0.5, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(r * 0.35, -r * 0.35), Vector2(r * 1.0, 0), Vector2(r * 0.35, r * 0.35)]), ice)
	for i in 5:
		var a := -0.9 + i * 0.45
		var base := Vector2(r * 0.15, 0) + Vector2.from_angle(a + PI) * r * 0.45
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -r * 0.07), base + Vector2.from_angle(a + PI) * r * 0.35, base + Vector2(0, r * 0.07)]), ice)
	CreatureArt.eyes(self, Vector2(r * 0.42, 0), r * 0.18, r * 0.07, Color(0.5, 0.9, 1.0), lit, alpha)
	draw_set_transform(Vector2.ZERO)
