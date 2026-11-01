class_name Umibozu
extends Boss
## O monge do mar: uma cabeça enorme e escura que se ergue das ondas. Na
## névoa ele é quase invisível e a luz de passagem não o fere: só depois de
## alguns instantes sob o feixe ele se revela e passa a queimar. Lança ondas
## que precisam ser quebradas pela luz antes de chegar à ilha, e avança a
## cada uma.

var _stand := 0.0
var _wave_cd := 2.5
var _lit_time := 0.0
var _shown := 0.0 ## 0..1: quanto ele está visível.


func begin(at_angle: float) -> void:
	position = Vector2.from_angle(at_angle) * 470.0
	_stand = data["stand"]


func revealed() -> bool:
	return _lit_time >= float(data["reveal"])


func take_light(amount: float, reflect: bool = false) -> void:
	if not revealed():
		_lit = 0.12 # Conta o tempo sob a luz, mas ainda não queima.
		return
	super.take_light(amount, reflect)


func _move(delta: float) -> void:
	var reveal: float = data["reveal"]
	if _lit > 0.0:
		_lit_time = minf(_lit_time + delta, reveal + 1.2)
	else:
		_lit_time = maxf(0.0, _lit_time - delta * 1.5)
	_shown = move_toward(_shown, 1.0 if revealed() else clampf(_lit_time / reveal, 0.0, 1.0) * 0.6, delta * 4.0)
	var d := position.length()
	if d > _stand + 0.5:
		position = position.normalized() * move_toward(d, maxf(_stand, reach()), speed * rate() * lit_factor() * delta)
		return
	_wave_cd -= delta * rate()
	if _wave_cd <= 0.0:
		_wave_cd = data["wave_every"]
		spawn_request.emit("boulder", position + facing() * radius)
		Sfx.play(&"splash", 0.6)
		_stand = maxf(reach(), _stand - float(data["advance"]))


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	# Ondulações em volta: sempre visíveis, entregam onde ele está.
	for k in 3:
		var rr := r * 1.1 + fmod(_time * 25.0 + k * 20.0, 60.0)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(0.8, 0.9, 1.0, 0.3 * (1.0 - (rr - r * 1.1) / 60.0) * alpha), 2.0)
	var vis := lerpf(0.22, 1.0, _shown) * alpha
	var skin := CreatureArt.c(Color(0.08, 0.1, 0.16), lit, 1.0)
	draw_circle(Vector2.ZERO, r * 1.05, Color(0.0, 0.0, 0.0, 0.25 * vis))
	draw_circle(Vector2.ZERO, r, Color(skin, vis))
	draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.45, Color(0.18, 0.22, 0.3, 0.6 * vis))
	if revealed():
		draw_arc(Vector2.ZERO, r * 1.02, 0.0, TAU, 40, Color(1.0, 0.8, 0.45, 0.7 * alpha), 2.5)
	elif _lit_time > 0.0:
		# Anel que se completa enquanto a luz o revela.
		draw_arc(Vector2.ZERO, r * 1.15, -PI / 2.0, -PI / 2.0 + TAU * clampf(_lit_time / float(data["reveal"]), 0.0, 1.0), 32, Color(1.0, 0.9, 0.6, 0.8 * alpha), 3.0)
	# Olhos sempre acesos, virados para o farol.
	var face := facing()
	for s: float in [-1.0, 1.0]:
		var eye := face * r * 0.45 + face.orthogonal() * s * r * 0.32
		draw_circle(eye, r * 0.2, Color(1.0, 0.95, 0.7, 0.25 * alpha))
		draw_circle(eye, r * 0.11, Color(1.0, 0.95, 0.7, alpha))
