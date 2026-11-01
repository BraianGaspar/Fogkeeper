class_name Lighthouse
extends Node2D
## O farol: vida, mira e todas as fontes de luz.
## Fica sempre na origem do mundo (0, 0). A aparência vem de Keepers.

signal died
signal damaged(amount: float)
signal pulsed

var keeper := "classic"
var max_hp := 0.0
var hp := 0.0
var regen := 0.0
var beam_range := 0.0
var beam_half_angle := 0.0
var beam_dps := 0.0
var turn_speed := 0.0
var lens_count := 1
var pulse_level := 0
var sweeper_level := 0
var magnet_radius := 0.0
var lit_slow := Balance.LIT_SLOW
var hp_scale := 1.0 ## Multiplicador de vida da dificuldade.
var combustion := 0 ## Nível da melhoria Combustão.
var ember_heal := 0.0 ## Vida por brasa recolhida (Brasas vitais).
var ability_cooldown := 1.0 ## Multiplicador da recarga das habilidades.
# Evoluções.
var fresnel := false
var crown := false
var ember_tide := false

var aim_angle := 0.0
var target_angle := 0.0

var enemies_root: Node2D
var embers_root: Node2D
var effects_root: Node2D

var _beams: Array[Beam] = []
var _sweepers: Array[Beam] = []
var _sweeper_angle := 0.0
var _pulse_timer := 0.0
var _time := 0.0
var _hurt_flash := 0.0
var _dead := false
var _ink_t := 0.0
var _ink_range := 1.0
var _overcharge_t := 0.0
var _overcharge: Dictionary = {}
var _charm_t := 0.0
var _charm_angle := 0.0
var _charm_pull := 0.0
var _sleep_t := 0.0
var _sleep_power := 1.0


func _ready() -> void:
	z_index = 4


func reset() -> void:
	max_hp = Balance.LIGHTHOUSE_MAX_HP * hp_scale
	hp = max_hp
	regen = 0.0
	beam_range = Balance.BEAM_RANGE
	beam_half_angle = deg_to_rad(Balance.BEAM_HALF_ANGLE_DEG)
	beam_dps = Balance.BEAM_DPS
	turn_speed = Balance.TURN_SPEED
	lens_count = 1
	pulse_level = 0
	sweeper_level = 0
	magnet_radius = Balance.MAGNET_RADIUS
	lit_slow = Balance.LIT_SLOW
	combustion = 0
	ember_heal = 0.0
	ability_cooldown = 1.0
	fresnel = false
	crown = false
	ember_tide = false
	aim_angle = -PI / 2.0
	target_angle = aim_angle
	_pulse_timer = 0.0
	_hurt_flash = 0.0
	_ink_t = 0.0
	_overcharge_t = 0.0
	_charm_t = 0.0
	_sleep_t = 0.0
	_dead = false
	for s in _sweepers:
		s.queue_free()
	_sweepers.clear()
	rebuild_beams()


func rebuild_beams() -> void:
	for b in _beams:
		b.queue_free()
	_beams.clear()
	var beam_color: Color = Keepers.get_keeper(keeper)["beam"]
	for i in lens_count:
		var b := Beam.new()
		b.offset = TAU * i / lens_count
		b.intensity = 1.0 if i == 0 or crown else 0.75
		b.color = beam_color
		add_child(b)
		_beams.append(b)
	var arms := 0 if sweeper_level == 0 else (2 if crown else 1)
	while _sweepers.size() < arms:
		var s := Beam.new()
		s.color = Color(0.65, 0.88, 1.0)
		s.intensity = 0.7
		add_child(s)
		_sweepers.append(s)


func take_damage(amount: float, quiet: bool = false) -> void:
	if _dead:
		return
	hp -= amount
	if not quiet:
		_hurt_flash = 0.25
		damaged.emit(amount)
	if hp <= 0.0:
		hp = 0.0
		_dead = true
		died.emit()


## Tutorial: o farol volta com a vida cheia em vez de a partida acabar.
func revive() -> void:
	_dead = false
	hp = max_hp


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


## Tinta do Kraken: encurta o alcance dos feixes por alguns segundos.
func apply_ink(seconds: float, range_factor: float) -> void:
	_ink_t = seconds
	_ink_range = range_factor


## Canto da Iara: puxa a mira na direção dela enquanto dura.
func charm(seconds: float, toward: float, pull: float) -> void:
	_charm_t = seconds
	_charm_angle = toward
	_charm_pull = pull


## Feitiço da Cuca: a luz adormece e perde força por alguns segundos.
func sleep(seconds: float, power: float) -> void:
	_sleep_t = seconds
	_sleep_power = power


## Habilidade Sobrecarga: feixe principal concentrado e mais forte.
func start_overcharge(ability: Dictionary) -> void:
	_overcharge = ability
	_overcharge_t = ability["duration"]


func overcharged() -> bool:
	return _overcharge_t > 0.0


func inked() -> bool:
	return _ink_t > 0.0


func charmed() -> bool:
	return _charm_t > 0.0


func asleep() -> bool:
	return _sleep_t > 0.0


func _process(delta: float) -> void:
	_time += delta
	_ink_t = maxf(0.0, _ink_t - delta)
	_overcharge_t = maxf(0.0, _overcharge_t - delta)
	_charm_t = maxf(0.0, _charm_t - delta)
	_sleep_t = maxf(0.0, _sleep_t - delta)
	aim_angle = wrapf(rotate_toward(aim_angle, target_angle, turn_speed * delta), -PI, PI)
	if charmed():
		aim_angle = wrapf(rotate_toward(aim_angle, _charm_angle, _charm_pull * delta), -PI, PI)

	var range_mult := _ink_range if inked() else 1.0
	var power := _sleep_power if asleep() else 1.0
	var enemies := enemies_root.get_children()
	var embers := embers_root.get_children()
	for i in _beams.size():
		var b := _beams[i]
		b.angle = aim_angle + b.offset
		b.range_px = beam_range * range_mult
		b.half_angle = beam_half_angle
		b.dps = (beam_dps if i == 0 or crown else beam_dps * Balance.SECONDARY_LENS_FACTOR) * power
		b.hot = i == 0 and fresnel
		b.dim = asleep()
		b.reflects = i == 0
		if i == 0 and overcharged():
			b.range_px *= _overcharge["range"]
			b.half_angle *= _overcharge["angle"]
			b.dps *= _overcharge["dps"]
			b.hot = true
		b.apply(delta, enemies, embers)

	if not _sweepers.is_empty():
		var spin := Balance.SWEEPER_SPEED * (1.0 + 0.25 * (sweeper_level - 1))
		_sweeper_angle = wrapf(_sweeper_angle + spin * delta, -PI, PI)
		for i in _sweepers.size():
			var s := _sweepers[i]
			s.angle = _sweeper_angle + PI * i
			s.range_px = beam_range * 0.6 * range_mult
			s.half_angle = beam_half_angle * 0.7
			s.dps = beam_dps * (0.35 + 0.15 * sweeper_level) * power
			s.dim = asleep()
			s.apply(delta, enemies, embers)

	if regen > 0.0 and not _dead:
		heal(regen * delta)

	if pulse_level > 0:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = Balance.pulse_cooldown(pulse_level)
			_fire_pulse()

	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	queue_redraw()


func _fire_pulse() -> void:
	var w := PulseWave.new()
	w.max_radius = Balance.PULSE_RADIUS + 30.0 * pulse_level
	w.damage = Balance.PULSE_DAMAGE * (1.0 + 0.4 * (pulse_level - 1)) * (beam_dps / Balance.BEAM_DPS)
	w.enemies_root = enemies_root
	effects_root.add_child(w)
	if ember_tide:
		for node in embers_root.get_children():
			var m := node as Ember
			if m:
				m.attract()
	Sfx.play(&"pulse")
	pulsed.emit()


func _draw() -> void:
	LighthouseArt.draw(self, keeper, Vector2.ZERO, 1.0, _time, overcharged() or fresnel)
	if inked():
		var k := minf(1.0, _ink_t)
		for i in 5:
			var a := _time * 0.7 + i * 1.3
			draw_circle(Vector2.from_angle(a) * 26.0, 30.0 - i * 2.0, Color(0.04, 0.02, 0.07, 0.28 * k))
	if charmed():
		# Notas do canto da Iara girando em volta da lanterna.
		for i in 4:
			var a := _time * 2.0 + i * TAU / 4.0
			var p := Vector2.from_angle(a) * 34.0
			draw_circle(p, 3.5, Color(0.5, 1.0, 0.85, 0.85))
			draw_line(p + Vector2(3, 0), p + Vector2(3, -10), Color(0.5, 1.0, 0.85, 0.85), 1.5)
	if asleep():
		var k := minf(1.0, _sleep_t)
		draw_circle(Vector2.ZERO, 40.0, Color(0.45, 0.25, 0.7, 0.18 * k))
		for i in 3:
			var f := fmod(_time * 0.6 + i / 3.0, 1.0)
			UiTheme.draw_text(self, "z", Vector2(18.0 + f * 22.0, -26.0 - f * 30.0), 14 + i * 3, Color(0.8, 0.65, 1.0, k * (1.0 - f)))
	if _hurt_flash > 0.0:
		draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.2, 0.1, _hurt_flash * 1.6))
