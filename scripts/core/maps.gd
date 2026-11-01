class_name Maps
extends RefCounted
## Mapas jogáveis: nome, história, criaturas de cada papel e chefes.
## As estatísticas vêm de Balance (por papel); aqui ficam identidade e enredo.
## Para criar um mapa: entrada em LIST, paleta em DayCycle.PALETTES, cenário em
## scripts/world/ (classe com o mesmo `scenery`), arte das criaturas em
## CreatureArt e textos em I18n.

const ORDER := ["bay", "fjord"]

const LIST := {
	"bay": {
		"name": "Baía da Névoa",
		"tagline": "Mar aberto, naufrágios e a serpente das profundezas.",
		"story": "Você aceitou cuidar do velho farol da Baía da Névoa depois que o último faroleiro desapareceu sem deixar rastro. Na primeira noite, a névoa subiu do mar trazendo vozes, cantos de sereia e algo enorme se movendo sob as ondas. Os navios da costa dependem da sua luz até o amanhecer.",
		"scenery": "bay",
		"creatures": {"basic": "wraith", "fast": "siren", "brute": "crab", "tentacle": "tentacle", "boulder": "boulder"},
		"bosses": ["leviathan", "kraken"],
	},
	"fjord": {
		"name": "Fiorde Congelado",
		"tagline": "Gelo eterno, aurora no céu e lobos que caçam na nevasca.",
		"story": "Um navio de suprimentos ficou preso no gelo do fiorde, e o farol abandonado da ilha é a única luz que pode guiá-lo. Você atravessou o gelo a pé para reacendê-lo. As lendas dizem que os mortos do naufrágio antigo ainda andam, e que gigantes e o grande lobo despertam quando a nevasca chega.",
		"scenery": "fjord",
		"creatures": {"basic": "draugr", "fast": "ice_wolf", "brute": "troll", "tentacle": "tentacle", "boulder": "boulder"},
		"bosses": ["jotunn", "fenrir"],
	},
}

## Nome visível de cada criatura (arte), traduzido via I18n.
const CREATURE_NAMES := {
	"wraith": "Espectro da névoa", "siren": "Sereia", "crab": "Caranguejo de Karkinos",
	"draugr": "Draugr", "ice_wolf": "Lobo de gelo", "troll": "Troll de gelo",
	"tentacle": "Tentáculo", "boulder": "Pedra de gelo",
	"leviathan": "Leviatã", "kraken": "Kraken", "jotunn": "Jötunn", "fenrir": "Fenrir",
}

## Subtítulo dos chefes na barra de vida.
const BOSS_TITLES := {
	"leviathan": "Serpente das profundezas", "kraken": "Terror dos abismos",
	"jotunn": "Gigante do gelo", "fenrir": "O lobo do fim do mundo",
}


static func get_map(id: String) -> Dictionary:
	return LIST.get(id, LIST["bay"])


## Chefe que aparece em cada horário de Balance.BOSS_TIMES (e o extra).
static func boss_at(map_id: String, index: int) -> String:
	var bosses: Array = get_map(map_id)["bosses"]
	return bosses[index % bosses.size()]
