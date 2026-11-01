class_name Trailer
extends CanvasLayer
## Trailer roteirizado para a Steam: o bot joga cenas curtas de cada mapa
## (com chefes) enquanto legendas contam a ideia do jogo, e termina no logo.
## Grave com o Movie Maker do Godot:
##   GODOT=... FFMPEG=... tools/trailer.sh   (grava em PNG e converte para MP4)
## As legendas ficam aqui (en ou pt), fora das traduções do jogo.

## Cenas: mapa, segundos de partida simulados, chefe (índice no mapa, -1 = nenhum),
## duração e legenda.
const SHOTS := [
	{"map": "bay", "at": 140.0, "boss": -1, "time": 5.0, "en": "You are the lighthouse.", "pt": "Você é o farol."},
	{"map": "bay", "at": 230.0, "boss": 0, "time": 5.0, "en": "The light burns what hides in the fog.", "pt": "A luz queima o que se esconde na névoa."},
	{"map": "fjord", "at": 260.0, "boss": 1, "time": 5.0, "en": "Gods and monsters from five mythologies.", "pt": "Deuses e monstros de cinco mitologias."},
	{"map": "amazon", "at": 280.0, "boss": 1, "time": 5.0, "en": "Brazilian folklore. Japanese yōkai. Egyptian gods.", "pt": "Folclore brasileiro. Yōkai japoneses. Deuses do Egito."},
	{"map": "japan", "at": 300.0, "boss": 1, "time": 5.0, "en": "Every boss plays by its own rules.", "pt": "Cada chefe tem as próprias regras."},
	{"map": "egypt", "at": 320.0, "boss": 0, "time": 5.5, "en": "Collect embers. Evolve your light.", "pt": "Recolha brasas. Evolua sua luz."},
	{"map": "egypt", "at": 380.0, "boss": 1, "time": 5.0, "en": "Hold on until dawn.", "pt": "Resista até o amanhecer."},
]
const INTRO := 3.0
const OUTRO := 5.0

var main: Node
var lang := "en"

var _t := 0.0
var _shot := -1
var _shot_t := 0.0
var _started := false
var _caption: Label
var _logo: Label
var _sub: Label
var _fade: ColorRect


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_caption = UiTheme.label("", 42, UiTheme.TEXT, true)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_left = 120
	_caption.offset_right = -120
	_caption.offset_top = -250
	_caption.offset_bottom = -160
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_constant_override("outline_size", 10)
	add_child(_caption)
	_logo = UiTheme.label("FOGKEEPER", 120, UiTheme.GOLD, true)
	_logo.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_logo.grow_vertical = Control.GROW_DIRECTION_BOTH
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_theme_constant_override("outline_size", 14)
	add_child(_logo)
	_sub = UiTheme.label("", 34, UiTheme.TEXT, true)
	_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_sub.offset_top = 110
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_sub)
	_sub.text = "Wishlist now on Steam" if lang == "en" else "Adicione à lista de desejos na Steam"


func _process(delta: float) -> void:
	# Espera os sons ficarem prontos, para o vídeo já começar com música.
	if not _started:
		if not Sfx.is_ready():
			return
		_started = true
		main.trailer_title()
	_t += delta
	var total_shots := 0.0
	for s: Dictionary in SHOTS:
		total_shots += float(s["time"])
	if _t < INTRO:
		_fade.color.a = clampf(1.0 - _t, 0.0, 1.0) * 0.6 + 0.4 * clampf((_t - 2.0), 0.0, 1.0)
		_logo.modulate.a = clampf(_t - 0.3, 0.0, 1.0) * clampf(INTRO - _t, 0.0, 1.0) * 2.0
		_sub.modulate.a = 0.0
		_caption.text = ""
		return
	var local := _t - INTRO
	if local < total_shots:
		_logo.modulate.a = 0.0
		var acc := 0.0
		for i in SHOTS.size():
			var dur: float = SHOTS[i]["time"]
			if local < acc + dur:
				if i != _shot:
					_shot = i
					_shot_t = 0.0
					var s: Dictionary = SHOTS[i]
					main.trailer_shot(s["map"], s["at"], s["boss"])
				_shot_t = local - acc
				_caption.text = SHOTS[i][lang]
				_caption.modulate.a = clampf(_shot_t * 2.5, 0.0, 1.0) * clampf((dur - _shot_t) * 3.0, 0.0, 1.0)
				# Corte rápido para o preto entre as cenas.
				_fade.color.a = clampf(1.0 - _shot_t * 4.0, 0.0, 1.0) + clampf((_shot_t - dur + 0.2) * 5.0, 0.0, 1.0)
				break
			acc += dur
		return
	# Fim: logo e chamada para a lista de desejos.
	var o := local - total_shots
	if _shot != -2:
		_shot = -2
		main.trailer_title()
	_caption.text = ""
	_fade.color.a = 0.55
	_logo.modulate.a = clampf(o * 1.5, 0.0, 1.0)
	_sub.modulate.a = clampf(o - 0.8, 0.0, 1.0)
	if o >= OUTRO:
		get_tree().quit()
