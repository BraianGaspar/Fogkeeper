class_name Sphinx
extends Boss
## A Esfinge. Para longe da ilha e propõe enigmas: três símbolos surgem em
## volta do farol e ela mostra, acima da cabeça, qual deles é a resposta.
## Segure o feixe no símbolo certo por um instante para responder: ela fica
## atordoada e a luz a fere em dobro. Errar ou demorar faz pedras de arenito
## rolarem contra o farol. Fora dessa janela, a luz a fere só pela metade.

const GLYPHS := ["ankh", "eye", "feather"]
const GLYPH_RADIUS := 210.0

var _riddle_cd := 0.0
var _riddle_t := 0.0
var _slots: Array[float] = []
var _glyph_ids: Array[String] = []
var _answer := 0
var _hold := 0.0
var _hold_slot := -1
var _weak_t := 0.0


func begin(at_angle: float) -> void:
	position = Vector2.from_angle(at_angle) * (float(data["stand"]) + 150.0)
	_riddle_cd = float(data["riddle_every"]) * 0.5


func riddling() -> bool:
	return _riddle_t > 0.0 and not dying


## Direção do símbolo certo (o bot usa para responder).
func answer_angle() -> float:
	return _slots[_answer] if _answer < _slots.size() else 0.0


func take_light(amount: float, reflect: bool = false) -> void:
	var mult: float = data["weak_damage"] if _weak_t > 0.0 else data["strong_damage"]
	super.take_light(amount * mult, reflect)


func _move(delta: float) -> void:
	_weak_t = maxf(0.0, _weak_t - delta)
	var stand: float = data["stand"]
	var d := position.length()
	if d > stand + 0.5:
		position = position.normalized() * move_toward(d, stand, speed * delta)
		return
	if riddling():
		_riddle_t -= delta
		var slot := _slot_under_beam()
		if slot >= 0 and slot == _hold_slot:
			_hold += delta
		else:
			_hold_slot = slot
			_hold = 0.0
		if _hold >= float(data["answer"]):
			if slot == _answer:
				_solve()
			else:
				_punish()
		elif _riddle_t <= 0.0:
			_punish()
		return
	if _weak_t > 0.0:
		return
	_riddle_cd -= delta * rate()
	if _riddle_cd <= 0.0:
		_start_riddle()


func _slot_under_beam() -> int:
	if lighthouse == null:
		return -1
	for i in _slots.size():
		if absf(angle_difference(lighthouse.aim_angle, _slots[i])) <= lighthouse.beam_half_angle + 0.08:
			return i
	return -1


func _start_riddle() -> void:
	var base := randf() * TAU
	_slots = [base, base + TAU / 3.0, base + TAU * 2.0 / 3.0]
	_glyph_ids.assign(GLYPHS.duplicate())
	_glyph_ids.shuffle()
	_answer = randi() % 3
	_riddle_t = data["riddle_time"]
	_hold = 0.0
	_hold_slot = -1
	Sfx.play(&"announce", 0.8)


func _solve() -> void:
	_riddle_t = 0.0
	_riddle_cd = data["riddle_every"]
	_weak_t = data["weak_time"]
	Sfx.play(&"relic", 1.2)


func _punish() -> void:
	_riddle_t = 0.0
	_riddle_cd = data["riddle_every"]
	for i in int(data["punish_stones"]):
		spawn_request.emit("boulder", position + Vector2.from_angle(TAU * i / float(data["punish_stones"])) * radius)
	Sfx.play(&"roar", 1.2)


func _can_melee() -> bool:
	return false


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	if riddling():
		_draw_riddle(alpha)
	draw_set_transform(Vector2.ZERO, facing().angle())
	var fur := CreatureArt.c(Color(0.78, 0.62, 0.36), lit, alpha)
	var dark := CreatureArt.c(Color(0.55, 0.42, 0.22), lit, alpha)
	# Corpo de leão deitado, patas à frente.
	var body := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		body.append(Vector2(cos(a) * r * 1.05 - r * 0.35, sin(a) * r * 0.6))
	draw_colored_polygon(body, fur)
	for s: float in [-1.0, 1.0]:
		draw_line(Vector2(r * 0.1, s * r * 0.45), Vector2(r * 1.0, s * r * 0.45), fur, r * 0.22)
	CreatureArt.tail(self, -r * 1.3, r * 0.8, r * 0.08, _time * 0.5, 0.0, r * 0.2, dark, 6)
	# Cabeça com o nemes listrado de azul e ouro.
	var head := Vector2(r * 0.45, 0)
	for i in 5:
		var col := Color(0.2, 0.3, 0.65) if i % 2 == 0 else Color(0.9, 0.75, 0.25)
		draw_circle(head - Vector2(r * 0.1, 0), r * (0.62 - i * 0.07), CreatureArt.c(col, lit, alpha))
	draw_circle(head + Vector2(r * 0.12, 0), r * 0.3, CreatureArt.c(Color(0.82, 0.66, 0.4), lit, alpha))
	CreatureArt.eyes(self, head + Vector2(r * 0.25, 0), r * 0.13, r * 0.06, Color(0.3, 0.8, 1.0), lit, alpha)
	draw_set_transform(Vector2.ZERO)
	if _weak_t > 0.0 and not dying:
		draw_arc(Vector2.ZERO, r * 1.3, 0.0, TAU, 40, Color(1.0, 0.85, 0.4, 0.8), 3.0)
		for i in 3:
			var a := _time * 4.0 + i * TAU / 3.0
			UiTheme.diamond(self, Vector2(cos(a) * r * 0.8, -r - 10.0 + sin(a) * 4.0), 4.0, Color(1.0, 0.95, 0.6))


## Os três símbolos em volta do farol e, acima da Esfinge, o que ela pede.
func _draw_riddle(alpha: float) -> void:
	var k := clampf(_riddle_t / float(data["riddle_time"]), 0.0, 1.0)
	_glyph(Vector2(0, -radius - 34.0), _glyph_ids[_answer], 18.0, Color(1.0, 0.85, 0.35, alpha))
	draw_arc(Vector2(0, -radius - 34.0), 26.0, -PI / 2.0, -PI / 2.0 + TAU * k, 32, Color(1.0, 0.85, 0.35, 0.8 * alpha), 3.0)
	for i in _slots.size():
		var p := Vector2.from_angle(_slots[i]) * GLYPH_RADIUS - position
		var held := _hold / float(data["answer"]) if i == _hold_slot else 0.0
		draw_circle(p, 26.0, Color(0.05, 0.04, 0.02, 0.55 * alpha))
		draw_arc(p, 26.0, 0.0, TAU, 32, Color(0.95, 0.8, 0.45, 0.6 * alpha), 2.0)
		if held > 0.0:
			draw_arc(p, 30.0, -PI / 2.0, -PI / 2.0 + TAU * held, 32, Color(1.0, 1.0, 0.8, alpha), 4.0)
		_glyph(p, _glyph_ids[i], 14.0, Color(0.95, 0.8, 0.45, alpha))


func _glyph(c: Vector2, id: String, s: float, col: Color) -> void:
	match id:
		"ankh":
			draw_arc(c + Vector2(0, -s * 0.45), s * 0.38, 0.0, TAU, 16, col, 3.0)
			draw_line(c + Vector2(0, -s * 0.07), c + Vector2(0, s), col, 3.0)
			draw_line(c + Vector2(-s * 0.55, s * 0.1), c + Vector2(s * 0.55, s * 0.1), col, 3.0)
		"eye":
			draw_arc(c, s * 0.75, PI * 1.15, PI * 1.85, 12, col, 2.5)
			draw_arc(c + Vector2(0, -s * 0.5), s * 0.75, PI * 0.15, PI * 0.85, 12, col, 2.5)
			draw_circle(c + Vector2(0, -s * 0.15), s * 0.2, col)
			draw_line(c + Vector2(-s * 0.1, s * 0.2), c + Vector2(-s * 0.3, s * 0.85), col, 2.0)
			draw_line(c + Vector2(s * 0.15, s * 0.2), c + Vector2(s * 0.5, s * 0.6), col, 2.0)
		"feather":
			draw_line(c + Vector2(0, s), c + Vector2(0, -s), col, 2.0)
			for j in 5:
				var y := -s * 0.8 + j * s * 0.35
				draw_line(c + Vector2(0, y + s * 0.1), c + Vector2(-s * 0.45, y - s * 0.1), col, 2.0)
				draw_line(c + Vector2(0, y + s * 0.1), c + Vector2(s * 0.45, y - s * 0.1), col, 2.0)
