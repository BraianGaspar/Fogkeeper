class_name Maps
extends RefCounted
## Mapas jogáveis: nome, história, criaturas de cada papel e chefes.
## As estatísticas vêm de Balance (por papel); aqui ficam identidade e enredo.
## Para criar um mapa: entrada em LIST, paleta em DayCycle.PALETTES, cenário em
## scripts/world/ (classe com o mesmo `scenery`), arte das criaturas em
## CreatureArt e textos em I18n.

const ORDER := ["bay", "fjord", "amazon", "japan", "egypt", "greece", "celtic"]

const LIST := {
	"bay": {
		"name": "Baía da Névoa",
		"tagline": "Mar aberto, naufrágios e a serpente das profundezas.",
		"story": "Você aceitou cuidar do velho farol da Baía da Névoa depois que o último faroleiro desapareceu sem deixar rastro. Na primeira noite, a névoa subiu do mar trazendo vozes, cantos de sereia e algo enorme se movendo sob as ondas. Os navios da costa dependem da sua luz até o amanhecer.",
		"scenery": "bay",
		"creatures": {"basic": "wraith", "fast": "siren", "brute": "crab", "thief": "ghost_gull", "mirror": "oyster",
			"moth": "jellyfish", "fogbank": "fog_bay", "tentacle": "tentacle", "boulder": "boulder"},
		"bosses": ["leviathan", "kraken"],
	},
	"fjord": {
		"name": "Fiorde Congelado",
		"tagline": "Gelo eterno, aurora no céu e lobos que caçam na nevasca.",
		"story": "Um navio de suprimentos ficou preso no gelo do fiorde, e o farol abandonado da ilha é a única luz que pode guiá-lo. Você atravessou o gelo a pé para reacendê-lo. As lendas dizem que os mortos do naufrágio antigo ainda andam, e que gigantes e o grande lobo despertam quando a nevasca chega.",
		"scenery": "fjord",
		"creatures": {"basic": "draugr", "fast": "ice_wolf", "brute": "troll", "thief": "raven", "mirror": "ice_shell",
			"moth": "frost_moth", "fogbank": "fog_fjord", "tentacle": "tentacle", "boulder": "boulder"},
		"bosses": ["jotunn", "fenrir"],
	},
	"amazon": {
		"name": "Rio Encantado",
		"tagline": "Igarapés, mata fechada e as lendas que acordam quando a luz se acende.",
		"story": "O barco do correio afundou no encontro das águas, e o velho farol da ilhota no meio do rio é a única luz que pode guiar os ribeirinhos de volta. Você remou até ele ao pôr do sol. Na margem, avisaram: quem acende uma luz na mata desperta o canto da Iara, a cobra de fogo e a velha Cuca. E o Saci adora roubar o que brilha.",
		"scenery": "river",
		"creatures": {"basic": "corpo_seco", "fast": "curupira", "brute": "mapinguari", "thief": "saci", "mirror": "jabuti",
			"moth": "mula", "fogbank": "fog_amazon", "tentacle": "boto", "boulder": "wisp"},
		"bosses": ["iara", "boitata", "cuca"],
	},
	"japan": {
		"name": "Mar dos Yōkai",
		"tagline": "Lanternas no mar, portões torii e yōkai que sobem das ondas.",
		"story": "Você assumiu o farol diante de uma vila de pescadores na noite do Obon, quando as famílias soltam lanternas no mar para guiar os mortos de volta. Os mais velhos avisaram: nessa noite os yōkai sobem das águas, o monge do mar pede um balde para afundar os barcos e uma raposa de nove caudas engana quem se perde na névoa.",
		"scenery": "japan",
		"creatures": {"basic": "funayurei", "fast": "kitsune", "brute": "oni", "thief": "tengu", "mirror": "kappa",
			"moth": "chochin", "fogbank": "fog_japan", "tentacle": "hitodama", "boulder": "wave", "decoy": "kyubi"},
		"bosses": ["umibozu", "kyubi"],
	},
	"egypt": {
		"name": "Farol de Alexandria",
		"tagline": "Ruínas de Faros, dunas e a serpente que tenta engolir o sol.",
		"story": "Dizem que o primeiro farol do mundo ficava aqui, na ilha de Faros. Você reacendeu a chama sobre as ruínas para guiar os barcos que descem o Nilo à noite. Mas a luz acordou o que dormia sob as areias: múmias, os chacais de Anúbis, a Esfinge e seus enigmas, e Apep, a serpente que toda noite tenta engolir o sol.",
		"scenery": "desert",
		"creatures": {"basic": "mummy", "fast": "jackal", "brute": "sobek", "thief": "ibis", "mirror": "scarab",
			"moth": "ba", "fogbank": "fog_egypt", "tentacle": "cobra", "boulder": "sandstone"},
		"bosses": ["sphinx", "apep"],
	},
	"greece": {
		"name": "Mar Egeu",
		"tagline": "Ilhas de mármore, templos em ruínas e monstros que nenhum herói venceu.",
		"story": "Um velho pescador de Ítaca pediu que alguém acendesse o farol do estreito, onde os navios somem entre dois rochedos. Você chegou de barco ao entardecer, passando por colunas de templos meio afundadas. Ninguém avisou que, à noite, as sombras sobem do Hades, as harpias descem dos penhascos e Cila acorda na sua caverna.",
		"scenery": "greece",
		"creatures": {"basic": "shade", "fast": "hellhound", "brute": "minotaur", "thief": "harpy", "mirror": "bronze_shield",
			"moth": "lampad", "fogbank": "fog_greece", "tentacle": "gorgon_snake", "boulder": "marble"},
		"bosses": ["scylla", "medusa"],
	},
	"celtic": {
		"name": "Costa Celta",
		"tagline": "Penhascos verdes, círculos de pedra e a noite em que o Outro Mundo se abre.",
		"story": "Você veio cuidar do farol de uma ilha das Hébridas na noite de Samhain, quando o véu entre os mundos fica fino. Os moradores trancaram as portas, deixaram comida para as fadas e pediram que a luz não se apagasse: dizem que o olho de Balor se abre no mar e que a velha do inverno caminha sobre as ondas.",
		"scenery": "celtic",
		"creatures": {"basic": "banshee", "fast": "kelpie", "brute": "fomorian", "thief": "pooka", "mirror": "selkie",
			"moth": "fairy", "fogbank": "fog_celtic", "tentacle": "peist", "boulder": "ogham"},
		"bosses": ["balor", "cailleach"],
	},
}

## Nome visível de cada criatura (arte), traduzido via I18n.
const CREATURE_NAMES := {
	"wraith": "Espectro da névoa", "siren": "Sereia", "crab": "Caranguejo de Karkinos",
	"ghost_gull": "Gaivota-fantasma", "oyster": "Ostra abissal", "jellyfish": "Água-viva luminosa", "fog_bay": "Névoa devoradora",
	"draugr": "Draugr", "ice_wolf": "Lobo de gelo", "troll": "Troll de gelo",
	"raven": "Corvo de Odin", "ice_shell": "Escudo de gelo", "frost_moth": "Mariposa de geada", "fog_fjord": "Névoa de Niflheim",
	"corpo_seco": "Corpo-seco", "curupira": "Curupira", "mapinguari": "Mapinguari",
	"saci": "Saci", "jabuti": "Jabuti encantado", "mula": "Mula sem cabeça", "fog_amazon": "Névoa da Matinta",
	"boto": "Boto encantado", "wisp": "Fogo-fátuo",
	"funayurei": "Funayūrei", "kitsune": "Kitsune", "oni": "Oni", "tengu": "Karasu-tengu", "kappa": "Kappa",
	"chochin": "Chōchin-obake", "fog_japan": "Névoa dos afogados", "hitodama": "Hitodama", "wave": "Onda", "kyubi": "Kyūbi",
	"mummy": "Múmia", "jackal": "Chacal de Anúbis", "sobek": "Crocodilo de Sobek", "ibis": "Íbis de Thoth", "scarab": "Escaravelho de ouro",
	"ba": "Alma Ba", "fog_egypt": "Tempestade de areia", "cobra": "Naja de Apep", "sandstone": "Pedra de arenito",
	"shade": "Sombra do Hades", "hellhound": "Cão do Hades", "minotaur": "Minotauro", "harpy": "Harpia",
	"bronze_shield": "Escudo de bronze", "lampad": "Lâmpade", "fog_greece": "Névoa do Estige", "gorgon_snake": "Serpente da górgona", "marble": "Bloco de mármore",
	"banshee": "Banshee", "kelpie": "Kelpie", "fomorian": "Fomoriano", "pooka": "Púca", "selkie": "Selkie",
	"fairy": "Fada luminosa", "fog_celtic": "Névoa do Outro Mundo", "peist": "Péist", "ogham": "Pedra de ogham",
	"tentacle": "Tentáculo", "boulder": "Pedra de gelo",
	"leviathan": "Leviatã", "kraken": "Kraken", "jotunn": "Jötunn", "fenrir": "Fenrir",
	"iara": "Iara", "boitata": "Boitatá", "cuca": "Cuca",
	"umibozu": "Umibōzu", "sphinx": "Esfinge", "apep": "Apep",
	"scylla": "Cila", "medusa": "Medusa", "balor": "Balor", "cailleach": "Cailleach",
}

## Subtítulo dos chefes na barra de vida.
const BOSS_TITLES := {
	"leviathan": "Serpente das profundezas", "kraken": "Terror dos abismos",
	"jotunn": "Gigante do gelo", "fenrir": "O lobo do fim do mundo",
	"iara": "A mãe d'água", "boitata": "A cobra de fogo", "cuca": "A bruxa da mata",
	"umibozu": "O monge do mar", "kyubi": "A raposa de nove caudas",
	"sphinx": "A guardiã dos enigmas", "apep": "A serpente do caos",
	"scylla": "O terror do estreito", "medusa": "A górgona do olhar de pedra",
	"balor": "O rei do olho maligno", "cailleach": "A velha do inverno",
}


static func get_map(id: String) -> Dictionary:
	return LIST.get(id, LIST["bay"])


## Chefe que aparece em cada horário de Balance.BOSS_TIMES; o índice 2 é o
## chefe extra do Impossível (mapas com dois chefes repetem o primeiro).
static func boss_at(map_id: String, index: int) -> String:
	var bosses: Array = get_map(map_id)["bosses"]
	return bosses[index % bosses.size()]
