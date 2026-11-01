class_name KeeperScreen
extends MenuScreen
## Escolha do farol (aparência), com prévia animada de cada um.

signal chosen(keeper_id: String)

const CARD := Vector2(215, 330)

var _status: Label


func _build() -> void:
	var box := centered_panel(1000, 24)
	title(box, tr("Escolha o seu farol"), 36)
	text(box, tr("Só a aparência muda: a força de todos é a mesma, para o ranking ser justo."), 15, UiTheme.TEXT_DIM)
	var cards: Array[ChoiceCard] = []
	var start := 0
	for i in Keepers.ORDER.size():
		var id: String = Keepers.ORDER[i]
		var k := Keepers.get_keeper(id)
		var card := ChoiceCard.new(tr(k["name"]), "", tr(k["desc"]), CARD)
		card.accent = (k["beam"] as Color).lerp(UiTheme.GOLD, 0.3)
		card.preview = draw_preview.bind(id)
		card.locked = not Progress.is_unlocked(id)
		if card.locked:
			card.lock_text = tr("%s de óleo") % Records.format_number(int(Progress.unlock_entry(id)["cost"]))
		cards.append(card)
		if id == Settings.keeper and not card.locked:
			start = i
	var picker := CardPicker.new()
	picker.gap = 22.0
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picker)
	_status = text(box, "", 15, UiTheme.GOLD)
	picker.selection_changed.connect(_show_status)
	picker.setup(cards, start)
	picker.chosen.connect(_on_chosen.bind(picker))
	back_button(box)


func _show_status(i: int) -> void:
	var id: String = Keepers.ORDER[i]
	if Progress.is_unlocked(id):
		_status.text = ""
		return
	var goal := Progress.goal_text(id)
	_status.text = tr("Escolha para comprar por %s de óleo (você tem %s).") % [
		Records.format_number(int(Progress.unlock_entry(id)["cost"])), Records.format_number(Progress.oil)]
	if goal != "":
		_status.text += "  " + tr("Ou libere de graça: %s.") % goal


func _on_chosen(i: int, picker: CardPicker) -> void:
	var id: String = Keepers.ORDER[i]
	if Progress.is_unlocked(id):
		chosen.emit(id)
		return
	if Progress.buy_unlock(id):
		Sfx.play(&"relic")
		Settings.keeper = id
		for c in get_children():
			c.queue_free()
		_build.call_deferred()
		return
	Sfx.play(&"denied")
	picker.rearm()
	_status.text = tr("Óleo insuficiente: você tem %s.") % Records.format_number(Progress.oil)


## O farol girando o feixe sobre o mar, na cor dele.
static func draw_preview(ci: CanvasItem, area: Rect2, t: float, keeper_id: String) -> void:
	ci.draw_rect(area, Color(0.04, 0.06, 0.11))
	var c := area.get_center()
	var beam: Color = Keepers.get_keeper(keeper_id)["beam"]
	var cone := PackedVector2Array([c])
	var cols := PackedColorArray([Color(beam, 0.55)])
	var reach := minf(area.size.x, area.size.y) * 0.5
	for i in 9:
		var a := t * 1.1 - 0.3 + 0.6 * i / 8.0
		cone.append(c + Vector2.from_angle(a) * reach)
		cols.append(Color(beam, 0.0))
	ci.draw_polygon(cone, cols)
	ci.draw_circle(c, 40.0, Color(0.3, 0.28, 0.24))
	LighthouseArt.draw(ci, keeper_id, c, 1.25, t)
