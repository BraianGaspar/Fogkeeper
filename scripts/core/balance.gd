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
const EMBER_LIFETIME := 14.0
const EMBER_PULL_SPEED := 520.0

# --- Inimigos ---
## "score" é quanto cada criatura queimada vale na pontuação.
const ENEMIES := {
	"mist": {"hp": 14.0, "speed": 54.0, "radius": 12.0, "damage": 4.0, "xp": 1, "score": 10, "color": Color(0.32, 0.22, 0.45)},
	"runner": {"hp": 9.0, "speed": 110.0, "radius": 9.0, "damage": 3.0, "xp": 1, "score": 12, "color": Color(0.2, 0.3, 0.46)},
	"brute": {"hp": 55.0, "speed": 28.0, "radius": 20.0, "damage": 10.0, "xp": 4, "score": 40, "color": Color(0.42, 0.18, 0.3)},
	"leviathan": {"hp": 650.0, "speed": 20.0, "radius": 38.0, "damage": 10.0, "boss": true, "xp": 30, "score": 750, "color": Color(0.26, 0.12, 0.36)},
}
const BOSS_TIMES := [300.0, 540.0] ## Momentos em que um Leviatã aparece.

# --- Dificuldade ---
## Multiplicadores sobre os valores acima. "spawn" acelera a criação de inimigos,
## "xp" reduz o XP necessário por nível e "score" multiplica a pontuação final.
## "normal" é a referência do autoplay: mantenha tudo em 1.0.
const DIFFICULTIES := {
	"easy": {"name": "Fácil", "desc": "Criaturas mais frágeis e menos dano. Bom para aprender a mirar.",
		"enemy_hp": 0.7, "enemy_damage": 0.6, "spawn": 0.8, "xp": 1.2, "score": 0.5},
	"normal": {"name": "Normal", "desc": "A noite como ela foi pensada. Exige atenção ao feixe e às brasas.",
		"enemy_hp": 1.0, "enemy_damage": 1.0, "spawn": 1.0, "xp": 1.0, "score": 1.0},
	"hard": {"name": "Difícil", "desc": "Mais criaturas, mais resistentes e mais agressivas. Para quem já domina a luz.",
		"enemy_hp": 1.3, "enemy_damage": 1.35, "spawn": 1.2, "xp": 0.9, "score": 1.6},
}
const DIFFICULTY_ORDER := ["easy", "normal", "hard"]

# --- Pontuação ---
const SCORE_PER_SECOND := 5
const SCORE_VICTORY := 5000
const SCORE_HEALTH_BONUS := 2000 ## Ao amanhecer, proporcional à vida restante.


static func xp_for_level(level: int, difficulty: String = "normal") -> int:
	var base := 5 + level * 4 + int(level * level * 0.15)
	return maxi(1, ceili(base / float(DIFFICULTIES[difficulty]["xp"])))


## Pontuação = (criaturas + sobrevivência + vitória + vida) × dificuldade.
static func score_breakdown(kill_points: int, seconds: float, victory: bool, hp_fraction: float, difficulty: String) -> Dictionary:
	var survival := int(seconds) * SCORE_PER_SECOND
	var win := SCORE_VICTORY if victory else 0
	var health := roundi(SCORE_HEALTH_BONUS * clampf(hp_fraction, 0.0, 1.0)) if victory else 0
	var mult: float = DIFFICULTIES[difficulty]["score"]
	return {
		"kills": kill_points, "survival": survival, "victory": win, "health": health,
		"multiplier": mult, "total": roundi((kill_points + survival + win + health) * mult),
	}


## Chefes ("boss": true) ignoram metade da escala de vida.
static func hp_multiplier(t: float) -> float:
	return 1.0 + t / 300.0 + pow(t / 520.0, 2.0)


static func spawn_interval(t: float) -> float:
	return maxf(0.2, 0.8 - t * 0.0011)


static func group_size(t: float) -> int:
	return 1 + int(t / 160.0)


static func spawn_weights(t: float) -> Dictionary:
	var w := {"mist": 10.0}
	if t >= 45.0:
		w["runner"] = minf(6.0, (t - 45.0) / 15.0)
	if t >= 120.0:
		w["brute"] = minf(3.0, (t - 120.0) / 90.0)
	return w


static func pulse_cooldown(level: int) -> float:
	return maxf(2.0, 6.0 - level * 0.8)
