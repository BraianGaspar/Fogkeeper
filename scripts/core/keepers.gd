class_name Keepers
extends RefCounted
## Faróis selecionáveis. São só aparência (o ranking continua justo):
## cores da torre, da lanterna e do feixe. O desenho fica em LighthouseArt.

const ORDER := ["classic", "stone", "iron", "crystal"]

const LIST := {
	"classic": {"name": "Farol Clássico", "desc": "Listras vermelhas e brancas, como manda a tradição.",
		"base": Color(0.93, 0.9, 0.85), "stripe": Color(0.76, 0.16, 0.15), "roof": Color(0.16, 0.16, 0.19),
		"lamp": Color(1.0, 0.88, 0.55), "beam": Color(1.0, 0.9, 0.62), "trim": Color(0.3, 0.3, 0.33)},
	"stone": {"name": "Torre de Pedra", "desc": "Pedra antiga coberta de musgo, de antes de qualquer mapa.",
		"base": Color(0.55, 0.53, 0.5), "stripe": Color(0.32, 0.45, 0.27), "roof": Color(0.3, 0.22, 0.16),
		"lamp": Color(1.0, 0.75, 0.4), "beam": Color(1.0, 0.8, 0.5), "trim": Color(0.38, 0.36, 0.33)},
	"iron": {"name": "Farol de Ferro", "desc": "Ferro escuro e latão polido, feito para tempestades.",
		"base": Color(0.22, 0.23, 0.26), "stripe": Color(0.78, 0.6, 0.3), "roof": Color(0.12, 0.12, 0.14),
		"lamp": Color(1.0, 0.68, 0.32), "beam": Color(1.0, 0.76, 0.45), "trim": Color(0.65, 0.5, 0.25)},
	"crystal": {"name": "Farol de Cristal", "desc": "Uma lanterna de cristal que brilha em tons gelados.",
		"base": Color(0.8, 0.9, 0.98), "stripe": Color(0.35, 0.6, 0.85), "roof": Color(0.2, 0.3, 0.45),
		"lamp": Color(0.85, 0.95, 1.0), "beam": Color(0.85, 0.94, 1.0), "trim": Color(0.55, 0.75, 0.95)},
}


static func get_keeper(id: String) -> Dictionary:
	return LIST.get(id, LIST["classic"])
