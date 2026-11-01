class_name Tutorial
extends Node
## Tutorial guiado: uma partida de treino na Baía, sem relógio nem chefes
## marcados. Cada passo só avança quando o jogador faz o que foi pedido; as
## dicas de teclas aparecem aqui (e na escolha de melhoria do tutorial), e
## não nas telas do jogo normal.
## Main cria o nó, chama begin(), repassa os eventos (on_kill, on_ember...)
## e tick() a cada quadro.

signal finished

enum Step { AIM, BURN, EMBERS, LEVEL_UP, ABILITIES, THIEF, MIRROR, BOSS, DONE }

const DONE_TIME := 6.0 ## Segundos lendo o último recado antes de terminar.

var main: Node ## O Main (sem class_name): spawner, lighthouse, hud, force_level_up().
var step := Step.AIM

var _count := 0
var _turned := 0.0
var _last_aim := 0.0
var _used: Dictionary = {}
var _timer := 0.0
var _spawned: Array[Enemy] = []


func begin() -> void:
	_last_aim = main.lighthouse.aim_angle
	_enter(Step.AIM)


func allows_level_up() -> bool:
	return step == Step.LEVEL_UP


func _key(action: String, slot: int = 0) -> String:
	return GameInput.label(action, slot)


func _enter(s: Step) -> void:
	step = s
	if main.autoplay:
		print("[tutorial] passo %d em %s" % [s, Records.format_time(main.elapsed)])
	_count = 0
	_timer = 0.0
	_spawned.clear()
	match s:
		Step.BURN:
			_spawn_ring("basic", 3, 420.0)
		Step.EMBERS:
			_spawn_ring("basic", 4, 470.0)
		Step.LEVEL_UP:
			main.force_level_up()
		Step.ABILITIES:
			_used.clear()
			_spawn_ring("basic", 8, 300.0)
		Step.THIEF:
			_spawn_ring("thief", 1, 520.0)
			_drop_embers(5)
		Step.MIRROR:
			_spawn_ring("mirror", 1, 430.0)
		Step.BOSS:
			var boss: Boss = main.spawner.spawn_boss("leviathan")
			boss.max_hp *= 0.3
			boss.hp = boss.max_hp
		Step.DONE:
			Sfx.play(&"victory")
	refresh()


## Texto do passo atual no painel do tutorial.
func refresh() -> void:
	var t := ""
	var body := ""
	var progress := ""
	match step:
		Step.AIM:
			t = tr("1. Gire o feixe")
			if GameInput.using_pad:
				body = tr("Use um dos analógicos para girar a luz do farol: o esquerdo gira, o direito aponta direto.")
			else:
				body = tr("Mova o mouse, use %s / %s (ou %s / %s) ou o analógico para girar a luz do farol.") % [
					_key("rotate_left"), _key("rotate_right"), _key("rotate_left", 1), _key("rotate_right", 1)]
			progress = "%d%%" % mini(100, int(_turned / (PI * 1.5) * 100.0))
		Step.BURN:
			t = tr("2. Queime as criaturas")
			body = tr("Criaturas saem da névoa e vêm atacar o farol. Mantenha a luz sobre elas até que queimem.")
			progress = "%d / 3" % _count
		Step.EMBERS:
			t = tr("3. Recolha as brasas")
			body = tr("Cada criatura queimada deixa uma brasa. Passe a luz sobre ela para trazê-la ao farol: é a sua experiência. Brasas esquecidas se apagam.")
			progress = "%d / 4" % _count
		Step.LEVEL_UP:
			t = tr("4. Suba de nível")
			if GameInput.using_pad:
				body = tr("Com brasas suficientes, você escolhe uma melhoria. Use o direcional para navegar e %s para escolher. %s troca as cartas e %s bane uma.") % [
					_key("menu_confirm"), _key("reroll"), _key("banish")]
			else:
				body = tr("Com brasas suficientes, você escolhe uma melhoria. %s / %s ou as setas para navegar, Enter, Espaço, 1-3 ou clique para escolher. T troca as cartas e B bane uma.") % [
					_key("rotate_left"), _key("rotate_right")]
		Step.ABILITIES:
			t = tr("5. Use as habilidades")
			if GameInput.using_pad:
				body = tr("%s: Clarão (fere e atordoa em volta)   •   %s: Sobrecarga (feixe concentrado)   •   %s: Sino da Névoa (puxa as brasas e cura). Use as três.") % [
					_key("ability_1"), _key("ability_2"), _key("ability_3")]
			else:
				body = tr("%s: Clarão (fere e atordoa em volta)   •   %s ou botão direito: Sobrecarga (feixe concentrado)   •   %s: Sino da Névoa (puxa as brasas e cura). Use as três.") % [
					_key("ability_1"), _key("ability_2"), _key("ability_3")]
			progress = "%d / 3" % _used.size()
		Step.THIEF:
			t = tr("6. Cuidado com a ladra")
			body = tr("A gaivota-fantasma não ataca o farol: ela rouba brasas soltas e foge para a névoa. Queime-a antes, e o roubo volta para você.")
		Step.MIRROR:
			t = tr("7. Luz refletida")
			body = tr("A ostra abissal fechada reflete a luz e fere o farol. Desvie o feixe e ataque quando ela abrir. O Clarão a abre na hora.")
		Step.BOSS:
			t = tr("8. Chefes")
			body = tr("À meia-noite e às 3h surgem chefes, sempre com um aviso vermelho antes. Cada um tem uma mecânica própria. Derrote este Leviatã enfraquecido: só a cabeça recebe dano, e ele mergulha de vez em quando.")
		Step.DONE:
			t = tr("Pronto!")
			body = tr("Na partida de verdade, resista até o amanhecer (06:00). %s pausa o jogo. Boa sorte, faroleiro.") % ("Esc" if not GameInput.using_pad else _key("pause"))
	main.hud.set_tutorial(t, body, progress)


func tick(delta: float) -> void:
	_timer += delta
	match step:
		Step.AIM:
			var aim: float = main.lighthouse.aim_angle
			_turned += absf(angle_difference(_last_aim, aim))
			_last_aim = aim
			refresh()
			if _turned >= PI * 1.5:
				_enter(Step.BURN)
		Step.BURN, Step.EMBERS, Step.ABILITIES:
			# Sempre há criaturas para praticar.
			if _alive() == 0 and _timer > 1.0:
				_timer = 0.0
				_spawn_ring("basic", 3 if step != Step.ABILITIES else 6, 420.0)
		Step.MIRROR:
			if _alive() == 0 and _timer > 1.0:
				_spawn_ring("mirror", 1, 430.0)
		Step.DONE:
			if _timer >= DONE_TIME:
				finished.emit()


func _alive() -> int:
	var n := 0
	for e in _spawned:
		if is_instance_valid(e) and not e.dying:
			n += 1
	return n


func on_kill(enemy: Enemy) -> void:
	match step:
		Step.BURN:
			_count += 1
			refresh()
			if _count >= 3:
				_enter(Step.EMBERS)
		Step.THIEF:
			if enemy.kind == "thief":
				_enter(Step.MIRROR)
		Step.MIRROR:
			if enemy.kind == "mirror":
				_enter(Step.BOSS)
		Step.BOSS:
			if enemy.is_boss():
				_enter(Step.DONE)


func on_ember() -> void:
	if step == Step.EMBERS:
		_count += 1
		refresh()
		if _count >= 4:
			_enter(Step.LEVEL_UP)


func on_upgrade() -> void:
	if step == Step.LEVEL_UP:
		_enter(Step.ABILITIES)


func on_ability(i: int) -> void:
	if step == Step.ABILITIES:
		_used[i] = true
		refresh()
		if _used.size() >= 3:
			_enter(Step.THIEF)


func on_escape(enemy: Enemy) -> void:
	if step == Step.THIEF and enemy.kind == "thief":
		main.hud.announce(tr("Ela fugiu! Outra vem aí."))
		_spawn_ring("thief", 1, 520.0)
		_drop_embers(4)


func _spawn_ring(role: String, n: int, dist: float) -> void:
	for i in n:
		var e: Enemy = main.spawner.spawn(role)
		e.position = Vector2.from_angle(randf() * TAU) * dist
		_spawned.append(e)


## Brasas soltas longe do farol, para a ladra ter o que roubar.
func _drop_embers(n: int) -> void:
	for i in n:
		var ember := Ember.new()
		ember.position = Vector2.from_angle(randf() * TAU) * randf_range(200.0, 300.0)
		ember.lighthouse = main.lighthouse
		ember.lifetime = 60.0
		ember.collected.connect(main._on_ember_collected)
		main.embers_root.add_child(ember)
