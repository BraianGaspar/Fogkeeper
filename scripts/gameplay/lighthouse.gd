class_name Lighthouse
extends Node2D
## O farol: vida, mira e todas as fontes de luz.
## Fica sempre na origem do mundo (0, 0). A aparência vem de Keepers.

signal died
signal damaged(amount: float)

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

var aim_angle := 0.0
var target_angle := 0.0

var enemies_root: Node2D
var embers_root: Node2D
var effects_root: Node2D

var _beams: Array[Beam] = []
var _sweeper: Beam = null
var _sweeper_angle := 0.0
var _pulse_timer := 0.0
var _time := 0.0
var _hurt_flash := 0.0
var _dead := false
var _ink_t := 0.0
var _ink_range := 1.0
var _overcharge_t := 0.0
var _overcharge: Dictionary = {}


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
	aim_angle = -PI / 2.0
	target_angle = aim_angle
	_pulse_timer = 0.0
	_hurt_flash = 0.0
	_ink_t = 0.0
	_overcharge_t = 0.0
	_dead = false
	if _sweeper:
		_sweeper.queue_free()
		_sweeper = null
	rebuild_beams()


func rebuild_beams() -> void:
	for b in _beams:
		b.queue_free()
	_beams.clear()
	var beam_color: Color = Keepers.get_keeper(keeper)["beam"]
	for i in lens_count:
		var b := Beam.new()
		b.offset = TAU * i / lens_count
		b.intensity = 1.0 if i == 0 else 0.75
		b.color = beam_color
		add_child(b)
		_beams.append(b)
	if sweeper_level > 0 and _sweeper == null:
		_sweeper = Beam.new()
		_sweeper.color = Color(0.65, 0.88, 1.0)
		_sweeper.intensity = 0.7
		add_child(_sweeper)


func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	_hurt_flash = 0.25
	damaged.emit(amount)
	if hp <= 0.0:
		hp = 0.0
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


## Tinta do Kraken: encurta o alcance dos feixes por alguns segundos.
func apply_ink(seconds: float, range_factor: float) -> void:
	_ink_t = seconds
	_ink_range = range_factor


## Habilidade Sobrecarga: feixe principal concentrado e mais forte.
func start_overcharge(ability: Dictionary) -> void:
	_overcharge = ability
	_overcharge_t = ability["duration"]


func overcharged() -> bool:
	return _overcharge_t > 0.0


func inked() -> bool:
	return _ink_t > 0.0


func _process(delta: float) -> void:
	_time += delta
	_ink_t = maxf(0.0, _ink_t - delta)
	_overcharge_t = maxf(0.0, _overcharge_t - delta)
	aim_angle = wrapf(rotate_toward(aim_angle, target_angle, turn_speed * delta), -PI, PI)

	var range_mult := _ink_range if inked() else 1.0
	var enemies := enemies_root.get_children()
	var embers := embers_root.get_children()
	for i in _beams.size():
		var b := _beams[i]
		b.angle = aim_angle + b.offset
		b.range_px = beam_range * range_mult
		b.half_angle = beam_half_angle
		b.dps = beam_dps if i == 0 else beam_dps * Balance.SECONDARY_LENS_FACTOR
		b.hot = false
		if i == 0 and overcharged():
			b.range_px *= _overcharge["range"]
			b.half_angle *= _overcharge["angle"]
			b.dps *= _overcharge["dps"]
			b.hot = true
		b.apply(delta, enemies, embers)

	if _sweeper:
		var spin := Balance.SWEEPER_SPEED * (1.0 + 0.25 * (sweeper_level - 1))
		_sweeper_angle = wrapf(_sweeper_angle + spin * delta, -PI, PI)
		_sweeper.angle = _sweeper_angle
		_sweeper.range_px = beam_range * 0.6 * range_mult
		_sweeper.half_angle = beam_half_angle * 0.7
		_sweeper.dps = beam_dps * (0.35 + 0.15 * sweeper_level)
		_sweeper.apply(delta, enemies, embers)

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
	Sfx.play(&"pulse")


func _draw() -> void:
	LighthouseArt.draw(self, keeper, Vector2.ZERO, 1.0, _time, overcharged())
	if inked():
		var k := minf(1.0, _ink_t)
		for i in 5:
			var a := _time * 0.7 + i * 1.3
			draw_circle(Vector2.from_angle(a) * 26.0, 30.0 - i * 2.0, Color(0.04, 0.02, 0.07, 0.28 * k))
	if _hurt_flash > 0.0:
		draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.2, 0.1, _hurt_flash * 1.6))
