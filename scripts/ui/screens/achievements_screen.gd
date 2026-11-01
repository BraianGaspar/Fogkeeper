class_name AchievementsScreen
extends MenuScreen
## Lista de conquistas: as obtidas com a data, as outras apagadas.


func _build() -> void:
	var box := centered_panel(860, 26)
	box.add_theme_constant_override("separation", 10)
	title(box, tr("Conquistas"), 36)
	var got := 0
	for a: Dictionary in Achievements.LIST:
		if Achievements.has(a["id"]):
			got += 1
	text(box, tr("%d de %d conquistas") % [got, Achievements.LIST.size()], 17, UiTheme.GOLD)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for a: Dictionary in Achievements.LIST:
		grid.add_child(_entry(a))
	default_focus = back_button(box)
	default_focus.focus_mode = Control.FOCUS_ALL


func _entry(a: Dictionary) -> Control:
	var have := Achievements.has(a["id"])
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(410, 0)
	panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.12, 0.1, 0.06, 0.8) if have else Color(0, 0, 0, 0.3),
		Color(UiTheme.GOLD, 0.8) if have else Color(UiTheme.GOLD_DARK, 0.4), 1, 10.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.draw.connect(func() -> void:
		var c := icon.size / 2.0
		if have:
			icon.draw_circle(c, 15.0, Color(UiTheme.GOLD, 0.25))
			UiTheme.diamond(icon, c, 11.0, UiTheme.GOLD)
			UiTheme.diamond(icon, c, 4.0, Color.WHITE)
		else:
			icon.draw_arc(c, 13.0, 0.0, TAU, 20, Color(UiTheme.GOLD_DARK, 0.6), 2.0)
	)
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	info.add_child(UiTheme.label(tr(a["name"]), 17, UiTheme.GOLD if have else UiTheme.TEXT_DIM, true))
	var desc := UiTheme.label(tr(a["desc"]), 14, UiTheme.TEXT if have else UiTheme.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)
	if have:
		info.add_child(UiTheme.label(Records.format_date(int(Progress.achievements[a["id"]])), 12, UiTheme.TEXT_DIM))
	return panel
