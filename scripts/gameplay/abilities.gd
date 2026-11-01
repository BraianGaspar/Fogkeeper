class_name Abilities
extends Node
## Habilidades ativas do farol, com recarga. O jogador leva três, escolhidas
## na oficina (Settings.loadout) entre as de Balance.ABILITIES.
## Main chama use(i) quando o jogador aperta a tecla do espaço i.

signal used(index: int)

const DEFAULT_LOADOUT := ["flash", "overcharge", "bell"]

var lighthouse: Lighthouse
var enemies_root: Node2D
var embers_root: Node2D
var effects_root: Node2D
var cooldowns: Array[float] = []
var loadout: Array[Dictionary] = [] ## As três habilidades equipadas nesta partida.
var _full: Array[float] = [] ## Recarga cheia de cada uma (o farol pode encurtar).


static func find(id: String) -> Dictionary:
	for a: Dictionary in Balance.ABILITIES:
		if a["id"] == id:
			return a
	return Balance.ABILITIES[0]


## Equipa as habilidades (ids) e zera as recargas.
func reset(ids: Array = DEFAULT_LOADOUT) -> void:
	cooldowns.clear()
	_full.clear()
	loadout.clear()
	for id: String in ids:
		var a := find(id)
		loadout.append(a)
		cooldowns.append(0.0)
		_full.append(float(a["cooldown"]))


func data(i: int) -> Dictionary:
	return loadout[i]


func is_ready(i: int) -> bool:
	return i < cooldowns.size() and cooldowns[i] <= 0.0


## 0 = pronta, 1 = acabou de ser usada.
func fraction(i: int) -> float:
	return cooldowns[i] / maxf(0.01, _full[i])


func _process(delta: float) -> void:
	for i in cooldowns.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)


func use(i: int) -> bool:
	if i >= cooldowns.size():
		return false
	if not is_ready(i):
		Sfx.play(&"denied")
		return false
	var a := loadout[i]
	_full[i] = float(a["cooldown"]) * lighthouse.ability_cooldown
	cooldowns[i] = _full[i]
	match a["id"]:
		"flash":
			var r: float = a["radius"]
			for node in enemies_root.get_children():
				var e := node as Enemy
				if e and not e.dying and e.position.length() - e.radius <= r:
					# Atordoa antes do dano: o Clarão apaga o Boitatá e abre o espelho.
					e.stun(a["stun"])
					e.take_light(a["damage"])
					DamageStats.add("ability", a["damage"])
			_ring(r, Color(1.0, 0.95, 0.8), 0.5, 10.0)
			Sfx.play(&"flash")
		"overcharge":
			lighthouse.start_overcharge(a)
			_ring(80.0, Color(1.0, 1.0, 1.0), 0.35, 4.0)
			Sfx.play(&"overcharge")
		"bell":
			for node in embers_root.get_children():
				var m := node as Ember
				if m:
					m.attract()
			lighthouse.heal(a["heal"])
			_ring(900.0, Color(1.0, 0.7, 0.35), 1.2, 3.0)
			Sfx.play(&"bell")
		"mirror":
			lighthouse.start_mirror(a["duration"])
			_ring(90.0, Color(0.75, 0.9, 1.0), 0.4, 4.0)
			Sfx.play(&"overcharge", 1.3)
		"tide":
			var r: float = a["radius"]
			for node in enemies_root.get_children():
				var e := node as Enemy
				if e and not e.dying and e.position.length() - e.radius <= r and e.position.length() > 1.0:
					# Chefes resistem: são empurrados só um pouco.
					var push: float = a["push"] * (0.25 if e.is_boss() else 1.0)
					e.position += e.position.normalized() * push
					e.stun(a["stun"])
			_ring(r, Color(0.45, 0.75, 1.0), 0.7, 14.0)
			Sfx.play(&"splash", 0.8)
		"beacon":
			lighthouse.start_beacon(a)
			_ring(140.0, Color(1.0, 0.85, 0.5), 0.5, 5.0)
			Sfx.play(&"pulse", 1.4)
	used.emit(i)
	return true


func _ring(radius: float, color: Color, duration: float, width: float) -> void:
	if Settings.reduce_flashes and radius > 300.0:
		return
	var fx := RingFx.new()
	fx.max_radius = radius
	fx.color = color
	fx.duration = duration
	fx.width = width
	effects_root.add_child(fx)
