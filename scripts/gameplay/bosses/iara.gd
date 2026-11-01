class_name Iara
extends Boss
## A mãe d'água. Nada em volta da ilha e, de tempos em tempos, canta: o
## canto puxa o feixe na direção dela, uma bolha d'água a protege e botos
## encantados nadam até o farol vindos de outros lados. Resista ao puxão,
## queime os botos e ataque a Iara quando o canto acabar.

var _angle := 0.0
var _sing_cd := 0.0
var _sing_t := 0.0
var _spawn_cd := 0.0


func begin(at_angle: float) -> void:
	_angle = at_angle
	position = Vector2.from_angle(_angle) * (float(data["stand"]) + 160.0)
	_sing_cd = float(data["sing_every"]) * 0.5


func singing() -> bool:
	return _sing_t > 0.0


func _move(delta: float) -> void:
	var r := rate()
	var stand: float = data["stand"]
	var d := move_toward(position.length(), stand, 90.0 * delta)
	if singing():
		_sing_t -= delta
		_spawn_cd -= delta * r
		if _spawn_cd <= 0.0:
			_spawn_cd = data["spawn_every"]
			# Botos chegam do lado oposto ao canto, longe de onde a luz é puxada.
			var a := _angle + PI + randf_range(-1.2, 1.2)
			spawn_request.emit("tentacle", Vector2.from_angle(a) * 520.0)
		if lighthouse:
			lighthouse.charm(0.2, position.angle(), float(data["pull"]) * r)
		if _sing_t <= 0.0:
			invulnerable = false
	else:
		_angle += speed * r * lit_factor() * delta
		_sing_cd -= delta * r
		if _sing_cd <= 0.0 and d <= stand + 1.0:
			_sing_cd = data["sing_every"]
			_sing_t = data["sing_time"]
			_spawn_cd = 0.3
			invulnerable = true
			Sfx.play(&"song")
	position = Vector2.from_angle(_angle) * d


func _can_melee() -> bool:
	return false


func facing() -> Vector2:
	if singing():
		return (-position).normalized()
	return Vector2.from_angle(_angle + PI / 2.0)


func _draw() -> void:
	var alpha := death_alpha()
	var lit := lit_amount()
	var r := radius
	draw_enrage_aura(r)
	# Ondulações na água em volta.
	for k in 3:
		var rr := r * 1.2 + fmod(_time * 30.0 + k * 22.0, 66.0)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color(0.6, 0.95, 0.85, 0.25 * (1.0 - rr / (r * 1.2 + 66.0)) * alpha), 2.0)
	draw_set_transform(Vector2.ZERO, facing().angle())
	var scales := CreatureArt.c(Color(0.15, 0.5, 0.4), lit, alpha)
	var fin := CreatureArt.c(Color(0.85, 0.75, 0.3), lit, alpha)
	var skin := CreatureArt.c(Color(0.72, 0.5, 0.38), lit, alpha)
	var hair := CreatureArt.c(Color(0.05, 0.12, 0.08), lit, alpha)
	var spine := CreatureArt.tail(self, -r * 0.2, r * 2.6, r * 0.55, _time * 1.3, 0.0, r * 0.6, scales, 12)
	for i in range(2, spine.size(), 2):
		draw_circle(spine[i], r * 0.08, CreatureArt.c(Color(0.5, 0.85, 0.6), lit, alpha))
	var end := spine[spine.size() - 1]
	draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.9, -r * 0.9), end + Vector2(-r * 0.45, 0)]), fin)
	draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.45, 0), end + Vector2(-r * 0.9, r * 0.9)]), fin)
	# Cabelos longos espalhados na água.
	for i in 5:
		draw_set_transform(Vector2(r * 0.3, (i - 2) * r * 0.18).rotated(facing().angle()), facing().angle())
		CreatureArt.tail(self, 0.0, r * (1.8 + 0.3 * (i % 2)), r * 0.16, _time * 1.6, i * 1.1, r * 0.5, hair, 8)
	draw_set_transform(Vector2.ZERO, facing().angle())
	draw_circle(Vector2(r * 0.05, 0), r * 0.5, skin)
	for s: float in [-1.0, 1.0]:
		var reach := r * (0.45 if singing() else 0.2)
		draw_line(Vector2(r * 0.1, s * r * 0.4), Vector2(r * 0.6 + reach, s * r * (0.75 - reach / r * 0.3)), skin, r * 0.16)
	draw_circle(Vector2(r * 0.45, 0), r * 0.36, skin)
	# Coroa de flores de vitória-régia.
	for i in 5:
		var a := -0.9 + i * 0.45 + PI
		draw_circle(Vector2(r * 0.45, 0) + Vector2.from_angle(a) * r * 0.36, r * 0.1, CreatureArt.c(Color(1.0, 0.7, 0.8), lit, alpha))
	CreatureArt.eyes(self, Vector2(r * 0.65, 0), r * 0.14, r * 0.06, Color(0.4, 1.0, 0.8), lit, alpha)
	draw_set_transform(Vector2.ZERO)
	if singing() and not dying:
		# Bolha d'água e notas do canto.
		var pulse := 0.6 + 0.4 * sin(_time * 6.0)
		draw_circle(Vector2.ZERO, r * 2.0, Color(0.4, 0.9, 1.0, 0.12 * pulse))
		draw_arc(Vector2.ZERO, r * 2.0, 0.0, TAU, 40, Color(0.7, 1.0, 1.0, 0.6 * pulse), 2.5)
		for i in 5:
			var f := fmod(_time * 0.7 + i / 5.0, 1.0)
			var p := (-position).normalized() * (r * 2.2 + f * 180.0) + Vector2(sin(_time * 3.0 + i) * 12.0, 0)
			draw_circle(p, 4.0, Color(0.6, 1.0, 0.85, 0.8 * (1.0 - f)))
			draw_line(p + Vector2(4, 0), p + Vector2(4, -12), Color(0.6, 1.0, 0.85, 0.8 * (1.0 - f)), 1.5)
