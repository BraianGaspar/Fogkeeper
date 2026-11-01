class_name MapScreen
extends MenuScreen
## Escolha do mapa: cartas com prévia animada e a história do mapa
## selecionado logo abaixo. Mapas bloqueados mostram como liberá-los;
## escolher um deles compra com óleo, se houver o bastante.

signal chosen(map_id: String)

const CARD := Vector2(204, 330)
const ACCENTS := {"bay": UiTheme.GOLD, "fjord": Color(0.55, 0.85, 1.0), "amazon": Color(0.55, 0.95, 0.5),
	"japan": Color(1.0, 0.55, 0.65), "egypt": Color(1.0, 0.82, 0.4), "greece": Color(0.55, 0.75, 1.0),
	"celtic": Color(0.5, 1.0, 0.75)}

var _story: Label
var _story_title: Label
var _status: Label


func _build() -> void:
	var box := centered_panel(1120, 20)
	box.add_theme_constant_override("separation", 8)
	title(box, tr("Escolha o mapa"), 36)
	var cards: Array[ChoiceCard] = []
	var start := 0
	# Com muitos mapas as cartas estreitam para caber numa fileira só.
	var n := Maps.ORDER.size()
	var gap := 14.0 if n <= 5 else 8.0
	var card_size := Vector2(minf(CARD.x, (1090.0 - gap * (n - 1)) / n), CARD.y)
	for i in Maps.ORDER.size():
		var id: String = Maps.ORDER[i]
		var m := Maps.get_map(id)
		var bosses := []
		for b: String in m["bosses"]:
			bosses.append(tr(Maps.CREATURE_NAMES[b]))
		var card := ChoiceCard.new(tr(m["name"]), " · ".join(bosses), tr(m["tagline"]), card_size)
		card.accent = ACCENTS.get(id, UiTheme.GOLD)
		card.preview = draw_preview.bind(id)
		card.locked = not Progress.is_unlocked(id)
		if card.locked:
			card.lock_text = tr("%s de óleo") % Records.format_number(int(Progress.unlock_entry(id)["cost"]))
		cards.append(card)
		if id == Settings.map and not card.locked:
			start = i
	var picker := CardPicker.new()
	picker.gap = gap
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
	_story.custom_minimum_size = Vector2(1040, 60)
	story_box.add_child(_story)
	box.add_child(story_panel)

	_status = text(box, "", 15, UiTheme.GOLD)
	picker.selection_changed.connect(_show_story)
	picker.setup(cards, start)
	picker.chosen.connect(_on_chosen.bind(picker))
	back_button(box)


func _on_chosen(i: int, picker: CardPicker) -> void:
	var id: String = Maps.ORDER[i]
	if Progress.is_unlocked(id):
		chosen.emit(id)
		return
	if Progress.buy_unlock(id):
		# Comprado: a tela se refaz com o mapa liberado e já selecionado.
		Sfx.play(&"relic")
		Settings.map = id
		for c in get_children():
			c.queue_free()
		_build.call_deferred()
		return
	Sfx.play(&"denied")
	picker.rearm()
	_status.text = tr("Óleo insuficiente: você tem %s.") % Records.format_number(Progress.oil)


func _show_story(i: int) -> void:
	var id: String = Maps.ORDER[i]
	var m := Maps.get_map(id)
	_status.text = ""
	if Progress.is_unlocked(id):
		_story_title.text = tr("Como você chegou aqui")
		_story.text = tr(m["story"])
		return
	_story_title.text = tr("Bloqueado")
	var cost := int(Progress.unlock_entry(id)["cost"])
	_story.text = tr("Libere de graça: %s. Ou escolha este mapa para comprá-lo por %s de óleo (você tem %s).") % [
		Progress.goal_text(id), Records.format_number(cost), Records.format_number(Progress.oil)]


## Miniatura viva do mapa, desenhada dentro de `area`.
static func draw_preview(ci: CanvasItem, area: Rect2, t: float, map_id: String) -> void:
	var c := area.get_center()
	var fjord := map_id == "fjord"
	var river := map_id == "amazon"
	var japan := map_id == "japan"
	var egypt := map_id == "egypt"
	var greece := map_id == "greece"
	var celtic := map_id == "celtic"
	var top := Color(0.05, 0.08, 0.15)
	var bottom := Color(0.02, 0.04, 0.08)
	if fjord:
		top = Color(0.14, 0.2, 0.3)
		bottom = Color(0.3, 0.36, 0.45)
	elif river:
		top = Color(0.05, 0.12, 0.09)
		bottom = Color(0.12, 0.14, 0.08)
	elif japan:
		top = Color(0.06, 0.06, 0.18)
		bottom = Color(0.03, 0.04, 0.1)
	elif egypt:
		top = Color(0.06, 0.1, 0.18)
		bottom = Color(0.04, 0.06, 0.12)
	elif greece:
		top = Color(0.04, 0.09, 0.22)
		bottom = Color(0.02, 0.05, 0.14)
	elif celtic:
		top = Color(0.05, 0.1, 0.12)
		bottom = Color(0.03, 0.06, 0.07)
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
			var p := Vector2(area.position.x + area.size.x * (0.08 + i * 0.2), c.y + sin(i * 2.3) * 45.0)
			if area.has_point(p):
				ci.draw_line(p, p + Vector2(18, 10), Color(1, 1, 1, 0.25), 1.0)
	elif river:
		# Margens de mata, vitórias-régias e vaga-lumes.
		# Copas das margens, sem sair da área da prévia.
		for edge: float in [area.position.y + 9.0, area.end.y - 9.0]:
			var k := 0
			var x := area.position.x + 10.0
			while x < area.end.x - 9.0:
				ci.draw_circle(Vector2(x, edge), 8.0 + 1.5 * sin(k * 1.9), Color(0.08, 0.2, 0.1))
				ci.draw_circle(Vector2(x - 2.0, edge - 2.0), 4.5, Color(0.12, 0.28, 0.14))
				x += 13.0
				k += 1
		for i in 5:
			var p := Vector2(area.position.x + area.size.x * (0.1 + i * 0.2), c.y + sin(i * 2.1) * 32.0)
			if p.distance_to(c) > 60.0:
				ci.draw_circle(p, 11.0, Color(0.22, 0.48, 0.2))
				ci.draw_arc(p, 11.0, 0.0, TAU, 16, Color(0.55, 0.3, 0.25), 2.0)
		for i in 9:
			var p := Vector2(area.position.x + fposmod(i * 97.0 + t * 12.0, area.size.x), area.position.y + 26.0 + fposmod(i * 53.0, area.size.y - 52.0))
			var blink := clampf(sin(t * 2.0 + i * 1.7) * 2.0, 0.0, 1.0)
			ci.draw_circle(p, 4.0, Color(0.9, 1.0, 0.4, 0.25 * blink))
			ci.draw_circle(p, 1.5, Color(0.95, 1.0, 0.6, blink))
	elif japan:
		# Lua grande, torii e lanternas do Obon.
		ci.draw_circle(area.position + Vector2(area.size.x * 0.2, area.size.y * 0.3), 22.0, Color(1.0, 0.95, 0.85, 0.35))
		var tg := area.position + Vector2(area.size.x * 0.78, area.size.y * 0.3)
		ci.draw_rect(Rect2(tg + Vector2(-20, -4), Vector2(40, 6)), Color(0.82, 0.18, 0.12))
		ci.draw_rect(Rect2(tg + Vector2(-22, -7), Vector2(44, 3)), Color(0.15, 0.1, 0.1))
		for x: float in [-12.0, 12.0]:
			ci.draw_circle(tg + Vector2(x, 0), 3.0, Color(0.75, 0.15, 0.1))
		for i in 7:
			var p := Vector2(area.position.x + fposmod(i * 61.0 + t * 8.0, area.size.x), area.position.y + area.size.y * (0.55 + 0.35 * sin(i * 2.3)))
			ci.draw_circle(p, 6.0, Color(1.0, 0.6, 0.25, 0.2))
			ci.draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5, 5)), Color(1.0, 0.8, 0.45))
	elif egypt:
		# Areia, pirâmides e colunas afundadas.
		var shore := area.position.x + area.size.x * 0.72
		ci.draw_rect(Rect2(shore, area.position.y, area.end.x - shore, area.size.y), Color(0.6, 0.48, 0.32))
		var py := Vector2(shore + (area.end.x - shore) * 0.5, area.position.y + area.size.y * 0.35)
		ci.draw_colored_polygon(PackedVector2Array([py + Vector2(-18, 12), py + Vector2(0, -12), py + Vector2(18, 12)]), Color(0.75, 0.6, 0.38))
		ci.draw_colored_polygon(PackedVector2Array([py + Vector2(0, -12), py + Vector2(18, 12), py + Vector2(4, 12)]), Color(0.5, 0.38, 0.24))
		for i in 3:
			ci.draw_circle(area.position + Vector2(area.size.x * (0.12 + i * 0.1), area.size.y * 0.75), 5.0, Color(0.78, 0.7, 0.55))
	elif greece:
		# Rochedo branco do estreito, colunas e o redemoinho de Caríbdis.
		var rock := area.position + Vector2(area.size.x * 0.8, area.size.y * 0.25)
		ci.draw_circle(rock, 22.0, Color(0.78, 0.76, 0.7))
		ci.draw_circle(rock + Vector2(-5, -5), 13.0, Color(0.9, 0.88, 0.84))
		var whirl := area.position + Vector2(area.size.x * 0.2, area.size.y * 0.25)
		for k in 3:
			var a0 := -t * 1.5 + k
			ci.draw_arc(whirl, 8.0 + k * 7.0, a0, a0 + 4.0, 14, Color(0.6, 0.75, 1.0, 0.35), 1.5)
		for i in 3:
			ci.draw_circle(area.position + Vector2(area.size.x * (0.14 + i * 0.09), area.size.y * 0.78), 4.5, Color(0.9, 0.88, 0.84))
	elif celtic:
		# Penhasco verde à esquerda e o círculo de pedras.
		var edge := area.position.x + area.size.x * 0.16
		ci.draw_rect(Rect2(area.position, Vector2(edge - area.position.x, area.size.y)), Color(0.2, 0.36, 0.2))
		ci.draw_line(Vector2(edge, area.position.y), Vector2(edge, area.end.y), Color(0.3, 0.3, 0.3), 3.0)
		var ring := area.position + Vector2(area.size.x * 0.78, area.size.y * 0.25)
		ci.draw_circle(ring, 20.0, Color(0.22, 0.34, 0.2))
		for i in 7:
			var p := ring + Vector2.from_angle(TAU * i / 7.0) * 13.0
			ci.draw_rect(Rect2(p - Vector2(2.5, 3), Vector2(5, 6)), Color(0.62, 0.64, 0.6))
		ci.draw_circle(ring, 6.0, Color(0.55, 1.0, 0.8, 0.15 + 0.1 * sin(t)))
	else:
		for i in 8:
			var p := Vector2(area.position.x + area.size.x * (0.06 + i * 0.12), c.y + 40.0 + sin(i * 1.7) * 35.0)
			ci.draw_arc(p, 9.0, -PI * 0.85, -PI * 0.15, 6, Color(0.45, 0.58, 0.75, 0.3), 1.5)
	# Ilha e farol.
	var island := Color(0.6, 0.53, 0.4)
	var grass := Color(0.27, 0.3, 0.24)
	if fjord:
		island = Color(0.9, 0.94, 1.0)
		grass = Color(0.85, 0.9, 0.97)
	elif river:
		island = Color(0.72, 0.6, 0.42)
		grass = Color(0.16, 0.3, 0.14)
	elif japan:
		island = Color(0.42, 0.4, 0.38)
		grass = Color(0.22, 0.3, 0.2)
	elif egypt:
		island = Color(0.78, 0.66, 0.46)
		grass = Color(0.68, 0.56, 0.38)
	elif greece:
		island = Color(0.82, 0.8, 0.74)
		grass = Color(0.52, 0.56, 0.4)
	elif celtic:
		island = Color(0.45, 0.45, 0.42)
		grass = Color(0.26, 0.46, 0.24)
	ci.draw_circle(c + Vector2(0, 8), 44.0, Color(1, 1, 1, 0.12))
	ci.draw_circle(c + Vector2(0, 8), 38.0, island)
	ci.draw_circle(c + Vector2(0, 8), 30.0, grass)
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
	var m := c + Vector2(minf(area.size.x * 0.3, 140.0), area.size.y * 0.22)
	if fjord:
		ci.draw_set_transform(m, PI)
		CreatureArt.wolf(ci, 13.0, t, 0.0, 0.0, 1.0, Color(0.24, 0.24, 0.28), Color(0.1, 0.1, 0.13), Color(1.0, 0.3, 0.2))
		ci.draw_set_transform(Vector2.ZERO)
	elif river:
		# Boitatá: cobra de fogo de olhos grandes.
		for i in range(7, -1, -1):
			var p := m + Vector2(-i * 10.0, sin(t * 2.5 + i * 0.8) * 6.0)
			ci.draw_circle(p, 12.0 - i * 0.8, Color(1.0, 0.45, 0.1, 0.25))
			ci.draw_circle(p, 8.0 - i * 0.6, Color(1.0, 0.55 + i * 0.03, 0.15))
		var head := m + Vector2(4, sin(t * 2.5) * 6.0)
		for s: float in [-1.0, 1.0]:
			ci.draw_circle(head + Vector2(2, s * 4.0), 3.0, Color(1.0, 1.0, 0.85))
	elif japan:
		ci.draw_set_transform(m, PI)
		CreatureArt.kyubi(ci, 11.0, t, 0.0, 0.0, 1.0)
		ci.draw_set_transform(Vector2.ZERO)
	elif egypt:
		# Apep: serpente escura de anéis dourados.
		for i in range(8, -1, -1):
			var p := m + Vector2(-i * 10.0, sin(t * 2.2 + i * 0.7) * 6.0)
			ci.draw_circle(p, 8.0 - i * 0.5, Color(0.16, 0.08, 0.2))
			if i % 2 == 0:
				ci.draw_arc(p, 6.0 - i * 0.4, 0.0, TAU, 10, Color(0.85, 0.65, 0.2), 1.5)
		ci.draw_circle(m + Vector2(6, sin(t * 2.2) * 6.0), 3.0, Color(0.9, 0.3, 1.0))
	elif greece:
		# Medusa: rosto pálido de olhos verdes e cabelo de serpentes.
		for i in 7:
			var a := PI * 0.6 + i * 0.3
			var tip := m + Vector2.from_angle(a) * (16.0 + 3.0 * sin(t * 3.0 + i))
			ci.draw_line(m, tip, Color(0.3, 0.5, 0.25), 3.0)
			ci.draw_circle(tip, 2.5, Color(0.4, 0.6, 0.3))
		ci.draw_circle(m, 9.0, Color(0.62, 0.7, 0.56))
		for s: float in [-1.0, 1.0]:
			ci.draw_circle(m + Vector2(s * 3.5, 1), 2.0, Color(0.7, 1.0, 0.6, 0.6 + 0.4 * sin(t * 2.0)))
	elif celtic:
		# O olho de Balor, abrindo e fechando.
		var o := clampf(sin(t * 0.9) * 1.5, 0.0, 1.0)
		ci.draw_circle(m, 13.0, Color(0.28, 0.3, 0.3))
		var pts := PackedVector2Array()
		for i in 12:
			var a := TAU * i / 12.0
			pts.append(m + Vector2(cos(a) * 9.0, sin(a) * 9.0 * maxf(0.08, o)))
		ci.draw_colored_polygon(pts, Color(1.0, 0.9, 0.7))
		ci.draw_circle(m, 4.0 * o, Color(0.9, 0.15, 0.05))
	else:
		for i in 7:
			var p := m + Vector2(-i * 11.0, sin(t * 2.0 + i * 0.8) * 6.0)
			ci.draw_circle(p, 10.0 - i * 0.9, Color(0.12, 0.28, 0.33))
		ci.draw_circle(m + Vector2(6, sin(t * 2.0) * 6.0), 2.0, Color(1.0, 0.85, 0.3))
