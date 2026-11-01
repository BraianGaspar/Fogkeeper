class_name Hud
extends CanvasLayer
## HUD da partida (vida, relógio da noite, pontos, chefe, habilidades, XP),
## avisos em fila numa camada própria (nunca ficam atrás de menus), registro
## de eventos e a troca entre as telas (scripts/ui/screens/).

signal start_requested(map_id: String, keeper_id: String, difficulty: String)
signal restart_pressed
signal resume_pressed
signal menu_pressed
signal quit_pressed
signal upgrade_chosen(id: String)
signal reroll_pressed
signal banish_pressed(id: String)
signal story_finished
signal endless_pressed
signal tutorial_requested

const DIM_TITLE := 0.15
const DIM_MENU := 0.6
const ALERT_TIME := 3.0
const LOG_SIZE := 30
const LOG_VISIBLE := 3
const LOG_FADE := 12.0

var abilities: Abilities:
	set(value):
		abilities = value
		if _ability_bar:
			_ability_bar.abilities = value

var _play_ui: Control
var _hp_caption: Label
var _hp_bar: OrnateBar
var _xp_bar: OrnateBar
var _clock: DawnClock
var _score_label: Label
var _score_caption: Label
var _kills_label: Label
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: OrnateBar
var _boss: Boss
var _ability_bar: AbilityBar
var _log_box: VBoxContainer
var _alerts: CanvasLayer
var _alert_label: Label
var _alert_banner: PanelContainer
var _alert_queue: Array[Dictionary] = []
var _alert_left := 0.0
var _alert_big_since := -100.0
var _clock_time := 0.0
var _log_timer := 0.0
var _events: Array[Dictionary] = [] # {"time": "02:47", "text": ..., "at": tempo real}
var _overlay: ColorRect
var _screen: MenuScreen
var _last_level := 1
var _settings_from_pause := false
var _pause_summary := ""
var _pause_upgrades: Array = []
var _last_run_id := ""
var _pending_map := "bay"
var _pending_keeper := "classic"
var _endless := false
var _hurt := 0.0
var _vignette: Control
var _tutorial_panel: PanelContainer
var _tutorial_title: Label
var _tutorial_body: Label
var _tutorial_progress: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_play_ui()
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0.02, 0.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)
	_build_alerts()


# --- HUD da partida -----------------------------------------------------------

func _build_play_ui() -> void:
	_play_ui = Control.new()
	_play_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_play_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_play_ui)

	# Vida e registro de eventos, no canto superior esquerdo.
	var left := VBoxContainer.new()
	left.position = Vector2(22, 16)
	left.add_theme_constant_override("separation", 2)
	_hp_caption = UiTheme.label("", 15, UiTheme.TEXT, true)
	left.add_child(_hp_caption)
	_hp_bar = OrnateBar.new()
	_hp_bar.fill_color = UiTheme.HP
	_hp_bar.trail_color = Color(1.0, 0.85, 0.6, 0.85)
	_hp_bar.bar_height = 16.0
	_hp_bar.custom_minimum_size = Vector2(290, 28)
	left.add_child(_hp_bar)
	_log_box = VBoxContainer.new()
	_log_box.add_theme_constant_override("separation", 0)
	_log_box.custom_minimum_size.x = 330
	left.add_child(_log_box)
	_play_ui.add_child(left)

	# Relógio da noite e barra do chefe, no topo central.
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.offset_left = -270
	top.offset_right = 270
	top.offset_top = 12
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_theme_constant_override("separation", 2)
	_clock = DawnClock.new()
	_clock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(_clock)
	_boss_box = VBoxContainer.new()
	_boss_box.add_theme_constant_override("separation", -2)
	_boss_name = UiTheme.label("", 17, UiTheme.DANGER, true)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	_boss_bar = OrnateBar.new()
	_boss_bar.fill_color = Color(0.75, 0.15, 0.2)
	_boss_bar.segments = 10
	_boss_bar.bar_height = 14.0
	_boss_bar.text_size = 12
	_boss_bar.custom_minimum_size = Vector2(540, 26)
	_boss_box.add_child(_boss_bar)
	_boss_box.visible = false
	top.add_child(_boss_box)
	_play_ui.add_child(top)

	# Pontos e criaturas, no canto superior direito.
	var right := VBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_right = -22
	right.offset_top = 10
	right.add_theme_constant_override("separation", -4)
	_score_label = UiTheme.label("0", 30, UiTheme.GOLD, true)
	_score_caption = UiTheme.label("", 13, UiTheme.TEXT_DIM)
	_kills_label = UiTheme.label("", 15, UiTheme.TEXT)
	for l in [_score_label, _score_caption, _kills_label]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(l)
	_play_ui.add_child(right)

	# Habilidades, acima da barra de XP.
	_ability_bar = AbilityBar.new()
	_ability_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_ability_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_ability_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var w := AbilityBar.SLOT * 3 + AbilityBar.GAP * 2
	_ability_bar.offset_left = -w / 2.0
	_ability_bar.offset_right = w / 2.0
	_ability_bar.offset_top = -150
	_ability_bar.offset_bottom = -70
	_play_ui.add_child(_ability_bar)

	# Barra de XP no rodapé, no estilo das barras de experiência dos RPGs.
	_xp_bar = OrnateBar.new()
	_xp_bar.fill_color = UiTheme.XP
	_xp_bar.segments = 20
	_xp_bar.bar_height = 16.0
	_xp_bar.text_size = 13
	_xp_bar.badge = "1"
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_xp_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_xp_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_xp_bar.offset_left = -430
	_xp_bar.offset_right = 430
	_xp_bar.offset_top = -62
	_xp_bar.offset_bottom = -14
	_play_ui.add_child(_xp_bar)

	# Painel do tutorial, acima das habilidades.
	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.03, 0.05, 0.09, 0.88), Color(0.45, 0.95, 0.85, 0.8), 2, 14.0))
	_tutorial_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_tutorial_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tutorial_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_tutorial_panel.offset_left = -330
	_tutorial_panel.offset_right = 330
	_tutorial_panel.offset_bottom = -158
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_panel.visible = false
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 2)
	_tutorial_panel.add_child(tbox)
	var head := HBoxContainer.new()
	tbox.add_child(head)
	_tutorial_title = UiTheme.label("", 19, Color(0.45, 0.95, 0.85), true)
	_tutorial_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_tutorial_title)
	_tutorial_progress = UiTheme.label("", 17, UiTheme.GOLD, true)
	head.add_child(_tutorial_progress)
	_tutorial_body = UiTheme.label("", 15, UiTheme.TEXT)
	_tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_body.custom_minimum_size.x = 630
	tbox.add_child(_tutorial_body)
	_play_ui.add_child(_tutorial_panel)

	# Bordas vermelhas quando o farol leva dano.
	_vignette = Control.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.draw.connect(_draw_vignette)
	_play_ui.add_child(_vignette)
	_play_ui.move_child(_vignette, 0)


func _draw_vignette() -> void:
	if _hurt <= 0.0:
		return
	var s := _vignette.size
	for i in 10:
		var w := 6.0 + i * 7.0
		var a := 0.06 * _hurt * (1.0 - i / 10.0)
		var col := Color(0.9, 0.05, 0.05, a)
		_vignette.draw_rect(Rect2(0, 0, s.x, w), col)
		_vignette.draw_rect(Rect2(0, s.y - w, s.x, w), col)
		_vignette.draw_rect(Rect2(0, 0, w, s.y), col)
		_vignette.draw_rect(Rect2(s.x - w, 0, w, s.y), col)


## O farol levou dano: as bordas da tela pulsam em vermelho.
func hurt(fraction: float) -> void:
	if Settings.screen_shake or Settings.particles:
		_hurt = minf(1.0, _hurt + 0.35 + fraction * 4.0)


func set_tutorial(title_text: String, body: String, progress: String) -> void:
	_tutorial_panel.visible = true
	_tutorial_title.text = title_text
	_tutorial_body.text = body
	_tutorial_progress.text = progress


func clear_tutorial() -> void:
	if _tutorial_panel:
		_tutorial_panel.visible = false


## Modo sem fim: o relógio deixa de marcar o amanhecer como fim.
func set_endless(on: bool) -> void:
	_endless = on
	_clock.show_marks = not on


## Avisos ficam numa camada acima de tudo, inclusive da escolha de melhoria.
func _build_alerts() -> void:
	_alerts = CanvasLayer.new()
	_alerts.layer = 20
	add_child(_alerts)
	_alert_banner = PanelContainer.new()
	_alert_banner.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.25, 0.03, 0.05, 0.85), UiTheme.DANGER, 2, 14.0))
	_alert_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_alert_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_alert_banner.offset_top = 128
	_alert_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_banner.modulate.a = 0.0
	_alerts.add_child(_alert_banner)
	_alert_label = UiTheme.label("", 28, UiTheme.GOLD, true)
	_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert_banner.add_child(_alert_label)


func _process(delta: float) -> void:
	if is_instance_valid(_boss) and not _boss.dying:
		_boss_bar.set_values(maxf(0.0, _boss.hp), _boss.max_hp)
		_boss_bar.text = "%d / %d" % [ceili(maxf(0.0, _boss.hp)), ceili(_boss.max_hp)]
		_boss_name.text = "%s — %s%s" % [tr(Maps.CREATURE_NAMES[_boss.kind]), tr(Maps.BOSS_TITLES[_boss.kind]),
			("   " + tr("(ENFURECIDO)")) if _boss.enraged else ""]
	elif _boss_box.visible:
		_boss_box.visible = false
	_process_alerts(delta)
	if _hurt > 0.0:
		_hurt = maxf(0.0, _hurt - delta * 2.5)
		_vignette.queue_redraw()
	_log_timer -= delta
	if _log_timer <= 0.0:
		_log_timer = 0.25
		_refresh_log()


## `cycle` é a hora do ciclo do dia (recomeça a cada noite no modo sem fim).
func update_stats(hp: float, max_hp: float, xp: int, xp_needed: int, level: int, elapsed: float, kills: int, score: int, cycle: float, night: int) -> void:
	_clock_time = cycle
	_hp_caption.text = tr("Farol")
	_hp_bar.set_values(hp, max_hp)
	_hp_bar.text = "%d / %d" % [ceili(hp), ceili(max_hp)]
	if level != _last_level:
		_last_level = level
		_xp_bar.set_values(xp, xp_needed)
		_xp_bar.snap()
		_xp_bar.flash()
	_xp_bar.set_values(xp, xp_needed)
	_xp_bar.badge = str(level)
	_xp_bar.text = tr("%d / %d XP   (%d%%)   —   próximo nível: %d") % [xp, xp_needed, int(100.0 * xp / maxf(1.0, xp_needed)), level + 1]
	_clock.progress = cycle / Balance.RUN_DURATION
	_clock.time_text = DayCycle.clock_text(cycle)
	if _endless:
		_clock.caption = tr("Noite %d (sem fim)   •   %s de partida") % [night, Records.format_time(elapsed)]
	else:
		_clock.caption = tr("%s de partida   •   amanhecer em %s") % [Records.format_time(elapsed), Records.format_time(maxf(0.0, Balance.RUN_DURATION - cycle))]
	_score_label.text = Records.format_number(score)
	_score_caption.text = tr("pontos")
	_kills_label.text = tr("%s criaturas queimadas") % Records.format_number(kills)


## Some com os avisos na tela e na fila (fim de partida, volta ao menu).
func clear_alerts() -> void:
	_alert_queue.clear()
	_alert_left = 0.0
	_alert_banner.modulate.a = 0.0


func reset_level(level: int) -> void:
	_last_level = level
	_xp_bar.set_values(0, 1)
	_xp_bar.snap()
	_events.clear()
	_alert_queue.clear()
	_alert_left = 0.0
	_alert_banner.modulate.a = 0.0
	set_boss(null)


func set_boss(boss: Boss) -> void:
	_boss = boss
	_boss_box.visible = boss != null
	if boss:
		_boss_bar.set_values(boss.hp, boss.max_hp)
		_boss_bar.snap()


# --- Avisos e registro ----------------------------------------------------------

## Aviso no topo da tela. `big` = aviso de chefe (faixa vermelha, mais tempo).
## Avisos que chegam juntos entram numa fila e aparecem um depois do outro.
func announce(text: String, color: Color = UiTheme.GOLD, big: bool = false) -> void:
	_events.push_front({"time": DayCycle.clock_text(_clock_time), "text": text, "at": Time.get_ticks_msec() / 1000.0})
	if _events.size() > LOG_SIZE:
		_events.pop_back()
	_alert_queue.append({"text": text, "color": color, "big": big})


## Verdadeiro logo depois de um aviso de chefe aparecer: Main espera antes
## de abrir a escolha de melhoria, para o jogador ler o aviso primeiro.
func alert_blocking() -> bool:
	return Time.get_ticks_msec() / 1000.0 - _alert_big_since < 2.0


func events() -> Array[Dictionary]:
	return _events


func _process_alerts(delta: float) -> void:
	if _alert_left > 0.0:
		_alert_left -= delta
		var shown := ALERT_TIME + 1.0 - _alert_left
		_alert_banner.modulate.a = clampf(minf(shown / 0.25, _alert_left / 0.6), 0.0, 1.0)
		return
	if _alert_queue.is_empty():
		_alert_banner.modulate.a = 0.0
		return
	var a: Dictionary = _alert_queue.pop_front()
	var big: bool = a["big"]
	_alert_label.text = a["text"]
	_alert_label.add_theme_color_override("font_color", a["color"])
	_alert_label.add_theme_font_size_override("font_size", 32 if big else 26)
	_alert_banner.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.25, 0.03, 0.05, 0.88), UiTheme.DANGER, 2, 14.0) if big
		else UiTheme.flat(Color(0.03, 0.04, 0.08, 0.75), Color(UiTheme.GOLD_DARK, 0.8), 1, 12.0))
	_alert_left = ALERT_TIME + (1.0 if big else 0.0)
	if big:
		_alert_big_since = Time.get_ticks_msec() / 1000.0


func _refresh_log() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var shown := 0
	for c in _log_box.get_children():
		c.queue_free()
	for e in _events:
		var age := now - float(e["at"])
		if age > LOG_FADE or shown >= LOG_VISIBLE:
			break
		var l := UiTheme.label("%s  %s" % [e["time"], e["text"]], 13, UiTheme.TEXT_DIM)
		l.modulate.a = clampf((LOG_FADE - age) / 3.0, 0.0, 1.0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 330
		_log_box.add_child(l)
		shown += 1


# --- Telas ------------------------------------------------------------------

func _set_screen(screen: MenuScreen, dim: float, show_hud: bool) -> void:
	if _screen:
		_screen.queue_free()
	_screen = screen
	_play_ui.visible = show_hud
	_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", dim, 0.2)
	screen.modulate.a = 0.0
	_overlay.add_child(screen)
	screen.create_tween().tween_property(screen, "modulate:a", 1.0, 0.18)
	screen.back_requested.connect(_on_back.bind(screen))


func _on_back(screen: MenuScreen) -> void:
	if screen is SettingsScreen and _settings_from_pause:
		_show_pause_again()
	elif screen is DifficultyScreen:
		show_keeper_select()
	elif screen is KeeperScreen:
		show_map_select()
	elif screen is StoryScreen:
		story_finished.emit()
	else:
		menu_pressed.emit()


## Esc / botão B. Retorna false se a tela atual não tem para onde voltar.
func back() -> bool:
	return _screen != null and _screen.go_back()


func show_playing() -> void:
	if _screen:
		_screen.queue_free()
		_screen = null
	_overlay.visible = false
	_play_ui.visible = true
	_ability_bar.visible = true


func show_title() -> void:
	clear_alerts()
	var s := TitleScreen.new()
	s.play_pressed.connect(_on_play)
	s.tutorial_pressed.connect(func() -> void: tutorial_requested.emit())
	s.workshop_pressed.connect(show_workshop)
	s.achievements_pressed.connect(show_achievements)
	s.history_pressed.connect(show_history)
	s.ranking_pressed.connect(show_ranking)
	s.settings_pressed.connect(show_settings.bind(false))
	s.quit_pressed.connect(func() -> void: quit_pressed.emit())
	_set_screen(s, DIM_TITLE, false)


## Na primeira vez, oferece o tutorial antes de jogar.
func _on_play() -> void:
	if Progress.tutorial_done or Progress.stat("tutorial_offered") > 0:
		show_map_select()
		return
	Progress.add_stat("tutorial_offered")
	Progress.save()
	var s := ConfirmScreen.new()
	s.heading = tr("Primeira noite no farol?")
	s.body = tr("Um tutorial rápido ensina a girar a luz, recolher brasas, usar as habilidades e enfrentar um chefe. Leva uns dois minutos e rende óleo para a oficina.")
	s.options = [
		[tr("Fazer o tutorial"), func() -> void: tutorial_requested.emit()],
		[tr("Pular e jogar"), show_map_select],
	]
	_set_screen(s, DIM_MENU, false)


func show_workshop() -> void:
	_set_screen(WorkshopScreen.new(), DIM_MENU, false)


func show_achievements() -> void:
	_set_screen(AchievementsScreen.new(), DIM_MENU, false)


## História do mapa antes da partida (o jogo fica pausado por trás).
func show_story(map_id: String) -> void:
	var s := StoryScreen.new()
	s.map_id = map_id
	s.finished.connect(func() -> void: story_finished.emit())
	_set_screen(s, 0.75, false)


func show_tutorial_done(oil: int) -> void:
	var s := ConfirmScreen.new()
	s.heading = tr("Tutorial concluído!")
	s.body = tr("Agora você conhece o farol. Na partida de verdade, as criaturas ficam mais fortes a cada hora e dois chefes aparecem antes do amanhecer.")
	if oil > 0:
		s.body += "\n\n" + tr("+%d de óleo para a oficina.") % oil
	s.options = [
		[tr("Jogar agora"), show_map_select],
		[tr("Menu principal"), func() -> void: menu_pressed.emit()],
	]
	_set_screen(s, DIM_MENU, false)


## Preparação da partida: mapa → farol → dificuldade.
func show_map_select() -> void:
	var s := MapScreen.new()
	s.chosen.connect(func(id: String) -> void:
		_pending_map = id
		Settings.map = id
		show_keeper_select()
	)
	_set_screen(s, DIM_MENU, false)


func show_keeper_select() -> void:
	var s := KeeperScreen.new()
	s.chosen.connect(func(id: String) -> void:
		_pending_keeper = id
		Settings.keeper = id
		show_difficulty()
	)
	_set_screen(s, DIM_MENU, false)


func show_difficulty() -> void:
	var s := DifficultyScreen.new()
	s.start.connect(func(d: String) -> void: start_requested.emit(_pending_map, _pending_keeper, d))
	_set_screen(s, DIM_MENU, false)


func show_settings(from_pause: bool, tab: int = 0) -> void:
	_settings_from_pause = from_pause
	var s := SettingsScreen.new()
	s.tab = tab
	s.language_changed.connect(func(t: int) -> void: show_settings(from_pause, t))
	_set_screen(s, DIM_MENU, from_pause)


func show_history() -> void:
	_set_screen(HistoryScreen.new(), DIM_MENU, false)


func show_ranking(difficulty: String = "", map_id: String = "") -> void:
	var s := RankingScreen.new()
	s.filter = difficulty
	s.map_filter = map_id
	s.highlight_id = _last_run_id
	_set_screen(s, DIM_MENU, false)


func show_pause(summary: String, upgrades: Array) -> void:
	_pause_summary = summary
	_pause_upgrades = upgrades
	_show_pause_again()


func _show_pause_again() -> void:
	var s := PauseScreen.new()
	s.summary = _pause_summary
	s.upgrades = _pause_upgrades
	s.events = _events
	s.resume_pressed.connect(func() -> void: resume_pressed.emit())
	s.settings_pressed.connect(show_settings.bind(true))
	s.restart_pressed.connect(func() -> void: restart_pressed.emit())
	s.menu_pressed.connect(func() -> void: menu_pressed.emit())
	s.quit_pressed.connect(func() -> void: quit_pressed.emit())
	_set_screen(s, DIM_MENU, true)


## `hints` mostra as teclas (só no tutorial).
func show_level_up(level: int, choices: Array, levels: Dictionary, rerolls: int, banishes: int, hints: bool) -> void:
	var s := LevelUpScreen.new()
	s.level = level
	s.choices = choices
	s.levels = levels
	s.rerolls = rerolls
	s.banishes = banishes
	s.show_hints = hints
	s.upgrade_chosen.connect(func(id: String) -> void: upgrade_chosen.emit(id))
	s.reroll_pressed.connect(func() -> void: reroll_pressed.emit())
	s.banish_pressed.connect(func(id: String) -> void: banish_pressed.emit(id))
	_set_screen(s, 0.5, true)
	_ability_bar.visible = false # Os botões de trocar e banir ficam onde está a barra.


func show_end(run: Dictionary, context: Dictionary) -> void:
	clear_alerts()
	_last_run_id = run["id"]
	var s := EndScreen.new()
	s.run = run
	s.context = context
	s.restart_pressed.connect(func() -> void: restart_pressed.emit())
	s.ranking_pressed.connect(func() -> void: show_ranking(run["difficulty"], run["map"]))
	s.menu_pressed.connect(func() -> void: menu_pressed.emit())
	s.endless_pressed.connect(func() -> void: endless_pressed.emit())
	_set_screen(s, 0.35 if context.get("can_continue", false) else 0.6, false)
