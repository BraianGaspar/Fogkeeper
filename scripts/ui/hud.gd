class_name Hud
extends CanvasLayer
## Interface inteira construída em código: barras, telas de título,
## pausa, escolha de melhoria e fim de partida.

signal start_pressed
signal restart_pressed
signal resume_pressed
signal quit_pressed
signal upgrade_chosen(id: String)

const ACCENT := Color(1.0, 0.82, 0.45)
const TEXT := Color(0.92, 0.9, 0.86)
const PANEL_BG := Color(0.05, 0.06, 0.1, 0.94)

var _play_ui: Control
var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kills_label: Label
var _overlay: ColorRect
var _panel_box: VBoxContainer
var _choice_ids: Array[String] = []
var _choices_ready := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_play_ui()
	_build_overlay()


# --- Construção -----------------------------------------------------------

func _build_play_ui() -> void:
	_play_ui = Control.new()
	_play_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_play_ui)

	_xp_bar = _make_bar(Color(1.0, 0.72, 0.3))
	_xp_bar.anchor_right = 1.0
	_xp_bar.offset_bottom = 8.0
	_play_ui.add_child(_xp_bar)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 18)
	_play_ui.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var hp_box := VBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 2)
	_hp_label = _make_label("Farol", 16)
	hp_box.add_child(_hp_label)
	_hp_bar = _make_bar(Color(0.95, 0.35, 0.3))
	_hp_bar.custom_minimum_size = Vector2(260, 16)
	hp_box.add_child(_hp_bar)
	row.add_child(hp_box)

	row.add_child(_spacer())
	_time_label = _make_label("00:00", 28)
	row.add_child(_time_label)
	row.add_child(_spacer())

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 2)
	_level_label = _make_label("Nível 1", 20)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kills_label = _make_label("0 queimadas", 16)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_level_label)
	right.add_child(_kills_label)
	right.custom_minimum_size.x = 260
	row.add_child(right)


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0.02, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = Color(ACCENT, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	_panel_box = VBoxContainer.new()
	_panel_box.add_theme_constant_override("separation", 14)
	_panel_box.custom_minimum_size.x = 480
	panel.add_child(_panel_box)


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _make_label(text: String, size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _make_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.13, 0.19)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.18, 0.14)
	hover.border_color = ACCENT
	hover.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", normal)
	b.pressed.connect(on_press)
	_panel_box.add_child(b)
	return b


# --- Telas ----------------------------------------------------------------

func _open_panel() -> void:
	for c in _panel_box.get_children():
		c.queue_free()
	_choice_ids.clear()
	_choices_ready = false
	_overlay.visible = true


func show_title() -> void:
	_play_ui.visible = false
	_open_panel()
	var title := _make_label("FAROL", 72, ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_box.add_child(title)
	_add_text("As criaturas da névoa temem a luz.\nGire o feixe e resista até o amanhecer.", 20, true)
	_add_text("Mouse, A/D ou analógico: girar o feixe\nO feixe também recolhe brasas (XP)\nEsc: pausar", 16, true, Color(TEXT, 0.7))
	var b := _make_button("Acender o farol", func() -> void: start_pressed.emit())
	b.call_deferred("grab_focus")


func show_playing() -> void:
	_overlay.visible = false
	_play_ui.visible = true


func show_pause() -> void:
	_open_panel()
	_add_title("Pausado")
	var b := _make_button("Continuar", func() -> void: resume_pressed.emit())
	_make_button("Recomeçar", func() -> void: restart_pressed.emit())
	_make_button("Sair", func() -> void: quit_pressed.emit())
	b.call_deferred("grab_focus")


func show_level_up(level: int, choices: Array, levels: Dictionary) -> void:
	_open_panel()
	_add_title("Nível %d" % level)
	_add_text("Escolha uma melhoria (1, 2 ou 3)", 16, true, Color(TEXT, 0.7))
	var buttons: Array[Button] = []
	for i in choices.size():
		var u: Dictionary = choices[i]
		var id: String = u["id"]
		var next_lvl := int(levels.get(id, 0)) + 1
		var label := "%d.  %s   (nv %d)\n%s" % [i + 1, u["name"], next_lvl, u["desc"]]
		var b := _make_button(label, func() -> void: _choose(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 72)
		b.disabled = true
		buttons.append(b)
		_choice_ids.append(id)
	# Pequeno atraso evita escolher sem querer enquanto se joga.
	get_tree().create_timer(0.35, true).timeout.connect(func() -> void:
		_choices_ready = true
		for b in buttons:
			if is_instance_valid(b):
				b.disabled = false
		if not buttons.is_empty() and is_instance_valid(buttons[0]):
			buttons[0].grab_focus()
	)


func press_choice(index: int) -> void:
	if _choices_ready and index < _choice_ids.size():
		_choose(_choice_ids[index])


func _choose(id: String) -> void:
	if not _choices_ready:
		return
	_choices_ready = false
	upgrade_chosen.emit(id)


func show_end(victory: bool, summary: Dictionary) -> void:
	_open_panel()
	_add_title("Amanheceu!" if victory else "A luz se apagou")
	var text := "Tempo: %s\nNível: %d\nCriaturas queimadas: %d" % [
		format_time(summary["time"]), summary["level"], summary["kills"]]
	_add_text(text, 20, true)
	var b := _make_button("Jogar de novo", func() -> void: restart_pressed.emit())
	_make_button("Sair", func() -> void: quit_pressed.emit())
	b.call_deferred("grab_focus")


func _add_title(text: String) -> void:
	var l := _make_label(text, 40, ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_box.add_child(l)


func _add_text(text: String, size: int, centered: bool, color: Color = TEXT) -> void:
	var l := _make_label(text, size, color)
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_box.add_child(l)


# --- Atualização ----------------------------------------------------------

func update_stats(hp: float, max_hp: float, xp: int, xp_needed: int, level: int, elapsed: float, kills: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "Farol  %d / %d" % [ceili(hp), int(max_hp)]
	_xp_bar.max_value = xp_needed
	_xp_bar.value = xp
	_level_label.text = "Nível %d" % level
	_time_label.text = "%s / %s" % [format_time(elapsed), format_time(Balance.RUN_DURATION)]
	_kills_label.text = "%d queimadas" % kills


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]
