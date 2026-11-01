class_name DayCycle
extends RefCounted
## Iluminação ao longo da partida: crepúsculo, noite de lua, tempestade,
## madrugada e amanhecer. Main chama update() a cada quadro; o cenário lê
## DayCycle.p, a paleta atual.
##
## Chaves da paleta:
##   sea, wave   cor do mar e das ondas/espuma
##   land        tinta multiplicada nas cores da ilha e dos rochedos
##   fog, fog_a  cor e opacidade da névoa
##   moon        reflexo da lua no mar (0..1)
##   dusk, dawn  brilho do pôr do sol (esquerda) e do nascer do sol (direita)
##   storm       chuva e relâmpagos (0..1)
##   night       estrelas refletidas e luz do farol no chão (0..1)

## Quadros-chave em fração da partida (1.0 = amanhecer, vitória).
const KEYS := [
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

## Avisos mostrados no HUD quando a partida passa por estes pontos.
const EVENTS := [
	{"at": 0.42, "text": "Nuvens pesadas se aproximam..."},
	{"at": 0.88, "text": "O céu começa a clarear. Aguente firme!"},
]

static var time := 0.0
static var p: Dictionary = KEYS[0]


static func update(run_time: float) -> void:
	time = run_time
	p = sample(run_time / Balance.RUN_DURATION)


static func sample(f: float) -> Dictionary:
	if f <= KEYS[0]["at"]:
		return KEYS[0]
	for i in range(1, KEYS.size()):
		var b: Dictionary = KEYS[i]
		if f <= b["at"]:
			var a: Dictionary = KEYS[i - 1]
			var k := smoothstep(0.0, 1.0, (f - float(a["at"])) / (float(b["at"]) - float(a["at"])))
			var out := {}
			for key: String in b:
				out[key] = lerp(a[key], b[key], k)
			return out
	return KEYS[-1]
