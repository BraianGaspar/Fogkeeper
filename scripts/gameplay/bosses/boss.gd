class_name Boss
extends Enemy
## Base dos chefes: vida e recompensa de Balance.BOSSES, fúria com metade da
## vida (dificuldades com "enrage") e pedido de lacaios ao Spawner.
## Subclasses implementam begin() (posição inicial), _move() e _draw().

signal spawn_request(role: String, at: Vector2)
signal enraged_now(boss: Boss)

var data: Dictionary = {}
var enraged := false
var can_enrage := false
var enrage_at := Balance.ENRAGE_AT ## Fração da vida em que enfurece (as marés sobem).


func setup_boss(id: String, hp_mult: float, damage_mult: float, speed_mult: float, enrage_allowed: bool) -> void:
	kind = id
	art = id
	data = Balance.BOSSES[id]
	max_hp = float(data["hp"]) * (1.0 + (hp_mult - 1.0) * 0.5)
	hp = max_hp
	speed = float(data["speed"]) * speed_mult
	radius = float(data["radius"])
	damage = float(data["damage"]) * damage_mult
	xp_value = int(data["xp"])
	score_value = 0 # Chefes contam como bônus próprio na pontuação.
	can_enrage = enrage_allowed


## Posiciona o chefe ao entrar, no ângulo dado.
func begin(_angle: float) -> void:
	pass


func is_boss() -> bool:
	return true


## Ritmo das mecânicas: acelera quando enfurecido.
func rate() -> float:
	return Balance.ENRAGE_SPEED if enraged else 1.0


## Luz desacelera chefes só pela metade.
func lit_factor() -> float:
	if _lit <= 0.0 or lighthouse == null:
		return 1.0
	return lerpf(1.0, lighthouse.lit_slow, 0.5)


func take_light(amount: float, reflect: bool = false) -> void:
	super.take_light(amount, reflect)
	if can_enrage and not enraged and not dying and hp < max_hp * enrage_at:
		enraged = true
		enraged_now.emit(self)


## Chefes resistem ao atordoamento.
func stun(seconds: float) -> void:
	super.stun(seconds * 0.25)


func draw_enrage_aura(r: float) -> void:
	if not enraged or dying:
		return
	var pulse := 0.6 + 0.4 * sin(_time * 8.0)
	draw_circle(Vector2.ZERO, r * 1.8, Color(1.0, 0.15, 0.1, 0.12 * pulse))
	draw_arc(Vector2.ZERO, r * 1.5, 0.0, TAU, 40, Color(1.0, 0.3, 0.2, 0.6 * pulse), 3.0)


func death_alpha() -> float:
	return 1.0 - _death_t / DEATH_TIME if dying else 1.0
