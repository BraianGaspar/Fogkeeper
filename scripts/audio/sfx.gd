class_name Sfx
extends Node
## Sons sintetizados em código (ainda não há arquivos de áudio), os
## barramentos de volume Music, SFX e Damage (Damage passa pelo SFX) e a
## trilha dinâmica: calma (uma por mapa), tensão antes de um chefe e batalha.
## Main cria o nó; depois qualquer script chama Sfx.play(&"hover") e
## Sfx.music(&"boss").
##
## A síntese roda numa thread ao iniciar, para não travar a abertura.
## Em modo headless (autoplay, CI) nada é gerado e play() não faz nada.

const RATE := 22050
const MUSIC_RATE := 16000
const VOICES := 16
const BUSES := ["Music", "SFX", "Damage"]
## Intervalo mínimo (s) entre repetições do mesmo som, para não saturar.
const THROTTLE := {&"steal": 0.15, &"burn": 0.05, &"ember": 0.035, &"damage": 0.14, &"hover": 0.04, &"pulse": 0.2, &"denied": 0.2}
const MUSIC_DB := -8.0
const SILENT_DB := -60.0
const SEA_DB := -14.0
const FADE := 2.5 ## Segundos de transição entre trilhas.

## Grupos que o jogador pode ligar e desligar nas configurações.
const GROUPS := ["ui", "creatures", "embers", "damage", "abilities", "bosses", "weather", "alerts", "ambience"]
const GROUP_NAMES := {
	"ui": "Interface e menus", "creatures": "Criaturas queimando", "embers": "Brasas coletadas",
	"damage": "Dano no farol", "abilities": "Habilidades e pulso", "bosses": "Chefes",
	"weather": "Trovões", "alerts": "Avisos", "ambience": "Mar e vento",
}
const SOUND_GROUP := {
	&"hover": "ui", &"confirm": "ui", &"back": "ui", &"level_up": "ui", &"victory": "ui", &"defeat": "ui", &"denied": "ui",
	&"burn": "creatures", &"ember": "embers", &"damage": "damage",
	&"pulse": "abilities", &"flash": "abilities", &"overcharge": "abilities", &"bell": "abilities",
	&"burn_big": "creatures", &"steal": "creatures",
	&"boss": "bosses", &"splash": "bosses", &"ink": "bosses", &"throw": "bosses", &"growl": "bosses", &"roar": "bosses", &"relic": "bosses",
	&"song": "bosses", &"ignite": "bosses", &"spell": "bosses", &"achievement": "alerts",
	&"thunder": "weather", &"announce": "alerts", &"warning": "alerts",
}

static var _instance: Sfx

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last: Dictionary = {}
var _tracks: Dictionary = {} # &"calm", &"tension", &"boss" -> AudioStreamPlayer
var _sea: AudioStreamPlayer
var _music_state := &"calm"
var _map := "bay"
var _fades: Dictionary = {}
var _task := -1
var _pending: Dictionary = {}
var _rng := RandomNumberGenerator.new() ## Só usado pela thread de síntese.
var _lp := 0.0 ## Estado do filtro de ruído durante a síntese.


static func play(id: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if _instance:
		_instance._play(id, pitch, volume_db)


## Troca a trilha com transição suave: &"calm", &"tension", &"boss" ou &"none".
static func music(state: StringName) -> void:
	if _instance and _instance._music_state != state:
		_instance._music_state = state
		_instance._apply_music()


## Escolhe a trilha calma do mapa.
static func set_map(map_id: String) -> void:
	if _instance and _instance._map != map_id:
		_instance._map = map_id
		_instance._set_calm_stream()


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
	for state: StringName in [&"calm", &"tension", &"boss"]:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = SILENT_DB
		add_child(p)
		_tracks[state] = p
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
	_sea.volume_db = SEA_DB if Settings.sound_enabled("ambience") else SILENT_DB
	if _task == -1 or not WorkerThreadPool.is_task_completed(_task):
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_streams = _pending
	_set_calm_stream()
	_tracks[&"tension"].stream = _streams.get(&"music_tension")
	_tracks[&"boss"].stream = _streams.get(&"music_boss")
	for p: AudioStreamPlayer in _tracks.values():
		if not p.playing and p.stream:
			p.play()
	_sea.stream = _streams.get(&"sea")
	_sea.play()
	_apply_music()


func _set_calm_stream() -> void:
	var calm: AudioStreamPlayer = _tracks[&"calm"]
	var stream: AudioStream = _streams.get(StringName("music_" + _map), _streams.get(&"music_bay"))
	if stream and calm.stream != stream:
		calm.stream = stream
		calm.play()


func _apply_music() -> void:
	for state: StringName in _tracks:
		var p: AudioStreamPlayer = _tracks[state]
		var target := MUSIC_DB if state == _music_state else SILENT_DB
		if state == &"boss" and _music_state == &"boss":
			target = MUSIC_DB + 2.0
		if _fades.has(state):
			(_fades[state] as Tween).kill()
		var tw := create_tween()
		tw.tween_property(p, "volume_db", target, FADE).set_trans(Tween.TRANS_SINE)
		_fades[state] = tw


func _play(id: StringName, pitch: float, volume_db: float) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null or not Settings.sound_enabled(SOUND_GROUP.get(id, "ui")):
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
	s[&"warning"] = _render(2.4, _s_warning)
	s[&"splash"] = _render(0.8, _s_splash)
	s[&"ink"] = _render(0.7, _s_ink)
	s[&"throw"] = _render(0.5, _s_throw)
	s[&"growl"] = _render(1.2, _s_growl)
	s[&"roar"] = _render(1.8, _s_roar)
	s[&"relic"] = _render(1.8, _s_relic)
	s[&"denied"] = _render(0.15, _s_denied)
	s[&"flash"] = _render(1.0, _s_flash)
	s[&"overcharge"] = _render(0.9, _s_overcharge)
	s[&"bell"] = _render(2.8, _s_bell)
	s[&"steal"] = _render(0.3, _s_steal)
	s[&"song"] = _render(3.6, _s_song)
	s[&"ignite"] = _render(1.0, _s_ignite)
	s[&"spell"] = _render(1.6, _s_spell)
	s[&"achievement"] = _render(1.6, _s_achievement)
	s[&"burn_big"] = _render(0.5, _s_burn_big)
	s[&"sea"] = _render_sea(_rng)
	s[&"music_bay"] = _render_music(
		[[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [130.8, 196.0, 261.6], [196.0, 246.9, 293.7],
		[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]],
		[440.0, 523.3, 587.3, 659.3, 784.0, 880.0], 21, 2.2)
	s[&"music_fjord"] = _render_music(
		[[146.8, 174.6, 220.0], [116.5, 146.8, 174.6], [174.6, 220.0, 261.6], [130.8, 196.0, 261.6],
		[146.8, 174.6, 220.0], [196.0, 233.1, 293.7], [220.0, 277.2, 329.6], [146.8, 174.6, 220.0]],
		[587.3, 698.5, 784.0, 880.0, 1046.5, 1174.7], 33, 1.2)
	s[&"music_amazon"] = _render_music(
		[[146.8, 185.0, 220.0], [130.8, 164.8, 196.0], [174.6, 220.0, 261.6], [146.8, 185.0, 220.0],
		[196.0, 246.9, 293.7], [130.8, 164.8, 196.0], [164.8, 207.7, 246.9], [146.8, 185.0, 220.0]],
		[587.3, 659.3, 740.0, 880.0, 987.8, 1174.7], 47, 3.0)
	s[&"music_tension"] = _render_tension()
	s[&"music_boss"] = _render_boss_music()
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


## Trilha calma em loop: acordes lentos e sinos esparsos (uma por mapa).
static func _render_music(chords: Array, pentatonic: Array, bell_seed: int, bell_decay: float) -> AudioStreamWAV:
	const CHORD_LEN := 4.0
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
	var brng := RandomNumberGenerator.new()
	brng.seed = bell_seed
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
				v += sin(TAU * b.y * dt) * exp(-dt * bell_decay) * 0.06 * minf(1.0, dt * 200.0)
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


# --- Chefes, habilidades e avisos -------------------------------------------

## Trompa grave de duas notas: um chefe se aproxima.
func _s_warning(t: float) -> float:
	var f := 110.0 if t < 1.0 else 146.8
	var local := t if t < 1.0 else t - 1.0
	var env := minf(1.0, local / 0.15) * exp(-local * 1.2)
	return (sin(TAU * f * t) + 0.6 * sin(TAU * 2.0 * f * t) + 0.35 * sin(TAU * 3.0 * f * t) + 0.2 * sin(TAU * 4.0 * f * t)) * env * 0.22


func _s_splash(t: float) -> float:
	_lp += 0.12 * (_rng.randf_range(-1.0, 1.0) - _lp)
	return (_lp * 2.2 * exp(-t * 5.0) + sin(TAU * (300.0 + 200.0 * sin(t * 30.0)) * t) * exp(-t * 8.0) * 0.15) * 0.5


func _s_ink(t: float) -> float:
	_lp += 0.04 * (_rng.randf_range(-1.0, 1.0) - _lp)
	return (_lp * 3.0 * (0.6 + 0.4 * sin(TAU * 14.0 * t)) + sin(TAU * (90.0 - 40.0 * t) * t) * 0.3) * exp(-t * 4.0) * 0.45


func _s_throw(t: float) -> float:
	_lp += 0.2 * (_rng.randf_range(-1.0, 1.0) - _lp)
	var env := sin(PI * clampf(t / 0.5, 0.0, 1.0))
	return _lp * env * 0.5


func _s_growl(t: float) -> float:
	_lp += 0.05 * (_rng.randf_range(-1.0, 1.0) - _lp)
	var f := 70.0 + 10.0 * sin(TAU * 3.0 * t)
	var env := minf(1.0, t / 0.2) * minf(1.0, (1.2 - t) / 0.4)
	return (sin(TAU * f * t) * (1.0 + _lp * 2.0) + 0.4 * sin(TAU * 2.0 * f * t)) * env * 0.3


func _s_roar(t: float) -> float:
	_lp += 0.08 * (_rng.randf_range(-1.0, 1.0) - _lp)
	var f := 55.0 + 25.0 * exp(-t * 2.0)
	var env := minf(1.0, t / 0.1) * minf(1.0, (1.8 - t) / 0.6)
	return (sin(TAU * f * t) + 0.5 * sin(TAU * 1.5 * f * t) + _lp * 2.5) * env * 0.28


func _s_relic(t: float) -> float:
	return _arpeggio(t, [784.0, 987.8, 1174.7, 1568.0, 1975.5], 0.09, 2.5) * 0.14


func _s_denied(t: float) -> float:
	return (sin(TAU * 140.0 * t) + 0.5 * sin(TAU * 210.0 * t)) * exp(-t * 18.0) * 0.25


func _s_flash(t: float) -> float:
	_lp += 0.5 * (_rng.randf_range(-1.0, 1.0) - _lp)
	return (_arpeggio(t, [1046.5, 1318.5, 1568.0], 0.0, 3.0) * 0.15 + _lp * exp(-t * 7.0) * 0.25)


func _s_overcharge(t: float) -> float:
	var f := 300.0 + 700.0 * minf(1.0, t / 0.6)
	return sin(TAU * f * t) * (0.6 + 0.4 * sin(TAU * 18.0 * t)) * minf(1.0, t * 20.0) * minf(1.0, (0.9 - t) * 5.0) * 0.18


## Sino grande com parciais inarmônicos, como um sino de bronze.
func _s_bell(t: float) -> float:
	var f := 261.6
	var v := sin(TAU * f * t) + 0.6 * sin(TAU * f * 2.76 * t) * exp(-t * 1.5) + 0.3 * sin(TAU * f * 5.4 * t) * exp(-t * 3.0)
	return v * exp(-t * 1.1) * minf(1.0, t * 300.0) * 0.22


# --- Trilhas de tensão e batalha -------------------------------------------

## Antes do chefe: zumbido grave crescente e batidas de coração.
static func _render_tension() -> AudioStreamWAV:
	const LENGTH := 12.0
	var n := int(LENGTH * MUSIC_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / MUSIC_RATE
		var swell := 0.6 + 0.4 * sin(TAU * t / LENGTH)
		var v := (sin(TAU * 73.4 * t) + 0.5 * sin(TAU * 110.0 * t) + 0.25 * sin(TAU * 146.8 * t)) * 0.12 * swell
		v += (sin(TAU * 1174.7 * t) + sin(TAU * 1244.5 * t)) * 0.012 * swell
		var beat := fmod(t, 1.2)
		for hit: float in [0.0, 0.22]:
			var dt := beat - hit
			if dt >= 0.0 and dt < 0.2:
				v += sin(TAU * (60.0 - 80.0 * dt) * dt) * exp(-dt * 25.0) * 0.45
		samples[i] = v
	return _to_wav(samples, MUSIC_RATE, true)


## Batalha contra chefe: bumbo, caixa, chimbal, baixo em ostinato e acordes
## de metais em lá menor, a 132 batidas por minuto.
static func _render_boss_music() -> AudioStreamWAV:
	const BPM := 132.0
	const BARS := 12
	var beat := 60.0 / BPM
	var length := beat * 4.0 * BARS
	var n := int(length * MUSIC_RATE)
	const TABLE := 1024
	var bright := PackedFloat32Array()
	bright.resize(TABLE)
	for i in TABLE:
		var x := TAU * i / TABLE
		var v := 0.0
		for h in range(1, 8):
			v += sin(h * x) / h
		bright[i] = v * 0.55
	var bass := [55.0, 55.0, 65.4, 55.0, 82.4, 55.0, 49.0, 55.0]
	var chords := [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / MUSIC_RATE
		var b := t / beat
		var in_beat := fmod(t, beat)
		var eighth := fmod(t, beat * 0.5)
		var bar := int(b / 4.0)
		var v := 0.0
		# Bumbo em todo tempo; caixa no 2 e no 4; chimbal nas colcheias.
		v += sin(TAU * (55.0 + 90.0 * exp(-in_beat * 30.0)) * in_beat) * exp(-in_beat * 14.0) * 0.5
		var noise := rng.randf_range(-1.0, 1.0)
		if int(b) % 2 == 1:
			v += noise * exp(-in_beat * 20.0) * 0.22
		v += noise * exp(-eighth * 90.0) * 0.06
		# Baixo em colcheias.
		var bf: float = bass[int(b * 2.0) % bass.size()]
		v += bright[int(fposmod(bf * t, 1.0) * TABLE)] * 0.16 * exp(-eighth * 5.0)
		# Metais: acorde a cada 3 compassos, com ataque no início.
		var chord: Array = chords[(bar / 3) % chords.size()]
		var since := fmod(t, beat * 12.0)
		var env := minf(1.0, since * 8.0) * (0.55 + 0.45 * exp(-since * 1.5))
		for f: float in chord:
			v += bright[int(fposmod(f * t, 1.0) * TABLE)] * 0.05 * env
		samples[i] = v
	return _to_wav(samples, MUSIC_RATE, true)


# --- Rio Encantado, criaturas especiais e conquistas ----------------------------

## Assobio curto e ladino: uma ladra levou uma brasa.
func _s_steal(t: float) -> float:
	var f := 1400.0 + 900.0 * sin(PI * clampf(t / 0.3, 0.0, 1.0))
	return sin(TAU * f * t) * minf(1.0, t * 60.0) * minf(1.0, (0.3 - t) * 20.0) * 0.12


## Canto da Iara: melodia aguda e ondulante, com eco.
func _s_song(t: float) -> float:
	var notes := [880.0, 987.8, 1174.7, 987.8, 1318.5, 1174.7]
	var i := mini(int(t / 0.6), notes.size() - 1)
	var local := t - i * 0.6
	var f: float = notes[i] * (1.0 + 0.012 * sin(TAU * 6.0 * t))
	var env := minf(1.0, local / 0.12) * (0.7 + 0.3 * exp(-local * 3.0)) * minf(1.0, (3.6 - t) / 0.8)
	var v := sin(TAU * f * t) + 0.3 * sin(TAU * 2.0 * f * t)
	return (v * env + 0.35 * sin(TAU * f * maxf(0.0, t - 0.25)) * env) * 0.09


## Chama que reacende com um sopro.
func _s_ignite(t: float) -> float:
	_lp += 0.3 * (_rng.randf_range(-1.0, 1.0) - _lp)
	var env := minf(1.0, t / 0.15) * exp(-t * 3.0)
	return (_lp * 1.6 + sin(TAU * (80.0 + 60.0 * t) * t) * 0.4) * env * 0.45


## Feitiço de sono: acorde descendente e misterioso.
func _s_spell(t: float) -> float:
	var f := 520.0 * pow(0.5, t / 1.6)
	var env := minf(1.0, t * 10.0) * minf(1.0, (1.6 - t) * 2.0)
	return (sin(TAU * f * t) + sin(TAU * f * 1.26 * t) * 0.6 + sin(TAU * f * 1.5 * t) * 0.4) * (0.7 + 0.3 * sin(TAU * 7.0 * t)) * env * 0.12


func _s_achievement(t: float) -> float:
	return _arpeggio(t, [659.3, 880.0, 1108.7, 1318.5], 0.07, 2.6) * 0.15


## Queima forte (elites e criaturas grandes): estalo grave com chiado.
func _s_burn_big(t: float) -> float:
	_lp += 0.15 * (_rng.randf_range(-1.0, 1.0) - _lp)
	return (_lp * 1.4 * exp(-t * 9.0) + sin(TAU * (160.0 - 120.0 * t) * t) * exp(-t * 10.0) * 0.6) * 0.4
