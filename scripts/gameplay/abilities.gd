class_name Abilities
extends Node
## Habilidades ativas do farol (Balance.ABILITIES), com recarga.
## Main chama use(i) quando o jogador aperta a tecla da habilidade.

signal used(index: int)

var lighthouse: Lighthouse
var enemies_root: Node2D
var embers_root: Node2D
var effects_root: Node2D
var cooldowns: Array[float] = []


func reset() -> void:
	cooldowns.clear()
	for a in Balance.ABILITIES:
		cooldowns.append(0.0)


func is_ready(i: int) -> bool:
	return i < cooldowns.size() and cooldowns[i] <= 0.0


## 0 = pronta, 1 = acabou de ser usada.
func fraction(i: int) -> float:
	return cooldowns[i] / float(Balance.ABILITIES[i]["cooldown"])


func _process(delta: float) -> void:
	for i in cooldowns.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)


func use(i: int) -> bool:
	if i >= cooldowns.size():
		return false
	if not is_ready(i):
		Sfx.play(&"denied")
		return false
	var a: Dictionary = Balance.ABILITIES[i]
	cooldowns[i] = a["cooldown"]
	match a["id"]:
		"flash":
			var r: float = a["radius"]
			for node in enemies_root.get_children():
				var e := node as Enemy
				if e and not e.dying and e.position.length() - e.radius <= r:
					e.take_light(a["damage"])
					e.stun(a["stun"])
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
	used.emit(i)
	return true


func _ring(radius: float, color: Color, duration: float, width: float) -> void:
	var fx := RingFx.new()
	fx.max_radius = radius
	fx.color = color
	fx.duration = duration
	fx.width = width
	effects_root.add_child(fx)
