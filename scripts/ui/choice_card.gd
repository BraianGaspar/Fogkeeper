class_name ChoiceCard
extends Control
## Carta de escolha (melhoria, mapa, farol ou dificuldade): ícone ou prévia,
## nome, etiqueta, níveis (losangos) e descrição. O destaque animado fica
## aqui; a navegação por teclado e mouse fica no CardPicker.

const SIZE := Vector2(250, 340)

var icon_id := ""
## Prévia desenhada no lugar do ícone: func(ci: CanvasItem, area: Rect2, time: float).
var preview: Callable
var accent := UiTheme.GOLD
var hotkey := ""
var pips := 0 ## Losangos acesos (nível que a carta levará).
var max_pips := 0
var selected := false
var card_size := SIZE

var _glow := 0.0
var _flash := 0.0
var _time := 0.0


func _init(title: String, tag: String, desc: String, size_override: Vector2 = SIZE) -> void:
	card_size = size_override
	size = card_size
	custom_minimum_size = card_size
	pivot_offset = card_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var w := card_size.x
	var h := card_size.y

	var name_label := UiTheme.label(title, 21, UiTheme.TEXT, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.position = Vector2(12, h * 0.385)
	name_label.size = Vector2(w - 24, 54)
	add_child(name_label)

	var tag_label := UiTheme.label(tag, 14, UiTheme.GOLD)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.position = Vector2(12, h * 0.385 + 54)
	tag_label.size = Vector2(w - 24, 20)
	add_child(tag_label)

	var desc_label := UiTheme.label(desc, 14 if w < 230.0 else 15, UiTheme.TEXT_DIM)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.position = Vector2(16, _desc_top())
	desc_label.size = Vector2(w - 32, h - _desc_top() - 10)
	add_child(desc_label)


func _desc_top() -> float:
	return card_size.y * 0.385 + 54 + 20 + 26


func flash() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_time += delta
	_glow = move_toward(_glow, 1.0 if selected else 0.0, delta * 6.0)
	_flash = maxf(0.0, _flash - delta * 3.0)
	var target := Vector2.ONE * (1.06 if selected else 1.0)
	scale = scale.lerp(target, 1.0 - exp(-delta * 14.0))
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, card_size)
	if _glow > 0.0:
		var pulse := 0.75 + 0.25 * sin(_time * 5.0)
		for i in 6:
			draw_rect(r.grow(2.0 + i * 3.0), Color(accent, 0.07 * _glow * pulse * (1.0 - i / 6.0)), false, 3.0)

	var top := Color(0.11, 0.11, 0.18).lerp(Color(0.2, 0.15, 0.1), _glow * 0.6)
	var bottom := Color(0.04, 0.045, 0.08)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(0, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))

	var art := Rect2(10, 10, card_size.x - 20, card_size.y * 0.385 - 14)
	if preview.is_valid():
		preview.call(self, art, _time)
		draw_rect(art, Color(accent, 0.3 + 0.4 * _glow), false, 1.0)
	else:
		var ic := art.get_center()
		var rad := minf(art.size.x, art.size.y) * 0.45
		for i in 4:
			draw_circle(ic, rad - i * rad * 0.18, Color(accent, (0.03 + 0.03 * _glow) * (i + 1)))
		draw_arc(ic, rad, 0.0, TAU, 48, Color(accent, 0.35 + 0.4 * _glow), 1.5)
		Icons.draw(self, icon_id, ic, rad * 0.56, accent.lerp(Color(1.0, 0.85, 0.55), 0.3))

	draw_rect(r, UiTheme.GOLD_DARK.lerp(accent, _glow), false, 1.5 + 1.5 * _glow)
	draw_rect(r.grow(-5.0), Color(accent, 0.12 + 0.2 * _glow), false, 1.0)

	if max_pips > 0:
		var gap := 16.0
		var x0 := card_size.x / 2.0 - (max_pips - 1) * gap / 2.0
		var y := _desc_top() - 13.0
		for i in max_pips:
			var col := UiTheme.GOLD if i < pips else Color(UiTheme.GOLD_DARK, 0.6)
			UiTheme.diamond(self, Vector2(x0 + i * gap, y), 5.5 if i == pips - 1 else 4.5, col)

	UiTheme.diamond(self, Vector2(card_size.x / 2.0, 0), 6.0, accent)
	if hotkey != "":
		var hk := Vector2(22, 22)
		draw_circle(hk, 13.0, Color(0, 0, 0, 0.7))
		draw_arc(hk, 13.0, 0.0, TAU, 24, Color(accent, 0.7), 1.5)
		UiTheme.draw_text(self, hotkey, hk, 15, accent, UiTheme.heading_font())

	if _flash > 0.0:
		draw_rect(r, Color(1.0, 0.95, 0.8, 0.5 * _flash))
