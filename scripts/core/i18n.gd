class_name I18n
extends RefCounted
## Traduções feitas em código. A chave é o próprio texto em português; cada
## entrada traz [inglês, espanhol]. Para traduzir um texto novo: use tr("...")
## (ou TranslationServer.translate em funções estáticas) e adicione a linha
## aqui. Textos de dados (melhorias, dificuldades, eventos) também entram.

const LANGUAGE_NAMES := {"pt_BR": "Português", "en": "English", "es": "Español"}

const TEXTS := {
	# Menu principal e navegação
	"Jogar": ["Play", "Jugar"],
	"Histórico": ["History", "Historial"],
	"Ranking": ["Leaderboard", "Clasificación"],
	"Configurações": ["Settings", "Ajustes"],
	"Sair": ["Quit", "Salir"],
	"Voltar": ["Back", "Volver"],
	"As criaturas da névoa temem a luz. Resista até o amanhecer.": ["The creatures of the fog fear the light. Hold out until dawn.", "Las criaturas de la niebla temen la luz. Resiste hasta el amanecer."],
	"Mouse, A/D ou analógico: girar o feixe   •   Esc: pausar": ["Mouse, A/D or stick: turn the beam   •   Esc: pause", "Ratón, A/D o stick: girar el haz   •   Esc: pausa"],
	# Dificuldade
	"Escolha a dificuldade": ["Choose the difficulty", "Elige la dificultad"],
	"Nome do faroleiro:": ["Keeper's name:", "Nombre del farero:"],
	"Nome do faroleiro": ["Keeper's name", "Nombre del farero"],
	"Pontuação ×%s": ["Score ×%s", "Puntuación ×%s"],
	"A/D ou ←/→ para escolher   •   Enter ou clique para começar   •   Esc para voltar": ["A/D or ←/→ to choose   •   Enter or click to start   •   Esc to go back", "A/D o ←/→ para elegir   •   Enter o clic para empezar   •   Esc para volver"],
	"Fácil": ["Easy", "Fácil"],
	"Normal": ["Normal", "Normal"],
	"Difícil": ["Hard", "Difícil"],
	"Criaturas mais frágeis e menos dano. Bom para aprender a mirar.": ["Weaker creatures that deal less damage. Good for learning to aim.", "Criaturas más frágiles y con menos daño. Ideal para aprender a apuntar."],
	"A noite como ela foi pensada. Exige atenção ao feixe e às brasas.": ["The night as it was meant to be. Mind both the beam and the embers.", "La noche tal como fue pensada. Atención al haz y a las brasas."],
	"Mais criaturas, mais resistentes e mais agressivas. Para quem já domina a luz.": ["More creatures, tougher and more aggressive. For those who have mastered the light.", "Más criaturas, más resistentes y más agresivas. Para quien ya domina la luz."],
	# Subir de nível e melhorias
	"Nível %d!": ["Level %d!", "¡Nivel %d!"],
	"Escolha uma melhoria": ["Choose an upgrade", "Elige una mejora"],
	"Novo!": ["New!", "¡Nuevo!"],
	"Nível %d → %d": ["Level %d → %d", "Nivel %d → %d"],
	"A/D ou ←/→ para navegar   •   Enter, Espaço, 1-3 ou clique para escolher": ["A/D or ←/→ to browse   •   Enter, Space, 1-3 or click to choose", "A/D o ←/→ para navegar   •   Enter, Espacio, 1-3 o clic para elegir"],
	"Lente ampla": ["Wide Lens", "Lente amplia"],
	"Lente de longo alcance": ["Long-Range Lens", "Lente de largo alcance"],
	"Chama intensa": ["Intense Flame", "Llama intensa"],
	"Engrenagens lubrificadas": ["Oiled Gears", "Engranajes lubricados"],
	"Lente extra": ["Extra Lens", "Lente extra"],
	"Pulso de luz": ["Light Pulse", "Pulso de luz"],
	"Farolete giratório": ["Spinning Lantern", "Farolillo giratorio"],
	"Paredes reforçadas": ["Reinforced Walls", "Muros reforzados"],
	"Faroleiro dedicado": ["Devoted Keeper", "Farero dedicado"],
	"Correntes quentes": ["Warm Currents", "Corrientes cálidas"],
	"Óleo fresco": ["Fresh Oil", "Aceite fresco"],
	"Feixe 20% mais largo.": ["Beam 20% wider.", "Haz un 20% más ancho."],
	"Feixe alcança 15% mais longe.": ["Beam reaches 15% farther.", "El haz llega un 15% más lejos."],
	"Toda a luz causa 25% mais dano.": ["All light deals 25% more damage.", "Toda la luz causa un 25% más de daño."],
	"O feixe gira 25% mais rápido.": ["The beam turns 25% faster.", "El haz gira un 25% más rápido."],
	"Adiciona mais um feixe, distribuído ao redor do farol.": ["Adds another beam, spread around the lighthouse.", "Añade otro haz, repartido alrededor del faro."],
	"Uma onda de luz periódica queima tudo ao redor.": ["A periodic wave of light burns everything around.", "Una onda de luz periódica quema todo alrededor."],
	"Um feixe menor que gira sozinho.": ["A smaller beam that spins on its own.", "Un haz más pequeño que gira solo."],
	"+25 de vida máxima e recupera 25.": ["+25 max health and restores 25.", "+25 de vida máxima y recupera 25."],
	"Regenera 0,6 de vida por segundo.": ["Regenerates 0.6 health per second.", "Regenera 0,6 de vida por segundo."],
	"Brasas são puxadas de 40% mais longe.": ["Embers are pulled from 40% farther away.", "Las brasas se atraen desde un 40% más lejos."],
	"Recupera 30 de vida.": ["Restores 30 health.", "Recupera 30 de vida."],
	# HUD e avisos
	"Farol": ["Lighthouse", "Faro"],
	"pontos": ["points", "puntos"],
	"%s criaturas queimadas": ["%s creatures burned", "%s criaturas quemadas"],
	"%d / %d XP   (%d%%)   —   próximo nível: %d": ["%d / %d XP   (%d%%)   —   next level: %d", "%d / %d XP   (%d%%)   —   siguiente nivel: %d"],
	"Amanhecer em %s": ["Dawn in %s", "Amanecer en %s"],
	"O Leviatã emergiu das profundezas!": ["The Leviathan rises from the deep!", "¡El Leviatán emergió de las profundidades!"],
	"Nuvens pesadas se aproximam...": ["Heavy clouds are rolling in...", "Se acercan nubes pesadas..."],
	"O céu começa a clarear. Aguente firme!": ["The sky begins to brighten. Hold on!", "El cielo empieza a aclarar. ¡Aguanta!"],
	# Pausa e fim de partida
	"Pausado": ["Paused", "En pausa"],
	"Continuar": ["Resume", "Continuar"],
	"Recomeçar": ["Restart", "Reiniciar"],
	"Menu principal": ["Main menu", "Menú principal"],
	"Sair do jogo": ["Quit game", "Salir del juego"],
	"Nenhuma": ["None", "Ninguna"],
	"Amanheceu!": ["Dawn has come!", "¡Amaneció!"],
	"A luz se apagou": ["The light went out", "La luz se apagó"],
	"O farol resistiu à noite inteira.": ["The lighthouse held out all night.", "El faro resistió toda la noche."],
	"A névoa tomou a ilha desta vez.": ["The fog took the island this time.", "La niebla tomó la isla esta vez."],
	"Novo recorde!": ["New record!", "¡Nuevo récord!"],
	"Tempo": ["Time", "Tiempo"],
	"Nível": ["Level", "Nivel"],
	"Nível %d": ["Level %d", "Nivel %d"],
	"Criaturas queimadas": ["Creatures burned", "Criaturas quemadas"],
	"Pontos (criaturas + tempo%s)": ["Points (creatures + time%s)", "Puntos (criaturas + tiempo%s)"],
	" + vitória + vida": [" + victory + health", " + victoria + vida"],
	"Posição no ranking (%s): #%d de %d": ["Leaderboard position (%s): #%d of %d", "Posición en la clasificación (%s): #%d de %d"],
	"Jogar de novo": ["Play again", "Jugar de nuevo"],
	"Ver ranking": ["View leaderboard", "Ver clasificación"],
	# Histórico
	"Histórico de partidas": ["Match history", "Historial de partidas"],
	"Nenhuma partida ainda. Acenda o farol!": ["No matches yet. Light the lighthouse!", "Aún no hay partidas. ¡Enciende el faro!"],
	"%d partidas registradas": ["%d matches recorded", "%d partidas registradas"],
	"Vitória": ["Victory", "Victoria"],
	"Derrota": ["Defeat", "Derrota"],
	"%s pts": ["%s pts", "%s pts"],
	"Partida de %s": ["Match on %s", "Partida del %s"],
	"Jogador": ["Player", "Jugador"],
	"Resultado": ["Result", "Resultado"],
	"Vitória — amanheceu": ["Victory — dawn came", "Victoria — amaneció"],
	"Derrota — a luz se apagou": ["Defeat — the light went out", "Derrota — la luz se apagó"],
	"Dificuldade": ["Difficulty", "Dificultad"],
	"Duração": ["Duration", "Duración"],
	"Nível alcançado": ["Level reached", "Nivel alcanzado"],
	"Pontuação final": ["Final score", "Puntuación final"],
	"Posição no ranking (%s)": ["Leaderboard position (%s)", "Posición en la clasificación (%s)"],
	"Como a pontuação foi formada": ["Score breakdown", "Cómo se formó la puntuación"],
	"Criaturas": ["Creatures", "Criaturas"],
	"Sobrevivência": ["Survival", "Supervivencia"],
	"Vida restante": ["Remaining health", "Vida restante"],
	"Multiplicador da dificuldade": ["Difficulty multiplier", "Multiplicador de dificultad"],
	"Habilidades escolhidas (%d)": ["Upgrades chosen (%d)", "Mejoras elegidas (%d)"],
	# Ranking
	"Todas": ["All", "Todas"],
	"Pontos": ["Points", "Puntos"],
	"Data": ["Date", "Fecha"],
	"Nenhuma partida nesta categoria ainda.": ["No matches in this category yet.", "Aún no hay partidas en esta categoría."],
	"Sua melhor posição (%s): #%d de %d": ["Your best position (%s): #%d of %d", "Tu mejor posición (%s): #%d de %d"],
	"%s ainda não tem partidas nesta categoria.": ["%s has no matches in this category yet.", "%s aún no tiene partidas en esta categoría."],
	"Pontuação: criaturas queimadas (%s pontos cada, conforme o tipo) + %d por segundo sobrevivido + %s pela vitória + até %s pela vida restante ao amanhecer, multiplicado pela dificuldade (%s).": [
		"Score: creatures burned (%s points each, by type) + %d per second survived + %s for victory + up to %s for health left at dawn, multiplied by difficulty (%s).",
		"Puntuación: criaturas quemadas (%s puntos cada una, según el tipo) + %d por segundo sobrevivido + %s por la victoria + hasta %s por la vida restante al amanecer, multiplicado por la dificultad (%s)."],
	"Ranking deste computador. O ranking online chega com a versão da Steam.": ["Leaderboard for this computer. Online leaderboards arrive with the Steam version.", "Clasificación de este ordenador. La clasificación en línea llegará con la versión de Steam."],
	# Configurações
	"Geral": ["General", "General"],
	"Gráficos": ["Graphics", "Gráficos"],
	"Áudio": ["Audio", "Audio"],
	"Idioma": ["Language", "Idioma"],
	"Qualidade visual": ["Visual quality", "Calidad visual"],
	"Baixa": ["Low", "Baja"],
	"Média": ["Medium", "Media"],
	"Alta": ["High", "Alta"],
	"Tela cheia": ["Fullscreen", "Pantalla completa"],
	"Sincronização vertical (VSync)": ["Vertical sync (VSync)", "Sincronización vertical (VSync)"],
	"Tremor de tela": ["Screen shake", "Temblor de pantalla"],
	"Ligado": ["On", "Activado"],
	"Desligado": ["Off", "Desactivado"],
	"Qualidade baixa reduz névoa, ondas, chuva e faíscas para PCs mais fracos.": ["Low quality reduces fog, waves, rain and sparks for weaker PCs.", "La calidad baja reduce niebla, olas, lluvia y chispas para PCs más modestos."],
	"Volume geral": ["Master volume", "Volumen general"],
	"Trilha sonora": ["Music", "Música"],
	"Efeitos sonoros": ["Sound effects", "Efectos de sonido"],
	"Som de dano": ["Damage sound", "Sonido de daño"],
	"Arraste até 0% para desativar um canal.": ["Drag to 0% to turn a channel off.", "Arrastra hasta 0% para desactivar un canal."],
}


static func setup() -> void:
	# pt_BR também ganha uma tradução (identidade); sem ela, o Godot cairia no
	# idioma de fallback (inglês) quando o jogo estivesse em português.
	var pt := Translation.new()
	pt.locale = "pt_BR"
	var en := Translation.new()
	en.locale = "en"
	var es := Translation.new()
	es.locale = "es"
	for key: String in TEXTS:
		pt.add_message(key, key)
		en.add_message(key, TEXTS[key][0])
		es.add_message(key, TEXTS[key][1])
	for t in [pt, en, es]:
		TranslationServer.add_translation(t)
