extends Node2D
## Orquestra a partida: estados, XP, níveis, chefes, pontuação e fim de jogo.
##
## Argumentos de linha de comando (depois de `--`):
##   --autoplay       um bot joga sozinho e imprime um resumo (balanceamento)
##   --seed=N         semente fixa para partidas reproduzíveis
##   --difficulty=D   easy, normal, medium, hard ou impossible (padrão: normal)
##   --map=M          bay ou fjord (padrão: bay)
##   --keeper=K       aparência do farol (classic, stone, iron, crystal)
##   --screenshot=T   salva user://screenshot.png aos T segundos
##                    (tempo de partida no autoplay; tempo real fora dele)
##   --ui=TELA        abre direto uma tela para inspecionar o visual:
##                    map, keeper, difficulty, settings, controls, graphics,
##                    audio, history, ranking,
##                    pause, levelup, end, victory, boss
##   --cycle=T        fixa a hora do dia (segundos de partida) no cenário

enum State { TITLE, PLAYING, LEVEL_UP, PAUSED, GAME_OVER, VICTORY }

const TITLE_CAMERA := Vector2(-290, 0)

var state: State = State.TITLE
var difficulty := "normal"
var map_id := "bay"
var keeper := "classic"
var elapsed := 0.0
var kills := 0
var kill_points := 0
var bosses_killed := 0
var relics: Array[String] = []
var level := 1
var xp := 0
var xp_needed := 0
var upgrade_levels: Dictionary = {}
var upgrade_order: Array[String] = []
var pending_level_ups := 0
var autoplay := false
var rng := RandomNumberGenerator.new()

var world: Node2D
var background: Background
var fog: Fog
var enemies_root: Node2D
var embers_root: Node2D
var effects_root: Node2D
var lighthouse: Lighthouse
var spawner: Spawner
var abilities: Abilities
var hud: Hud
var camera: Camera2D

var _shake := 0.0
var _using_mouse := true
var _last_mouse := Vector2.ZERO
var _next_report := 30.0
var _screenshot_at := -1.0
var _clock := 0.0
var _title_time := 0.0
var _sunrise := 0.0
var _event_index := 0
var _ember_streak := 0
var _ember_timer := 0.0
var _levelup_waiting := false
var _bosses_alive := 0
var _ui_arg := ""
var _cycle_arg := -1.0
var _arg_map := ""
var _arg_keeper := ""
var _arg_difficulty := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameInput.setup()
	I18n.setup()
	_parse_args()
	if not autoplay:
		Settings.load_settings()
	difficulty = _arg_difficulty if _arg_difficulty != "" else (Settings.difficulty if not autoplay else "normal")
	map_id = _arg_map if _arg_map != "" else (Settings.map if not autoplay else "bay")
	keeper = _arg_keeper if _arg_keeper != "" else Settings.keeper
	# Argumentos de inspeção valem só nesta execução (não são salvos).
	Settings.map = map_id
	Settings.keeper = keeper
	Settings.difficulty = difficulty
	add_child(Sfx.new())
	Settings.apply()
	_build_world()
	_build_hud()
	_set_map(map_id)
	if autoplay:
		start_run(map_id, keeper, difficulty)
	else:
		go_to_title()
		if _ui_arg != "":
			_open_debug_ui(_ui_arg)


func _parse_args() -> void:
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			autoplay = true
		elif arg.begins_with("--seed="):
			rng.seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--difficulty="):
			_arg_difficulty = arg.get_slice("=", 1)
		elif arg.begins_with("--map="):
			_arg_map = arg.get_slice("=", 1)
		elif arg.begins_with("--keeper="):
			_arg_keeper = arg.get_slice("=", 1)
		elif arg.begins_with("--screenshot="):
			_screenshot_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--ui="):
			_ui_arg = arg.get_slice("=", 1)
		elif arg.begins_with("--cycle="):
			_cycle_arg = float(arg.get_slice("=", 1))
	if _arg_difficulty != "" and not Balance.DIFFICULTIES.has(_arg_difficulty):
		push_warning("Dificuldade desconhecida: %s; usando normal." % _arg_difficulty)
		_arg_difficulty = "normal"
	if _arg_map != "" and not Maps.LIST.has(_arg_map):
		push_warning("Mapa desconhecido: %s; usando bay." % _arg_map)
		_arg_map = "bay"


func _build_world() -> void:
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	background = Background.new()
	world.add_child(background)
	embers_root = _container("Embers")
	enemies_root = _container("Enemies")

	lighthouse = Lighthouse.new()
	lighthouse.enemies_root = enemies_root
	lighthouse.embers_root = embers_root
	world.add_child(lighthouse)
	lighthouse.died.connect(_on_lighthouse_died)
	lighthouse.damaged.connect(_on_lighthouse_damaged)

	effects_root = _container("Effects")
	lighthouse.effects_root = effects_root
	fog = Fog.new()
	world.add_child(fog)

	spawner = Spawner.new()
	spawner.enemies_root = enemies_root
	spawner.lighthouse = lighthouse
	spawner.rng = rng
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.boss_warning.connect(_on_boss_warning)
	spawner.boss_spawned.connect(_on_boss_spawned)
	world.add_child(spawner)

	abilities = Abilities.new()
	abilities.lighthouse = lighthouse
	abilities.enemies_root = enemies_root
	abilities.embers_root = embers_root
	abilities.effects_root = effects_root
	world.add_child(abilities)
	abilities.reset()


func _container(node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	world.add_child(n)
	return n


func _build_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.abilities = abilities
	hud.start_requested.connect(start_run)
	hud.restart_pressed.connect(func() -> void: start_run(map_id, keeper, difficulty))
	hud.resume_pressed.connect(func() -> void: _set_paused(false))
	hud.menu_pressed.connect(go_to_title)
	hud.quit_pressed.connect(func() -> void: get_tree().quit())
	hud.upgrade_chosen.connect(_apply_upgrade)


## Troca cenário, paleta e trilha calma para o mapa.
func _set_map(id: String) -> void:
	map_id = id
	DayCycle.set_map(id)
	Sfx.set_map(id)
	var want_fjord: bool = Maps.get_map(id)["scenery"] == "fjord"
	if (background is FjordBackground) != want_fjord:
		background.queue_free()
		background = FjordBackground.new() if want_fjord else Background.new()
		world.add_child(background)
		world.move_child(background, 0)


# --- Fluxo da partida -----------------------------------------------------

func _clear_world() -> void:
	for root in [enemies_root, embers_root, effects_root]:
		for c in root.get_children():
			c.queue_free()
	spawner.active = false
	_bosses_alive = 0
	lighthouse.keeper = keeper
	lighthouse.reset()
	abilities.reset()


## Menu principal: o cenário do último mapa fica vivo ao fundo, com o farol
## girando sozinho.
func go_to_title() -> void:
	keeper = Settings.keeper
	_set_map(Settings.map)
	_clear_world()
	state = State.TITLE
	get_tree().paused = false
	Sfx.music(&"calm")
	hud.show_title()


func start_run(new_map: String, new_keeper: String, diff: String) -> void:
	difficulty = diff
	keeper = new_keeper
	_set_map(new_map)
	if not autoplay and _ui_arg == "": # Capturas de teste não mexem nas preferências.
		Settings.difficulty = diff
		Settings.map = new_map
		Settings.keeper = new_keeper
		Settings.save()
	var d: Dictionary = Balance.DIFFICULTIES[difficulty]
	lighthouse.hp_scale = d["lighthouse_hp"]
	fog.density = float(d["fog"]) * Settings.FOG_LEVELS[clampi(Settings.fog_level, 0, 2)]
	_clear_world()
	elapsed = 0.0
	kills = 0
	kill_points = 0
	bosses_killed = 0
	relics = []
	level = 1
	xp = 0
	xp_needed = Balance.xp_for_level(level, difficulty)
	upgrade_levels = {}
	upgrade_order = []
	pending_level_ups = 0
	_levelup_waiting = false
	_next_report = 30.0
	_event_index = 0
	_sunrise = 0.0
	spawner.difficulty = difficulty
	spawner.map_id = map_id
	spawner.reset()
	spawner.active = true
	DayCycle.update(0.0)
	state = State.PLAYING
	get_tree().paused = false
	Sfx.music(&"calm")
	hud.reset_level(level)
	hud.show_playing()
	hud.announce(tr(Maps.get_map(map_id)["name"]) + "  —  " + tr("Resista até o amanhecer"))
	_update_hud()


func _process(delta: float) -> void:
	_clock += delta
	if _shake > 0.0 and Settings.screen_shake:
		_shake = maxf(0.0, _shake - delta * 30.0)
		camera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake
	else:
		_shake = 0.0
		camera.offset = Vector2.ZERO
	_ember_timer -= delta
	if _ember_timer <= 0.0:
		_ember_streak = 0
	# No menu principal a câmera desliza para a esquerda e o farol fica à direita.
	var cam_target := TITLE_CAMERA if state == State.TITLE else Vector2.ZERO
	camera.position = camera.position.lerp(cam_target, 1.0 - exp(-delta * 4.0))

	match state:
		State.TITLE:
			_title_time += delta
			DayCycle.update(pingpong(_title_time * 10.0 + 40.0, Balance.RUN_DURATION))
			lighthouse.target_angle = lighthouse.aim_angle + delta * 0.6
		State.VICTORY:
			_sunrise += delta
			DayCycle.update(Balance.RUN_DURATION + minf(_sunrise * 12.0, 60.0))
		State.PLAYING:
			_process_run(delta)
	if _cycle_arg >= 0.0:
		DayCycle.update(_cycle_arg)

	var shot_clock := elapsed if autoplay else _clock
	if _screenshot_at > 0.0 and shot_clock >= _screenshot_at:
		_screenshot_at = -1.0
		_take_screenshot()


func _process_run(delta: float) -> void:
	elapsed += delta
	spawner.elapsed = elapsed
	DayCycle.update(elapsed)
	_update_aim()
	if autoplay:
		_bot_abilities()
	var events := DayCycle.events()
	while _event_index < events.size() and elapsed / Balance.RUN_DURATION >= events[_event_index]["at"]:
		hud.announce(tr(events[_event_index]["text"]))
		Sfx.play(&"announce")
		_event_index += 1
	if _levelup_waiting and not hud.alert_blocking():
		_levelup_waiting = false
		_open_level_up()
		return
	if autoplay and elapsed >= _next_report:
		_next_report += 30.0
		print("[autoplay] %s  hp=%d/%d  nível=%d  inimigos=%d  mortes=%d" % [
			Records.format_time(elapsed), lighthouse.hp, lighthouse.max_hp, level,
			enemies_root.get_child_count(), kills])
	if elapsed >= Balance.RUN_DURATION:
		_end_run(true)
		return
	_update_hud()


func _update_aim() -> void:
	if autoplay:
		var target := _closest_enemy()
		if target:
			lighthouse.target_angle = target.position.angle()
		return

	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length() > 0.3:
		_using_mouse = false
		lighthouse.target_angle = stick.angle()
		return

	var turn := Input.get_axis(&"rotate_left", &"rotate_right")
	if absf(turn) > 0.0:
		_using_mouse = false
		lighthouse.target_angle = lighthouse.aim_angle + signf(turn) * 0.5
		return

	var mouse_screen := get_viewport().get_mouse_position()
	if mouse_screen.distance_to(_last_mouse) > 2.0:
		_using_mouse = true
		_last_mouse = mouse_screen
	if _using_mouse:
		lighthouse.target_angle = (get_global_mouse_position() - camera.offset).angle()
	else:
		lighthouse.target_angle = lighthouse.aim_angle


## O bot usa as habilidades de forma simples, para medir o jogo com elas.
func _bot_abilities() -> void:
	var near := 0
	for node in enemies_root.get_children():
		var e := node as Enemy
		if e and not e.dying and e.position.length() < 160.0:
			near += 1
	if near >= 8:
		abilities.use(0)
	if _bosses_alive > 0 or near >= 12:
		abilities.use(1)
	if embers_root.get_child_count() >= 15 or lighthouse.hp < lighthouse.max_hp * 0.5:
		abilities.use(2)


func _closest_enemy() -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for node in enemies_root.get_children():
		var e := node as Enemy
		if e == null or e.dying or e.invulnerable:
			continue
		var d := e.position.length()
		if d < best_d:
			best_d = d
			best = e
	return best


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if state == State.PLAYING:
			_set_paused(true)
		else:
			hud.back()
	elif event.is_action_pressed(&"menu_back"):
		hud.back()
	elif state == State.PLAYING and not autoplay:
		for i in 3:
			if event.is_action_pressed(StringName("ability_%d" % (i + 1))):
				abilities.use(i)


func _set_paused(paused: bool) -> void:
	state = State.PAUSED if paused else State.PLAYING
	get_tree().paused = paused
	if paused:
		var summary := "%s   •   %s   •   %s   •   %s" % [DayCycle.clock_text(elapsed), Records.format_time(elapsed),
			tr("Nível %d") % level, tr("%s pts") % Records.format_number(_current_score())]
		hud.show_pause(summary, upgrade_order)
	else:
		hud.show_playing()


# --- Inimigos, chefes, XP e melhorias ---------------------------------------

func _on_enemy_spawned(e: Enemy) -> void:
	e.killed.connect(_on_enemy_killed)


func _boss_name(id: String) -> String:
	return tr(Maps.CREATURE_NAMES[id])


func _on_boss_warning(id: String) -> void:
	if state != State.PLAYING and state != State.LEVEL_UP:
		return
	hud.announce(tr("%s se aproxima!") % _boss_name(id), UiTheme.DANGER, true)
	Sfx.play(&"warning")
	Sfx.music(&"tension")


func _on_boss_spawned(boss: Boss) -> void:
	_bosses_alive += 1
	boss.enraged_now.connect(_on_boss_enraged)
	hud.set_boss(boss)
	hud.announce(tr("%s emergiu!") % _boss_name(boss.kind), UiTheme.DANGER, true)
	Sfx.play(&"boss")
	Sfx.music(&"boss")
	_shake = 8.0


func _on_boss_enraged(boss: Boss) -> void:
	hud.announce(tr("%s está enfurecido!") % _boss_name(boss.kind), UiTheme.DANGER)
	Sfx.play(&"roar")
	_shake = 6.0


func _on_enemy_killed(enemy: Enemy) -> void:
	if state != State.PLAYING and state != State.LEVEL_UP:
		return
	kills += 1
	if enemy.is_boss():
		_on_boss_killed(enemy as Boss)
	else:
		kill_points += enemy.score_value
	if enemy.xp_value > 0:
		var pieces := 6 if enemy.is_boss() else 1
		for i in pieces:
			var ember := Ember.new()
			ember.value = maxi(1, enemy.xp_value / pieces)
			ember.position = enemy.position + (Vector2.from_angle(TAU * i / pieces) * 30.0 if pieces > 1 else Vector2.ZERO)
			ember.lighthouse = lighthouse
			ember.lifetime = Balance.DIFFICULTIES[difficulty]["ember_life"]
			ember.collected.connect(_on_ember_collected)
			embers_root.add_child(ember)
	if Settings.particles and Settings.quality > Settings.QUALITY_LOW and effects_root.get_child_count() < 150:
		var fx := BurnFx.new()
		fx.position = enemy.position
		fx.radius = enemy.radius
		fx.count = (16 if enemy.is_boss() else 7) if Settings.quality == Settings.QUALITY_HIGH else 4
		effects_root.add_child(fx)
	Sfx.play(&"burn", randf_range(0.85, 1.2), 4.0 if enemy.is_boss() else 0.0)


## Chefe derrotado: relíquia exclusiva, cura e bônus de pontos.
func _on_boss_killed(boss: Boss) -> void:
	bosses_killed += 1
	_bosses_alive = maxi(0, _bosses_alive - 1)
	relics.append(boss.kind)
	Upgrades.apply_relic(boss.kind, lighthouse)
	lighthouse.heal(Balance.BOSS_HEAL)
	var relic: Dictionary = Balance.RELICS[boss.kind]
	hud.announce(tr("%s derrotado! Relíquia: %s — %s") % [_boss_name(boss.kind), tr(relic["name"]), tr(relic["desc"])], Color(0.7, 0.9, 1.0))
	Sfx.play(&"relic")
	if _bosses_alive == 0:
		Sfx.music(&"calm")
		hud.set_boss(null)
	_shake = 10.0


func _on_ember_collected(value: int) -> void:
	xp += value
	_ember_streak += 1
	_ember_timer = 0.6
	Sfx.play(&"ember", 1.0 + minf(_ember_streak, 14) * 0.04)
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = Balance.xp_for_level(level, difficulty)
		pending_level_ups += 1
	if pending_level_ups > 0 and state == State.PLAYING and not _levelup_waiting:
		# Um aviso de chefe acabou de aparecer: deixe o jogador lê-lo primeiro.
		if hud.alert_blocking() and not autoplay:
			_levelup_waiting = true
		else:
			_open_level_up()


func _open_level_up() -> void:
	var choices := Upgrades.roll(upgrade_levels, rng, 3)
	state = State.LEVEL_UP
	if autoplay:
		_apply_upgrade(choices[rng.randi() % choices.size()]["id"])
		return
	get_tree().paused = true
	_update_hud()
	hud.show_level_up(level - pending_level_ups + 1, choices, upgrade_levels)


func _apply_upgrade(id: String) -> void:
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	upgrade_order.append(id)
	Upgrades.apply(id, lighthouse)
	pending_level_ups -= 1
	if pending_level_ups > 0:
		_open_level_up()
	else:
		state = State.PLAYING
		get_tree().paused = false
		hud.show_playing()


# --- Fim de partida -------------------------------------------------------

func _on_lighthouse_damaged(amount: float) -> void:
	_shake = minf(10.0, _shake + amount * 0.8)
	Sfx.play(&"damage", randf_range(0.9, 1.1))


func _on_lighthouse_died() -> void:
	if state == State.PLAYING or state == State.LEVEL_UP:
		_end_run(false)


func _current_score() -> int:
	return Balance.score_breakdown(kill_points, bosses_killed, elapsed, false, 0.0, difficulty)["total"]


func _end_run(victory: bool) -> void:
	state = State.VICTORY if victory else State.GAME_OVER
	var breakdown := Balance.score_breakdown(kill_points, bosses_killed, elapsed, victory, lighthouse.hp / lighthouse.max_hp, difficulty)
	if autoplay:
		print("[autoplay] FIM  mapa=%s  dificuldade=%s  vitória=%s  tempo=%s  nível=%d  mortes=%d  chefes=%d  pontos=%d  melhorias=%s" % [
			map_id, difficulty, victory, Records.format_time(elapsed), level, kills, bosses_killed, breakdown["total"], upgrade_levels])
		get_tree().quit()
		return
	var run := {
		"id": "%d-%d" % [Time.get_unix_time_from_system(), rng.randi()],
		"date": int(Time.get_unix_time_from_system()),
		"name": Settings.display_name(),
		"map": map_id,
		"keeper": keeper,
		"difficulty": difficulty,
		"victory": victory,
		"duration": elapsed,
		"level": level,
		"kills": kills,
		"bosses": bosses_killed,
		"score": breakdown["total"],
		"breakdown": breakdown,
		"upgrades": upgrade_order.duplicate(),
		"relics": relics.duplicate(),
	}
	if _ui_arg == "":
		Records.add(run)
	var context := {
		"clock": DayCycle.clock_text(elapsed),
		"hours_left": DayCycle.hours_left_text(elapsed),
		"time_left": Records.format_time(maxf(0.0, Balance.RUN_DURATION - elapsed)),
		"next": "",
	}
	var nb := spawner.next_boss()
	if not victory and not nb.is_empty() and float(nb["t"]) > elapsed:
		context["next"] = tr("Próximo marco: %s chegaria em %s.") % [_boss_name(nb["boss"]), Records.format_time(float(nb["t"]) - elapsed)]
	hud.set_boss(null)
	if victory:
		# O sol nasce: as criaturas se desfazem e o cenário clareia ao fundo.
		spawner.active = false
		for node in enemies_root.get_children():
			(node as Enemy).dissolve()
		Sfx.play(&"victory")
		Sfx.music(&"calm")
	else:
		get_tree().paused = true
		Sfx.play(&"defeat")
		Sfx.music(&"none")
	hud.show_end(run, context)


func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("user://screenshot.png")
	get_viewport().get_texture().get_image().save_png(path)
	print("[screenshot] salvo em ", path)
	if _ui_arg != "" or _cycle_arg >= 0.0:
		get_tree().quit()


func _update_hud() -> void:
	hud.update_stats(lighthouse.hp, lighthouse.max_hp, xp, xp_needed, level, elapsed, kills, _current_score())


# --- Inspeção visual (--ui=) ----------------------------------------------

func _open_debug_ui(screen: String) -> void:
	match screen:
		"map":
			hud.show_map_select()
		"keeper":
			hud.show_keeper_select()
		"difficulty":
			hud.show_difficulty()
		"settings":
			hud.show_settings(false)
		"controls", "graphics", "audio":
			hud.show_settings(false, ["", "controls", "graphics", "audio"].find(screen))
		"history":
			hud.show_history()
		"ranking":
			hud.show_ranking()
		"pause", "levelup", "end", "victory", "boss":
			start_run(map_id, keeper, difficulty)
			elapsed = 250.0
			spawner.elapsed = elapsed
			kills = 431
			kill_points = 4980
			level = 14
			xp = 30
			xp_needed = Balance.xp_for_level(level, difficulty)
			for id: String in ["wide_lens", "intense_flame", "intense_flame", "pulse", "gears", "twin_lens"]:
				_apply_upgrade_silently(id)
			for i in 30:
				spawner.spawn(["basic", "fast", "brute"][i % 3]).position *= rng.randf_range(0.35, 0.9)
			spawner.spawn_boss(Maps.boss_at(map_id, 0))
			abilities.cooldowns[1] = 12.0
			DayCycle.update(elapsed)
			_update_hud()
			if screen == "pause":
				_set_paused(true)
			elif screen == "levelup":
				pending_level_ups = 1
				_open_level_up()
			elif screen == "end":
				_end_run(false)
			elif screen == "victory":
				bosses_killed = 2
				relics.assign([Maps.boss_at(map_id, 0), Maps.boss_at(map_id, 1)])
				elapsed = Balance.RUN_DURATION
				_end_run(true)


func _apply_upgrade_silently(id: String) -> void:
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	upgrade_order.append(id)
	Upgrades.apply(id, lighthouse)
