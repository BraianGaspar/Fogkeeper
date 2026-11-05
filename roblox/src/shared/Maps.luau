-- Mapas jogáveis: nome, história, arte de cada papel de criatura, chefes,
-- paleta do dia e clima. Porta de scripts/core/maps.gd e day_cycle.gd.
-- As estatísticas vêm de Balance (por papel); aqui ficam identidade e enredo.
-- Textos em português (são as chaves de tradução, iguais ao Godot).

local Maps = {}

Maps.ORDER = { "bay", "fjord", "amazon", "japan", "egypt", "greece", "celtic" }

Maps.LIST = {
	bay = {
		name = "Baía da Névoa",
		tagline = "Mar aberto, naufrágios e a serpente das profundezas.",
		story = "Você aceitou cuidar do velho farol da Baía da Névoa depois que o último faroleiro desapareceu sem deixar rastro. Na primeira noite, a névoa subiu do mar trazendo vozes, cantos de sereia e algo enorme se movendo sob as ondas. Os navios da costa dependem da sua luz até o amanhecer.",
		scenery = "Bay",
		creatures = { basic = "wraith", fast = "siren", brute = "crab", thief = "ghost_gull", mirror = "oyster",
			moth = "jellyfish", fogbank = "fog_bay", tentacle = "tentacle", boulder = "boulder" },
		bosses = { "leviathan", "kraken" },
	},
	fjord = {
		name = "Fiorde Congelado",
		tagline = "Gelo eterno, aurora no céu e lobos que caçam na nevasca.",
		story = "Um navio de suprimentos ficou preso no gelo do fiorde, e o farol abandonado da ilha é a única luz que pode guiá-lo. Você atravessou o gelo a pé para reacendê-lo. As lendas dizem que os mortos do naufrágio antigo ainda andam, e que gigantes e o grande lobo despertam quando a nevasca chega.",
		scenery = "Fjord",
		creatures = { basic = "draugr", fast = "ice_wolf", brute = "troll", thief = "raven", mirror = "ice_shell",
			moth = "frost_moth", fogbank = "fog_fjord", tentacle = "tentacle", boulder = "boulder" },
		bosses = { "jotunn", "fenrir" },
	},
	amazon = {
		name = "Rio Encantado",
		tagline = "Igarapés, mata fechada e as lendas que acordam quando a luz se acende.",
		story = "O barco do correio afundou no encontro das águas, e o velho farol da ilhota no meio do rio é a única luz que pode guiar os ribeirinhos de volta. Você remou até ele ao pôr do sol. Na margem, avisaram: quem acende uma luz na mata desperta o canto da Iara, a cobra de fogo e a velha Cuca. E o Saci adora roubar o que brilha.",
		scenery = "Amazon",
		creatures = { basic = "corpo_seco", fast = "curupira", brute = "mapinguari", thief = "saci", mirror = "jabuti",
			moth = "mula", fogbank = "fog_amazon", tentacle = "boto", boulder = "wisp" },
		bosses = { "iara", "boitata", "cuca" },
	},
	japan = {
		name = "Mar dos Yōkai",
		tagline = "Lanternas no mar, portões torii e yōkai que sobem das ondas.",
		story = "Você assumiu o farol diante de uma vila de pescadores na noite do Obon, quando as famílias soltam lanternas no mar para guiar os mortos de volta. Os mais velhos avisaram: nessa noite os yōkai sobem das águas, o monge do mar pede um balde para afundar os barcos e uma raposa de nove caudas engana quem se perde na névoa.",
		scenery = "Japan",
		creatures = { basic = "funayurei", fast = "kitsune", brute = "oni", thief = "tengu", mirror = "kappa",
			moth = "chochin", fogbank = "fog_japan", tentacle = "hitodama", boulder = "wave", decoy = "kyubi_decoy" },
		bosses = { "umibozu", "kyubi" },
	},
	egypt = {
		name = "Farol de Alexandria",
		tagline = "Ruínas de Faros, dunas e a serpente que tenta engolir o sol.",
		story = "Dizem que o primeiro farol do mundo ficava aqui, na ilha de Faros. Você reacendeu a chama sobre as ruínas para guiar os barcos que descem o Nilo à noite. Mas a luz acordou o que dormia sob as areias: múmias, os chacais de Anúbis, a Esfinge e seus enigmas, e Apep, a serpente que toda noite tenta engolir o sol.",
		scenery = "Egypt",
		creatures = { basic = "mummy", fast = "jackal", brute = "sobek", thief = "ibis", mirror = "scarab",
			moth = "ba", fogbank = "fog_egypt", tentacle = "cobra", boulder = "sandstone" },
		bosses = { "sphinx", "apep" },
	},
	greece = {
		name = "Mar Egeu",
		tagline = "Ilhas de mármore, templos em ruínas e monstros que nenhum herói venceu.",
		story = "Um velho pescador de Ítaca pediu que alguém acendesse o farol do estreito, onde os navios somem entre dois rochedos. Você chegou de barco ao entardecer, passando por colunas de templos meio afundadas. Ninguém avisou que, à noite, as sombras sobem do Hades, as harpias descem dos penhascos e Cila acorda na sua caverna.",
		scenery = "Greece",
		creatures = { basic = "shade", fast = "hellhound", brute = "minotaur", thief = "harpy", mirror = "bronze_shield",
			moth = "lampad", fogbank = "fog_greece", tentacle = "gorgon_snake", boulder = "marble" },
		bosses = { "scylla", "medusa" },
	},
	celtic = {
		name = "Costa Celta",
		tagline = "Penhascos verdes, círculos de pedra e a noite em que o Outro Mundo se abre.",
		story = "Você veio cuidar do farol de uma ilha das Hébridas na noite de Samhain, quando o véu entre os mundos fica fino. Os moradores trancaram as portas, deixaram comida para as fadas e pediram que a luz não se apagasse: dizem que o olho de Balor se abre no mar e que a velha do inverno caminha sobre as ondas.",
		scenery = "Celtic",
		creatures = { basic = "banshee", fast = "kelpie", brute = "fomorian", thief = "pooka", mirror = "selkie",
			moth = "fairy", fogbank = "fog_celtic", tentacle = "peist", boulder = "ogham" },
		bosses = { "balor", "cailleach" },
	},
}

-- Nome visível de cada criatura (arte).
Maps.CREATURE_NAMES = {
	wraith = "Espectro da névoa", siren = "Sereia", crab = "Caranguejo de Karkinos",
	ghost_gull = "Gaivota-fantasma", oyster = "Ostra abissal", jellyfish = "Água-viva luminosa", fog_bay = "Névoa devoradora",
	draugr = "Draugr", ice_wolf = "Lobo de gelo", troll = "Troll de gelo",
	raven = "Corvo de Odin", ice_shell = "Escudo de gelo", frost_moth = "Mariposa de geada", fog_fjord = "Névoa de Niflheim",
	corpo_seco = "Corpo-seco", curupira = "Curupira", mapinguari = "Mapinguari",
	saci = "Saci", jabuti = "Jabuti encantado", mula = "Mula sem cabeça", fog_amazon = "Névoa da Matinta",
	boto = "Boto encantado", wisp = "Fogo-fátuo",
	funayurei = "Funayūrei", kitsune = "Kitsune", oni = "Oni", tengu = "Karasu-tengu", kappa = "Kappa",
	chochin = "Chōchin-obake", fog_japan = "Névoa dos afogados", hitodama = "Hitodama", wave = "Onda", kyubi = "Kyūbi", kyubi_decoy = "Kyūbi",
	mummy = "Múmia", jackal = "Chacal de Anúbis", sobek = "Crocodilo de Sobek", ibis = "Íbis de Thoth", scarab = "Escaravelho de ouro",
	ba = "Alma Ba", fog_egypt = "Tempestade de areia", cobra = "Naja de Apep", sandstone = "Pedra de arenito",
	shade = "Sombra do Hades", hellhound = "Cão do Hades", minotaur = "Minotauro", harpy = "Harpia",
	bronze_shield = "Escudo de bronze", lampad = "Lâmpade", fog_greece = "Névoa do Estige", gorgon_snake = "Serpente da górgona", marble = "Bloco de mármore",
	banshee = "Banshee", kelpie = "Kelpie", fomorian = "Fomoriano", pooka = "Púca", selkie = "Selkie",
	fairy = "Fada luminosa", fog_celtic = "Névoa do Outro Mundo", peist = "Péist", ogham = "Pedra de ogham",
	tentacle = "Tentáculo", boulder = "Pedra de gelo",
	leviathan = "Leviatã", kraken = "Kraken", jotunn = "Jötunn", fenrir = "Fenrir",
	iara = "Iara", boitata = "Boitatá", cuca = "Cuca",
	umibozu = "Umibōzu", sphinx = "Esfinge", apep = "Apep",
	scylla = "Cila", medusa = "Medusa", balor = "Balor", cailleach = "Cailleach",
}

-- Subtítulo dos chefes na barra de vida.
Maps.BOSS_TITLES = {
	leviathan = "Serpente das profundezas", kraken = "Terror dos abismos",
	jotunn = "Gigante do gelo", fenrir = "O lobo do fim do mundo",
	iara = "A mãe d'água", boitata = "A cobra de fogo", cuca = "A bruxa da mata",
	umibozu = "O monge do mar", kyubi = "A raposa de nove caudas",
	sphinx = "A guardiã dos enigmas", apep = "A serpente do caos",
	scylla = "O terror do estreito", medusa = "A górgona do olhar de pedra",
	balor = "O rei do olho maligno", cailleach = "A velha do inverno",
}

-- Paleta do dia por mapa (porta de DayCycle.*_KEYS do Godot). "at" é a
-- fração da noite (1.0 = amanhecer, 1.1 = dia claro da vitória).
--   sea, wave   cor do mar (gelo/rio) e das ondas
--   land        tinta da ilha e das estruturas
--   fog, fog_a  cor e opacidade da névoa
--   moon        reflexo da lua (0..1)
--   dusk, dawn  brilho do pôr e do nascer do sol
--   storm       tempestade (0..1)
--   night       estrelas e luz do farol no chão (0..1)
--   aurora      aurora boreal (só no fiorde)
Maps.PALETTES = {
	bay = {
		{ at = 0.0, sea = Color3.new(0.12, 0.08, 0.16), wave = Color3.new(0.75, 0.45, 0.5), land = Color3.new(0.85, 0.62, 0.62), fog = Color3.new(0.7, 0.45, 0.6), fog_a = 0.8, moon = 0.0, dusk = 0.8, dawn = 0.0, storm = 0.0, night = 0.2 },
		{ at = 0.1, sea = Color3.new(0.045, 0.07, 0.12), wave = Color3.new(0.3, 0.42, 0.6), land = Color3.new(0.55, 0.6, 0.72), fog = Color3.new(0.55, 0.5, 0.7), fog_a = 1.0, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.3, sea = Color3.new(0.05, 0.085, 0.14), wave = Color3.new(0.45, 0.58, 0.75), land = Color3.new(0.6, 0.66, 0.78), fog = Color3.new(0.55, 0.55, 0.72), fog_a = 1.0, moon = 1.0, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.44, sea = Color3.new(0.035, 0.055, 0.09), wave = Color3.new(0.35, 0.45, 0.6), land = Color3.new(0.48, 0.52, 0.62), fog = Color3.new(0.45, 0.48, 0.6), fog_a = 1.1, moon = 0.4, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.5, sea = Color3.new(0.025, 0.04, 0.065), wave = Color3.new(0.4, 0.5, 0.62), land = Color3.new(0.42, 0.46, 0.55), fog = Color3.new(0.4, 0.44, 0.55), fog_a = 1.25, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.58, sea = Color3.new(0.025, 0.04, 0.065), wave = Color3.new(0.4, 0.5, 0.62), land = Color3.new(0.42, 0.46, 0.55), fog = Color3.new(0.4, 0.44, 0.55), fog_a = 1.25, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.65, sea = Color3.new(0.05, 0.08, 0.13), wave = Color3.new(0.42, 0.55, 0.72), land = Color3.new(0.56, 0.62, 0.74), fog = Color3.new(0.55, 0.52, 0.7), fog_a = 1.0, moon = 0.8, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.82, sea = Color3.new(0.04, 0.06, 0.12), wave = Color3.new(0.38, 0.45, 0.66), land = Color3.new(0.5, 0.52, 0.66), fog = Color3.new(0.58, 0.52, 0.72), fog_a = 1.0, moon = 0.4, dusk = 0.0, dawn = 0.05, storm = 0.0, night = 0.9 },
		{ at = 0.92, sea = Color3.new(0.1, 0.11, 0.2), wave = Color3.new(0.62, 0.58, 0.75), land = Color3.new(0.68, 0.62, 0.72), fog = Color3.new(0.75, 0.62, 0.75), fog_a = 0.85, moon = 0.0, dusk = 0.0, dawn = 0.45, storm = 0.0, night = 0.5 },
		{ at = 1.0, sea = Color3.new(0.22, 0.2, 0.3), wave = Color3.new(1.0, 0.75, 0.6), land = Color3.new(0.95, 0.8, 0.72), fog = Color3.new(1.0, 0.78, 0.7), fog_a = 0.55, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1 },
		{ at = 1.1, sea = Color3.new(0.16, 0.32, 0.45), wave = Color3.new(1.0, 0.92, 0.78), land = Color3.new(1.0, 0.95, 0.88), fog = Color3.new(1.0, 0.9, 0.8), fog_a = 0.12, moon = 0.0, dusk = 0.0, dawn = 0.8, storm = 0.0, night = 0.0 },
	},
	fjord = {
		{ at = 0.0, sea = Color3.new(0.42, 0.36, 0.5), wave = Color3.new(0.95, 0.75, 0.85), land = Color3.new(0.95, 0.8, 0.85), fog = Color3.new(0.85, 0.7, 0.85), fog_a = 0.7, moon = 0.0, dusk = 0.7, dawn = 0.0, storm = 0.0, night = 0.2, aurora = 0.0 },
		{ at = 0.12, sea = Color3.new(0.12, 0.16, 0.26), wave = Color3.new(0.55, 0.7, 0.9), land = Color3.new(0.6, 0.68, 0.85), fog = Color3.new(0.7, 0.78, 0.92), fog_a = 0.9, moon = 0.4, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0, aurora = 0.4 },
		{ at = 0.3, sea = Color3.new(0.12, 0.2, 0.28), wave = Color3.new(0.5, 0.95, 0.8), land = Color3.new(0.6, 0.8, 0.8), fog = Color3.new(0.6, 0.85, 0.85), fog_a = 0.9, moon = 0.6, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0, aurora = 1.0 },
		{ at = 0.42, sea = Color3.new(0.11, 0.15, 0.22), wave = Color3.new(0.55, 0.7, 0.85), land = Color3.new(0.58, 0.66, 0.78), fog = Color3.new(0.75, 0.82, 0.9), fog_a = 1.0, moon = 0.2, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0, aurora = 0.3 },
		{ at = 0.5, sea = Color3.new(0.2, 0.24, 0.3), wave = Color3.new(0.8, 0.88, 0.95), land = Color3.new(0.7, 0.75, 0.82), fog = Color3.new(0.88, 0.92, 0.98), fog_a = 1.4, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0, aurora = 0.0 },
		{ at = 0.6, sea = Color3.new(0.2, 0.24, 0.3), wave = Color3.new(0.8, 0.88, 0.95), land = Color3.new(0.7, 0.75, 0.82), fog = Color3.new(0.88, 0.92, 0.98), fog_a = 1.4, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0, aurora = 0.0 },
		{ at = 0.68, sea = Color3.new(0.12, 0.17, 0.27), wave = Color3.new(0.6, 0.6, 0.95), land = Color3.new(0.6, 0.66, 0.85), fog = Color3.new(0.7, 0.72, 0.92), fog_a = 0.95, moon = 0.5, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0, aurora = 0.8 },
		{ at = 0.85, sea = Color3.new(0.14, 0.17, 0.28), wave = Color3.new(0.62, 0.68, 0.9), land = Color3.new(0.65, 0.68, 0.85), fog = Color3.new(0.78, 0.76, 0.92), fog_a = 0.95, moon = 0.3, dusk = 0.0, dawn = 0.1, storm = 0.0, night = 0.9, aurora = 0.3 },
		{ at = 1.0, sea = Color3.new(0.55, 0.5, 0.58), wave = Color3.new(1.0, 0.85, 0.7), land = Color3.new(1.0, 0.88, 0.82), fog = Color3.new(1.0, 0.85, 0.78), fog_a = 0.5, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1, aurora = 0.0 },
		{ at = 1.1, sea = Color3.new(0.7, 0.8, 0.88), wave = Color3.new(1.0, 1.0, 0.95), land = Color3.new(1.0, 1.0, 1.0), fog = Color3.new(1.0, 0.98, 0.95), fog_a = 0.15, moon = 0.0, dusk = 0.0, dawn = 0.7, storm = 0.0, night = 0.0, aurora = 0.0 },
	},
	amazon = {
		{ at = 0.0, sea = Color3.new(0.36, 0.24, 0.12), wave = Color3.new(0.95, 0.65, 0.4), land = Color3.new(1.0, 0.75, 0.6), fog = Color3.new(0.9, 0.6, 0.45), fog_a = 0.7, moon = 0.0, dusk = 0.9, dawn = 0.0, storm = 0.0, night = 0.15 },
		{ at = 0.1, sea = Color3.new(0.07, 0.12, 0.09), wave = Color3.new(0.35, 0.55, 0.42), land = Color3.new(0.55, 0.68, 0.6), fog = Color3.new(0.45, 0.6, 0.5), fog_a = 1.0, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.3, sea = Color3.new(0.06, 0.12, 0.1), wave = Color3.new(0.45, 0.65, 0.55), land = Color3.new(0.6, 0.72, 0.66), fog = Color3.new(0.5, 0.65, 0.55), fog_a = 1.0, moon = 1.0, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.44, sea = Color3.new(0.05, 0.09, 0.08), wave = Color3.new(0.38, 0.5, 0.45), land = Color3.new(0.48, 0.56, 0.52), fog = Color3.new(0.42, 0.52, 0.48), fog_a = 1.15, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.5, sea = Color3.new(0.04, 0.07, 0.07), wave = Color3.new(0.42, 0.52, 0.5), land = Color3.new(0.42, 0.5, 0.48), fog = Color3.new(0.4, 0.48, 0.46), fog_a = 1.3, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.58, sea = Color3.new(0.04, 0.07, 0.07), wave = Color3.new(0.42, 0.52, 0.5), land = Color3.new(0.42, 0.5, 0.48), fog = Color3.new(0.4, 0.48, 0.46), fog_a = 1.3, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.66, sea = Color3.new(0.06, 0.12, 0.1), wave = Color3.new(0.45, 0.62, 0.52), land = Color3.new(0.58, 0.7, 0.62), fog = Color3.new(0.5, 0.62, 0.55), fog_a = 1.0, moon = 0.8, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.84, sea = Color3.new(0.08, 0.12, 0.12), wave = Color3.new(0.45, 0.55, 0.6), land = Color3.new(0.58, 0.62, 0.66), fog = Color3.new(0.6, 0.6, 0.66), fog_a = 0.95, moon = 0.3, dusk = 0.0, dawn = 0.1, storm = 0.0, night = 0.9 },
		{ at = 1.0, sea = Color3.new(0.32, 0.25, 0.2), wave = Color3.new(1.0, 0.78, 0.62), land = Color3.new(1.0, 0.85, 0.75), fog = Color3.new(1.0, 0.8, 0.7), fog_a = 0.55, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1 },
		{ at = 1.1, sea = Color3.new(0.3, 0.34, 0.2), wave = Color3.new(0.95, 0.95, 0.75), land = Color3.new(1.0, 1.0, 0.92), fog = Color3.new(1.0, 0.95, 0.85), fog_a = 0.12, moon = 0.0, dusk = 0.0, dawn = 0.7, storm = 0.0, night = 0.0 },
	},
	japan = {
		{ at = 0.0, sea = Color3.new(0.3, 0.14, 0.2), wave = Color3.new(1.0, 0.55, 0.55), land = Color3.new(1.0, 0.7, 0.7), fog = Color3.new(0.85, 0.5, 0.6), fog_a = 0.7, moon = 0.0, dusk = 0.9, dawn = 0.0, storm = 0.0, night = 0.15 },
		{ at = 0.1, sea = Color3.new(0.05, 0.06, 0.14), wave = Color3.new(0.4, 0.45, 0.75), land = Color3.new(0.6, 0.6, 0.8), fog = Color3.new(0.55, 0.5, 0.75), fog_a = 1.0, moon = 0.6, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.3, sea = Color3.new(0.06, 0.07, 0.16), wave = Color3.new(0.55, 0.6, 0.9), land = Color3.new(0.7, 0.7, 0.88), fog = Color3.new(0.6, 0.55, 0.8), fog_a = 1.0, moon = 1.0, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.44, sea = Color3.new(0.04, 0.05, 0.11), wave = Color3.new(0.4, 0.45, 0.65), land = Color3.new(0.5, 0.52, 0.66), fog = Color3.new(0.45, 0.45, 0.62), fog_a = 1.15, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.5, sea = Color3.new(0.03, 0.04, 0.08), wave = Color3.new(0.45, 0.5, 0.65), land = Color3.new(0.42, 0.45, 0.55), fog = Color3.new(0.4, 0.42, 0.55), fog_a = 1.3, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.58, sea = Color3.new(0.03, 0.04, 0.08), wave = Color3.new(0.45, 0.5, 0.65), land = Color3.new(0.42, 0.45, 0.55), fog = Color3.new(0.4, 0.42, 0.55), fog_a = 1.3, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.66, sea = Color3.new(0.06, 0.06, 0.15), wave = Color3.new(0.55, 0.55, 0.88), land = Color3.new(0.66, 0.64, 0.86), fog = Color3.new(0.62, 0.55, 0.8), fog_a = 1.0, moon = 0.9, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.85, sea = Color3.new(0.08, 0.07, 0.16), wave = Color3.new(0.6, 0.55, 0.85), land = Color3.new(0.66, 0.6, 0.8), fog = Color3.new(0.7, 0.6, 0.8), fog_a = 0.95, moon = 0.3, dusk = 0.0, dawn = 0.1, storm = 0.0, night = 0.9 },
		{ at = 1.0, sea = Color3.new(0.3, 0.2, 0.3), wave = Color3.new(1.0, 0.75, 0.7), land = Color3.new(1.0, 0.82, 0.82), fog = Color3.new(1.0, 0.78, 0.78), fog_a = 0.55, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1 },
		{ at = 1.1, sea = Color3.new(0.2, 0.32, 0.48), wave = Color3.new(1.0, 0.92, 0.9), land = Color3.new(1.0, 0.96, 0.95), fog = Color3.new(1.0, 0.92, 0.92), fog_a = 0.12, moon = 0.0, dusk = 0.0, dawn = 0.7, storm = 0.0, night = 0.0 },
	},
	egypt = {
		{ at = 0.0, sea = Color3.new(0.32, 0.2, 0.18), wave = Color3.new(1.0, 0.7, 0.45), land = Color3.new(1.0, 0.75, 0.6), fog = Color3.new(0.95, 0.65, 0.45), fog_a = 0.65, moon = 0.0, dusk = 1.0, dawn = 0.0, storm = 0.0, night = 0.15 },
		{ at = 0.1, sea = Color3.new(0.05, 0.08, 0.15), wave = Color3.new(0.4, 0.5, 0.72), land = Color3.new(0.62, 0.62, 0.78), fog = Color3.new(0.6, 0.58, 0.68), fog_a = 0.9, moon = 0.5, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.3, sea = Color3.new(0.06, 0.1, 0.17), wave = Color3.new(0.5, 0.62, 0.85), land = Color3.new(0.7, 0.7, 0.85), fog = Color3.new(0.62, 0.6, 0.72), fog_a = 0.9, moon = 1.0, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.44, sea = Color3.new(0.07, 0.08, 0.12), wave = Color3.new(0.5, 0.5, 0.6), land = Color3.new(0.62, 0.58, 0.6), fog = Color3.new(0.65, 0.55, 0.45), fog_a = 1.1, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.3, night = 1.0 },
		{ at = 0.5, sea = Color3.new(0.12, 0.1, 0.08), wave = Color3.new(0.7, 0.6, 0.45), land = Color3.new(0.72, 0.6, 0.48), fog = Color3.new(0.8, 0.62, 0.4), fog_a = 1.35, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.58, sea = Color3.new(0.12, 0.1, 0.08), wave = Color3.new(0.7, 0.6, 0.45), land = Color3.new(0.72, 0.6, 0.48), fog = Color3.new(0.8, 0.62, 0.4), fog_a = 1.35, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.66, sea = Color3.new(0.06, 0.1, 0.17), wave = Color3.new(0.5, 0.6, 0.85), land = Color3.new(0.68, 0.68, 0.84), fog = Color3.new(0.62, 0.6, 0.72), fog_a = 0.95, moon = 0.8, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.85, sea = Color3.new(0.08, 0.1, 0.16), wave = Color3.new(0.55, 0.58, 0.8), land = Color3.new(0.7, 0.66, 0.8), fog = Color3.new(0.72, 0.64, 0.7), fog_a = 0.9, moon = 0.3, dusk = 0.0, dawn = 0.1, storm = 0.0, night = 0.9 },
		{ at = 1.0, sea = Color3.new(0.32, 0.25, 0.25), wave = Color3.new(1.0, 0.8, 0.6), land = Color3.new(1.0, 0.85, 0.72), fog = Color3.new(1.0, 0.82, 0.65), fog_a = 0.5, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1 },
		{ at = 1.1, sea = Color3.new(0.15, 0.4, 0.55), wave = Color3.new(1.0, 0.95, 0.85), land = Color3.new(1.0, 0.97, 0.9), fog = Color3.new(1.0, 0.95, 0.85), fog_a = 0.1, moon = 0.0, dusk = 0.0, dawn = 0.7, storm = 0.0, night = 0.0 },
	},
	greece = {
		{ at = 0.0, sea = Color3.new(0.2, 0.18, 0.3), wave = Color3.new(1.0, 0.75, 0.5), land = Color3.new(1.0, 0.82, 0.68), fog = Color3.new(0.9, 0.7, 0.6), fog_a = 0.6, moon = 0.0, dusk = 1.0, dawn = 0.0, storm = 0.0, night = 0.15 },
		{ at = 0.1, sea = Color3.new(0.03, 0.07, 0.17), wave = Color3.new(0.35, 0.5, 0.8), land = Color3.new(0.62, 0.66, 0.82), fog = Color3.new(0.5, 0.55, 0.75), fog_a = 0.95, moon = 0.5, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.3, sea = Color3.new(0.04, 0.09, 0.2), wave = Color3.new(0.45, 0.62, 0.9), land = Color3.new(0.7, 0.74, 0.9), fog = Color3.new(0.52, 0.58, 0.78), fog_a = 0.95, moon = 1.0, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.44, sea = Color3.new(0.03, 0.06, 0.13), wave = Color3.new(0.38, 0.48, 0.68), land = Color3.new(0.52, 0.56, 0.7), fog = Color3.new(0.45, 0.48, 0.65), fog_a = 1.1, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.3, night = 1.0 },
		{ at = 0.5, sea = Color3.new(0.02, 0.04, 0.09), wave = Color3.new(0.42, 0.5, 0.68), land = Color3.new(0.45, 0.48, 0.6), fog = Color3.new(0.4, 0.44, 0.6), fog_a = 1.25, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.58, sea = Color3.new(0.02, 0.04, 0.09), wave = Color3.new(0.42, 0.5, 0.68), land = Color3.new(0.45, 0.48, 0.6), fog = Color3.new(0.4, 0.44, 0.6), fog_a = 1.25, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.66, sea = Color3.new(0.04, 0.09, 0.2), wave = Color3.new(0.45, 0.6, 0.88), land = Color3.new(0.66, 0.7, 0.88), fog = Color3.new(0.52, 0.56, 0.76), fog_a = 0.95, moon = 0.8, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.85, sea = Color3.new(0.06, 0.09, 0.2), wave = Color3.new(0.55, 0.58, 0.85), land = Color3.new(0.72, 0.68, 0.84), fog = Color3.new(0.68, 0.6, 0.78), fog_a = 0.9, moon = 0.3, dusk = 0.0, dawn = 0.1, storm = 0.0, night = 0.9 },
		{ at = 1.0, sea = Color3.new(0.25, 0.25, 0.4), wave = Color3.new(1.0, 0.82, 0.7), land = Color3.new(1.0, 0.88, 0.8), fog = Color3.new(1.0, 0.82, 0.75), fog_a = 0.5, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1 },
		{ at = 1.1, sea = Color3.new(0.1, 0.38, 0.6), wave = Color3.new(1.0, 0.97, 0.92), land = Color3.new(1.0, 0.98, 0.95), fog = Color3.new(1.0, 0.96, 0.92), fog_a = 0.1, moon = 0.0, dusk = 0.0, dawn = 0.7, storm = 0.0, night = 0.0 },
	},
	celtic = {
		{ at = 0.0, sea = Color3.new(0.18, 0.16, 0.22), wave = Color3.new(0.95, 0.7, 0.55), land = Color3.new(0.95, 0.8, 0.7), fog = Color3.new(0.8, 0.7, 0.68), fog_a = 0.75, moon = 0.0, dusk = 0.8, dawn = 0.0, storm = 0.0, night = 0.2 },
		{ at = 0.1, sea = Color3.new(0.04, 0.08, 0.1), wave = Color3.new(0.35, 0.5, 0.55), land = Color3.new(0.55, 0.65, 0.66), fog = Color3.new(0.5, 0.6, 0.6), fog_a = 1.1, moon = 0.3, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.3, sea = Color3.new(0.05, 0.1, 0.12), wave = Color3.new(0.45, 0.6, 0.65), land = Color3.new(0.6, 0.7, 0.72), fog = Color3.new(0.55, 0.65, 0.66), fog_a = 1.15, moon = 0.9, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.44, sea = Color3.new(0.03, 0.06, 0.08), wave = Color3.new(0.38, 0.48, 0.52), land = Color3.new(0.48, 0.55, 0.56), fog = Color3.new(0.45, 0.52, 0.54), fog_a = 1.2, moon = 0.2, dusk = 0.0, dawn = 0.0, storm = 0.3, night = 1.0 },
		{ at = 0.5, sea = Color3.new(0.025, 0.045, 0.06), wave = Color3.new(0.4, 0.5, 0.55), land = Color3.new(0.42, 0.48, 0.5), fog = Color3.new(0.42, 0.48, 0.5), fog_a = 1.3, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.58, sea = Color3.new(0.025, 0.045, 0.06), wave = Color3.new(0.4, 0.5, 0.55), land = Color3.new(0.42, 0.48, 0.5), fog = Color3.new(0.42, 0.48, 0.5), fog_a = 1.3, moon = 0.0, dusk = 0.0, dawn = 0.0, storm = 1.0, night = 1.0 },
		{ at = 0.66, sea = Color3.new(0.05, 0.1, 0.12), wave = Color3.new(0.45, 0.6, 0.64), land = Color3.new(0.58, 0.68, 0.7), fog = Color3.new(0.55, 0.64, 0.64), fog_a = 1.1, moon = 0.7, dusk = 0.0, dawn = 0.0, storm = 0.0, night = 1.0 },
		{ at = 0.85, sea = Color3.new(0.07, 0.09, 0.13), wave = Color3.new(0.55, 0.58, 0.7), land = Color3.new(0.66, 0.68, 0.74), fog = Color3.new(0.66, 0.64, 0.7), fog_a = 1.0, moon = 0.3, dusk = 0.0, dawn = 0.1, storm = 0.0, night = 0.9 },
		{ at = 1.0, sea = Color3.new(0.25, 0.22, 0.3), wave = Color3.new(1.0, 0.8, 0.7), land = Color3.new(1.0, 0.86, 0.8), fog = Color3.new(0.95, 0.82, 0.8), fog_a = 0.6, moon = 0.0, dusk = 0.0, dawn = 1.0, storm = 0.0, night = 0.1 },
		{ at = 1.1, sea = Color3.new(0.18, 0.34, 0.4), wave = Color3.new(0.95, 0.97, 0.95), land = Color3.new(0.95, 1.0, 0.95), fog = Color3.new(0.92, 0.95, 0.94), fog_a = 0.15, moon = 0.0, dusk = 0.0, dawn = 0.7, storm = 0.0, night = 0.0 },
	},
}

-- Avisos de clima mostrados no HUD quando a noite passa por estes pontos.
local CLEAR = "O céu começa a clarear. Aguente firme!"
Maps.EVENTS = {
	bay = { { at = 0.42, text = "Nuvens pesadas se aproximam..." }, { at = 0.88, text = CLEAR } },
	fjord = { { at = 0.42, text = "O vento uiva: vem aí uma nevasca..." }, { at = 0.88, text = CLEAR } },
	amazon = { { at = 0.42, text = "Trovões ecoam sobre a mata: vem aí um temporal..." }, { at = 0.88, text = CLEAR } },
	japan = { { at = 0.42, text = "O vento muda de repente: um tufão se aproxima..." }, { at = 0.88, text = CLEAR } },
	egypt = { { at = 0.42, text = "O vento do deserto levanta uma tempestade de areia..." }, { at = 0.88, text = CLEAR } },
	greece = { { at = 0.42, text = "Raios cortam o céu: Zeus anda irritado esta noite..." }, { at = 0.88, text = CLEAR } },
	celtic = { { at = 0.42, text = "Uma chuva fria chega do Atlântico..." }, { at = 0.88, text = CLEAR } },
}

-- Clima de cada mapa (fog.gd): `storm` é o que cai na tempestade, `ambient`
-- o que flutua a noite toda; `lightning` liga os relâmpagos (respeitam
-- "reduzir clarões"); `aurora` só no fiorde.
Maps.WEATHER = {
	bay = { storm = "rain", lightning = true },
	fjord = { storm = "snow", ambient = "snow", aurora = true },
	amazon = { storm = "rain", ambient = "fireflies", lightning = true },
	japan = { storm = "rain", ambient = "petals", lightning = true },
	egypt = { storm = "sand" },
	greece = { storm = "rain", lightning = true },
	celtic = { storm = "rain", ambient = "fairy_lights", lightning = true },
}

-- Cor do mapa nas telas (prévias e destaque), igual ao Godot (map_screen.gd).
Maps.ACCENT = {
	bay = Color3.fromRGB(110, 170, 230), fjord = Color3.fromRGB(150, 220, 255), amazon = Color3.fromRGB(120, 220, 120),
	japan = Color3.fromRGB(255, 140, 166), egypt = Color3.fromRGB(255, 209, 102), greece = Color3.fromRGB(140, 190, 255),
	celtic = Color3.fromRGB(120, 230, 170),
}

function Maps.get(id: string)
	return Maps.LIST[id] or Maps.LIST.bay
end

-- Chefe que aparece em cada horário (índice 1, 2...); o índice 3 é o chefe
-- extra do Impossível (mapas com dois chefes repetem o primeiro).
function Maps.bossAt(mapId: string, index: number): string
	local bosses = Maps.get(mapId).bosses
	return bosses[(index - 1) % #bosses + 1]
end

-- Arte de um papel no mapa (nil se o mapa não usa esse papel).
function Maps.artFor(mapId: string, role: string): string?
	return Maps.get(mapId).creatures[role]
end

-- Mapa ao qual uma arte pertence (para o bestiário e o cenário).
function Maps.mapOfArt(art: string): string?
	for _, id in Maps.ORDER do
		local m = Maps.LIST[id]
		for _, a in m.creatures do
			if a == art then
				return id
			end
		end
		if table.find(m.bosses, art) then
			return id
		end
	end
	return nil
end

-- Paleta interpolada na fração `f` da noite (0..1.1), com suavização igual
-- ao smoothstep do Godot.
function Maps.sample(mapId: string, f: number): { [string]: any }
	local keys = Maps.PALETTES[mapId] or Maps.PALETTES.bay
	if f <= keys[1].at then
		return keys[1]
	end
	for i = 2, #keys do
		local b = keys[i]
		if f <= b.at then
			local a = keys[i - 1]
			local k = math.clamp((f - a.at) / (b.at - a.at), 0, 1)
			k = k * k * (3 - 2 * k)
			local out = {}
			for key, bv in b do
				local av = a[key]
				if av == nil then
					av = bv
				end
				if typeof(bv) == "Color3" then
					out[key] = (av :: Color3):Lerp(bv, k)
				else
					out[key] = av + (bv - av) * k
				end
			end
			return out
		end
	end
	return keys[#keys]
end

-- Lista ordenada e estável de todos os ids de arte (índice usado no
-- Snapshot). Ordem: criaturas de cada mapa (na ordem de ORDER, papéis na
-- ordem de ROLE_ORDER), chefes de cada mapa e, por fim, as artes extras que
-- BossData declarar (partes de chefes). Ids repetidos entram uma vez só.
-- Servidor e cliente montam a mesma lista porque leem os mesmos módulos.
local ROLE_ORDER = { "basic", "fast", "brute", "thief", "mirror", "moth", "fogbank", "tentacle", "boulder", "decoy" }

local function buildArts(): { string }
	local list, seen = {}, {}
	local function add(id: string?)
		if id and not seen[id] then
			seen[id] = true
			table.insert(list, id)
		end
	end
	for _, mapId in Maps.ORDER do
		local m = Maps.LIST[mapId]
		for _, role in ROLE_ORDER do
			add(m.creatures[role])
		end
	end
	for _, mapId in Maps.ORDER do
		for _, boss in Maps.LIST[mapId].bosses do
			add(boss)
		end
	end
	local ok, BossData = pcall(function()
		local mod = script.Parent:WaitForChild("BossData", 5)
		return if mod then require(mod) else nil
	end)
	if ok and type(BossData) == "table" and type(BossData.ARTS) == "table" then
		for _, id in BossData.ARTS do
			add(id)
		end
	end
	return list
end

Maps.ROLE_ORDER = ROLE_ORDER
Maps.ARTS = buildArts()

return Maps
