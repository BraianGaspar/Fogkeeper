class_name StoryScreen
extends MenuScreen
## "Como você chegou aqui": a história do mapa aparece letra por letra antes
## da partida. O botão (ou Enter, ou Esc) pula a história e começa a noite;
## clicar fora dele mostra o texto inteiro de uma vez.

signal finished

const CHARS_PER_SECOND := 55.0

var map_id := "bay"

var _story: Label
var _preview: Control
var _hint: Label
var _shown := 0.0
var _done := false
var _closed := false
var _start: Button


func _build() -> void:
	var m := Maps.get_map(map_id)
	var box := centered_panel(820, 34)
	box.add_theme_constant_override("separation", 12)
	_preview = Control.new()
	var preview := _preview
	preview.custom_minimum_size = Vector2(820, 170)
	preview.draw.connect(func() -> void: MapScreen.draw_preview(preview, Rect2(Vector2.ZERO, preview.size), Time.get_ticks_msec() / 1000.0, map_id))
	box.add_child(preview)
	title(box, tr(m["name"]), 38)
	var sub := text(box, tr("Como você chegou aqui"), 17, UiTheme.GOLD)
	sub.add_theme_font_override("font", UiTheme.heading_font())
	_story = text(box, tr(m["story"]), 19, UiTheme.TEXT, false)
	_story.custom_minimum_size = Vector2(820, 150)
	_story.visible_characters = 0
	_hint = text(box, "", 14, UiTheme.TEXT_DIM)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	_start = add_button(row, tr("Pular história"), _finish)
	_start.custom_minimum_size.x = 300
	default_focus = _start
	_hint.text = tr("Dá para desligar esta história em Configurações > Geral.")


func _process(delta: float) -> void:
	if not _done:
		_shown += delta * CHARS_PER_SECOND
		_story.visible_characters = int(_shown)
		if _story.visible_ratio >= 1.0:
			_done = true
			_start.text = tr("Começar a noite")
	_preview.queue_redraw()


## Clique fora dos botões: completa o texto; de novo, começa a noite.
func _advance() -> void:
	if not _done:
		_done = true
		_story.visible_characters = -1
		_start.text = tr("Começar a noite")
		return
	_finish()


func _finish() -> void:
	if _closed:
		return
	_closed = true
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()


func go_back() -> bool:
	_finish()
	return true
