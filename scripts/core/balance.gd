class_name Balance
extends RefCounted
## Todos os números de balanceamento do jogo ficam aqui.
## Ajuste estes valores e rode `tools/autoplay.sh` para ver o efeito.

# --- Partida ---
const RUN_DURATION := 600.0 ## Segundos até o amanhecer (vitória).

# --- Farol ---
const LIGHTHOUSE_MAX_HP := 100.0
const LIGHTHOUSE_RADIUS := 30.0
const ISLAND_RADIUS := 72.0
const ATTACK_INTERVAL := 1.0 ## Intervalo entre ataques de um inimigo encostado no farol.
const LIT_SLOW := 0.55 ## Multiplicador de velocidade de inimigos iluminados.

# --- Feixe principal ---
const BEAM_RANGE := 340.0
const BEAM_HALF_ANGLE_DEG := 14.0
const BEAM_DPS := 24.0
const TURN_SPEED := 2.8 ## Radianos por segundo.
const SECONDARY_LENS_FACTOR := 0.6 ## Dano das lentes extras em relação à principal.

# --- Armas secundárias ---
const SWEEPER_SPEED := 1.6
const PULSE_RADIUS := 170.0
const PULSE_DAMAGE := 18.0

# --- Brasas (XP) ---
const MAGNET_RADIUS := 90.0
const EMBER_LIFETIME := 14.0 ## Base; a dificuldade pode encurtar.
const EMBER_PULL_SPEED := 520.0

# --- Criaturas comuns ---
## Estatísticas por papel; cada mapa dá aparência e nome próprios a cada papel
## (ver Maps). "score" é quanto cada criatura queimada vale.
const ENEMIES := {
	"basic": {"hp": 14.0, "speed": 54.0, "radius": 12.0, "damage": 4.0, "xp": 1, "score": 10},
	"fast": {"hp": 9.0, "speed": 110.0, "radius": 9.0, "damage": 3.0, "xp": 1, "score": 12},
	"brute": {"hp": 55.0, "speed": 28.0, "radius": 20.0, "damage": 10.0, "xp": 4, "score": 40},
	# Criaturas especiais (ver Enemy): ladra de brasas, espelho, mariposa e névoa.
	"thief": {"hp": 16.0, "speed": 95.0, "radius": 11.0, "damage": 0.0, "xp": 1, "score": 25},
	"mirror": {"hp": 30.0, "speed": 38.0, "radius": 15.0, "damage": 8.0, "xp": 3, "score": 35},
	"moth": {"hp": 26.0, "speed": 44.0, "radius": 13.0, "damage": 6.0, "xp": 2, "score": 30},
	"fogbank": {"hp": 90.0, "speed": 26.0, "radius": 70.0, "damage": 0.0, "xp": 3, "score": 50},
	# Lacaios criados por chefes.
	"tentacle": {"hp": 26.0, "speed": 70.0, "radius": 10.0, "damage": 7.0, "xp": 1, "score": 15},
	"boulder": {"hp": 20.0, "speed": 135.0, "radius": 13.0, "damage": 12.0, "xp": 0, "score": 5},
	"decoy": {"hp": 30.0, "speed": 0.38, "radius": 26.0, "damage": 8.0, "xp": 0, "score": 5}, ## Ilusões da Kyūbi.
}

## Criaturas de elite (Médio em diante): mais fortes e valiosas.
const ELITE := {"hp": 3.0, "damage": 1.5, "radius": 1.3, "xp": 4, "score": 3}

# --- Criaturas especiais ---
const THIEF_CARRY := 4 ## Brasas que a ladra rouba antes de fugir.
const THIEF_PATIENCE := 12.0 ## Segundos procurando brasas antes de desistir e fugir.
const MIRROR_CLOSED := 2.6 ## Segundos fechado: a luz não fere e o feixe principal volta em parte para o farol.
const MIRROR_OPEN := 1.8 ## Segundos aberto (vulnerável).
const MIRROR_REFLECT := 0.08 ## Fração do dano do feixe principal refletida no farol.
const MOTH_GROW := 0.5 ## Crescimento por segundo enquanto iluminada.
const MOTH_MAX := 1.5 ## Crescimento máximo (dano e brasas crescem junto).
const FOGBANK_START := 150.0 ## Primeira névoa devoradora.
const FOGBANK_EVERY := 70.0
const FOGBANK_DRAIN := 5.0 ## Brasas dentro da névoa somem este tanto mais rápido.

# --- Chefes ---
## Vida e recompensas; os números de cada mecânica ficam junto do chefe.
const BOSSES := {
	"leviathan": {"hp": 650.0, "speed": 0.32, "radius": 30.0, "damage": 10.0, "xp": 30,
		"dive_every": 9.0, "dive_time": 2.6, "start_radius": 430.0},
	"kraken": {"hp": 900.0, "speed": 40.0, "radius": 46.0, "damage": 10.0, "xp": 40,
		"stand": 310.0, "spawn_every": 3.0, "ink_every": 11.0, "ink_time": 3.5, "ink_range": 0.55},
	"jotunn": {"hp": 760.0, "speed": 22.0, "radius": 36.0, "damage": 14.0, "xp": 30,
		"stand": 250.0, "throw_every": 3.2, "advance": 18.0},
	"fenrir": {"hp": 820.0, "speed": 0.9, "radius": 30.0, "damage": 18.0, "xp": 40,
		"circle": 270.0, "charge_every": 6.5, "telegraph": 1.1, "dash_speed": 520.0, "dodge_after": 0.6, "dodge_cooldown": 2.5},
	"iara": {"hp": 700.0, "speed": 0.3, "radius": 26.0, "damage": 0.0, "xp": 30,
		"stand": 285.0, "sing_every": 9.0, "sing_time": 4.0, "pull": 1.7, "spawn_every": 1.1},
	"boitata": {"hp": 820.0, "speed": 0.42, "radius": 28.0, "damage": 16.0, "xp": 40,
		"start_radius": 430.0, "blaze_time": 6.5, "dim_time": 3.5, "wisp_every": 1.8, "dim_damage": 1.6, "approach": 12.0},
	"cuca": {"hp": 850.0, "speed": 40.0, "radius": 30.0, "damage": 0.0, "xp": 40,
		"stand": 290.0, "cast_every": 7.0, "cast_time": 2.4, "interrupt": 0.08, "sleep_time": 4.5, "sleep_power": 0.35},
	"umibozu": {"hp": 760.0, "speed": 18.0, "radius": 44.0, "damage": 18.0, "xp": 30,
		"stand": 320.0, "reveal": 0.8, "wave_every": 4.0, "advance": 14.0},
	"kyubi": {"hp": 760.0, "speed": 0.38, "radius": 28.0, "damage": 0.0, "xp": 40,
		"stand": 290.0, "illusion_every": 10.0, "decoys": 3, "fire_every": 2.6},
	"sphinx": {"hp": 820.0, "speed": 30.0, "radius": 40.0, "damage": 0.0, "xp": 30,
		"stand": 300.0, "riddle_every": 9.0, "riddle_time": 6.0, "answer": 1.1, "weak_time": 5.0,
		"weak_damage": 2.0, "strong_damage": 0.5, "punish_stones": 4},
	"apep": {"hp": 900.0, "speed": 0.36, "radius": 30.0, "damage": 16.0, "xp": 40,
		"start_radius": 430.0, "approach": 11.0, "eat_range": 0.4, "spawn_every": 2.8},
}
const BOSS_TIMES := [300.0, 540.0] ## Momentos dos chefes (o mapa diz quem aparece).
const BOSS_WARNING := 8.0 ## Segundos de aviso antes de um chefe surgir.
const BOSS_HEAL := 25.0 ## Vida recuperada ao derrotar um chefe.
const ENRAGE_AT := 0.5 ## Fração de vida em que chefes enfurecem (dificuldades com "enrage").
const ENRAGE_SPEED := 1.4 ## Multiplicador de velocidade e ritmo dos chefes enfurecidos.

## Relíquia deixada por cada chefe (aplicada em Upgrades.apply_relic).
const RELICS := {
	"leviathan": {"name": "Escama do Leviatã", "desc": "+40 de vida máxima e cura total."},
	"kraken": {"name": "Olho do Kraken", "desc": "Feixe alcança 20% mais longe."},
	"jotunn": {"name": "Coração de Gelo", "desc": "Criaturas iluminadas ficam ainda mais lentas."},
	"fenrir": {"name": "Presa de Fenrir", "desc": "Feixe gira 30% mais rápido e causa 15% mais dano."},
	"iara": {"name": "Pérola da Iara", "desc": "Brasas são puxadas de 50% mais longe e o farol regenera 0,5 de vida por segundo."},
	"boitata": {"name": "Olho do Boitatá", "desc": "Toda a luz causa 25% mais dano."},
	"cuca": {"name": "Caldeirão da Cuca", "desc": "Habilidades recarregam 30% mais rápido."},
	"umibozu": {"name": "Balde sem fundo", "desc": "Ganha mais um feixe ao redor do farol."},
	"kyubi": {"name": "Hoshi no tama", "desc": "A luz causa 20% mais dano e gira 15% mais rápido."},
	"sphinx": {"name": "Olho de Hórus", "desc": "Ganha um nível de Pulso de luz."},
	"apep": {"name": "Escama de Apep", "desc": "Criaturas iluminadas ficam 25% mais lentas e o feixe alcança 10% mais longe."},
}

# --- Habilidades ativas ---
const ABILITIES := [
	{"id": "flash", "name": "Clarão", "desc": "Explosão de luz que fere e atordoa tudo por perto.",
		"cooldown": 24.0, "radius": 230.0, "damage": 60.0, "stun": 2.0},
	{"id": "overcharge", "name": "Sobrecarga", "desc": "O feixe principal fica concentrado e muito mais forte por alguns segundos.",
		"cooldown": 20.0, "duration": 5.0, "dps": 2.5, "range": 1.3, "angle": 0.6},
	{"id": "bell", "name": "Sino da Névoa", "desc": "Puxa todas as brasas para o farol e recupera um pouco de vida.",
		"cooldown": 30.0, "heal": 10.0},
	# Liberadas na oficina; o jogador escolhe três (Settings.loadout).
	{"id": "mirror", "name": "Espelho", "desc": "Um segundo feixe aponta para o lado oposto por alguns segundos.",
		"cooldown": 22.0, "duration": 6.0},
	{"id": "tide", "name": "Maré", "desc": "Uma onda empurra para longe as criaturas perto do farol.",
		"cooldown": 24.0, "radius": 320.0, "push": 150.0, "stun": 0.6},
	{"id": "beacon", "name": "Sinalizador", "desc": "Dois feixes giram sozinhos em volta do farol por alguns segundos.",
		"cooldown": 26.0, "duration": 8.0, "spin": 3.0, "dps": 0.6},
]

# --- Dificuldade ---
## Multiplicadores e regras. "xp" multiplica o XP necessário por nível,
## "ember_life" é quanto as brasas duram, "elite" a chance de uma criatura vir
## como elite, "enrage" faz chefes enfurecerem, "extra_boss" soma um chefe aos
## 7:00 e "fog" deixa a névoa mais densa. "normal" é a referência do autoplay.
const DIFFICULTIES := {
	"easy": {"name": "Fácil", "desc": "Criaturas frágeis, brasas duram mais e o farol é mais resistente. Para aprender a mirar.",
		"enemy_hp": 0.8, "enemy_damage": 0.7, "enemy_speed": 0.95, "spawn": 0.9, "xp": 1.0, "ember_life": 15.0,
		"elite": 0.0, "enrage": false, "extra_boss": false, "lighthouse_hp": 1.15, "fog": 0.85, "score": 0.5},
	"normal": {"name": "Normal", "desc": "A noite como ela foi pensada. Mire entre queimar e recolher brasas.",
		"enemy_hp": 1.0, "enemy_damage": 1.0, "enemy_speed": 1.0, "spawn": 1.0, "xp": 1.0, "ember_life": 14.0,
		"elite": 0.0, "enrage": false, "extra_boss": false, "lighthouse_hp": 1.0, "fog": 1.0, "score": 1.0},
	"medium": {"name": "Médio", "desc": "Surgem criaturas de elite e as brasas somem mais cedo.",
		"enemy_hp": 1.1, "enemy_damage": 1.12, "enemy_speed": 1.04, "spawn": 1.08, "xp": 1.08, "ember_life": 11.0,
		"elite": 0.04, "enrage": false, "extra_boss": false, "lighthouse_hp": 1.0, "fog": 1.1, "score": 1.3},
	"hard": {"name": "Difícil", "desc": "Mais elites, brasas fugazes e chefes que enfurecem com metade da vida.",
		"enemy_hp": 1.25, "enemy_damage": 1.3, "enemy_speed": 1.08, "spawn": 1.2, "xp": 1.15, "ember_life": 9.0,
		"elite": 0.08, "enrage": true, "extra_boss": false, "lighthouse_hp": 1.0, "fog": 1.2, "score": 1.7},
	"impossible": {"name": "Impossível", "desc": "Farol frágil, névoa densa, hordas de elite e um chefe a mais. Quase ninguém vê o amanhecer.",
		"enemy_hp": 1.8, "enemy_damage": 2.0, "enemy_speed": 1.2, "spawn": 1.5, "xp": 1.35, "ember_life": 6.0,
		"elite": 0.15, "enrage": true, "extra_boss": true, "lighthouse_hp": 0.75, "fog": 1.45, "score": 2.5},
}
const DIFFICULTY_ORDER := ["easy", "normal", "medium", "hard", "impossible"]
const EXTRA_BOSS_TIME := 420.0
const DIFFICULTY_RAMP := 180.0 ## Segundos até os aumentos da dificuldade valerem por inteiro.
const ELITE_START := 60.0 ## Elites só aparecem depois disto.


## Valor de uma regra da dificuldade no tempo t. O que facilita (< 1) vale
## desde o início; o que dificulta cresce do Normal até o valor cheio em
## DIFFICULTY_RAMP segundos, para o começo não ser injusto.
static func difficulty_value(difficulty: String, key: String, t: float) -> float:
	var v: float = DIFFICULTIES[difficulty][key]
	if key == "elite":
		return v * clampf((t - ELITE_START) / DIFFICULTY_RAMP, 0.0, 1.0)
	if v <= 1.0:
		return v
	return lerpf(1.0, v, clampf(t / DIFFICULTY_RAMP, 0.0, 1.0))

# --- Modo sem fim (depois do amanhecer) ---
const ENDLESS_BOSS_FIRST := 60.0 ## Segundos até o primeiro chefe da nova noite.
const ENDLESS_BOSS_EVERY := 150.0
const ENDLESS_FOGBANK_EVERY := 45.0
const MAX_ENEMIES := 240 ## Teto de criaturas vivas (protege o desempenho nas noites longas).

# --- Pontuação ---
const SCORE_PER_SECOND := 5
const SCORE_PER_BOSS := 1500
const SCORE_VICTORY := 5000
const SCORE_HEALTH_BONUS := 2000 ## Ao amanhecer, proporcional à vida restante.
const SCORE_ENDLESS_PER_SECOND := 10 ## Depois do amanhecer, cada segundo vale o dobro.
const SCORE_PER_NIGHT := 4000 ## Cada noite extra sobrevivida no modo sem fim.

# --- Melhorias desbloqueáveis ---
const VITAL_EMBER_HEAL := 0.4 ## Vida por brasa recolhida, por nível de Brasas vitais.
const COMBUSTION_RADIUS := 70.0 ## + 15 por nível da melhoria Combustão.
const COMBUSTION_DAMAGE := 10.0 ## Por nível, escalado pelo dano da luz.

# --- Progressão entre partidas ---
const OIL_PER_SCORE := 0.005 ## Óleo ganho por ponto ao fim de cada partida.
const OIL_MIN := 5
const OIL_TUTORIAL := 50

## Melhorias permanentes da oficina. Custo do nível n = cost × n.
const META := [
	{"id": "granite", "name": "Paredes de granito", "desc": "+10 de vida máxima por nível.", "max": 5, "cost": 60},
	{"id": "polish", "name": "Lente polida", "desc": "+5% de dano da luz por nível.", "max": 5, "cost": 80},
	{"id": "fine_gears", "name": "Engrenagens finas", "desc": "+6% de velocidade de giro por nível.", "max": 3, "cost": 70},
	{"id": "long_wick", "name": "Pavio longo", "desc": "Brasas duram 1,5 s a mais por nível.", "max": 3, "cost": 60},
	{"id": "copper", "name": "Ímã de cobre", "desc": "Brasas são puxadas de 10% mais longe por nível.", "max": 3, "cost": 60},
	{"id": "reroll", "name": "Segunda opinião", "desc": "+1 troca de cartas por partida, por nível.", "max": 3, "cost": 90},
	{"id": "banish", "name": "Lista negra", "desc": "+1 banimento de carta por partida, por nível.", "max": 2, "cost": 120},
	{"id": "fourth_card", "name": "Olhar atento", "desc": "Uma carta a mais em cada escolha de melhoria.", "max": 1, "cost": 400},
	{"id": "head_start", "name": "Pavio aceso", "desc": "Começa a partida com uma melhoria aleatória.", "max": 1, "cost": 250},
	{"id": "fisher", "name": "Sorte do pescador", "desc": "+10% de óleo ganho por nível.", "max": 3, "cost": 100},
]
const BASE_REROLLS := 1
const BASE_BANISHES := 0

## Desbloqueios: por óleo, ou de graça ao cumprir a meta ("goal").
## Metas: "midnight" (sobreviver até a meia-noite), "boss" (derrotar um
## chefe), "dawn" (ver o amanhecer), "dawn_medium" (amanhecer no Médio ou acima).
const UNLOCKS := [
	{"id": "fjord", "kind": "map", "cost": 150, "goal": "midnight"},
	{"id": "amazon", "kind": "map", "cost": 300, "goal": "boss"},
	{"id": "japan", "kind": "map", "cost": 400, "goal": "dawn"},
	{"id": "egypt", "kind": "map", "cost": 500, "goal": "dawn_medium"},
	{"id": "stone", "kind": "keeper", "cost": 80, "goal": ""},
	{"id": "iron", "kind": "keeper", "cost": 160, "goal": ""},
	{"id": "crystal", "kind": "keeper", "cost": 240, "goal": "dawn"},
	{"id": "combustion", "kind": "upgrade", "cost": 200, "goal": ""},
	{"id": "vital_embers", "kind": "upgrade", "cost": 200, "goal": ""},
	{"id": "monk", "kind": "hero", "cost": 150, "goal": ""},
	{"id": "pirate", "kind": "hero", "cost": 200, "goal": ""},
	{"id": "astronomer", "kind": "hero", "cost": 250, "goal": ""},
	{"id": "fisher", "kind": "hero", "cost": 150, "goal": ""},
	{"id": "mirror", "kind": "ability", "cost": 180, "goal": ""},
	{"id": "tide", "kind": "ability", "cost": 180, "goal": ""},
	{"id": "beacon", "kind": "ability", "cost": 180, "goal": ""},
]


static func xp_for_level(level: int, difficulty: String = "normal") -> int:
	var base := 6 + level * 6 + int(level * level * 0.3)
	return maxi(1, ceili(base * float(DIFFICULTIES[difficulty]["xp"])))


## Pontuação em partes fáceis de ler: criaturas, tempo e bônus, depois a
## dificuldade multiplica o subtotal. O tempo depois do amanhecer (modo sem
## fim) entra em "endless", com noites extras valendo bônus.
## No Modo Chefões o tempo conta ao contrário: terminar rápido vale mais.
## Cada maré soma TIDE_SCORE ao multiplicador.
static func score_breakdown(kill_points: int, bosses: int, seconds: float, victory: bool, hp_fraction: float, difficulty: String, tide_level: int = 0, rush: bool = false) -> Dictionary:
	var survival := int(minf(seconds, RUN_DURATION)) * SCORE_PER_SECOND
	if rush:
		survival = int(maxf(0.0, BOSS_RUSH_PAR - seconds)) * SCORE_RUSH_PER_SECOND if victory else 0
	var extra := maxf(0.0, seconds - RUN_DURATION)
	var endless := 0 if rush else int(extra) * SCORE_ENDLESS_PER_SECOND + int(extra / RUN_DURATION) * SCORE_PER_NIGHT
	var boss_bonus := bosses * SCORE_PER_BOSS
	var win := SCORE_VICTORY if victory else 0
	var health := roundi(SCORE_HEALTH_BONUS * clampf(hp_fraction, 0.0, 1.0)) if victory else 0
	var subtotal := kill_points + survival + endless + boss_bonus + win + health
	var mult: float = float(DIFFICULTIES[difficulty]["score"]) * (1.0 + TIDE_SCORE * tide_level)
	return {
		"kills": kill_points, "survival": survival, "endless": endless, "bosses": boss_bonus, "victory": win, "health": health,
		"subtotal": subtotal, "multiplier": mult, "total": roundi(subtotal * mult),
	}


## Chefes ("boss") ignoram metade da escala de vida.
static func hp_multiplier(t: float) -> float:
	return 1.0 + t / 300.0 + pow(t / 520.0, 2.0)


static func spawn_interval(t: float) -> float:
	return maxf(0.2, 0.8 - t * 0.0011)


static func group_size(t: float) -> int:
	return 1 + int(t / 160.0)


static func spawn_weights(t: float) -> Dictionary:
	var w := {"basic": 10.0}
	if t >= 45.0:
		w["fast"] = minf(6.0, (t - 45.0) / 15.0)
	if t >= 120.0:
		w["brute"] = minf(3.0, (t - 120.0) / 90.0)
	if t >= 90.0:
		w["thief"] = minf(1.0, (t - 90.0) / 60.0)
	if t >= 160.0:
		w["mirror"] = minf(1.0, (t - 160.0) / 120.0)
	if t >= 210.0:
		w["moth"] = minf(1.0, (t - 210.0) / 120.0)
	return w


static func pulse_cooldown(level: int) -> float:
	return maxf(2.0, 6.0 - level * 0.8)


# --- Faroleiros jogáveis ---
## Cada faroleiro muda as regras do farol (a aparência continua em Keepers).
## Chaves: lens (lentes extras), dps, range, width (largura do feixe), hp
## (vida somada), pulse (nível inicial do Pulso), magnet, xp (XP por nível).
const HEROES := {
	"keeper": {"name": "Faroleira", "desc": "Equilibrada: nenhuma vantagem, nenhuma desvantagem."},
	"monk": {"name": "Monge", "desc": "Começa com duas lentes extras, mas a luz causa 30% menos dano.", "lens": 2, "dps": 0.7},
	"pirate": {"name": "Pirata", "desc": "Feixe curto e forte: 30% menos alcance, 50% mais dano e 30 de vida a mais.", "range": 0.7, "dps": 1.5, "hp": 30.0},
	"astronomer": {"name": "Astrônoma", "desc": "Começa com Pulso de luz nível 2, mas o feixe é 30% mais estreito.", "pulse": 2, "width": 0.7},
	"fisher": {"name": "Pescador", "desc": "Puxa brasas de muito mais longe e sobe de nível 15% mais rápido, com 20 de vida a menos.", "magnet": 1.8, "xp": 0.85, "hp": -20.0},
}
const HERO_ORDER := ["keeper", "monk", "pirate", "astronomer", "fisher"]

# --- Marés (níveis de desafio depois de ver o amanhecer) ---
## Cumulativas: a Maré N soma as regras de 1 até N.
const TIDES := [
	{"desc": "Criaturas 10% mais rápidas.", "speed": 1.1},
	{"desc": "Brasas duram 25% menos.", "ember": 0.75},
	{"desc": "Chefes chegam 1 minuto antes.", "boss_early": 60.0},
	{"desc": "Mais criaturas de elite.", "elite": 0.05},
	{"desc": "Farol com 15% menos vida.", "lighthouse": 0.85},
	{"desc": "Uma troca de cartas a menos.", "reroll": -1},
	{"desc": "Criaturas com 15% mais vida.", "hp": 1.15},
	{"desc": "Névoa mais densa.", "fog": 0.25},
	{"desc": "Chefes enfurecem com 75% da vida.", "enrage": 0.75},
	{"desc": "Chefes derrotados não curam o farol.", "no_heal": 1.0},
]
const TIDE_SCORE := 0.15 ## Pontuação extra por nível de maré.


## Efeito somado das marés até `level`. Multiplicadores começam em 1, somas em 0.
static func tide(level: int, key: String) -> float:
	var multiply := key in ["speed", "ember", "lighthouse", "hp"]
	var v := 1.0 if multiply else 0.0
	if key == "enrage":
		v = ENRAGE_AT
	for i in mini(level, TIDES.size()):
		var t: Dictionary = TIDES[i]
		if not t.has(key):
			continue
		if multiply:
			v *= float(t[key])
		elif key == "enrage":
			v = maxf(v, float(t[key]))
		else:
			v += float(t[key])
	return v

# --- Modo Chefões ---
const BOSS_RUSH_PAUSE := 6.0 ## Segundos entre um chefe e o próximo.
const BOSS_RUSH_START_PICKS := 6 ## Melhorias escolhidas antes do primeiro chefe.
const BOSS_RUSH_PAR := 900.0 ## Abaixo disto, cada segundo poupado vale pontos.
const SCORE_RUSH_PER_SECOND := 10
