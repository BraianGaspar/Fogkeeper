class_name Upgrades
extends RefCounted
## Catálogo de melhorias oferecidas a cada nível, evoluções e as melhorias
## permanentes da oficina.
## Para criar uma nova: adicione uma entrada em LIST e um caso em apply().
## Cartas listadas em Balance.UNLOCKS só aparecem depois de desbloqueadas.

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
	{"id": "combustion", "name": "Combustão", "desc": "Criaturas queimadas explodem e ferem as vizinhas.", "max": 3},
	{"id": "vital_embers", "name": "Brasas vitais", "desc": "Cada brasa recolhida recupera 0,4 de vida.", "max": 3},
]

## Evoluções: aparecem quando as duas melhorias de "needs" estão no máximo.
const EVOLUTIONS := [
	{"id": "fresnel", "name": "Lente de Fresnel", "desc": "O feixe principal arde em branco: +30% de dano e +25% de alcance.", "needs": ["long_lens", "intense_flame"]},
	{"id": "crown", "name": "Coroa de Luz", "desc": "Lentes extras causam dano total e o farolete ganha um segundo braço.", "needs": ["twin_lens", "sweeper"]},
	{"id": "ember_tide", "name": "Maré de Brasas", "desc": "Cada pulso de luz puxa todas as brasas para o farol.", "needs": ["pulse", "magnet"]},
	{"id": "bastion", "name": "Bastião", "desc": "+50 de vida máxima, cura total e regeneração dobrada.", "needs": ["walls", "repairs"]},
	{"id": "fan", "name": "Leque de Luz", "desc": "Feixe principal 50% mais largo e criaturas iluminadas ainda mais lentas.", "needs": ["wide_lens", "gears"]},
]

const FALLBACK := {"id": "fresh_oil", "name": "Óleo fresco", "desc": "Recupera 30 de vida.", "max": 999}


static func find(id: String) -> Dictionary:
	for u: Dictionary in LIST:
		if u["id"] == id:
			return u
	for u: Dictionary in EVOLUTIONS:
		if u["id"] == id:
			return u
	return FALLBACK if id == FALLBACK["id"] else {"id": id, "name": id, "desc": "", "max": 1}


static func is_evolution(id: String) -> bool:
	for u: Dictionary in EVOLUTIONS:
		if u["id"] == id:
			return true
	return false


## Evoluções liberadas pelas melhorias atuais e ainda não escolhidas.
static func ready_evolutions(levels: Dictionary) -> Array:
	var out: Array = []
	for e: Dictionary in EVOLUTIONS:
		if levels.has(e["id"]):
			continue
		var ok := true
		for need: String in e["needs"]:
			if int(levels.get(need, 0)) < int(find(need)["max"]):
				ok = false
		if ok:
			out.append(e)
	return out


## Sorteia `count` cartas. Evoluções prontas entram primeiro; cartas banidas
## e as ainda bloqueadas na oficina ficam de fora.
static func roll(levels: Dictionary, rng: RandomNumberGenerator, count: int = 3, banished: Array = []) -> Array:
	var pool: Array = []
	for u in LIST:
		if int(levels.get(u["id"], 0)) < int(u["max"]) and not banished.has(u["id"]) and Progress.is_unlocked(u["id"]):
			pool.append(u)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var result := ready_evolutions(levels)
	result.append_array(pool)
	result = result.slice(0, count)
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
		"combustion":
			lh.combustion += 1
		"vital_embers":
			lh.ember_heal += Balance.VITAL_EMBER_HEAL
		"fresh_oil":
			lh.heal(30.0)
		"fresnel":
			lh.fresnel = true
			lh.beam_dps *= 1.3
			lh.beam_range *= 1.25
		"crown":
			lh.crown = true
			lh.rebuild_beams()
		"ember_tide":
			lh.ember_tide = true
		"bastion":
			lh.max_hp += 50.0
			lh.heal(lh.max_hp)
			lh.regen = maxf(1.0, lh.regen * 2.0)
		"fan":
			lh.beam_half_angle *= 1.5
			lh.lit_slow *= 0.75
		_:
			push_warning("Upgrade desconhecido: %s" % id)


## Relíquia deixada por um chefe derrotado (Balance.RELICS).
static func apply_relic(boss_id: String, lh: Lighthouse) -> void:
	match boss_id:
		"leviathan":
			lh.max_hp += 40.0
			lh.heal(lh.max_hp)
		"kraken":
			lh.beam_range *= 1.2
		"jotunn":
			lh.lit_slow *= 0.7
		"fenrir":
			lh.turn_speed *= 1.3
			lh.beam_dps *= 1.15
		"iara":
			lh.magnet_radius *= 1.5
			lh.regen += 0.5
		"boitata":
			lh.beam_dps *= 1.25
		"cuca":
			lh.ability_cooldown *= 0.7


## Melhorias permanentes da oficina, aplicadas no começo de cada partida.
static func apply_meta(lh: Lighthouse) -> void:
	lh.max_hp += 10.0 * Progress.level("granite")
	lh.hp = lh.max_hp
	lh.beam_dps *= 1.0 + 0.05 * Progress.level("polish")
	lh.turn_speed *= 1.0 + 0.06 * Progress.level("fine_gears")
	lh.magnet_radius *= 1.0 + 0.1 * Progress.level("copper")
