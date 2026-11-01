class_name RankingScreen
extends MenuScreen
## Ranking local: melhores pontuações, filtráveis por dificuldade e mapa,
## com a posição do jogador ("1º lugar"). A fórmula da pontuação fica só na
## tela de fim de partida, linha por linha, para a tabela ficar limpa.

const COLUMNS := [100, 160, 110, 60, 80, 160, 110, 150] ## Posição Jogador Pontos Nível Tempo Mapa Dificuldade Data
const SHOWN := 50

var filter := ""
var map_filter := ""
var highlight_id := "" ## Partida recém-terminada, destacada na tabela.

var _table: VBoxContainer
var _footer: Label


func _build() -> void:
	var box := centered_panel(1040, 22)
	box.add_theme_constant_override("separation", 10)
	title(box, tr("Ranking"), 34)

	var diffs := [""]
	diffs.append_array(Balance.DIFFICULTY_ORDER)
	box.add_child(_filter_row(diffs, filter, _set_filter, func(f: String) -> String: return tr("Todas") if f == "" else difficulty_name(f)))
	var maps := [""]
	maps.append_array(Maps.ORDER)
	box.add_child(_filter_row(maps, map_filter, _set_map_filter, func(f: String) -> String: return tr("Todos os mapas") if f == "" else tr(Maps.get_map(f)["name"])))

	box.add_child(_row([tr("Posição"), tr("Jogador"), tr("Pontos"), tr("Nível"), tr("Tempo"), tr("Mapa"), tr("Dificuldade"), tr("Data")], UiTheme.GOLD, null))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_table = VBoxContainer.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.add_theme_constant_override("separation", 3)
	scroll.add_child(_table)

	_footer = UiTheme.label("", 17, UiTheme.GOLD)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_footer)
	text(box, tr("Ranking deste computador. O ranking online chega com a versão da Steam."), 13, UiTheme.TEXT_DIM)
	var back := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 220
	_refresh()


func _filter_row(values: Array, current: String, on_pick: Callable, label_of: Callable) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var group := ButtonGroup.new()
	for v: String in values:
		var b := UiTheme.small_button(label_of.call(v), on_pick.bind(v), true)
		b.button_group = group
		b.custom_minimum_size.x = 118
		b.button_pressed = v == current
		row.add_child(b)
		if v == current and default_focus == null:
			default_focus = b
	return row


func _set_filter(f: String) -> void:
	filter = f
	_refresh()


func _set_map_filter(f: String) -> void:
	map_filter = f
	_refresh()


func _refresh() -> void:
	for c in _table.get_children():
		c.queue_free()
	var list := Records.ranking(filter, map_filter)
	var me := Settings.display_name()
	if list.is_empty():
		var empty := UiTheme.label(tr("Nenhuma partida nesta categoria ainda."), 17, UiTheme.TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_table.add_child(empty)
	for i in mini(list.size(), SHOWN):
		var r := list[i]
		var bg: Variant = null
		if r["id"] == highlight_id:
			bg = Color(0.35, 0.25, 0.08, 0.9)
		elif r["name"] == me:
			bg = Color(0.16, 0.14, 0.2, 0.9)
		elif i % 2 == 0:
			bg = Color(1, 1, 1, 0.03)
		var color := UiTheme.GOLD if i < 3 else UiTheme.TEXT
		_table.add_child(_row([
			Records.ordinal(i + 1), r["name"], Records.format_number(r["score"]), str(r["level"]),
			Records.format_time(r["duration"]), tr(Maps.get_map(r["map"])["name"]), difficulty_name(r["difficulty"]),
			Records.format_date(r["date"]),
		], color, bg))
	var pos := Records.best_position_of(me, filter, map_filter)
	if pos > 0:
		_footer.text = tr("Sua melhor posição (%s): %s, entre %d partidas") % [me, Records.ordinal(pos), list.size()]
	else:
		_footer.text = tr("%s ainda não tem partidas nesta categoria.") % me


func _row(cells: Array, color: Color, bg: Variant) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.flat(bg if bg != null else Color.TRANSPARENT, Color.TRANSPARENT, 0, 5.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	for i in cells.size():
		var l := UiTheme.label(str(cells[i]), 15, color)
		l.custom_minimum_size.x = COLUMNS[i]
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if i == 2:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		elif i == 3 or i == 4:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(l)
	return panel

