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
const ENEMIES := {
	"mist": {"hp": 14.0, "speed": 54.0, "radius": 12.0, "damage": 4.0, "xp": 1, "color": Color(0.32, 0.22, 0.45)},
	"runner": {"hp": 9.0, "speed": 110.0, "radius": 9.0, "damage": 3.0, "xp": 1, "color": Color(0.2, 0.3, 0.46)},
	"brute": {"hp": 55.0, "speed": 28.0, "radius": 20.0, "damage": 10.0, "xp": 4, "color": Color(0.42, 0.18, 0.3)},
	"leviathan": {"hp": 650.0, "speed": 20.0, "radius": 38.0, "damage": 10.0, "boss": true, "xp": 30, "color": Color(0.26, 0.12, 0.36)},
}
const BOSS_TIMES := [300.0, 540.0] ## Momentos em que um Leviatã aparece.


static func xp_for_level(level: int) -> int:
	return 5 + level * 4 + int(level * level * 0.15)


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
