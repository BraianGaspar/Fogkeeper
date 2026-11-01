class_name Kraken
extends Boss
## Fica na borda do mar sem se aproximar: lança tentáculos que rastejam até o
## farol e cospe tinta que encurta o feixe por alguns segundos.
## Para vencê-lo é preciso alcançar o corpo com a luz enquanto se defende.

const ARMS := 8

var _spawn_cd := 1.5
var _ink_cd := 0.0
var _ink_flash := 0.0


func begin(at_angle: float) -> void:
	position = Vector2.from_angle(at_angle) * (float(data["stand"]) + 170.0)
	_ink_cd = data["ink_every"] * 0.6


func _move(delta: float) -> void:
	_ink_flash = maxf(0.0, _ink_flash - delta * 1.5)
	var d := position.length()
	var stand: float = data["stand"]
	if d > stand + 0.5:
		position = position.normalized() * move_toward(d, stand, speed * delta)
		return
	var r := rate()
	_spawn_cd -= delta * r
	if _spawn_cd <= 0.0:
		_spawn_cd = data["spawn_every"]
		var side := facing().orthogonal() * randf_range(-1.0, 1.0) * radius
		spawn_request.emit("tentacle", position + facing() * radius + side)
	_ink_cd -= delta * r
	if _ink_cd <= 0.0:
		_ink_cd = data["ink_every"]
		_ink_flash = 1.0
		if lighthouse:
			lighthouse.apply_ink(data["ink_time"], data["ink_range"])
		Sfx.play(&"ink")


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	draw_enrage_aura(radius)
	var r := radius
	var skin := CreatureArt.c(Color(0.45, 0.1, 0.18), lit, alpha)
	var dark := CreatureArt.c(Color(0.25, 0.05, 0.1), lit, alpha)
	var face := facing()
	# Braços ondulando em volta do corpo.
	for i in ARMS:
		var a := face.angle() + PI + (i - (ARMS - 1) / 2.0) * 0.45
		draw_set_transform(Vector2.from_angle(a) * r * 0.5, a)
		var spine := CreatureArt.tail(self, 0.0, -r * 2.6, r * 0.32, _time * 0.9, i * 0.8, r * 0.6, skin, 10)
		for j in range(2, spine.size(), 3):
			draw_circle(spine[j], r * 0.07, CreatureArt.c(Color(0.9, 0.6, 0.65), lit, alpha))
	draw_set_transform(Vector2.ZERO, face.angle())
	# Manto alongado para trás e olhos enormes virados para o farol.
	var mantle := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var stretch := 1.6 if cos(a) < 0.0 else 1.0
		mantle.append(Vector2(cos(a) * r * stretch, sin(a) * r * 0.9))
	draw_colored_polygon(mantle, skin)
	for i in 6:
		draw_circle(Vector2(-r * (0.3 + i * 0.18), sin(i * 2.1) * r * 0.4), r * 0.1, dark)
	for s: float in [-1.0, 1.0]:
		var eye := Vector2(r * 0.35, s * r * 0.45)
		draw_circle(eye, r * 0.28, Color(0.95, 0.85, 0.4, alpha) if lit <= 0.0 else Color(1.0, 1.0, 0.8, alpha))
		draw_rect(Rect2(eye + Vector2(-r * 0.04, -r * 0.2), Vector2(r * 0.08, r * 0.4)), Color(0.05, 0.02, 0.02, alpha))
	draw_set_transform(Vector2.ZERO)
	if _ink_flash > 0.0:
		draw_circle(face * r * 1.2, r * (1.0 + (1.0 - _ink_flash) * 2.0), Color(0.05, 0.02, 0.08, 0.5 * _ink_flash))
