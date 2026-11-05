-- Fichas do bestiário: uma por criatura e chefe de cada mapa, com a lenda.
-- A ficha se abre quando o jogador queima a criatura pela primeira vez
-- (Progress guarda em ProgressJson.seen[arte]). Porta de scripts/core/bestiary.gd.

local Bestiary = {}

-- Ordem das fichas em cada mapa: comuns, especiais, lacaios e chefes.
Bestiary.ENTRIES = {
	bay = { "wraith", "siren", "crab", "ghost_gull", "oyster", "jellyfish", "fog_bay", "tentacle", "leviathan", "kraken" },
	fjord = { "draugr", "ice_wolf", "troll", "raven", "ice_shell", "frost_moth", "fog_fjord", "boulder", "jotunn", "fenrir" },
	amazon = { "corpo_seco", "curupira", "mapinguari", "saci", "jabuti", "mula", "fog_amazon", "boto", "wisp", "iara", "boitata", "cuca" },
	japan = { "funayurei", "kitsune", "oni", "tengu", "kappa", "chochin", "fog_japan", "hitodama", "wave", "umibozu", "kyubi" },
	egypt = { "mummy", "jackal", "sobek", "ibis", "scarab", "ba", "fog_egypt", "cobra", "sandstone", "sphinx", "apep" },
	greece = { "shade", "hellhound", "minotaur", "harpy", "bronze_shield", "lampad", "fog_greece", "gorgon_snake", "marble", "scylla", "medusa" },
	celtic = { "banshee", "kelpie", "fomorian", "pooka", "selkie", "fairy", "fog_celtic", "peist", "ogham", "balor", "cailleach" },
}

Bestiary.LORE = {
	wraith = "Almas de marinheiros perdidos na névoa, atraídas por qualquer luz que lembre o caminho de casa.",
	siren = "Nas lendas gregas, cantavam para atrair os navios contra as pedras.",
	crab = "Karkinos, o caranguejo gigante que Hera mandou contra Hércules; virou a constelação de Câncer.",
	ghost_gull = "Diz-se que as gaivotas guardam as almas dos pescadores. Estas guardam também o que brilha.",
	oyster = "Uma ostra das profundezas cuja concha reflete a luz como um espelho.",
	jellyfish = "Águas-vivas que brilham no escuro e se alimentam da própria luz que as queima.",
	fog_bay = "A névoa que dá nome à baía: onde ela passa, até as brasas se apagam.",
	tentacle = "Um dos braços do Kraken, que rasteja sozinho em direção à luz.",
	leviathan = "A serpente marinha do Livro de Jó, tão grande que o mar ferve à sua passagem.",
	kraken = "O monstro dos mares da Noruega, confundido com ilhas pelos marinheiros.",
	draugr = "Mortos-vivos nórdicos que guardam os túmulos e os navios afundados.",
	ice_wolf = "Lobos da nevasca, filhotes da longa noite do inverno nórdico.",
	troll = "Os trolls das montanhas viram pedra se a luz do sol os tocar.",
	raven = "Huginn e Muninn, os corvos de Odin, voam pelo mundo e levam o que acham para o deus.",
	ice_shell = "Uma carapaça de gelo tão polida que devolve a luz a quem a lança.",
	frost_moth = "Mariposas que nascem da geada e crescem quanto mais luz bebem.",
	fog_fjord = "Bruma de Niflheim, o mundo do gelo e da névoa primordial.",
	boulder = "Pedras de gelo arrancadas das montanhas pelas mãos de um gigante.",
	jotunn = "Os gigantes de gelo, inimigos antigos dos deuses de Asgard.",
	fenrir = "O lobo que os deuses prenderam com a corrente Gleipnir; dizem que a romperá no fim do mundo.",
	corpo_seco = "Alguém tão ruim em vida que nem a terra quis: anda seco, sem descanso.",
	curupira = "O guardião da mata, de cabelo de fogo e pés virados para trás, que confunde os caçadores.",
	mapinguari = "Gigante da Amazônia de um olho só e uma boca na barriga; seu grito paralisa.",
	saci = "O menino de uma perna só e gorro vermelho que vive no redemoinho e adora uma travessura.",
	jabuti = "O jabuti esperto das fábulas indígenas, que vence os mais fortes com astúcia.",
	mula = "Uma mulher amaldiçoada que vira mula sem cabeça, com fogo no lugar do pescoço.",
	fog_amazon = "A Matinta Pereira assobia na escuridão; quem ouve, que deixe fumo para ela.",
	boto = "O boto-cor-de-rosa que vira um moço de chapéu branco nas festas da beira do rio.",
	wisp = "Fogos-fátuos: as chamas azuladas do Boitatá que vagam pelos campos à noite.",
	iara = "A mãe d'água dos rios brasileiros, que encanta com o canto quem se aproxima.",
	boitata = "A cobra de fogo de olhos enormes que protege as matas dos incêndios.",
	cuca = "A velha bruxa com cabeça de jacaré da cantiga de ninar que diz: dorme, neném, que a Cuca vem pegar.",
	funayurei = "Fantasmas de afogados que pedem uma concha para encher os barcos de água.",
	kitsune = "Raposas mágicas que ganham uma cauda a cada século e acendem fogos-fátuos.",
	oni = "Ogros do folclore japonês, de chifres e porrete de ferro.",
	tengu = "Os karasu-tengu, meio homem e meio corvo, guardiões das montanhas.",
	kappa = "Criatura dos rios com um prato d'água na cabeça; se o prato esvazia, perde a força.",
	chochin = "Uma lanterna de papel velha que ganhou vida, com um olho e a língua de fora.",
	fog_japan = "A névoa onde os afogados esperam pelas lanternas do Obon.",
	hitodama = "Almas que saem do corpo como bolas de fogo azulado.",
	wave = "Ondas erguidas pelo monge do mar para engolir os barcos.",
	umibozu = "O monge do mar, uma cabeça escura e gigante que surge das ondas em noites calmas.",
	kyubi = "A raposa de nove caudas, mestra das ilusões, que já enganou imperadores.",
	mummy = "Os mortos preparados para a eternidade, acordados por quem perturba as tumbas.",
	jackal = "Os chacais de Anúbis, que guiam as almas pelo mundo dos mortos.",
	sobek = "Sobek, o deus crocodilo do Nilo, senhor das águas e da força.",
	ibis = "A íbis de Thoth, deus da escrita e da sabedoria.",
	scarab = "O escaravelho sagrado de Khepri, que empurra o sol pelo céu todas as manhãs.",
	ba = "A alma Ba, ave com rosto humano que visita o mundo dos vivos depois da morte.",
	fog_egypt = "Ventos do deserto que levantam areia até apagar o horizonte.",
	cobra = "As najas nascidas das escamas de Apep.",
	sandstone = "Blocos de arenito que a Esfinge faz rolar contra quem erra o enigma.",
	sphinx = "A guardiã dos enigmas: quem não responde certo não passa.",
	apep = "Apep, a serpente do caos que toda noite tenta engolir o barco do sol.",
	shade = "As almas do Hades, que vagam sem descanso quando não têm a moeda para pagar o barqueiro.",
	hellhound = "Os cães do mundo dos mortos, da mesma ninhada de Cérbero, que guarda os portões do Hades.",
	minotaur = "Meio homem, meio touro, preso no labirinto de Creta até ser vencido por Teseu.",
	harpy = "Aves de rosto humano que arrancavam a comida das mãos do rei Fineu.",
	bronze_shield = "Um hoplita de escudo polido como espelho, como o que Perseu usou para não encarar a Medusa.",
	lampad = "As Lâmpades, ninfas do submundo que seguem a deusa Hécate carregando tochas.",
	fog_greece = "A névoa do Estige, o rio que separa o mundo dos vivos do reino dos mortos.",
	gorgon_snake = "As serpentes que formam os cabelos da Medusa e se soltam para caçar sozinhas.",
	marble = "Blocos de mármore que despencam do rochedo de Cila.",
	scylla = "Cila, a ninfa transformada em monstro de seis cabeças que devorava marinheiros no estreito, ao lado de Caríbdis.",
	medusa = "A górgona cujo olhar transforma em pedra qualquer um que a encare.",
	banshee = "A mulher que lamenta à noite e anuncia, com seu grito, uma morte na família.",
	kelpie = "O cavalo d'água dos lagos escoceses, que convida os viajantes a montar e mergulha com eles.",
	fomorian = "Os fomorianos, gigantes do mar e da escuridão, antigos inimigos dos deuses da Irlanda.",
	pooka = "O púca muda de forma, de cavalo a lebre negra, e prega peças em quem anda à noite.",
	selkie = "Focas que tiram a pele para andar como gente; quem esconde a pele prende a selkie em terra.",
	fairy = "As luzes do povo das fadas, que dançam nos círculos de pedra na noite de Samhain.",
	fog_celtic = "A névoa que sobe quando o véu entre o nosso mundo e o Outro Mundo fica fino.",
	peist = "A péist, serpente dos lagos irlandeses que os santos teriam expulsado para o mar.",
	ogham = "Pedras marcadas com a antiga escrita ogham, que a Cailleach deixa cair do avental.",
	balor = "Balor, rei dos fomorianos, cujo único olho destruía tudo o que encarava quando a pálpebra se erguia.",
	cailleach = "A Cailleach, a velha divina do inverno, que traz as tempestades e ergueu as montanhas com pedras.",
}

-- Total de fichas e, se `seen` for dado (tabela arte -> true), quantas abertas.
function Bestiary.count(seen: { [string]: boolean }?): (number, number)
	local opened, all = 0, 0
	for _, list in Bestiary.ENTRIES do
		for _, art in list do
			all += 1
			if seen and seen[art] then
				opened += 1
			end
		end
	end
	return opened, all
end

-- Lista de todas as artes que têm ficha (para Progress validar o que grava).
function Bestiary.has(art: string): boolean
	return Bestiary.LORE[art] ~= nil
end

return Bestiary
