class_name TitleScreen
extends MenuScreen
## Tela inicial: logotipo sobre o cenário vivo e o menu principal.

signal play_pressed
signal tutorial_pressed
signal workshop_pressed
signal achievements_pressed
signal history_pressed
signal ranking_pressed
signal settings_pressed
signal quit_pressed

var _logo: Label
var _time := 0.0


func _build() -> void:
	# Coluna à esquerda; a câmera é deslocada para o farol aparecer à direita.
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	root.anchor_right = 0.56
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 6)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_logo = UiTheme.label("FOGKEEPER", 92, UiTheme.GOLD, true)
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_theme_constant_override("outline_size", 10)
	_logo.add_theme_constant_override("shadow_offset_y", 6)
	_logo.add_theme_constant_override("shadow_outline_size", 16)
	_logo.add_theme_color_override("font_shadow_color", Color(1.0, 0.6, 0.2, 0.25))
	root.add_child(_logo)

	var div := UiTheme.divider(460)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(div)
	var sub := UiTheme.label(tr("As criaturas da névoa temem a luz. Resista até o amanhecer."), 19, UiTheme.TEXT, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	root.add_child(spacer)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := OrnatePanel.new(24)
	center.add_child(panel)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size.x = 440
	menu.add_theme_constant_override("separation", 10)
	panel.add_child(menu)
	default_focus = add_button(menu, tr("Jogar"), func() -> void: play_pressed.emit())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	menu.add_child(grid)
	for entry: Array in [
		[tr("Tutorial"), tutorial_pressed], [tr("Oficina"), workshop_pressed],
		[tr("Conquistas"), achievements_pressed], [tr("Histórico"), history_pressed],
		[tr("Ranking"), ranking_pressed], [tr("Configurações"), settings_pressed],
	]:
		var sig: Signal = entry[1]
		var b := add_button(grid, entry[0], func() -> void: sig.emit())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_button(menu, tr("Sair"), func() -> void: quit_pressed.emit(), &"back")
	var oil := UiTheme.label(tr("Óleo do farol: %s") % Records.format_number(Progress.oil), 16, UiTheme.GOLD)
	oil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(oil)

	var footer := UiTheme.label("v%s" % ProjectSettings.get_setting("application/config/version", ""), 14, UiTheme.TEXT_DIM)
	footer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	footer.position.y -= 34
	add_child(footer)


func _process(delta: float) -> void:
	_time += delta
	# A luz do logotipo tremula como a chama do farol.
	var flicker := 0.92 + 0.05 * sin(_time * 2.1) + 0.03 * sin(_time * 7.3)
	_logo.add_theme_color_override("font_color", UiTheme.GOLD * Color(flicker, flicker, flicker))


func go_back() -> bool:
	return false
