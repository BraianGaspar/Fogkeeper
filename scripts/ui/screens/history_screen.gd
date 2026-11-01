class_name HistoryScreen
extends MenuScreen
## Histórico de partidas: lista à esquerda (mais recentes primeiro) e os
## detalhes da partida selecionada à direita.

var _detail: VBoxContainer


func _build() -> void:
	var box := centered_panel(1060, 26)
	title(box, tr("Histórico de partidas"), 36)

	var runs := Records.runs().duplicate()
	runs.reverse()
	if runs.is_empty():
		text(box, tr("Nenhuma partida ainda. Acenda o farol!"), 20, UiTheme.TEXT_DIM)
		default_focus = back_button(box)
		default_focus.focus_mode = Control.FOCUS_ALL
		return

	text(box, tr("%d partidas registradas") % runs.size(), 15, UiTheme.TEXT_DIM)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	box.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var detail_panel := PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(0, 0, 0, 0.35), Color(UiTheme.GOLD_DARK, 0.6), 1, 18.0))
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(detail_scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 6)
	detail_scroll.add_child(_detail)

	for run: Dictionary in runs:
		var result := tr("Vitória") if run["victory"] else tr("Derrota")
		var label := "%s   •   %s   •   %s\n%s  ·  %s  ·  %s" % [
			Records.format_date(run["date"]), result, tr(Maps.get_map(run["map"])["name"]), difficulty_name(run["difficulty"]),
			tr("Nível %d") % run["level"], tr("%s pts") % Records.format_number(run["score"])]
		var b := UiTheme.small_button(label, _show.bind(run))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 58)
		b.add_theme_font_override("font", ThemeDB.fallback_font)
		b.add_theme_font_size_override("font_size", 14)
		if run["victory"]:
			b.add_theme_color_override("font_color", UiTheme.GOOD.lerp(UiTheme.TEXT, 0.4))
		b.focus_entered.connect(_show.bind(run))
		list.add_child(b)
		if default_focus == null:
			default_focus = b
	_show(runs[0])

	var back := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 220


func _show(run: Dictionary) -> void:
	for c in _detail.get_children():
		c.queue_free()
	var head := UiTheme.label(tr("Partida de %s") % Records.format_date(run["date"]), 22, UiTheme.GOLD, true)
	_detail.add_child(head)
	stat_row(_detail, tr("Jogador"), run["name"])
	stat_row(_detail, tr("Resultado"), tr("Vitória — amanheceu") if run["victory"] else tr("Derrota — a luz se apagou"),
		UiTheme.GOOD if run["victory"] else UiTheme.DANGER)
	stat_row(_detail, tr("Mapa"), tr(Maps.get_map(run["map"])["name"]))
	stat_row(_detail, tr("Farol"), tr(Keepers.get_keeper(run["keeper"])["name"]))
	stat_row(_detail, tr("Dificuldade"), difficulty_name(run["difficulty"]))
	stat_row(_detail, tr("Duração"), Records.format_time(run["duration"]))
	stat_row(_detail, tr("Horário na história"), DayCycle.clock_text(run["duration"]))
	stat_row(_detail, tr("Nível alcançado"), str(run["level"]))
	stat_row(_detail, tr("Criaturas queimadas"), Records.format_number(run["kills"]))
	stat_row(_detail, tr("Chefes derrotados"), str(run["bosses"]))
	stat_row(_detail, tr("Pontuação final"), Records.format_number(run["score"]), UiTheme.GOLD)
	var pos := Records.position_of(run["id"], run["difficulty"], run["map"])
	if pos > 0:
		stat_row(_detail, tr("Posição no ranking (%s)") % difficulty_name(run["difficulty"]), Records.ordinal(pos), UiTheme.GOLD)

	_detail.add_child(UiTheme.label(tr("Como a pontuação foi formada"), 16, UiTheme.GOLD, true))
	var bd: Dictionary = run["breakdown"]
	stat_row(_detail, tr("Criaturas queimadas"), Records.format_number(bd["kills"]))
	stat_row(_detail, tr("Tempo sobrevivido"), Records.format_number(bd["survival"]))
	if int(bd.get("endless", 0)) > 0:
		stat_row(_detail, tr("Modo sem fim"), Records.format_number(bd["endless"]))
	stat_row(_detail, tr("Bônus de chefes"), Records.format_number(bd["bosses"]))
	stat_row(_detail, tr("Bônus de vitória"), Records.format_number(bd["victory"]))
	stat_row(_detail, tr("Bônus de vida restante"), Records.format_number(bd["health"]))
	stat_row(_detail, tr("Subtotal"), Records.format_number(bd["subtotal"]))
	stat_row(_detail, tr("Multiplicador da dificuldade"), "×%s" % DifficultyScreen._mult_text(bd["multiplier"]))

	var upgrades: Array = run["upgrades"]
	_detail.add_child(UiTheme.label(tr("Habilidades adquiridas (%d)") % upgrades.size(), 16, UiTheme.GOLD, true))
	upgrade_chips(_detail, upgrades)
	var relics: Array = run["relics"]
	if not relics.is_empty():
		var names := []
		for r: String in relics:
			names.append(tr(Balance.RELICS[r]["name"]))
		_detail.add_child(UiTheme.label(tr("Relíquias: %s") % ", ".join(names), 14, Color(0.7, 0.9, 1.0)))
