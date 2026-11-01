class_name Hud
extends CanvasLayer
## HUD da partida (vida, relógio do amanhecer, pontos, barra de XP, avisos)
## e a troca entre as telas de menu (scripts/ui/screens/).

signal start_requested(difficulty: String)
signal restart_pressed
signal resume_pressed
signal menu_pressed
signal quit_pressed
signal upgrade_chosen(id: String)

const DIM_TITLE := 0.15
const DIM_MENU := 0.6

var _play_ui: Control
var _hp_caption: Label
var _hp_bar: OrnateBar
var _xp_bar: OrnateBar
var _clock: DawnClock
var _score_label: Label
var _score_caption: Label
var _kills_label: Label
var _announce: Label
var _announce_tween: Tween
var _overlay: ColorRect
var _screen: MenuScreen
var _last_level := 1
var _settings_from_pause := false
var _pause_summary := ""
var _pause_upgrades: Array = []
var _last_run_id := ""


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


# --- HUD da partida -----------------------------------------------------------

func _build_play_ui() -> void:
	_play_ui = Control.new()
	_play_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_play_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_play_ui)

	# Vida, no canto superior esquerdo.
	var hp_box := VBoxContainer.new()
	hp_box.position = Vector2(22, 16)
	hp_box.add_theme_constant_override("separation", 0)
	_hp_caption = UiTheme.label("", 15, UiTheme.TEXT, true)
	hp_box.add_child(_hp_caption)
	_hp_bar = OrnateBar.new()
	_hp_bar.fill_color = UiTheme.HP
	_hp_bar.trail_color = Color(1.0, 0.85, 0.6, 0.85)
	_hp_bar.bar_height = 16.0
	_hp_bar.custom_minimum_size = Vector2(290, 28)
	hp_box.add_child(_hp_bar)
	_play_ui.add_child(hp_box)

	# Relógio do amanhecer, no topo central.
	_clock = DawnClock.new()
	_clock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_clock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_clock.custom_minimum_size = Vector2(380, 62)
	_clock.offset_left = -190
	_clock.offset_right = 190
	_clock.offset_top = 12
	_play_ui.add_child(_clock)

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

	_announce = UiTheme.label("", 30, UiTheme.GOLD, true)
	_announce.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_announce.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.offset_left = -500
	_announce.offset_right = 500
	_announce.offset_top = 110
	_announce.modulate.a = 0.0
	_play_ui.add_child(_announce)


func update_stats(hp: float, max_hp: float, xp: int, xp_needed: int, level: int, elapsed: float, kills: int, score: int) -> void:
	_hp_caption.text = tr("Farol")
	_hp_bar.set_values(hp, max_hp)
	_hp_bar.text = "%d / %d" % [ceili(hp), int(max_hp)]
	if level != _last_level:
		_last_level = level
		_xp_bar.set_values(xp, xp_needed)
		_xp_bar.snap()
		_xp_bar.flash()
	_xp_bar.set_values(xp, xp_needed)
	_xp_bar.badge = str(level)
	_xp_bar.text = tr("%d / %d XP   (%d%%)   —   próximo nível: %d") % [xp, xp_needed, int(100.0 * xp / maxf(1.0, xp_needed)), level + 1]
	_clock.progress = elapsed / Balance.RUN_DURATION
	_clock.time_text = Records.format_time(elapsed)
	_clock.caption = tr("Amanhecer em %s") % Records.format_time(maxf(0.0, Balance.RUN_DURATION - elapsed))
	_score_label.text = Records.format_number(score)
	_score_caption.text = tr("pontos")
	_kills_label.text = tr("%s criaturas queimadas") % Records.format_number(kills)


func reset_level(level: int) -> void:
	_last_level = level
	_xp_bar.set_values(0, 1)
	_xp_bar.snap()


## Aviso grande que aparece e some no topo da tela.
func announce(text: String, color: Color = UiTheme.GOLD) -> void:
	_announce.text = text
	_announce.add_theme_color_override("font_color", color)
	if _announce_tween:
		_announce_tween.kill()
	_announce.modulate.a = 0.0
	_announce_tween = create_tween()
	_announce_tween.tween_property(_announce, "modulate:a", 1.0, 0.3)
	_announce_tween.tween_interval(2.6)
	_announce_tween.tween_property(_announce, "modulate:a", 0.0, 0.8)


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


func show_title() -> void:
	var s := TitleScreen.new()
	s.play_pressed.connect(show_difficulty)
	s.history_pressed.connect(show_history)
	s.ranking_pressed.connect(show_ranking)
	s.settings_pressed.connect(show_settings.bind(false))
	s.quit_pressed.connect(func() -> void: quit_pressed.emit())
	_set_screen(s, DIM_TITLE, false)


func show_difficulty() -> void:
	var s := DifficultyScreen.new()
	s.start.connect(func(d: String) -> void: start_requested.emit(d))
	_set_screen(s, DIM_MENU, false)


func show_settings(from_pause: bool, tab: int = 0) -> void:
	_settings_from_pause = from_pause
	var s := SettingsScreen.new()
	s.tab = tab
	s.language_changed.connect(func(t: int) -> void: show_settings(from_pause, t))
	_set_screen(s, DIM_MENU, from_pause)


func show_history() -> void:
	_set_screen(HistoryScreen.new(), DIM_MENU, false)


func show_ranking(difficulty: String = "") -> void:
	var s := RankingScreen.new()
	s.filter = difficulty
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
	s.resume_pressed.connect(func() -> void: resume_pressed.emit())
	s.settings_pressed.connect(show_settings.bind(true))
	s.restart_pressed.connect(func() -> void: restart_pressed.emit())
	s.menu_pressed.connect(func() -> void: menu_pressed.emit())
	s.quit_pressed.connect(func() -> void: quit_pressed.emit())
	_set_screen(s, DIM_MENU, true)


func show_level_up(level: int, choices: Array, levels: Dictionary) -> void:
	var s := LevelUpScreen.new()
	s.level = level
	s.choices = choices
	s.levels = levels
	s.upgrade_chosen.connect(func(id: String) -> void: upgrade_chosen.emit(id))
	_set_screen(s, 0.5, true)


func show_end(run: Dictionary) -> void:
	_last_run_id = run["id"]
	var s := EndScreen.new()
	s.run = run
	s.restart_pressed.connect(func() -> void: restart_pressed.emit())
	s.ranking_pressed.connect(func() -> void: show_ranking(run["difficulty"]))
	s.menu_pressed.connect(func() -> void: menu_pressed.emit())
	_set_screen(s, 0.35 if run["victory"] else 0.6, false)
