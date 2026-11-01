class_name DayCycle
extends RefCounted
## Iluminação ao longo da partida, do entardecer ao amanhecer (e o dia, na
## vitória). Cada mapa tem sua paleta. Main chama update() a cada quadro; o
## cenário lê DayCycle.p, a paleta atual.
##
## Chaves da paleta:
##   sea, wave   cor do mar (ou do gelo) e das ondas/rachaduras
##   land        tinta multiplicada nas cores da ilha e das estruturas
##   fog, fog_a  cor e opacidade da névoa
##   moon        reflexo da lua (0..1)
##   dusk, dawn  brilho do pôr do sol (esquerda) e do nascer (direita)
##   storm       tempestade ou nevasca (0..1)
##   night       estrelas e luz do farol no chão (0..1)
##   aurora      aurora boreal (0..1, só no fiorde)

const NIGHT_START_HOUR := 18.0 ## A partida começa às 18:00...
const NIGHT_HOURS := 12.0 ## ...e amanhece 12 horas depois, às 06:00.

## Quadros-chave em fração da partida (1.0 = amanhecer, vitória).
const BAY_KEYS := [
	{"at": 0.0, "sea": Color(0.12, 0.08, 0.16), "wave": Color(0.75, 0.45, 0.5), "land": Color(0.85, 0.62, 0.62),
		"fog": Color(0.7, 0.45, 0.6), "fog_a": 0.8, "moon": 0.0, "dusk": 0.8, "dawn": 0.0, "storm": 0.0, "night": 0.2},
	{"at": 0.1, "sea": Color(0.045, 0.07, 0.12), "wave": Color(0.3, 0.42, 0.6), "land": Color(0.55, 0.6, 0.72),
		"fog": Color(0.55, 0.5, 0.7), "fog_a": 1.0, "moon": 0.3, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.3, "sea": Color(0.05, 0.085, 0.14), "wave": Color(0.45, 0.58, 0.75), "land": Color(0.6, 0.66, 0.78),
		"fog": Color(0.55, 0.55, 0.72), "fog_a": 1.0, "moon": 1.0, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.44, "sea": Color(0.035, 0.055, 0.09), "wave": Color(0.35, 0.45, 0.6), "land": Color(0.48, 0.52, 0.62),
		"fog": Color(0.45, 0.48, 0.6), "fog_a": 1.1, "moon": 0.4, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.5, "sea": Color(0.025, 0.04, 0.065), "wave": Color(0.4, 0.5, 0.62), "land": Color(0.42, 0.46, 0.55),
		"fog": Color(0.4, 0.44, 0.55), "fog_a": 1.25, "moon": 0.0, "dusk": 0.0, "dawn": 0.0, "storm": 1.0, "night": 1.0},
	{"at": 0.58, "sea": Color(0.025, 0.04, 0.065), "wave": Color(0.4, 0.5, 0.62), "land": Color(0.42, 0.46, 0.55),
		"fog": Color(0.4, 0.44, 0.55), "fog_a": 1.25, "moon": 0.0, "dusk": 0.0, "dawn": 0.0, "storm": 1.0, "night": 1.0},
	{"at": 0.65, "sea": Color(0.05, 0.08, 0.13), "wave": Color(0.42, 0.55, 0.72), "land": Color(0.56, 0.62, 0.74),
		"fog": Color(0.55, 0.52, 0.7), "fog_a": 1.0, "moon": 0.8, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.82, "sea": Color(0.04, 0.06, 0.12), "wave": Color(0.38, 0.45, 0.66), "land": Color(0.5, 0.52, 0.66),
		"fog": Color(0.58, 0.52, 0.72), "fog_a": 1.0, "moon": 0.4, "dusk": 0.0, "dawn": 0.05, "storm": 0.0, "night": 0.9},
	{"at": 0.92, "sea": Color(0.1, 0.11, 0.2), "wave": Color(0.62, 0.58, 0.75), "land": Color(0.68, 0.62, 0.72),
		"fog": Color(0.75, 0.62, 0.75), "fog_a": 0.85, "moon": 0.0, "dusk": 0.0, "dawn": 0.45, "storm": 0.0, "night": 0.5},
	{"at": 1.0, "sea": Color(0.22, 0.2, 0.3), "wave": Color(1.0, 0.75, 0.6), "land": Color(0.95, 0.8, 0.72),
		"fog": Color(1.0, 0.78, 0.7), "fog_a": 0.55, "moon": 0.0, "dusk": 0.0, "dawn": 1.0, "storm": 0.0, "night": 0.1},
	{"at": 1.1, "sea": Color(0.16, 0.32, 0.45), "wave": Color(1.0, 0.92, 0.78), "land": Color(1.0, 0.95, 0.88),
		"fog": Color(1.0, 0.9, 0.8), "fog_a": 0.12, "moon": 0.0, "dusk": 0.0, "dawn": 0.8, "storm": 0.0, "night": 0.0},
]

## No fiorde "sea" é o gelo; a aurora domina a noite e a tempestade é nevasca.
const FJORD_KEYS := [
	{"at": 0.0, "sea": Color(0.42, 0.36, 0.5), "wave": Color(0.95, 0.75, 0.85), "land": Color(0.95, 0.8, 0.85),
		"fog": Color(0.85, 0.7, 0.85), "fog_a": 0.7, "moon": 0.0, "dusk": 0.7, "dawn": 0.0, "storm": 0.0, "night": 0.2, "aurora": 0.0},
	{"at": 0.12, "sea": Color(0.12, 0.16, 0.26), "wave": Color(0.55, 0.7, 0.9), "land": Color(0.6, 0.68, 0.85),
		"fog": Color(0.7, 0.78, 0.92), "fog_a": 0.9, "moon": 0.4, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0, "aurora": 0.4},
	{"at": 0.3, "sea": Color(0.12, 0.2, 0.28), "wave": Color(0.5, 0.95, 0.8), "land": Color(0.6, 0.8, 0.8),
		"fog": Color(0.6, 0.85, 0.85), "fog_a": 0.9, "moon": 0.6, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0, "aurora": 1.0},
	{"at": 0.42, "sea": Color(0.11, 0.15, 0.22), "wave": Color(0.55, 0.7, 0.85), "land": Color(0.58, 0.66, 0.78),
		"fog": Color(0.75, 0.82, 0.9), "fog_a": 1.0, "moon": 0.2, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0, "aurora": 0.3},
	{"at": 0.5, "sea": Color(0.2, 0.24, 0.3), "wave": Color(0.8, 0.88, 0.95), "land": Color(0.7, 0.75, 0.82),
		"fog": Color(0.88, 0.92, 0.98), "fog_a": 1.4, "moon": 0.0, "dusk": 0.0, "dawn": 0.0, "storm": 1.0, "night": 1.0, "aurora": 0.0},
	{"at": 0.6, "sea": Color(0.2, 0.24, 0.3), "wave": Color(0.8, 0.88, 0.95), "land": Color(0.7, 0.75, 0.82),
		"fog": Color(0.88, 0.92, 0.98), "fog_a": 1.4, "moon": 0.0, "dusk": 0.0, "dawn": 0.0, "storm": 1.0, "night": 1.0, "aurora": 0.0},
	{"at": 0.68, "sea": Color(0.12, 0.17, 0.27), "wave": Color(0.6, 0.6, 0.95), "land": Color(0.6, 0.66, 0.85),
		"fog": Color(0.7, 0.72, 0.92), "fog_a": 0.95, "moon": 0.5, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0, "aurora": 0.8},
	{"at": 0.85, "sea": Color(0.14, 0.17, 0.28), "wave": Color(0.62, 0.68, 0.9), "land": Color(0.65, 0.68, 0.85),
		"fog": Color(0.78, 0.76, 0.92), "fog_a": 0.95, "moon": 0.3, "dusk": 0.0, "dawn": 0.1, "storm": 0.0, "night": 0.9, "aurora": 0.3},
	{"at": 1.0, "sea": Color(0.55, 0.5, 0.58), "wave": Color(1.0, 0.85, 0.7), "land": Color(1.0, 0.88, 0.82),
		"fog": Color(1.0, 0.85, 0.78), "fog_a": 0.5, "moon": 0.0, "dusk": 0.0, "dawn": 1.0, "storm": 0.0, "night": 0.1, "aurora": 0.0},
	{"at": 1.1, "sea": Color(0.7, 0.8, 0.88), "wave": Color(1.0, 1.0, 0.95), "land": Color(1.0, 1.0, 1.0),
		"fog": Color(1.0, 0.98, 0.95), "fog_a": 0.15, "moon": 0.0, "dusk": 0.0, "dawn": 0.7, "storm": 0.0, "night": 0.0, "aurora": 0.0},
]

## No Rio Encantado "sea" é a água barrenta; a noite é verde-escura, cheia de
## vaga-lumes, e a tempestade é um temporal de chuva tropical.
const AMAZON_KEYS := [
	{"at": 0.0, "sea": Color(0.36, 0.24, 0.12), "wave": Color(0.95, 0.65, 0.4), "land": Color(1.0, 0.75, 0.6),
		"fog": Color(0.9, 0.6, 0.45), "fog_a": 0.7, "moon": 0.0, "dusk": 0.9, "dawn": 0.0, "storm": 0.0, "night": 0.15},
	{"at": 0.1, "sea": Color(0.07, 0.12, 0.09), "wave": Color(0.35, 0.55, 0.42), "land": Color(0.55, 0.68, 0.6),
		"fog": Color(0.45, 0.6, 0.5), "fog_a": 1.0, "moon": 0.3, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.3, "sea": Color(0.06, 0.12, 0.1), "wave": Color(0.45, 0.65, 0.55), "land": Color(0.6, 0.72, 0.66),
		"fog": Color(0.5, 0.65, 0.55), "fog_a": 1.0, "moon": 1.0, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.44, "sea": Color(0.05, 0.09, 0.08), "wave": Color(0.38, 0.5, 0.45), "land": Color(0.48, 0.56, 0.52),
		"fog": Color(0.42, 0.52, 0.48), "fog_a": 1.15, "moon": 0.3, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.5, "sea": Color(0.04, 0.07, 0.07), "wave": Color(0.42, 0.52, 0.5), "land": Color(0.42, 0.5, 0.48),
		"fog": Color(0.4, 0.48, 0.46), "fog_a": 1.3, "moon": 0.0, "dusk": 0.0, "dawn": 0.0, "storm": 1.0, "night": 1.0},
	{"at": 0.58, "sea": Color(0.04, 0.07, 0.07), "wave": Color(0.42, 0.52, 0.5), "land": Color(0.42, 0.5, 0.48),
		"fog": Color(0.4, 0.48, 0.46), "fog_a": 1.3, "moon": 0.0, "dusk": 0.0, "dawn": 0.0, "storm": 1.0, "night": 1.0},
	{"at": 0.66, "sea": Color(0.06, 0.12, 0.1), "wave": Color(0.45, 0.62, 0.52), "land": Color(0.58, 0.7, 0.62),
		"fog": Color(0.5, 0.62, 0.55), "fog_a": 1.0, "moon": 0.8, "dusk": 0.0, "dawn": 0.0, "storm": 0.0, "night": 1.0},
	{"at": 0.84, "sea": Color(0.08, 0.12, 0.12), "wave": Color(0.45, 0.55, 0.6), "land": Color(0.58, 0.62, 0.66),
		"fog": Color(0.6, 0.6, 0.66), "fog_a": 0.95, "moon": 0.3, "dusk": 0.0, "dawn": 0.1, "storm": 0.0, "night": 0.9},
	{"at": 1.0, "sea": Color(0.32, 0.25, 0.2), "wave": Color(1.0, 0.78, 0.62), "land": Color(1.0, 0.85, 0.75),
		"fog": Color(1.0, 0.8, 0.7), "fog_a": 0.55, "moon": 0.0, "dusk": 0.0, "dawn": 1.0, "storm": 0.0, "night": 0.1},
	{"at": 1.1, "sea": Color(0.3, 0.34, 0.2), "wave": Color(0.95, 0.95, 0.75), "land": Color(1.0, 1.0, 0.92),
		"fog": Color(1.0, 0.95, 0.85), "fog_a": 0.12, "moon": 0.0, "dusk": 0.0, "dawn": 0.7, "storm": 0.0, "night": 0.0},
]

const PALETTES := {"bay": BAY_KEYS, "fjord": FJORD_KEYS, "amazon": AMAZON_KEYS}

## Avisos mostrados no HUD quando a partida passa por estes pontos.
const EVENTS := {
	"bay": [
		{"at": 0.42, "text": "Nuvens pesadas se aproximam..."},
		{"at": 0.88, "text": "O céu começa a clarear. Aguente firme!"},
	],
	"fjord": [
		{"at": 0.42, "text": "O vento uiva: vem aí uma nevasca..."},
		{"at": 0.88, "text": "O céu começa a clarear. Aguente firme!"},
	],
	"amazon": [
		{"at": 0.42, "text": "Trovões ecoam sobre a mata: vem aí um temporal..."},
		{"at": 0.88, "text": "O céu começa a clarear. Aguente firme!"},
	],
}

static var map := "bay"
static var time := 0.0
static var p: Dictionary = BAY_KEYS[0]


static func set_map(map_id: String) -> void:
	map = map_id if PALETTES.has(map_id) else "bay"


static func update(run_time: float) -> void:
	time = run_time
	p = sample(run_time / Balance.RUN_DURATION)


static func events() -> Array:
	return EVENTS[map]


static func sample(f: float) -> Dictionary:
	var keys: Array = PALETTES[map]
	if f <= keys[0]["at"]:
		return keys[0]
	for i in range(1, keys.size()):
		var b: Dictionary = keys[i]
		if f <= b["at"]:
			var a: Dictionary = keys[i - 1]
			var k := smoothstep(0.0, 1.0, (f - float(a["at"])) / (float(b["at"]) - float(a["at"])))
			var out := {}
			for key: String in b:
				out[key] = lerp(a.get(key, b[key]), b[key], k)
			return out
	return keys[-1]


## Hora do relógio da história: 18:00 no início, 06:00 no amanhecer.
static func clock_text(run_time: float) -> String:
	var hours := fposmod(NIGHT_START_HOUR + clampf(run_time / Balance.RUN_DURATION, 0.0, 1.0) * NIGHT_HOURS, 24.0)
	var minutes := int(hours * 60.0)
	return "%02d:%02d" % [minutes / 60, minutes % 60]


## Tempo da história que falta para o amanhecer, ex.: "3h13".
static func hours_left_text(run_time: float) -> String:
	var left := maxf(0.0, 1.0 - run_time / Balance.RUN_DURATION) * NIGHT_HOURS * 60.0
	return "%dh%02d" % [int(left) / 60, int(left) % 60]
