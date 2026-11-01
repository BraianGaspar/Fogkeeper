class_name RankingScreen
extends MenuScreen
## Ranking local: melhores pontuações, filtráveis por dificuldade, com a
## posição do jogador e as regras de pontuação.

const FILTERS := ["", "easy", "normal", "hard"]
const COLUMNS := [50, 200, 120, 80, 100, 120, 170] ## Larguras: # Jogador Pontos Nível Duração Dificuldade Data
const SHOWN := 50

var filter := ""
var highlight_id := "" ## Partida recém-terminada, destacada na tabela.

var _table: VBoxContainer
var _footer: Label
var _filter_buttons: Array[Button] = []


func _build() -> void:
	var box := centered_panel(920, 26)
	title(box, tr("Ranking"), 36)

	var filters := HBoxContainer.new()
	filters.alignment = BoxContainer.ALIGNMENT_CENTER
	filters.add_theme_constant_override("separation", 8)
	box.add_child(filters)
	var group := ButtonGroup.new()
	for f: String in FILTERS:
		var label := tr("Todas") if f == "" else difficulty_name(f)
		var b := UiTheme.small_button(label, _set_filter.bind(f), true)
		b.button_group = group
		b.custom_minimum_size.x = 130
		b.button_pressed = f == filter
		filters.add_child(b)
		_filter_buttons.append(b)
		if f == filter:
			default_focus = b

	box.add_child(_row(["#", tr("Jogador"), tr("Pontos"), tr("Nível"), tr("Duração"), tr("Dificuldade"), tr("Data")], UiTheme.GOLD, null))
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
	text(box, _rules_text(), 13, UiTheme.TEXT_DIM)
	var back := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 220
	_refresh()


func _set_filter(f: String) -> void:
	filter = f
	_refresh()


func _refresh() -> void:
	for c in _table.get_children():
		c.queue_free()
	var list := Records.ranking(filter)
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
			"%d" % (i + 1), r["name"], Records.format_number(r["score"]), str(r["level"]),
			Records.format_time(r["duration"]), difficulty_name(r["difficulty"]), Records.format_date(r["date"]),
		], color, bg))
	var pos := Records.best_position_of(me, filter)
	if pos > 0:
		_footer.text = tr("Sua melhor posição (%s): #%d de %d") % [me, pos, list.size()]
	else:
		_footer.text = tr("%s ainda não tem partidas nesta categoria.") % me


func _row(cells: Array, color: Color, bg: Variant) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.flat(bg if bg != null else Color.TRANSPARENT, Color.TRANSPARENT, 0, 6.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	for i in cells.size():
		var l := UiTheme.label(str(cells[i]), 16, color)
		l.custom_minimum_size.x = COLUMNS[i]
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if i == 2:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		elif i == 3 or i == 4:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(l)
	return panel


func _rules_text() -> String:
	var per_kill := []
	for kind: String in ["mist", "brute", "leviathan"]:
		per_kill.append(str(Balance.ENEMIES[kind]["score"]))
	var mults := []
	for id: String in Balance.DIFFICULTY_ORDER:
		mults.append("%s ×%s" % [difficulty_name(id), DifficultyScreen._mult_text(Balance.DIFFICULTIES[id]["score"])])
	return tr("Pontuação: criaturas queimadas (%s pontos cada, conforme o tipo) + %d por segundo sobrevivido + %s pela vitória + até %s pela vida restante ao amanhecer, multiplicado pela dificuldade (%s).") % [
		" / ".join(per_kill), Balance.SCORE_PER_SECOND, Records.format_number(Balance.SCORE_VICTORY),
		Records.format_number(Balance.SCORE_HEALTH_BONUS), " · ".join(mults)] + "\n" + tr("Ranking deste computador. O ranking online chega com a versão da Steam.")
