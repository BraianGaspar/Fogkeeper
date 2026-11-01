class_name KeeperScreen
extends MenuScreen
## Escolha do farol (aparência), com prévia animada de cada um.

signal chosen(keeper_id: String)

const CARD := Vector2(215, 330)


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
		cards.append(card)
		if id == Settings.keeper:
			start = i
	var picker := CardPicker.new()
	picker.gap = 22.0
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picker)
	picker.setup(cards, start)
	picker.chosen.connect(func(i: int) -> void: chosen.emit(Keepers.ORDER[i]))
	text(box, tr("A/D ou ←/→ para escolher   •   Enter ou clique para continuar   •   Esc para voltar"), 14, UiTheme.TEXT_DIM)
	back_button(box)


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
