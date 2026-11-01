class_name WorkshopScreen
extends MenuScreen
## Oficina do faroleiro: gasta o óleo ganho nas partidas em melhorias
## permanentes (Balance.META) e em desbloqueios (mapas, faróis e cartas).

var _oil: Label
var _list: VBoxContainer
var _status: Label


func _build() -> void:
	var box := centered_panel(860, 26)
	box.add_theme_constant_override("separation", 10)
	title(box, tr("Oficina do faroleiro"), 36)
	text(box, tr("Cada partida rende óleo, até as derrotas. Gaste-o aqui em melhorias que valem para todas as noites."), 15, UiTheme.TEXT_DIM)
	_oil = UiTheme.label("", 22, UiTheme.GOLD, true)
	_oil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_oil)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 390)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	_status = UiTheme.label("", 15, UiTheme.GOLD)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	var back := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 220
	_refresh()


func _refresh() -> void:
	_oil.text = tr("Óleo do farol: %s") % Records.format_number(Progress.oil)
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(UiTheme.label(tr("Melhorias permanentes"), 18, UiTheme.GOLD, true))
	var first: Button = null
	for m: Dictionary in Balance.META:
		var id: String = m["id"]
		var lv := Progress.level(id) if Progress.enabled else int(Progress.meta.get(id, 0))
		var cost := Progress.next_cost(id)
		var b := _row(tr(m["name"]), tr(m["desc"]), lv, int(m["max"]), cost, _buy_meta.bind(id))
		if first == null and b:
			first = b
	_list.add_child(UiTheme.label(tr("Desbloqueios"), 18, UiTheme.GOLD, true))
	for u: Dictionary in Balance.UNLOCKS:
		var id: String = u["id"]
		var kind := {"map": tr("Mapa"), "keeper": tr("Farol"), "upgrade": tr("Carta de melhoria")}.get(u["kind"], "") as String
		var desc := kind
		var goal := Progress.goal_text(id)
		if goal != "":
			desc += "   •   " + tr("ou de graça: %s") % goal
		if Progress.unlocked.has(id):
			_row(Progress.unlock_name(id), desc, 1, 1, -1, Callable())
		else:
			var b := _row(Progress.unlock_name(id), desc, 0, 1, int(u["cost"]), _buy_unlock.bind(id))
			if first == null and b:
				first = b
	if first:
		default_focus = first
		UiTheme.focus_silently.call_deferred(first)


## Linha: nome, descrição, níveis (losangos) e botão de compra.
func _row(name_text: String, desc: String, lv: int, max_lv: int, cost: int, on_buy: Callable) -> Button:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(0, 0, 0, 0.3), Color(UiTheme.GOLD_DARK, 0.5), 1, 10.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	var head := UiTheme.label(name_text, 18, UiTheme.TEXT, true)
	info.add_child(head)
	var d := UiTheme.label(desc, 14, UiTheme.TEXT_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(d)
	var pips := Control.new()
	pips.custom_minimum_size = Vector2(16 * max_lv + 8, 20)
	pips.draw.connect(func() -> void:
		for i in max_lv:
			UiTheme.diamond(pips, Vector2(8 + i * 16, 10), 5.5, UiTheme.GOLD if i < lv else Color(UiTheme.GOLD_DARK, 0.6))
	)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pips)
	var b: Button = null
	if cost < 0:
		var done := UiTheme.label(tr("Completo") if max_lv > 1 else tr("Liberado"), 16, UiTheme.GOOD)
		done.custom_minimum_size.x = 190
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(done)
	else:
		b = UiTheme.small_button(tr("Comprar: %s de óleo") % Records.format_number(cost), on_buy)
		b.custom_minimum_size.x = 190
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if Progress.oil < cost:
			b.modulate = Color(1, 1, 1, 0.55)
		row.add_child(b)
	_list.add_child(panel)
	return b


func _buy_meta(id: String) -> void:
	_after_buy(Progress.buy_meta(id), tr(Progress.meta_entry(id)["name"]))


func _buy_unlock(id: String) -> void:
	_after_buy(Progress.buy_unlock(id), Progress.unlock_name(id))


func _after_buy(ok: bool, what: String) -> void:
	if ok:
		Sfx.play(&"relic")
		_refresh()
		_status.text = tr("Comprado: %s") % what
	else:
		Sfx.play(&"denied")
		_status.text = tr("Óleo insuficiente. Jogue mais noites para juntar óleo.")
