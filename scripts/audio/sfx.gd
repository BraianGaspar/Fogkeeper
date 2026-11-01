class_name Sfx
extends Node
## Sons sintetizados em código (ainda não há arquivos de áudio) e os
## barramentos de volume Music, SFX e Damage (Damage passa pelo SFX).
## Main cria o nó; depois qualquer script chama Sfx.play(&"hover").
##
## A síntese roda numa thread ao iniciar, para não travar a abertura.
## Em modo headless (autoplay, CI) nada é gerado e play() não faz nada.

const RATE := 22050
const MUSIC_RATE := 16000
const VOICES := 16
const BUSES := ["Music", "SFX", "Damage"]
## Intervalo mínimo (s) entre repetições do mesmo som, para não saturar.
const THROTTLE := {&"burn": 0.05, &"ember": 0.035, &"damage": 0.14, &"hover": 0.04, &"pulse": 0.2}
const MUSIC_DB := -8.0
const SEA_DB := -14.0

static var _instance: Sfx

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last: Dictionary = {}
var _music: AudioStreamPlayer
var _sea: AudioStreamPlayer
var _task := -1
var _pending: Dictionary = {}
var _rng := RandomNumberGenerator.new() ## Só usado pela thread de síntese.
var _lp := 0.0 ## Estado do filtro de ruído durante a síntese.


static func play(id: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if _instance:
		_instance._play(id, pitch, volume_db)


static func apply_volumes() -> void:
	_ensure_buses()
	_set_bus("Master", Settings.master_volume)
	_set_bus("Music", Settings.music_volume)
	_set_bus("SFX", Settings.sfx_volume)
	_set_bus("Damage", Settings.damage_volume)


static func _ensure_buses() -> void:
	for bus_name: String in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, &"SFX" if bus_name == "Damage" else &"Master")


static func _set_bus(bus_name: String, volume: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(idx, volume <= 0)
	if volume > 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume / 100.0))


func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i in VOICES:
		var v := AudioStreamPlayer.new()
		v.bus = &"SFX"
		add_child(v)
		_voices.append(v)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)
	_sea = AudioStreamPlayer.new()
	_sea.bus = &"SFX"
	_sea.volume_db = SEA_DB
	add_child(_sea)
	if DisplayServer.get_name() != "headless":
		_task = WorkerThreadPool.add_task(_synthesize_all, false, "Sfx")


func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if _instance == self:
		_instance = null


func _process(_delta: float) -> void:
	if _task == -1 or not WorkerThreadPool.is_task_completed(_task):
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_streams = _pending
	_music.stream = _streams.get(&"music")
	_sea.stream = _streams.get(&"sea")
	_music.play()
	_sea.play()


func _play(id: StringName, pitch: float, volume_db: float) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if THROTTLE.has(id) and now - float(_last.get(id, -1.0)) < float(THROTTLE[id]):
		return
	_last[id] = now
	var v := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	v.stream = stream
	v.bus = &"Damage" if id == &"damage" else &"SFX"
	v.pitch_scale = pitch
	v.volume_db = volume_db
	v.play()


# --- Síntese (roda na thread) ---------------------------------------------

func _synthesize_all() -> void:
	_rng.seed = 5
	var s := {}
	s[&"hover"] = _render(0.06, _s_hover)
	s[&"confirm"] = _render(0.45, _s_confirm)
	s[&"back"] = _render(0.4, _s_back)
	s[&"level_up"] = _render(1.4, _s_level_up)
	s[&"announce"] = _render(1.6, _s_announce)
	s[&"victory"] = _render(3.0, _s_victory)
	s[&"defeat"] = _render(2.6, _s_defeat)
	s[&"ember"] = _render(0.09, _s_ember)
	s[&"burn"] = _render(0.16, _s_burn)
	s[&"damage"] = _render(0.25, _s_damage)
	s[&"pulse"] = _render(0.6, _s_pulse)
	s[&"thunder"] = _render(2.6, _s_thunder)
	s[&"boss"] = _render(2.6, _s_boss)
	s[&"music"] = _render_music()
	s[&"sea"] = _render_sea(_rng)
	_pending = s


func _s_hover(t: float) -> float:
	return sin(TAU * 1500.0 * t) * exp(-t * 70.0) * 0.22


func _s_confirm(t: float) -> float:
	return (_bell(t, 659.3, 7.0) + _bell(t - 0.07, 987.8, 7.0)) * 0.26


func _s_back(t: float) -> float:
	return (_bell(t, 987.8, 8.0) + _bell(t - 0.06, 659.3, 8.0)) * 0.2


func _s_level_up(t: float) -> float:
	return _arpeggio(t, [523.3, 659.3, 784.0, 1046.5], 0.08, 4.0) * 0.18


func _s_announce(t: float) -> float:
	return (_bell(t, 784.0, 3.0) + _bell(t - 0.18, 1174.7, 3.0)) * 0.16


func _s_victory(t: float) -> float:
	return _arpeggio(t, [523.3, 659.3, 784.0, 1046.5, 1318.5], 0.14, 1.8) * 0.14


func _s_defeat(t: float) -> float:
	return _arpeggio(t, [523.3, 440.0, 349.2, 261.6], 0.3, 2.2) * 0.18


func _s_ember(t: float) -> float:
	return (sin(TAU * 1760.0 * t) * exp(-t * 45.0) + sin(TAU * 2640.0 * t) * exp(-t * 60.0) * 0.3) * 0.13


func _s_burn(t: float) -> float:
	var n := _rng.randf_range(-1.0, 1.0)
	_lp += 0.25 * (n - _lp)
	return (n - _lp) * exp(-t * 26.0) * 0.16 + sin(TAU * (600.0 + 1400.0 * t) * t) * exp(-t * 30.0) * 0.05


func _s_damage(t: float) -> float:
	_lp += 0.08 * (_rng.randf_range(-1.0, 1.0) - _lp)
	return (sin(TAU * (120.0 - 150.0 * t) * t) * 0.7 + _lp * 1.6) * exp(-t * 16.0) * 0.55


func _s_pulse(t: float) -> float:
	_lp += 0.06 * (_rng.randf_range(-1.0, 1.0) - _lp)
	return (sin(TAU * (200.0 - 140.0 * t) * t) * 0.5 + _lp * 2.0) * exp(-t * 5.5) * 0.22


func _s_thunder(t: float) -> float:
	_lp += 0.035 * (_rng.randf_range(-1.0, 1.0) - _lp)
	var env := minf(1.0, t * 30.0) * exp(-t * 1.4) * (1.0 + 0.5 * sin(TAU * 6.0 * t))
	return _lp * env * 1.8


func _s_boss(t: float) -> float:
	var env := minf(1.0, t / 0.4) * minf(1.0, (2.6 - t) / 0.9)
	var f := 55.0 * (1.0 + 0.01 * sin(TAU * 5.0 * t))
	return (sin(TAU * f * t) + 0.5 * sin(TAU * 2.0 * f * t) + 0.3 * sin(TAU * 3.0 * f * t)) * env * 0.3


static func _arpeggio(t: float, notes: Array, step: float, decay: float) -> float:
	var v := 0.0
	for i in notes.size():
		v += _bell(t - i * step, notes[i], decay)
	return v


static func _bell(t: float, freq: float, decay: float) -> float:
	if t < 0.0:
		return 0.0
	var tone := sin(TAU * freq * t) + 0.35 * sin(TAU * 2.0 * freq * t) + 0.1 * sin(TAU * 3.0 * freq * t)
	return tone * exp(-t * decay) * minf(1.0, t * 300.0)


static func _render(duration: float, fn: Callable) -> AudioStreamWAV:
	var n := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var fade := 0.005 * RATE
	for i in n:
		samples[i] = float(fn.call(float(i) / RATE)) * minf(1.0, (n - i) / fade)
	return _to_wav(samples, RATE, false)


static func _to_wav(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


## Trilha ambiente em loop: acordes lentos em lá menor e sinos esparsos.
static func _render_music() -> AudioStreamWAV:
	const CHORD_LEN := 4.0
	var chords := [
		[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [130.8, 196.0, 261.6], [196.0, 246.9, 293.7],
		[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9],
	]
	var length := CHORD_LEN * chords.size()
	var n := int(length * MUSIC_RATE)

	# Timbre suave em tabela (seno + harmônicos) para poupar sin() por amostra.
	const TABLE := 1024
	var table := PackedFloat32Array()
	table.resize(TABLE)
	for i in TABLE:
		var x := TAU * i / TABLE
		table[i] = (sin(x) + 0.25 * sin(2.0 * x) + 0.08 * sin(3.0 * x)) / 1.33

	var bells: Array[Vector2] = [] # x = início, y = frequência
	var pentatonic := [440.0, 523.3, 587.3, 659.3, 784.0, 880.0]
	var brng := RandomNumberGenerator.new()
	brng.seed = 21
	var t_bell := 1.5
	while t_bell < length - 3.0:
		bells.append(Vector2(t_bell, pentatonic[brng.randi() % pentatonic.size()]))
		t_bell += brng.randf_range(1.5, 4.5)

	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / MUSIC_RATE
		var current := int(t / CHORD_LEN)
		var v := 0.0
		# Acorde atual e a cauda do anterior (com volta no loop).
		for back in 2:
			var k := posmod(current - back, chords.size())
			var local := fposmod(t - k * CHORD_LEN, length)
			var env := 0.0
			if local < 1.5:
				env = smoothstep(0.0, 1.5, local)
			elif local < CHORD_LEN:
				env = 1.0
			elif local < CHORD_LEN + 2.0:
				env = 1.0 - smoothstep(CHORD_LEN, CHORD_LEN + 2.0, local)
			if env <= 0.0:
				continue
			var notes: Array = chords[k]
			for j in notes.size():
				var f: float = notes[j]
				var trem := 1.0 + 0.15 * sin(TAU * 0.25 * t + j)
				v += table[int(fposmod(f * local, 1.0) * TABLE)] * 0.085 * env * trem
			var root: float = notes[0] * 0.5
			v += table[int(fposmod(root * local, 1.0) * TABLE)] * 0.11 * env
		for b in bells:
			var dt := t - b.x
			if dt >= 0.0 and dt < 3.0:
				v += sin(TAU * b.y * dt) * exp(-dt * 2.2) * 0.06 * minf(1.0, dt * 200.0)
		samples[i] = v
	return _to_wav(samples, MUSIC_RATE, true)


## Mar ao fundo: ruído filtrado com ondas lentas; as pontas são misturadas
## para o loop não estalar.
static func _render_sea(rng: RandomNumberGenerator) -> AudioStreamWAV:
	const LENGTH := 10.0
	const XFADE := 0.5
	var n := int(LENGTH * RATE)
	var extra := int(XFADE * RATE)
	var raw := PackedFloat32Array()
	raw.resize(n + extra)
	var lp := 0.0
	var lp2 := 0.0
	for i in n + extra:
		var t := float(i) / RATE
		lp += 0.05 * (rng.randf_range(-1.0, 1.0) - lp)
		lp2 += 0.3 * (lp - lp2)
		var swell := 0.55 + 0.45 * sin(TAU * t / 5.0)
		raw[i] = lp2 * swell * 1.6
	var samples := raw.slice(0, n)
	for i in extra:
		var k := float(i) / extra
		samples[i] = raw[n + i] * (1.0 - k) + raw[i] * k
	return _to_wav(samples, RATE, true)
