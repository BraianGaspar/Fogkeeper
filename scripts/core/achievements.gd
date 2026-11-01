class_name Achievements
extends RefCounted
## Conquistas locais, guardadas em Progress. Quando o jogo for para a Steam,
## unlock() é o único ponto que precisa chamar a API de conquistas.

const LIST := [
	{"id": "first_light", "name": "Primeira luz", "desc": "Termine uma partida."},
	{"id": "apprentice", "name": "Aprendiz de faroleiro", "desc": "Conclua o tutorial."},
	{"id": "dawn", "name": "Amanhecer", "desc": "Veja o amanhecer em qualquer mapa."},
	{"id": "three_seas", "name": "Guardião de todas as águas", "desc": "Veja o amanhecer em todos os mapas."},
	{"id": "hard_dawn", "name": "Noite difícil", "desc": "Veja o amanhecer no Difícil."},
	{"id": "impossible_dawn", "name": "O impossível", "desc": "Veja o amanhecer no Impossível."},
	{"id": "untouched", "name": "Intocado", "desc": "Veja o amanhecer com 90% da vida ou mais."},
	{"id": "no_walls", "name": "Sem paredes", "desc": "Veja o amanhecer sem escolher Paredes reforçadas."},
	{"id": "endless", "name": "Noite sem fim", "desc": "Sobreviva a uma segunda noite inteira no modo sem fim."},
	{"id": "evolution", "name": "Evolução", "desc": "Consiga uma evolução de melhorias."},
	{"id": "thief", "name": "Pega ladrão!", "desc": "Queime uma ladra de brasas antes que ela fuja com o roubo."},
	{"id": "kills_5000", "name": "Cinco mil chamas", "desc": "Queime 5.000 criaturas somando todas as partidas."},
	{"id": "oil_1000", "name": "Reserva de óleo", "desc": "Junte 1.000 de óleo ao todo."},
	{"id": "boss_leviathan", "name": "Caçador de serpentes", "desc": "Derrote o Leviatã."},
	{"id": "boss_kraken", "name": "Tinta seca", "desc": "Derrote o Kraken."},
	{"id": "boss_jotunn", "name": "Quebra-gelo", "desc": "Derrote o Jötunn."},
	{"id": "boss_fenrir", "name": "Gleipnir", "desc": "Derrote Fenrir."},
	{"id": "boss_iara", "name": "Ouvidos tapados", "desc": "Derrote a Iara."},
	{"id": "boss_boitata", "name": "Fogo contra fogo", "desc": "Derrote o Boitatá."},
	{"id": "boss_cuca", "name": "Nana, neném", "desc": "Derrote a Cuca."},
	{"id": "boss_umibozu", "name": "Balde sem fundo", "desc": "Derrote o Umibōzu."},
	{"id": "boss_kyubi", "name": "A verdadeira raposa", "desc": "Derrote a Kyūbi."},
	{"id": "boss_sphinx", "name": "Enigma resolvido", "desc": "Derrote a Esfinge."},
	{"id": "boss_apep", "name": "O sol nasce de novo", "desc": "Derrote Apep."},
	{"id": "boss_scylla", "name": "Entre a rocha e o redemoinho", "desc": "Derrote Cila."},
	{"id": "boss_medusa", "name": "Escudo espelhado", "desc": "Derrote a Medusa."},
	{"id": "boss_balor", "name": "Olho no olho", "desc": "Derrote Balor."},
	{"id": "boss_cailleach", "name": "Fim do inverno", "desc": "Derrote a Cailleach."},
	{"id": "tide_10", "name": "Maré cheia", "desc": "Veja o amanhecer na Maré 10."},
	{"id": "daily", "name": "Desafio do dia", "desc": "Complete um desafio diário."},
	{"id": "boss_rush", "name": "Todos os chefes", "desc": "Vença o Modo Chefões."},
	{"id": "bestiary", "name": "Bestiário completo", "desc": "Abra todas as fichas do bestiário."},
]

## Quem mostra o aviso na tela: func(entry: Dictionary). Main define.
static var listener: Callable


static func find(id: String) -> Dictionary:
	for a: Dictionary in LIST:
		if a["id"] == id:
			return a
	return {}


static func has(id: String) -> bool:
	return Progress.achievements.has(id)


## Desbloqueia e avisa; devolve true se for nova.
static func unlock(id: String, announce: bool = true) -> bool:
	if not Progress.enabled or has(id) or find(id).is_empty():
		return false
	Progress.achievements[id] = int(Time.get_unix_time_from_system())
	SteamService.achievement(id)
	Progress.save()
	if announce and listener.is_valid():
		listener.call(find(id))
	return true


## Conquistas que dependem do resultado da partida. Devolve as novas, sem
## aviso (a tela de fim de partida as lista).
static func check_run(run: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var candidates: Array[String] = ["first_light"]
	var c := Bestiary.count()
	if c.x >= c.y:
		candidates.append("bestiary")
	if run["victory"] and run.get("mode", "normal") != "boss_rush":
		candidates.append("dawn")
		if run["difficulty"] in ["hard", "impossible"]:
			candidates.append("hard_dawn")
		if run["difficulty"] == "impossible":
			candidates.append("impossible_dawn")
		if float(run.get("hp_fraction", 0.0)) >= 0.9:
			candidates.append("untouched")
		if not (run["upgrades"] as Array).has("walls"):
			candidates.append("no_walls")
		var won_maps := {}
		for r in Records.runs():
			if r["victory"]:
				won_maps[r["map"]] = true
		if won_maps.size() >= Maps.ORDER.size():
			candidates.append("three_seas")
	if Progress.stat("kills") >= 5000:
		candidates.append("kills_5000")
	if Progress.oil_total >= 1000:
		candidates.append("oil_1000")
	for id in candidates:
		if unlock(id, false):
			out.append(id)
	return out
