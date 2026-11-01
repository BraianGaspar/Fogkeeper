extends Node2D
## Orquestra a partida: estados, XP, níveis, vitória e derrota.
##
## Argumentos de linha de comando (depois de `--`):
##   --autoplay     um bot joga sozinho e imprime um resumo (balanceamento)
##   --seed=N       semente fixa para partidas reproduzíveis
##   --screenshot=T salva user://screenshot.png aos T segundos (com --autoplay)

enum State { TITLE, PLAYING, LEVEL_UP, PAUSED, GAME_OVER, VICTORY }

var state: State = State.TITLE
var elapsed := 0.0
var kills := 0
var level := 1
var xp := 0
var xp_needed := 0
var upgrade_levels: Dictionary = {}
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameInput.setup()
	_parse_args()
	_build_world()
	_build_hud()
	if autoplay:
		start_run()
	else:
		state = State.TITLE
		get_tree().paused = true
		hud.show_title()


func _parse_args() -> void:
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			autoplay = true
		elif arg.begins_with("--seed="):
			rng.seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--screenshot="):
			_screenshot_at = float(arg.get_slice("=", 1))


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
	spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.killed.connect(_on_enemy_killed))
	world.add_child(spawner)


func _container(node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	world.add_child(n)
	return n


func _build_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.start_pressed.connect(start_run)
	hud.restart_pressed.connect(start_run)
	hud.resume_pressed.connect(func() -> void: _set_paused(false))
	hud.quit_pressed.connect(func() -> void: get_tree().quit())
	hud.upgrade_chosen.connect(_apply_upgrade)


# --- Fluxo da partida -----------------------------------------------------

func start_run() -> void:
	for root in [enemies_root, embers_root, effects_root]:
		for c in root.get_children():
			c.queue_free()
	elapsed = 0.0
	kills = 0
	level = 1
	xp = 0
	xp_needed = Balance.xp_for_level(level)
	upgrade_levels = {}
	pending_level_ups = 0
	_next_report = 30.0
	lighthouse.reset()
	spawner.reset()
	state = State.PLAYING
	get_tree().paused = false
	hud.show_playing()
	_update_hud()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 30.0)
		camera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake
	else:
		camera.offset = Vector2.ZERO

	if state != State.PLAYING:
		return
	elapsed += delta
	spawner.elapsed = elapsed
	_update_aim()
	if autoplay and elapsed >= _next_report:
		_next_report += 30.0
		print("[autoplay] %s  hp=%d/%d  nível=%d  inimigos=%d  mortes=%d" % [
			Hud.format_time(elapsed), lighthouse.hp, lighthouse.max_hp, level,
			enemies_root.get_child_count(), kills])
	if _screenshot_at > 0.0 and elapsed >= _screenshot_at:
		_screenshot_at = -1.0
		_take_screenshot()
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
		elif state == State.PAUSED:
			_set_paused(false)
	elif state == State.LEVEL_UP:
		for i in 3:
			if event.is_action_pressed(StringName("choose_%d" % (i + 1))):
				hud.press_choice(i)


func _set_paused(paused: bool) -> void:
	state = State.PAUSED if paused else State.PLAYING
	get_tree().paused = paused
	if paused:
		hud.show_pause()
	else:
		hud.show_playing()


# --- XP e melhorias -------------------------------------------------------

func _on_enemy_killed(enemy: Enemy) -> void:
	kills += 1
	var ember := Ember.new()
	ember.value = enemy.xp_value
	ember.position = enemy.position
	ember.lighthouse = lighthouse
	ember.collected.connect(_on_ember_collected)
	embers_root.add_child(ember)


func _on_ember_collected(value: int) -> void:
	xp += value
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = Balance.xp_for_level(level)
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
	hud.show_level_up(level, choices, upgrade_levels)


func _apply_upgrade(id: String) -> void:
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
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


func _on_lighthouse_died() -> void:
	if state == State.PLAYING or state == State.LEVEL_UP:
		_end_run(false)


func _end_run(victory: bool) -> void:
	state = State.VICTORY if victory else State.GAME_OVER
	var summary := {"time": elapsed, "level": level, "kills": kills, "victory": victory}
	if autoplay:
		print("[autoplay] FIM  vitória=%s  tempo=%s  nível=%d  mortes=%d  melhorias=%s" % [
			victory, Hud.format_time(elapsed), level, kills, upgrade_levels])
		get_tree().quit()
		return
	get_tree().paused = true
	hud.show_end(victory, summary)


func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("user://screenshot.png")
	get_viewport().get_texture().get_image().save_png(path)
	print("[autoplay] screenshot salvo em ", path)


func _update_hud() -> void:
	hud.update_stats(lighthouse.hp, lighthouse.max_hp, xp, xp_needed, level, elapsed, kills)
