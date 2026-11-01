class_name DamageStats
extends RefCounted
## Números da partida para o resumo do fim: dano por fonte de luz e brasas
## recolhidas ou perdidas. Main zera no começo de cada partida.

const SOURCES := ["beam", "lens", "sweeper", "pulse", "ability", "combustion"]
const NAMES := {
	"beam": "Feixe principal", "lens": "Lentes extras", "sweeper": "Farolete",
	"pulse": "Pulso de luz", "ability": "Habilidades", "combustion": "Combustão",
}

static var damage: Dictionary = {}
static var embers_collected := 0
static var embers_lost := 0


static func reset() -> void:
	damage = {}
	embers_collected = 0
	embers_lost = 0


static func add(source: String, amount: float) -> void:
	damage[source] = float(damage.get(source, 0.0)) + amount


static func total() -> float:
	var t := 0.0
	for v: float in damage.values():
		t += v
	return t


## Fontes da maior para a menor, com a fração do dano total: [[id, fração], ...].
static func ranked() -> Array:
	var t := maxf(1.0, total())
	var out := []
	for s: String in SOURCES:
		if float(damage.get(s, 0.0)) > 0.0:
			out.append([s, float(damage[s]) / t])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return out
