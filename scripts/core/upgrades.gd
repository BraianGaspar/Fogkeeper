class_name Upgrades
extends RefCounted
## Catálogo de melhorias oferecidas a cada nível.
## Para criar uma nova: adicione uma entrada em LIST e um caso em apply().

const LIST := [
	{"id": "wide_lens", "name": "Lente ampla", "desc": "Feixe 20% mais largo.", "max": 5},
	{"id": "long_lens", "name": "Lente de longo alcance", "desc": "Feixe alcança 15% mais longe.", "max": 5},
	{"id": "intense_flame", "name": "Chama intensa", "desc": "Toda a luz causa 25% mais dano.", "max": 6},
	{"id": "gears", "name": "Engrenagens lubrificadas", "desc": "O feixe gira 25% mais rápido.", "max": 4},
	{"id": "twin_lens", "name": "Lente extra", "desc": "Adiciona mais um feixe, distribuído ao redor do farol.", "max": 3},
	{"id": "pulse", "name": "Pulso de luz", "desc": "Uma onda de luz periódica queima tudo ao redor.", "max": 5},
	{"id": "sweeper", "name": "Farolete giratório", "desc": "Um feixe menor que gira sozinho.", "max": 3},
	{"id": "walls", "name": "Paredes reforçadas", "desc": "+25 de vida máxima e recupera 25.", "max": 4},
	{"id": "repairs", "name": "Faroleiro dedicado", "desc": "Regenera 0,6 de vida por segundo.", "max": 5},
	{"id": "magnet", "name": "Correntes quentes", "desc": "Brasas são puxadas de 40% mais longe.", "max": 3},
]

const FALLBACK := {"id": "fresh_oil", "name": "Óleo fresco", "desc": "Recupera 30 de vida.", "max": 999}


static func roll(levels: Dictionary, rng: RandomNumberGenerator, count: int = 3) -> Array:
	var pool: Array = []
	for u in LIST:
		if int(levels.get(u["id"], 0)) < int(u["max"]):
			pool.append(u)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var result := pool.slice(0, count)
	if result.is_empty():
		result.append(FALLBACK)
	return result


static func apply(id: String, lh: Lighthouse) -> void:
	match id:
		"wide_lens":
			lh.beam_half_angle *= 1.2
		"long_lens":
			lh.beam_range *= 1.15
		"intense_flame":
			lh.beam_dps *= 1.25
		"gears":
			lh.turn_speed *= 1.25
		"twin_lens":
			lh.lens_count += 1
			lh.rebuild_beams()
		"pulse":
			lh.pulse_level += 1
		"sweeper":
			lh.sweeper_level += 1
			lh.rebuild_beams()
		"walls":
			lh.max_hp += 25.0
			lh.heal(25.0)
		"repairs":
			lh.regen += 0.6
		"magnet":
			lh.magnet_radius *= 1.4
		"fresh_oil":
			lh.heal(30.0)
		_:
			push_warning("Upgrade desconhecido: %s" % id)
