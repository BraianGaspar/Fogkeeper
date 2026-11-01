extends Node2D
## Orquestra a partida: estados, XP, níveis, chefes, pontuação, fim de jogo,
## modo sem fim, tutorial e a progressão entre partidas.
##
## Argumentos de linha de comando (depois de `--`):
##   --autoplay       um bot joga sozinho e imprime um resumo (balanceamento)
##   --seed=N         semente fixa para partidas reproduzíveis
##   --difficulty=D   easy, normal, medium, hard ou impossible (padrão: normal)
##   --map=M          bay, fjord ou amazon (padrão: bay)
##   --keeper=K       aparência do farol (classic, stone, iron, crystal)
##   --screenshot=T   salva user://screenshot.png aos T segundos
##                    (tempo de partida no autoplay; tempo real fora dele)
##   --ui=TELA        abre direto uma tela para inspecionar o visual:
##                    map, keeper, difficulty, settings, controls, graphics,
##                    audio, accessibility, history, ranking, workshop, achievements,
##                    story, hero, bestiary, credits, daily,
##                    pause, levelup, end, victory, boss, endless, tutorial
##   --cycle=T        fixa a hora do dia (segundos de partida) no cenário
##   --no-save        não grava progresso (testes que abrem o jogo normalmente)
##   --locale=L       idioma só nesta execução (pt_BR, en, es, fr, de, ru, zh_CN, ja, ko)
##   --trailer=L      grava o trailer (en ou pt); use com --write-movie (ver Trailer)
##   --tutorial       com --autoplay: o bot faz o tutorial inteiro (teste dos passos)
##   --mode=M         com --autoplay: daily (desafio diário) ou boss_rush (Modo Chefões)

enum State { TITLE, STORY, PLAYING, LEVEL_UP, PAUSED, GAME_OVER, VICTORY }

const TITLE_CAMERA := Vector2(-290, 0)
const TUTORIAL_CLOCK := 140.0 ## Hora fixa do cenário no tutorial (noite clara).
const ACHIEVEMENT_COLOR := Color(0.45, 0.95, 0.85)

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
var endless := false
var nights := 0 ## Noites extras completas no modo sem fim.
var rerolls := 0
var banishes := 0
var banished: Array[String] = []
var hero := "keeper" ## Faroleiro jogável (Balance.HEROES).
var tide := 0 ## Maré escolhida (níveis de desafio).
var mode := "normal" ## "normal", "daily" (desafio diário) ou "boss_rush" (Modo Chefões).
var daily_date := "" ## Data do desafio diário, "AAAA-MM-DD".
var autoplay := false
var tutorial: Tutorial = null
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
var _choices: Array = []
var _run: Dictionary = {} ## Partida já salva (o modo sem fim a atualiza).
var _oil_paid := 0 ## Óleo já pago por esta partida.
var _kills_counted := 0 ## Criaturas desta partida já somadas ao total.
var _ui_arg := ""
var _cycle_arg := -1.0
var _arg_map := ""
var _arg_keeper := ""
var _arg_difficulty := ""
var _no_save := false
var _arg_tutorial := false
var _arg_locale := ""
var _arg_mode := ""
var _trailer := ""
var _rush_queue: Array = [] ## Modo Chefões: [mapa, chefe] ainda por vir.
var _rush_wait := 0.0
var _force := {} ## Regras fixas da próxima partida (desafio diário): hero, tide, seed.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameInput.setup()
	I18n.setup()
	_parse_args()
	if not autoplay:
		Settings.load_settings()
	elif _trailer == "":
		Settings.window_mode = Settings.WINDOWED # Testes do bot não tomam a tela.
	# O bot mede o jogo puro: sem progressão. Capturas leem, mas não gravam.
	Progress.enabled = not autoplay
	Progress.read_only = _ui_arg != "" or _cycle_arg >= 0.0 or _no_save
	Progress.load_progress()
	if not autoplay:
		SteamService.init()
	difficulty = _arg_difficulty if _arg_difficulty != "" else (Settings.difficulty if not autoplay else "normal")
	map_id = _arg_map if _arg_map != "" else (Settings.map if not autoplay else "bay")
	keeper = _arg_keeper if _arg_keeper != "" else Settings.keeper
	# Argumentos de inspeção valem só nesta execução (não são salvos).
	Settings.map = map_id
	Settings.keeper = keeper
	Settings.difficulty = difficulty
	if _arg_locale != "":
		Settings.locale = _arg_locale
	Sfx.synchronous = _trailer != ""
	add_child(Sfx.new())
	add_child(ColorFilter.new())
	Settings.apply()
	_build_world()
	_build_hud()
	_set_map(map_id)
	Achievements.listener = _on_achievement
	if _trailer != "":
		Settings.locale = "en" if _trailer == "en" else "pt_BR"
		Settings.apply()
		var tr_node := Trailer.new()
		tr_node.main = self
		tr_node.lang = "en" if _trailer == "en" else "pt"
		add_child(tr_node)
		trailer_title()
	elif autoplay and _arg_tutorial:
		start_tutorial()
	elif autoplay and _arg_mode == "boss_rush":
		start_boss_rush()
	elif autoplay and _arg_mode == "daily":
		start_daily()
	elif autoplay:
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
		elif arg.begins_with("--trailer="):
			_trailer = arg.get_slice("=", 1)
			autoplay = true
		elif arg.begins_with("--mode="):
			_arg_mode = arg.get_slice("=", 1)
		elif arg.begins_with("--locale="):
			_arg_locale = arg.get_slice("=", 1)
		elif arg == "--tutorial":
			_arg_tutorial = true
		elif arg == "--no-save":
			_no_save = true
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
	spawner.embers_root = embers_root
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
	abilities.used.connect(_on_ability_used)


func _container(node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	world.add_child(n)
	return n


func _build_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.abilities = abilities
	hud.start_requested.connect(func(m: String, k: String, d: String) -> void: start_run(m, k, d, true))
	hud.restart_pressed.connect(_restart)
	hud.resume_pressed.connect(func() -> void: _set_paused(false))
	hud.menu_pressed.connect(go_to_title)
	hud.quit_pressed.connect(_quit)
	hud.upgrade_chosen.connect(_apply_upgrade)
	hud.reroll_pressed.connect(_reroll)
	hud.banish_pressed.connect(_banish)
	hud.story_finished.connect(_begin_night)
	hud.endless_pressed.connect(continue_endless)
	hud.tutorial_requested.connect(start_tutorial)
	hud.daily_requested.connect(start_daily)
	hud.boss_rush_requested.connect(start_boss_rush)
	hud.pause_requested.connect(func() -> void:
		if state == State.PLAYING:
			_set_paused(true)
	)


## Troca cenário, paleta e trilha calma para o mapa.
func _set_map(id: String) -> void:
	map_id = id
	DayCycle.set_map(id)
	Sfx.set_map(id)
	var scenery: String = Maps.get_map(id)["scenery"]
	var want: Script = {"fjord": FjordBackground, "river": RiverBackground, "japan": JapanBackground, "desert": DesertBackground}.get(scenery, Background)
	if background.get_script() != want:
		background.queue_free()
		background = want.new()
		world.add_child(background)
		world.move_child(background, 0)


# --- Fluxo da partida -----------------------------------------------------

func _clear_world() -> void:
	for root in [enemies_root, embers_root, effects_root]:
		for c in root.get_children():
			c.queue_free()
	spawner.active = false
	_bosses_alive = 0
	Engine.time_scale = 1.0
	lighthouse.keeper = keeper
	lighthouse.reset()
	abilities.reset(_loadout())


## As três habilidades equipadas (as liberadas; o bot e o tutorial usam as básicas).
func _loadout() -> Array:
	if autoplay or _force.get("default_loadout", false) or state == State.TITLE:
		return Abilities.DEFAULT_LOADOUT
	for id: String in Settings.loadout:
		if not Progress.is_unlocked(id):
			return Abilities.DEFAULT_LOADOUT
	return Settings.loadout


## Menu principal: o cenário do último mapa fica vivo ao fundo, com o farol
## girando sozinho.
func go_to_title() -> void:
	_save_endless_progress()
	_drop_tutorial()
	keeper = Settings.keeper
	_set_map(Settings.map)
	_clear_world()
	state = State.TITLE
	get_tree().paused = false
	Sfx.music(&"calm")
	hud.show_title()


func _restart() -> void:
	_save_endless_progress()
	if tutorial:
		start_tutorial()
	elif mode == "daily":
		start_daily()
	elif mode == "boss_rush":
		start_boss_rush()
	else:
		start_run(map_id, keeper, difficulty)


func _quit() -> void:
	_save_endless_progress()
	get_tree().quit()


## Começa uma partida. Vindo do menu, mostra antes a história do mapa.
func start_run(new_map: String, new_keeper: String, diff: String, from_menu: bool = false) -> void:
	if from_menu:
		mode = "normal"
	_setup_run(new_map, new_keeper, diff)
	if from_menu and Settings.show_story and not autoplay and _ui_arg == "":
		state = State.STORY
		get_tree().paused = true
		Sfx.music(&"calm")
		hud.show_story(map_id)
	else:
		_begin_night()


func _drop_tutorial() -> void:
	if tutorial:
		tutorial.queue_free()
		tutorial = null
	hud.clear_tutorial()


## Zera tudo para uma partida nova (sem começá-la). O modo ("normal",
## "daily", "boss_rush") e as regras fixas do diário vêm de `mode` e `_force`.
func _setup_run(new_map: String, new_keeper: String, diff: String) -> void:
	difficulty = diff
	keeper = new_keeper
	_set_map(new_map)
	if not autoplay and _ui_arg == "" and mode == "normal": # Capturas e modos especiais não mexem nas preferências.
		Settings.difficulty = diff
		Settings.map = new_map
		Settings.keeper = new_keeper
		Settings.save()
	hero = _force.get("hero", Settings.hero if Progress.is_unlocked(Settings.hero) else "keeper")
	tide = _force.get("tide", Settings.tide)
	if autoplay or tutorial:
		hero = "keeper"
		tide = 0
	if _force.has("seed"):
		rng.seed = _force["seed"]
	var d: Dictionary = Balance.DIFFICULTIES[difficulty]
	lighthouse.hp_scale = float(d["lighthouse_hp"]) * Balance.tide(tide, "lighthouse")
	fog.density = float(d["fog"]) * Settings.FOG_LEVELS[clampi(Settings.fog_level, 0, 2)] + Balance.tide(tide, "fog")
	_drop_tutorial()
	_clear_world()
	Upgrades.apply_meta(lighthouse)
	lighthouse.apply_hero(hero)
	DamageStats.reset()
	_rush_queue = []
	elapsed = 0.0
	kills = 0
	kill_points = 0
	bosses_killed = 0
	relics = []
	level = 1
	xp = 0
	xp_needed = _xp_for(level)
	upgrade_levels = {}
	upgrade_order = []
	pending_level_ups = 0
	endless = false
	nights = 0
	rerolls = maxi(0, Balance.BASE_REROLLS + Progress.level("reroll") + int(Balance.tide(tide, "reroll")))
	banishes = Balance.BASE_BANISHES + Progress.level("banish")
	banished = []
	_run = {}
	_oil_paid = 0
	_kills_counted = 0
	_levelup_waiting = false
	_next_report = 30.0
	_event_index = 0
	_sunrise = 0.0
	spawner.difficulty = difficulty
	spawner.map_id = map_id
	spawner.tide = tide
	spawner.reset()
	DayCycle.update(0.0)
	hud.reset_level(level)
	hud.set_endless(false)
	_update_hud()
	_force = {}


## A noite começa de fato: criaturas, música e o primeiro aviso.
func _begin_night() -> void:
	state = State.PLAYING
	get_tree().paused = false
	spawner.active = tutorial == null
	Sfx.music(&"calm")
	hud.show_playing()
	if tutorial:
		return
	hud.announce(tr(Maps.get_map(map_id)["name"]) + "  —  " + tr("Resista até o amanhecer"))
	if Progress.level("head_start") > 0:
		var pick: Dictionary = Upgrades.roll(upgrade_levels, rng, 1, banished)[0]
		_apply_upgrade_silently(pick["id"])
		hud.announce(tr("Pavio aceso: %s") % tr(pick["name"]), UiTheme.GOLD)


## Tutorial: partida de treino guiada na Baía, sem relógio nem chefes marcados.
func start_tutorial() -> void:
	mode = "normal"
	_force = {"hero": "keeper", "tide": 0, "default_loadout": true}
	_setup_run("bay", Settings.keeper, "easy")
	lighthouse.regen = 4.0
	tutorial = Tutorial.new()
	tutorial.main = self
	add_child(tutorial)
	tutorial.finished.connect(_on_tutorial_finished)
	DayCycle.update(TUTORIAL_CLOCK)
	_begin_night()
	tutorial.begin()


func _on_tutorial_finished() -> void:
	if autoplay:
		print("[tutorial] concluído em %s" % Records.format_time(elapsed))
		get_tree().quit()
		return
	var first := not Progress.tutorial_done
	Progress.tutorial_done = true
	if first:
		Progress.add_oil(Balance.OIL_TUTORIAL)
	Progress.save()
	Achievements.unlock("apprentice")
	tutorial.queue_free()
	tutorial = null
	hud.clear_tutorial()
	state = State.GAME_OVER
	get_tree().paused = true
	hud.show_tutorial_done(Balance.OIL_TUTORIAL if first else 0)


## Depois do amanhecer: a névoa volta e a partida segue noite adentro.
func continue_endless() -> void:
	endless = true
	state = State.PLAYING
	get_tree().paused = false
	spawner.start_endless(elapsed)
	_event_index = 0
	hud.set_endless(true)
	hud.show_playing()
	Sfx.music(&"calm")
	hud.announce(tr("A névoa volta. Noite %d!") % (nights + 2), UiTheme.DANGER, true)
	Sfx.play(&"warning")


## XP para subir do nível dado (o Pescador sobe mais rápido).
func _xp_for(lv: int) -> int:
	return maxi(1, roundi(Balance.xp_for_level(lv, difficulty) * float(Balance.HEROES[hero].get("xp", 1.0))))


## Desafio diário: mapa, faroleiro, maré e semente do dia; ranking próprio.
func start_daily() -> void:
	var rules := Records.daily_rules(Time.get_date_dict_from_system())
	mode = "daily"
	daily_date = rules["date"]
	_force = {"hero": rules["hero"], "tide": rules["tide"], "seed": rules["seed"]}
	start_run(rules["map"], Settings.keeper, "normal")
	hud.announce(tr("Desafio diário de %s") % daily_date, Color(0.5, 0.85, 1.0), true)


## Modo Chefões: todos os chefes, mapa por mapa, um depois do outro.
func start_boss_rush() -> void:
	mode = "boss_rush"
	_setup_run("bay", Settings.keeper, "normal")
	for m: String in Maps.ORDER:
		for b: String in Maps.get_map(m)["bosses"]:
			_rush_queue.append([m, b])
	spawner.clear_schedule()
	_rush_wait = 3.0
	_begin_night()
	hud.announce(tr("Modo Chefões: %d chefes até o fim") % _rush_queue.size(), UiTheme.DANGER, true)
	# Monta a build antes do primeiro chefe.
	level = 1 + Balance.BOSS_RUSH_START_PICKS
	xp_needed = _xp_for(level)
	pending_level_ups = Balance.BOSS_RUSH_START_PICKS
	_open_level_up()


## Chama o próximo chefe quando o anterior cai; vitória quando acabam.
func _process_rush(delta: float) -> void:
	# As criaturas comuns ficam mais fortes a cada chefe derrotado.
	spawner.elapsed = minf(90.0 + 35.0 * bosses_killed, 480.0)
	if _bosses_alive > 0:
		return
	if _rush_queue.is_empty():
		if bosses_killed > 0:
			_end_run(true)
		return
	_rush_wait -= delta
	if _rush_wait > 0.0:
		return
	var next: Array = _rush_queue.pop_front()
	if next[0] != map_id:
		_set_map(next[0])
		spawner.map_id = map_id
		hud.announce(tr(Maps.get_map(map_id)["name"]))
	_on_boss_warning(next[1])
	spawner.spawn_boss(next[1])
	_rush_wait = Balance.BOSS_RUSH_PAUSE


## Hora do ciclo do dia: no modo sem fim, cada noite recomeça às 18:00.
func _cycle_time() -> float:
	if endless:
		return fposmod(elapsed - Balance.RUN_DURATION, Balance.RUN_DURATION)
	if tutorial:
		return TUTORIAL_CLOCK
	if mode == "boss_rush":
		return 260.0
	return elapsed


func _process(delta: float) -> void:
	_clock += delta
	SteamService.tick()
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
	var cam_target := TITLE_CAMERA if state == State.TITLE and _trailer == "" else Vector2.ZERO
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

	var shot_clock := elapsed if autoplay and _trailer == "" else _clock
	if _screenshot_at > 0.0 and shot_clock >= _screenshot_at:
		_screenshot_at = -1.0
		_take_screenshot()


func _process_run(delta: float) -> void:
	elapsed += delta
	spawner.elapsed = elapsed
	DayCycle.update(_cycle_time())
	_update_aim()
	if autoplay:
		_bot_abilities()
	if tutorial:
		tutorial.tick(delta)
		_update_hud()
		return
	if mode == "boss_rush":
		_process_rush(delta)
		if _levelup_waiting and not hud.alert_blocking():
			_levelup_waiting = false
			_open_level_up()
		_update_hud()
		return
	var events := DayCycle.events()
	var cycle_f := _cycle_time() / Balance.RUN_DURATION
	while _event_index < events.size() and cycle_f >= events[_event_index]["at"]:
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
	if endless:
		if elapsed >= Balance.RUN_DURATION * (nights + 2):
			_night_survived()
	elif elapsed >= Balance.RUN_DURATION:
		_end_run(true)
		return
	_update_hud()


## Modo sem fim: mais uma noite inteira sobrevivida.
func _night_survived() -> void:
	nights += 1
	_event_index = 0
	hud.announce(tr("Noite %d sobrevivida! +%s pontos") % [nights + 1, Records.format_number(Balance.SCORE_PER_NIGHT)], UiTheme.GOOD, true)
	Sfx.play(&"victory")
	Achievements.unlock("endless")


func _update_aim() -> void:
	if autoplay:
		# Diante de um enigma da Esfinge, o bot responde (como um jogador atento).
		for node in enemies_root.get_children():
			if node is Sphinx and (node as Sphinx).riddling():
				lighthouse.target_angle = (node as Sphinx).answer_angle()
				return
		var target := _closest_enemy()
		if target:
			lighthouse.target_angle = target.position.angle()
		else:
			lighthouse.target_angle = lighthouse.aim_angle + 0.5 # Varre a névoa esperando.
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
	if _using_mouse and not hud.pointer_on_controls():
		lighthouse.target_angle = (get_global_mouse_position() - camera.offset).angle()
	elif _using_mouse:
		lighthouse.target_angle = lighthouse.aim_angle
	else:
		lighthouse.target_angle = lighthouse.aim_angle


## O bot usa as habilidades de forma simples, para medir o jogo com elas.
func _bot_abilities() -> void:
	if tutorial:
		if tutorial.step == Tutorial.Step.ABILITIES:
			for i in 3:
				if abilities.is_ready(i):
					abilities.use(i)
		return
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
		if e == null or e.dying or e.invulnerable or e.immune_to_light():
			continue
		var d := e.position.length()
		if d < best_d:
			best_d = d
			best = e
	return best


## Celular: o app foi para segundo plano (ligação, outro app): pausa a partida.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING and not autoplay:
		_set_paused(true)


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
	Engine.time_scale = 1.0
	if paused:
		var summary := "%s   •   %s   •   %s   •   %s" % [DayCycle.clock_text(_cycle_time()), Records.format_time(elapsed),
			tr("Nível %d") % level, tr("%s pts") % Records.format_number(_current_score())]
		hud.show_pause(summary, upgrade_order)
	else:
		hud.show_playing()


# --- Inimigos, chefes, XP e melhorias ---------------------------------------

func _on_enemy_spawned(e: Enemy) -> void:
	e.killed.connect(_on_enemy_killed)
	e.escaped.connect(_on_enemy_escaped)


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
	if boss is Cuca:
		(boss as Cuca).interrupted.connect(func() -> void: hud.announce(tr("Feitiço da Cuca interrompido!"), UiTheme.GOOD))
	hud.set_boss(boss)
	hud.announce(tr("%s emergiu!") % _boss_name(boss.kind), UiTheme.DANGER, true)
	Sfx.play(&"boss")
	Sfx.music(&"boss")
	_ring_fx(boss.position, 140.0, Color(1.0, 0.3, 0.25), 0.8, 8.0)
	_shake = 8.0


func _on_boss_enraged(boss: Boss) -> void:
	hud.announce(tr("%s está enfurecido!") % _boss_name(boss.kind), UiTheme.DANGER)
	Sfx.play(&"roar")
	_shake = 6.0


func _on_enemy_escaped(enemy: Enemy) -> void:
	if tutorial:
		tutorial.on_escape(enemy)
	if enemy.carried > 0 and (state == State.PLAYING or state == State.LEVEL_UP):
		hud.announce(tr("%s fugiu com %d brasas!") % [tr(Maps.CREATURE_NAMES[enemy.art]), enemy.carried], UiTheme.TEXT_DIM)


func _on_enemy_killed(enemy: Enemy) -> void:
	if state != State.PLAYING and state != State.LEVEL_UP:
		return
	kills += 1
	Progress.add_stat("seen_" + enemy.art)
	if enemy.is_boss():
		_on_boss_killed(enemy as Boss)
	else:
		kill_points += enemy.score_value
	var pieces := 6 if enemy.is_boss() else 1
	if enemy.kind == "thief" and enemy.carried > 0:
		pieces = 1 + mini(enemy.carried, 10)
		Achievements.unlock("thief")
	if enemy.xp_value > 0 or pieces > 1:
		for i in pieces:
			var ember := Ember.new()
			ember.value = maxi(1, enemy.xp_value / pieces) if enemy.is_boss() else (enemy.xp_value if i == 0 else 1)
			ember.position = enemy.position + (Vector2.from_angle(TAU * i / pieces) * 30.0 if pieces > 1 else Vector2.ZERO)
			ember.lighthouse = lighthouse
			ember.lifetime = (float(Balance.DIFFICULTIES[difficulty]["ember_life"]) + 1.5 * Progress.level("long_wick")) * Balance.tide(tide, "ember")
			ember.collected.connect(_on_ember_collected)
			embers_root.add_child(ember)
	var big := enemy.is_boss() or enemy.elite or enemy.radius >= 18.0
	if Settings.particles and Settings.quality > Settings.QUALITY_LOW and effects_root.get_child_count() < 150:
		var fx := BurnFx.new()
		fx.position = enemy.position
		fx.radius = enemy.radius
		fx.count = (16 if big else 7) if Settings.quality == Settings.QUALITY_HIGH else 4
		effects_root.add_child(fx)
		if big:
			_ring_fx(enemy.position, enemy.radius * 3.0, Color(1.0, 0.75, 0.4), 0.3, 4.0)
	if big and not enemy.is_boss():
		Sfx.play(&"burn_big", randf_range(0.9, 1.1))
		_hit_stop(0.05)
		_shake = maxf(_shake, 3.0)
	else:
		Sfx.play(&"burn", randf_range(0.85, 1.2), 4.0 if enemy.is_boss() else 0.0)
	if lighthouse.combustion > 0:
		_explode.call_deferred(enemy.position, lighthouse.combustion)
	if tutorial:
		tutorial.on_kill(enemy)


## Combustão: a criatura queimada explode e fere as vizinhas.
func _explode(at: Vector2, lv: int) -> void:
	var r := Balance.COMBUSTION_RADIUS + 15.0 * lv
	var dmg := Balance.COMBUSTION_DAMAGE * lv * lighthouse.beam_dps / Balance.BEAM_DPS
	for node in enemies_root.get_children():
		var e := node as Enemy
		if e and not e.dying and not e.is_boss() and e.position.distance_to(at) <= r + e.radius:
			e.take_light(dmg)
	_ring_fx(at, r, Color(1.0, 0.55, 0.2), 0.3, 3.0)


## Chefe derrotado: relíquia exclusiva, cura e bônus de pontos.
func _on_boss_killed(boss: Boss) -> void:
	bosses_killed += 1
	_bosses_alive = maxi(0, _bosses_alive - 1)
	relics.append(boss.kind)
	Upgrades.apply_relic(boss.kind, lighthouse)
	if Balance.tide(tide, "no_heal") <= 0.0:
		lighthouse.heal(Balance.BOSS_HEAL)
	var relic: Dictionary = Balance.RELICS[boss.kind]
	hud.announce(tr("%s derrotado! Relíquia: %s — %s") % [_boss_name(boss.kind), tr(relic["name"]), tr(relic["desc"])], Color(0.7, 0.9, 1.0))
	Sfx.play(&"relic")
	Achievements.unlock("boss_" + boss.kind)
	if _bosses_alive == 0:
		Sfx.music(&"calm")
		hud.set_boss(null)
	_ring_fx(boss.position, 260.0, Color(1.0, 0.9, 0.6), 0.9, 10.0)
	_hit_stop(0.3)
	_shake = 12.0


func _on_ember_collected(value: int) -> void:
	xp += value
	_ember_streak += 1
	_ember_timer = 0.6
	if lighthouse.ember_heal > 0.0:
		lighthouse.heal(lighthouse.ember_heal)
	Sfx.play(&"ember", 1.0 + minf(_ember_streak, 14) * 0.04)
	if tutorial:
		tutorial.on_ember()
		if not tutorial.allows_level_up():
			xp = mini(xp, xp_needed - 1)
			return
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = _xp_for(level)
		pending_level_ups += 1
	if pending_level_ups > 0 and state == State.PLAYING and not _levelup_waiting:
		# Um aviso de chefe acabou de aparecer: deixe o jogador lê-lo primeiro.
		if hud.alert_blocking() and not autoplay:
			_levelup_waiting = true
		else:
			_open_level_up()


## Tutorial: sobe um nível na hora certa, para ensinar a escolha.
func force_level_up() -> void:
	level += 1
	xp = 0
	xp_needed = _xp_for(level)
	pending_level_ups += 1
	_open_level_up()


func _card_count() -> int:
	return 3 + Progress.level("fourth_card")


func _open_level_up(reroll: bool = false) -> void:
	if not reroll:
		_choices = Upgrades.roll(upgrade_levels, rng, _card_count(), banished)
	state = State.LEVEL_UP
	if autoplay:
		_apply_upgrade(_choices[rng.randi() % _choices.size()]["id"])
		return
	get_tree().paused = true
	Engine.time_scale = 1.0
	_update_hud()
	_ring_fx(Vector2.ZERO, 200.0, UiTheme.GOLD, 0.6, 6.0)
	hud.show_level_up(level - pending_level_ups + 1, _choices, upgrade_levels, rerolls, banishes, tutorial != null)


func _reroll() -> void:
	if rerolls <= 0 or state != State.LEVEL_UP:
		Sfx.play(&"denied")
		return
	rerolls -= 1
	_choices = Upgrades.roll(upgrade_levels, rng, _card_count(), banished)
	_open_level_up(true)


func _banish(id: String) -> void:
	if banishes <= 0 or state != State.LEVEL_UP or Upgrades.is_evolution(id) or id == Upgrades.FALLBACK["id"]:
		Sfx.play(&"denied")
		return
	banishes -= 1
	banished.append(id)
	hud.announce(tr("%s banida desta partida.") % tr(Upgrades.find(id)["name"]), UiTheme.TEXT_DIM)
	_choices = Upgrades.roll(upgrade_levels, rng, _card_count(), banished)
	_open_level_up(true)


func _apply_upgrade(id: String) -> void:
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	upgrade_order.append(id)
	Upgrades.apply(id, lighthouse)
	pending_level_ups -= 1
	if Upgrades.is_evolution(id):
		hud.announce(tr("Evolução: %s!") % tr(Upgrades.find(id)["name"]), Color(0.85, 0.7, 1.0), true)
		Achievements.unlock("evolution")
		_ring_fx(Vector2.ZERO, 320.0, Color(0.85, 0.7, 1.0), 0.9, 8.0)
	if tutorial:
		tutorial.on_upgrade()
	if pending_level_ups > 0:
		_open_level_up()
	else:
		state = State.PLAYING
		get_tree().paused = false
		hud.show_playing()


func _on_ability_used(i: int) -> void:
	if tutorial:
		tutorial.on_ability(i)


# --- Efeitos ------------------------------------------------------------------

func _ring_fx(at: Vector2, radius: float, color: Color, duration: float, width: float) -> void:
	if not Settings.particles or Settings.reduce_flashes or (autoplay and _trailer == ""):
		return
	var fx := RingFx.new()
	fx.position = at
	fx.max_radius = radius
	fx.color = color
	fx.duration = duration
	fx.width = width
	effects_root.add_child(fx)


## Congela a ação por um instante nos golpes fortes (pode ser desligado).
func _hit_stop(seconds: float) -> void:
	if not Settings.hit_stop or (autoplay and _trailer == "") or Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.08
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


# --- Fim de partida -------------------------------------------------------

func _on_lighthouse_damaged(amount: float) -> void:
	_shake = minf(10.0, _shake + amount * 0.8)
	hud.hurt(amount / maxf(1.0, lighthouse.max_hp))
	Sfx.play(&"damage", randf_range(0.9, 1.1))


func _on_lighthouse_died() -> void:
	if tutorial or _trailer != "":
		lighthouse.revive()
		hud.announce(tr("O farol foi reacendido. Tente de novo!"))
		return
	if state == State.PLAYING or state == State.LEVEL_UP:
		_end_run(false)


func _current_score() -> int:
	return Balance.score_breakdown(kill_points, bosses_killed, elapsed, endless, 0.0, difficulty, tide, mode == "boss_rush")["total"]


func _build_run(victory: bool) -> Dictionary:
	var hp_fraction: float = lighthouse.hp / lighthouse.max_hp if victory else float(_run.get("hp_fraction", 0.0))
	var won := victory or endless
	var breakdown := Balance.score_breakdown(kill_points, bosses_killed, elapsed, won, hp_fraction, difficulty, tide, mode == "boss_rush")
	return {
		"id": _run.get("id", "%d-%d" % [Time.get_unix_time_from_system(), rng.randi()]),
		"date": _run.get("date", int(Time.get_unix_time_from_system())),
		"name": Settings.display_name(),
		"map": map_id,
		"keeper": keeper,
		"difficulty": difficulty,
		"victory": won,
		"duration": elapsed,
		"level": level,
		"kills": kills,
		"bosses": bosses_killed,
		"score": breakdown["total"],
		"breakdown": breakdown,
		"upgrades": upgrade_order.duplicate(),
		"relics": relics.duplicate(),
		"hp_fraction": hp_fraction,
		"hero": hero,
		"tide": tide,
		"mode": mode,
		"daily": daily_date if mode == "daily" else "",
		"damage": DamageStats.ranked(),
		"embers": [DamageStats.embers_collected, DamageStats.embers_lost],
	}


## Salva a partida (ou atualiza a do amanhecer, no modo sem fim), paga o óleo
## e confere metas e conquistas. Devolve o que a tela de fim deve mostrar.
func _record_run(run: Dictionary) -> Dictionary:
	var out := {"oil": 0, "unlocks": [], "achievements": []}
	if _ui_arg != "":
		return out
	if _run.is_empty():
		Records.add(run)
		Progress.add_stat("runs")
		if run["victory"]:
			Progress.add_stat("wins")
	else:
		Records.update(run)
	_run = run
	Progress.add_stat("kills", kills - _kills_counted)
	_kills_counted = kills
	var oil := maxi(0, Progress.oil_for(int(run["score"])) - _oil_paid)
	_oil_paid += oil
	Progress.add_oil(oil, false)
	out["oil"] = oil
	# Ver o amanhecer na maré mais alta libera a próxima (Normal ou acima).
	if run["victory"] and mode != "boss_rush" and difficulty != "easy" and tide >= Progress.stat("tide_max"):
		Progress.stats["tide_max"] = mini(tide + 1, Balance.TIDES.size())
		if tide + 1 <= Balance.TIDES.size():
			out["unlocks"].append(tr("Maré %d") % (tide + 1))
	var special: Array[String] = []
	if run["victory"] and tide >= Balance.TIDES.size():
		special.append("tide_10")
	if mode == "daily":
		special.append("daily")
	if mode == "boss_rush" and run["victory"]:
		special.append("boss_rush")
	for id in special:
		if Achievements.unlock(id, false):
			out["achievements"].append(tr(Achievements.find(id)["name"]))
	SteamService.upload_score(run)
	for id in Progress.check_goals(run):
		out["unlocks"].append(Progress.unlock_name(id))
	for id in Achievements.check_run(run):
		out["achievements"].append(tr(Achievements.find(id)["name"]))
	Progress.save()
	return out


## No modo sem fim, sair pelo menu ou reiniciar também guarda o progresso.
func _save_endless_progress() -> void:
	if endless and (state == State.PLAYING or state == State.PAUSED or state == State.LEVEL_UP):
		_record_run(_build_run(false))
		endless = false


func _end_run(victory: bool) -> void:
	Engine.time_scale = 1.0
	state = State.VICTORY if victory else State.GAME_OVER
	var run := _build_run(victory)
	if autoplay:
		print("[autoplay] FIM  mapa=%s  dificuldade=%s  vitória=%s  tempo=%s  nível=%d  mortes=%d  chefes=%d  pontos=%d  melhorias=%s" % [
			map_id, difficulty, victory, Records.format_time(elapsed), level, kills, bosses_killed, run["score"], upgrade_levels])
		get_tree().quit()
		return
	var was_endless := endless
	var cycle := _cycle_time()
	var rewards := _record_run(run)
	endless = false
	var context := {
		"clock": DayCycle.clock_text(cycle),
		"hours_left": DayCycle.hours_left_text(cycle),
		"time_left": Records.format_time(maxf(0.0, Balance.RUN_DURATION - cycle)),
		"next": "",
		"endless": was_endless,
		"nights": nights + 2,
		"can_continue": victory and not was_endless and mode != "boss_rush",
		"rush_total": bosses_killed + _rush_queue.size() + _bosses_alive,
	}
	context.merge(rewards)
	var nb := spawner.next_boss()
	if not victory and not nb.is_empty() and float(nb["t"]) > elapsed:
		context["next"] = tr("Próximo marco: %s chegaria em %s.") % [_boss_name(nb["boss"]), Records.format_time(float(nb["t"]) - elapsed)]
	hud.set_boss(null)
	if victory:
		# O sol nasce: as criaturas se desfazem e o cenário clareia ao fundo.
		spawner.active = false
		_sunrise = 0.0
		for node in enemies_root.get_children():
			(node as Enemy).dissolve()
		Sfx.play(&"victory")
		Sfx.music(&"calm")
	else:
		get_tree().paused = true
		Sfx.play(&"defeat")
		Sfx.music(&"none")
	hud.show_end(run, context)


func _on_achievement(a: Dictionary) -> void:
	hud.announce(tr("Conquista desbloqueada: %s") % tr(a["name"]), ACHIEVEMENT_COLOR)
	Sfx.play(&"achievement")


func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("user://screenshot.png")
	get_viewport().get_texture().get_image().save_png(path)
	print("[screenshot] salvo em ", path)
	if _ui_arg != "" or _cycle_arg >= 0.0 or _trailer != "":
		get_tree().quit()


func _update_hud() -> void:
	hud.update_stats(lighthouse.hp, lighthouse.max_hp, xp, xp_needed, level, elapsed, kills, _current_score(), _cycle_time(), nights + 2 if endless else 1)


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
		"workshop":
			hud.show_workshop()
		"hero":
			hud.show_hero_select()
		"bestiary":
			hud.show_bestiary()
		"credits":
			hud.show_credits()
		"daily":
			hud.show_daily()
		"accessibility":
			hud.show_settings(false, 4)
		"achievements":
			hud.show_achievements()
		"story":
			start_run(map_id, keeper, difficulty)
			state = State.STORY
			get_tree().paused = true
			hud.show_story(map_id)
		"tutorial":
			start_tutorial()
		"pause", "levelup", "end", "victory", "boss", "endless":
			start_run(map_id, keeper, difficulty)
			elapsed = 250.0
			spawner.elapsed = elapsed
			kills = 431
			kill_points = 4980
			level = 14
			xp = 30
			xp_needed = _xp_for(level)
			for id: String in ["wide_lens", "wide_lens", "wide_lens", "wide_lens", "wide_lens", "gears", "gears", "gears", "gears", "pulse", "twin_lens"]:
				_apply_upgrade_silently(id)
			var roles := ["basic", "fast", "brute", "thief", "mirror", "moth"]
			for i in 30:
				spawner.spawn(roles[i % roles.size()]).position *= rng.randf_range(0.35, 0.9)
			spawner.spawn("fogbank").position = Vector2(-320, -120)
			spawner.spawn_boss(Maps.boss_at(map_id, 0 if screen != "endless" else 1))
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
			elif screen == "endless":
				elapsed = Balance.RUN_DURATION + 200.0
				endless = true
				nights = 0
				spawner.elapsed = elapsed
				hud.set_endless(true)
				_update_hud()


func _apply_upgrade_silently(id: String) -> void:
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	upgrade_order.append(id)
	Upgrades.apply(id, lighthouse)


# --- Trailer (--trailer=) -------------------------------------------------

## Abertura e encerramento: o farol girando sozinho, sem interface.
func trailer_title() -> void:
	_set_map("bay")
	_clear_world()
	state = State.TITLE
	get_tree().paused = false
	Sfx.music(&"calm")
	hud.show_playing()
	hud.set_hud_visible(false)


## Uma cena do trailer: o mapa em plena noite, cheio de criaturas e, se
## pedido, com o chefe já em campo. O bot mira; o farol não morre.
func trailer_shot(map: String, at: float, boss: int) -> void:
	start_run(map, "classic", "normal")
	hud.set_hud_visible(true)
	elapsed = at
	spawner.elapsed = at
	level = 12
	for id: String in ["wide_lens", "wide_lens", "intense_flame", "intense_flame", "twin_lens", "pulse", "pulse", "sweeper", "walls"]:
		_apply_upgrade_silently(id)
	lighthouse.regen = 40.0
	var roles := ["basic", "fast", "brute", "basic", "thief", "mirror", "moth", "fast"]
	for i in 26:
		spawner.spawn(roles[i % roles.size()]).position *= rng.randf_range(0.4, 0.95)
	if boss >= 0:
		var b := spawner.spawn_boss(Maps.boss_at(map, boss))
		b.position = b.position.normalized() * 330.0
	DayCycle.update(at)
	_update_hud()
