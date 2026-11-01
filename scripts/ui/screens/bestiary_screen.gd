class_name BestiaryScreen
extends MenuScreen
## Bestiário: uma ficha por criatura e chefe de cada mapa, com o desenho do
## jogo e a lenda real. Fichas fechadas mostram só a silhueta.

const CELL := Vector2(96, 96)

var map_id := "bay"
var _grid: GridContainer


func _build() -> void:
	var box := centered_panel(1000, 22)
	box.add_theme_constant_override("separation", 10)
	title(box, tr("Bestiário"), 36)
	var c := Bestiary.count()
	text(box, tr("%d de %d fichas abertas") % [c.x, c.y], 16, UiTheme.GOLD)
	# Abas dos mapas quebram em duas linhas quando não cabem numa só.
	var tabs := HFlowContainer.new()
	tabs.alignment = FlowContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	box.add_child(tabs)
	var group := ButtonGroup.new()
	for id: String in Maps.ORDER:
		var b := UiTheme.small_button(tr(Maps.get_map(id)["name"]), _show_map.bind(id), true)
		b.button_group = group
		b.custom_minimum_size.x = 180
		b.button_pressed = id == map_id
		tabs.add_child(b)
		if id == map_id:
			default_focus = b
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	back_button(box)
	_show_map(map_id)


func _show_map(id: String) -> void:
	map_id = id
	for child in _grid.get_children():
		child.queue_free()
	for art: String in Bestiary.ENTRIES[id]:
		_grid.add_child(_entry(art))


func _entry(art: String) -> Control:
	var open := Bestiary.seen(art)
	var boss := Spawner.BOSS_SCRIPTS.has(art)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.12, 0.05, 0.06, 0.8) if boss else Color(0, 0, 0, 0.3),
		Color(UiTheme.DANGER, 0.6) if boss else Color(UiTheme.GOLD_DARK, 0.5), 1, 8.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	row.add_child(_art_cell(art, open))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var name_text := tr(Maps.CREATURE_NAMES[art]) if open else "???"
	info.add_child(UiTheme.label(name_text, 18, UiTheme.DANGER if boss else UiTheme.GOLD, true))
	if boss and open:
		info.add_child(UiTheme.label(tr(Maps.BOSS_TITLES[art]), 13, UiTheme.TEXT_DIM))
	var lore := UiTheme.label(tr(Bestiary.LORE[art]) if open else tr("Queime esta criatura para abrir a ficha."), 14, UiTheme.TEXT if open else UiTheme.TEXT_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = 340
	info.add_child(lore)
	return panel


## O desenho do jogo dentro de um quadrado; chefes usam o próprio nó, parado.
func _art_cell(art: String, open: bool) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = CELL
	cell.clip_contents = true
	var holder := Node2D.new()
	holder.position = CELL / 2.0
	if not open:
		holder.modulate = Color(0.0, 0.0, 0.02, 0.85)
	cell.add_child(holder)
	if Spawner.BOSS_SCRIPTS.has(art):
		var b: Boss = Spawner.BOSS_SCRIPTS[art].new()
		b.setup_boss(art, 1.0, 1.0, 1.0, false)
		b.begin(0.0)
		b.process_mode = Node.PROCESS_MODE_DISABLED
		var s := 30.0 / b.radius
		holder.scale = Vector2.ONE * s
		holder.position = CELL / 2.0 - b.position * s
		holder.add_child(b)
	else:
		var r := 30.0 if art.begins_with("fog_") else 22.0
		holder.draw.connect(func() -> void: CreatureArt.draw(holder, art, r, 0.6, 0.4, Vector2.RIGHT, 0.0, 1.0, 1.0))
	return cell
