class_name MapScreen
extends MenuScreen
## Escolha do mapa: cartas com prévia animada e a história do mapa
## selecionado logo abaixo.

signal chosen(map_id: String)

const CARD := Vector2(360, 330)

var _story: Label
var _story_title: Label


func _build() -> void:
	var box := centered_panel(1000, 20)
	box.add_theme_constant_override("separation", 8)
	title(box, tr("Escolha o mapa"), 36)
	var cards: Array[ChoiceCard] = []
	var start := 0
	for i in Maps.ORDER.size():
		var id: String = Maps.ORDER[i]
		var m := Maps.get_map(id)
		var bosses := []
		for b: String in m["bosses"]:
			bosses.append(tr(Maps.CREATURE_NAMES[b]))
		var card := ChoiceCard.new(tr(m["name"]), tr("Chefes: %s") % " · ".join(bosses), tr(m["tagline"]), CARD)
		card.accent = Color(0.55, 0.85, 1.0) if id == "fjord" else UiTheme.GOLD
		card.preview = draw_preview.bind(id)
		cards.append(card)
		if id == Settings.map:
			start = i
	var picker := CardPicker.new()
	picker.gap = 40.0
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picker)

	var story_panel := PanelContainer.new()
	story_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(0, 0, 0, 0.35), Color(UiTheme.GOLD_DARK, 0.6), 1, 14.0))
	var story_box := VBoxContainer.new()
	story_panel.add_child(story_box)
	_story_title = UiTheme.label("", 18, UiTheme.GOLD, true)
	story_box.add_child(_story_title)
	_story = UiTheme.label("", 15, UiTheme.TEXT)
	_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story.custom_minimum_size = Vector2(900, 60)
	story_box.add_child(_story)
	box.add_child(story_panel)

	picker.selection_changed.connect(_show_story)
	picker.setup(cards, start)
	picker.chosen.connect(func(i: int) -> void: chosen.emit(Maps.ORDER[i]))
	text(box, tr("A/D ou ←/→ para escolher   •   Enter ou clique para continuar   •   Esc para voltar"), 14, UiTheme.TEXT_DIM)
	back_button(box)


func _show_story(i: int) -> void:
	var m := Maps.get_map(Maps.ORDER[i])
	_story_title.text = tr("Como você chegou aqui")
	_story.text = tr(m["story"])


## Miniatura viva do mapa, desenhada dentro de `area`.
static func draw_preview(ci: CanvasItem, area: Rect2, t: float, map_id: String) -> void:
	var c := area.get_center()
	var fjord := map_id == "fjord"
	var top := Color(0.14, 0.2, 0.3) if fjord else Color(0.05, 0.08, 0.15)
	var bottom := Color(0.3, 0.36, 0.45) if fjord else Color(0.02, 0.04, 0.08)
	ci.draw_polygon(PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	if fjord:
		for band in 2:
			var col := Color(0.3, 1.0, 0.6) if band == 0 else Color(0.55, 0.4, 1.0)
			var pts := PackedVector2Array()
			for i in 9:
				var x := area.position.x + area.size.x * i / 8.0
				pts.append(Vector2(x, area.position.y + 22.0 + band * 14.0 + sin(x * 0.03 + t + band) * 8.0))
			ci.draw_polyline(pts, Color(col, 0.45), 6.0)
		for i in 5:
			var p := Vector2(area.position.x + 30.0 + i * 70.0, c.y + sin(i * 2.3) * 45.0)
			if area.has_point(p):
				ci.draw_line(p, p + Vector2(18, 10), Color(1, 1, 1, 0.25), 1.0)
	else:
		for i in 8:
			var p := Vector2(area.position.x + 20.0 + i * 46.0, c.y + 40.0 + sin(i * 1.7) * 35.0)
			ci.draw_arc(p, 9.0, -PI * 0.85, -PI * 0.15, 6, Color(0.45, 0.58, 0.75, 0.3), 1.5)
	# Ilha e farol.
	var island := Color(0.9, 0.94, 1.0) if fjord else Color(0.6, 0.53, 0.4)
	ci.draw_circle(c + Vector2(0, 8), 44.0, Color(1, 1, 1, 0.12))
	ci.draw_circle(c + Vector2(0, 8), 38.0, island)
	ci.draw_circle(c + Vector2(0, 8), 30.0, Color(0.85, 0.9, 0.97) if fjord else Color(0.27, 0.3, 0.24))
	var beam_angle := t * 0.8
	var cone := PackedVector2Array([c + Vector2(0, 8)])
	var cols := PackedColorArray([Color(1.0, 0.9, 0.6, 0.45)])
	for i in 9:
		var a := beam_angle - 0.25 + 0.5 * i / 8.0
		var tip := c + Vector2(0, 8) + Vector2.from_angle(a) * 120.0
		cone.append(Vector2(clampf(tip.x, area.position.x, area.end.x), clampf(tip.y, area.position.y, area.end.y)))
		cols.append(Color(1.0, 0.9, 0.6, 0.0))
	ci.draw_polygon(cone, cols)
	LighthouseArt.draw(ci, "classic", c + Vector2(0, 8), 0.45, t)
	# Criatura-símbolo do mapa.
	var m := c + Vector2(area.size.x * 0.3, area.size.y * 0.22)
	if fjord:
		ci.draw_set_transform(m, PI)
		CreatureArt.wolf(ci, 13.0, t, 0.0, 0.0, 1.0, Color(0.24, 0.24, 0.28), Color(0.1, 0.1, 0.13), Color(1.0, 0.3, 0.2))
		ci.draw_set_transform(Vector2.ZERO)
	else:
		for i in 7:
			var p := m + Vector2(-i * 11.0, sin(t * 2.0 + i * 0.8) * 6.0)
			ci.draw_circle(p, 10.0 - i * 0.9, Color(0.12, 0.28, 0.33))
		ci.draw_circle(m + Vector2(6, sin(t * 2.0) * 6.0), 2.0, Color(1.0, 0.85, 0.3))
