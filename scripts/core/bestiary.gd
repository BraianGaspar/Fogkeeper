class_name Bestiary
extends RefCounted
## Fichas das criaturas e chefes, com a lenda de cada um. A ficha se abre na
## primeira vez que a criatura é queimada (Progress.stats["seen_<arte>"]).

## Ordem das fichas em cada mapa: comuns, especiais, lacaios e chefes.
const ENTRIES := {
	"bay": ["wraith", "siren", "crab", "ghost_gull", "oyster", "jellyfish", "fog_bay", "tentacle", "leviathan", "kraken"],
	"fjord": ["draugr", "ice_wolf", "troll", "raven", "ice_shell", "frost_moth", "fog_fjord", "boulder", "jotunn", "fenrir"],
	"amazon": ["corpo_seco", "curupira", "mapinguari", "saci", "jabuti", "mula", "fog_amazon", "boto", "wisp", "iara", "boitata", "cuca"],
	"japan": ["funayurei", "kitsune", "oni", "tengu", "kappa", "chochin", "fog_japan", "hitodama", "wave", "umibozu", "kyubi"],
	"egypt": ["mummy", "jackal", "sobek", "ibis", "scarab", "ba", "fog_egypt", "cobra", "sandstone", "sphinx", "apep"],
}

const LORE := {
	"wraith": "Almas de marinheiros perdidos na névoa, atraídas por qualquer luz que lembre o caminho de casa.",
	"siren": "Nas lendas gregas, cantavam para atrair os navios contra as pedras.",
	"crab": "Karkinos, o caranguejo gigante que Hera mandou contra Hércules; virou a constelação de Câncer.",
	"ghost_gull": "Diz-se que as gaivotas guardam as almas dos pescadores. Estas guardam também o que brilha.",
	"oyster": "Uma ostra das profundezas cuja concha reflete a luz como um espelho.",
	"jellyfish": "Águas-vivas que brilham no escuro e se alimentam da própria luz que as queima.",
	"fog_bay": "A névoa que dá nome à baía: onde ela passa, até as brasas se apagam.",
	"tentacle": "Um dos braços do Kraken, que rasteja sozinho em direção à luz.",
	"leviathan": "A serpente marinha do Livro de Jó, tão grande que o mar ferve à sua passagem.",
	"kraken": "O monstro dos mares da Noruega, confundido com ilhas pelos marinheiros.",
	"draugr": "Mortos-vivos nórdicos que guardam os túmulos e os navios afundados.",
	"ice_wolf": "Lobos da nevasca, filhotes da longa noite do inverno nórdico.",
	"troll": "Os trolls das montanhas viram pedra se a luz do sol os tocar.",
	"raven": "Huginn e Muninn, os corvos de Odin, voam pelo mundo e levam o que acham para o deus.",
	"ice_shell": "Uma carapaça de gelo tão polida que devolve a luz a quem a lança.",
	"frost_moth": "Mariposas que nascem da geada e crescem quanto mais luz bebem.",
	"fog_fjord": "Bruma de Niflheim, o mundo do gelo e da névoa primordial.",
	"boulder": "Pedras de gelo arrancadas das montanhas pelas mãos de um gigante.",
	"jotunn": "Os gigantes de gelo, inimigos antigos dos deuses de Asgard.",
	"fenrir": "O lobo que os deuses prenderam com a corrente Gleipnir; dizem que a romperá no fim do mundo.",
	"corpo_seco": "Alguém tão ruim em vida que nem a terra quis: anda seco, sem descanso.",
	"curupira": "O guardião da mata, de cabelo de fogo e pés virados para trás, que confunde os caçadores.",
	"mapinguari": "Gigante da Amazônia de um olho só e uma boca na barriga; seu grito paralisa.",
	"saci": "O menino de uma perna só e gorro vermelho que vive no redemoinho e adora uma travessura.",
	"jabuti": "O jabuti esperto das fábulas indígenas, que vence os mais fortes com astúcia.",
	"mula": "Uma mulher amaldiçoada que vira mula sem cabeça, com fogo no lugar do pescoço.",
	"fog_amazon": "A Matinta Pereira assobia na escuridão; quem ouve, que deixe fumo para ela.",
	"boto": "O boto-cor-de-rosa que vira um moço de chapéu branco nas festas da beira do rio.",
	"wisp": "Fogos-fátuos: as chamas azuladas do Boitatá que vagam pelos campos à noite.",
	"iara": "A mãe d'água dos rios brasileiros, que encanta com o canto quem se aproxima.",
	"boitata": "A cobra de fogo de olhos enormes que protege as matas dos incêndios.",
	"cuca": "A velha bruxa com cabeça de jacaré da cantiga de ninar que diz: dorme, neném, que a Cuca vem pegar.",
	"funayurei": "Fantasmas de afogados que pedem uma concha para encher os barcos de água.",
	"kitsune": "Raposas mágicas que ganham uma cauda a cada século e acendem fogos-fátuos.",
	"oni": "Ogros do folclore japonês, de chifres e porrete de ferro.",
	"tengu": "Os karasu-tengu, meio homem e meio corvo, guardiões das montanhas.",
	"kappa": "Criatura dos rios com um prato d'água na cabeça; se o prato esvazia, perde a força.",
	"chochin": "Uma lanterna de papel velha que ganhou vida, com um olho e a língua de fora.",
	"fog_japan": "A névoa onde os afogados esperam pelas lanternas do Obon.",
	"hitodama": "Almas que saem do corpo como bolas de fogo azulado.",
	"wave": "Ondas erguidas pelo monge do mar para engolir os barcos.",
	"umibozu": "O monge do mar, uma cabeça escura e gigante que surge das ondas em noites calmas.",
	"kyubi": "A raposa de nove caudas, mestra das ilusões, que já enganou imperadores.",
	"mummy": "Os mortos preparados para a eternidade, acordados por quem perturba as tumbas.",
	"jackal": "Os chacais de Anúbis, que guiam as almas pelo mundo dos mortos.",
	"sobek": "Sobek, o deus crocodilo do Nilo, senhor das águas e da força.",
	"ibis": "A íbis de Thoth, deus da escrita e da sabedoria.",
	"scarab": "O escaravelho sagrado de Khepri, que empurra o sol pelo céu todas as manhãs.",
	"ba": "A alma Ba, ave com rosto humano que visita o mundo dos vivos depois da morte.",
	"fog_egypt": "Ventos do deserto que levantam areia até apagar o horizonte.",
	"cobra": "As najas nascidas das escamas de Apep.",
	"sandstone": "Blocos de arenito que a Esfinge faz rolar contra quem erra o enigma.",
	"sphinx": "A guardiã dos enigmas: quem não responde certo não passa.",
	"apep": "Apep, a serpente do caos que toda noite tenta engolir o barco do sol.",
}


static func seen(art: String) -> bool:
	return not Progress.enabled or Progress.stat("seen_" + art) > 0


## Quantas fichas estão abertas e quantas existem.
static func count() -> Vector2i:
	var opened := 0
	var all := 0
	for map: String in ENTRIES:
		for art: String in ENTRIES[map]:
			all += 1
			if seen(art):
				opened += 1
	return Vector2i(opened, all)
