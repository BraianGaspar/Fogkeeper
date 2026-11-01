extends Node2D
## Orquestra a partida: estados, XP, níveis, pontuação, vitória e derrota.
##
## Argumentos de linha de comando (depois de `--`):
##   --autoplay       um bot joga sozinho e imprime um resumo (balanceamento)
##   --seed=N         semente fixa para partidas reproduzíveis
##   --difficulty=D   easy, normal ou hard (padrão do autoplay: normal)
##   --screenshot=T   salva user://screenshot.png aos T segundos
##                    (tempo de partida no autoplay; tempo real fora dele)
##   --ui=TELA        abre direto uma tela para inspecionar o visual:
##                    difficulty, settings, history, ranking, pause, levelup, end
##   --cycle=T        fixa a hora do dia (segundos de partida) no cenário

enum State { TITLE, PLAYING, LEVEL_UP, PAUSED, GAME_OVER, VICTORY }

const TITLE_CAMERA := Vector2(-290, 0)

var state: State = State.TITLE
var difficulty := "normal"
var elapsed := 0.0
var kills := 0
var kill_points := 0
var level := 1
var xp := 0
var xp_needed := 0
var upgrade_levels: Dictionary = {}
var upgrade_order: Array[String] = []
var pending_level_ups := 0
var autoplay := false
var rng := RandomNumberGenerator.new()

var world: Node2D
var enemies_root: Node2D
var embers_root: Node2D
var effects_root: Node2D
var lighthouse: Lighthouse
var spawner: Spawner
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
var _ui_arg := ""
var _cycle_arg := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameInput.setup()
	I18n.setup()
	_parse_args()
	if not autoplay:
		Settings.load_settings()
		difficulty = Settings.difficulty
	add_child(Sfx.new())
	Settings.apply()
	DayCycle.update(0.0)
	_build_world()
	_build_hud()
	if autoplay:
		start_run(difficulty)
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
			difficulty = arg.get_slice("=", 1)
		elif arg.begins_with("--screenshot="):
			_screenshot_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--ui="):
			_ui_arg = arg.get_slice("=", 1)
		elif arg.begins_with("--cycle="):
			_cycle_arg = float(arg.get_slice("=", 1))
	if not Balance.DIFFICULTIES.has(difficulty):
		push_warning("Dificuldade desconhecida: %s; usando normal." % difficulty)
		difficulty = "normal"


func _build_world() -> void:
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	world.add_child(Background.new())
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
	world.add_child(Fog.new())

	spawner = Spawner.new()
	spawner.enemies_root = enemies_root
	spawner.lighthouse = lighthouse
	spawner.rng = rng
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	world.add_child(spawner)


func _container(node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	world.add_child(n)
	return n


func _build_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.start_requested.connect(start_run)
	hud.restart_pressed.connect(func() -> void: start_run(difficulty))
	hud.resume_pressed.connect(func() -> void: _set_paused(false))
	hud.menu_pressed.connect(go_to_title)
	hud.quit_pressed.connect(func() -> void: get_tree().quit())
	hud.upgrade_chosen.connect(_apply_upgrade)


# --- Fluxo da partida -----------------------------------------------------

func _clear_world() -> void:
	for root in [enemies_root, embers_root, effects_root]:
		for c in root.get_children():
			c.queue_free()
	spawner.active = false
	lighthouse.reset()


## Menu principal: o cenário fica vivo ao fundo, com o farol girando sozinho.
func go_to_title() -> void:
	_clear_world()
	state = State.TITLE
	get_tree().paused = false
	hud.show_title()


func start_run(diff: String) -> void:
	difficulty = diff
	if not autoplay:
		Settings.difficulty = diff
		Settings.save()
	_clear_world()
	elapsed = 0.0
	kills = 0
	kill_points = 0
	level = 1
	xp = 0
	xp_needed = Balance.xp_for_level(level, difficulty)
	upgrade_levels = {}
	upgrade_order = []
	pending_level_ups = 0
	_next_report = 30.0
	_event_index = 0
	_sunrise = 0.0
	spawner.difficulty = difficulty
	spawner.reset()
	spawner.active = true
	DayCycle.update(0.0)
	state = State.PLAYING
	get_tree().paused = false
	hud.reset_level(level)
	hud.show_playing()
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
			# Na tela inicial o dia vai e volta devagar, mostrando o cenário.
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
	while _event_index < DayCycle.EVENTS.size() and elapsed / Balance.RUN_DURATION >= DayCycle.EVENTS[_event_index]["at"]:
		hud.announce(tr(DayCycle.EVENTS[_event_index]["text"]))
		Sfx.play(&"announce")
		_event_index += 1
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


func _closest_enemy() -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for node in enemies_root.get_children():
		var e := node as Enemy
		if e == null or e.dying:
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


func _set_paused(paused: bool) -> void:
	state = State.PAUSED if paused else State.PLAYING
	get_tree().paused = paused
	if paused:
		var summary := "%s   •   %s   •   %s" % [Records.format_time(elapsed), tr("Nível %d") % level,
			tr("%s pts") % Records.format_number(_current_score())]
		hud.show_pause(summary, upgrade_order)
	else:
		hud.show_playing()


# --- Inimigos, XP e melhorias -----------------------------------------------

func _on_enemy_spawned(e: Enemy) -> void:
	e.killed.connect(_on_enemy_killed)
	if Balance.ENEMIES[e.kind].get("boss", false) and state == State.PLAYING:
		hud.announce(tr("O Leviatã emergiu das profundezas!"), UiTheme.DANGER)
		Sfx.play(&"boss")
		_shake = 8.0


func _on_enemy_killed(enemy: Enemy) -> void:
	if state != State.PLAYING and state != State.LEVEL_UP:
		return
	kills += 1
	kill_points += int(Balance.ENEMIES[enemy.kind].get("score", 0))
	var ember := Ember.new()
	ember.value = enemy.xp_value
	ember.position = enemy.position
	ember.lighthouse = lighthouse
	ember.collected.connect(_on_ember_collected)
	embers_root.add_child(ember)
	var boss: bool = Balance.ENEMIES[enemy.kind].get("boss", false)
	if Settings.quality > Settings.QUALITY_LOW and effects_root.get_child_count() < 150:
		var fx := BurnFx.new()
		fx.position = enemy.position
		fx.radius = enemy.radius
		fx.count = (16 if boss else 7) if Settings.quality == Settings.QUALITY_HIGH else 4
		effects_root.add_child(fx)
	Sfx.play(&"burn", randf_range(0.85, 1.2), 4.0 if boss else 0.0)
	if boss:
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
	if pending_level_ups > 0 and state == State.PLAYING:
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
	return Balance.score_breakdown(kill_points, elapsed, false, 0.0, difficulty)["total"]


func _end_run(victory: bool) -> void:
	state = State.VICTORY if victory else State.GAME_OVER
	var breakdown := Balance.score_breakdown(kill_points, elapsed, victory, lighthouse.hp / lighthouse.max_hp, difficulty)
	if autoplay:
		print("[autoplay] FIM  vitória=%s  tempo=%s  nível=%d  mortes=%d  pontos=%d  melhorias=%s" % [
			victory, Records.format_time(elapsed), level, kills, breakdown["total"], upgrade_levels])
		get_tree().quit()
		return
	var run := {
		"id": "%d-%d" % [Time.get_unix_time_from_system(), rng.randi()],
		"date": int(Time.get_unix_time_from_system()),
		"name": Settings.display_name(),
		"difficulty": difficulty,
		"victory": victory,
		"duration": elapsed,
		"level": level,
		"kills": kills,
		"score": breakdown["total"],
		"breakdown": breakdown,
		"upgrades": upgrade_order.duplicate(),
	}
	if _ui_arg == "":
		Records.add(run)
	if victory:
		# O sol nasce: as criaturas se desfazem e o cenário clareia ao fundo.
		spawner.active = false
		for node in enemies_root.get_children():
			(node as Enemy).dissolve()
		Sfx.play(&"victory")
	else:
		get_tree().paused = true
		Sfx.play(&"defeat")
	hud.show_end(run)


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
		"difficulty":
			hud.show_difficulty()
		"settings":
			hud.show_settings(false)
		"history":
			hud.show_history()
		"ranking":
			hud.show_ranking()
		"pause", "levelup", "end":
			start_run(difficulty)
			elapsed = 252.0
			kills = 431
			kill_points = 4980
			level = 14
			xp = 30
			xp_needed = Balance.xp_for_level(level, difficulty)
			for id: String in ["wide_lens", "intense_flame", "intense_flame", "pulse", "gears", "twin_lens"]:
				_apply_upgrade_silently(id)
			for i in 40:
				spawner.spawn(["mist", "runner", "brute"][i % 3]).position *= rng.randf_range(0.35, 0.9)
			DayCycle.update(elapsed)
			_update_hud()
			if screen == "pause":
				_set_paused(true)
			elif screen == "levelup":
				pending_level_ups = 1
				_open_level_up()
			else:
				_end_run(false)


func _apply_upgrade_silently(id: String) -> void:
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	upgrade_order.append(id)
	Upgrades.apply(id, lighthouse)
