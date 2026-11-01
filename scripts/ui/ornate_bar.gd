class_name OrnateBar
extends Control
## Barra de progresso no estilo RPG, desenhada em código: moldura dourada,
## divisões, brilho, faísca na ponta e rastro animado quando o valor muda.
## Com `badge`, mostra um medalhão à esquerda (o nível, na barra de XP).

var fill_color := UiTheme.XP
var trail_color := Color(1.0, 0.95, 0.85, 0.75)
var segments := 0
var bar_height := 18.0
var badge := ""
var text := ""
var text_size := 13
var max_value := 1.0
var value := 0.0

var _shown := 0.0
var _trail := 0.0
var _trail_hold := 0.0
var _flash := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(v: float, maxv: float) -> void:
	value = v
	max_value = maxf(maxv, 0.0001)


## Pula a animação (ex.: ao subir de nível a barra recomeça do zero).
func snap() -> void:
	_shown = clampf(value / max_value, 0.0, 1.0)
	_trail = _shown


func flash() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_time += delta
	var target := clampf(value / max_value, 0.0, 1.0)
	if target < _shown - 0.0001:
		_trail = maxf(_trail, _shown)
		_shown = target
		_trail_hold = 0.4
	else:
		_shown = lerpf(_shown, target, 1.0 - exp(-delta * 7.0))
	if _trail_hold > 0.0:
		_trail_hold -= delta
	else:
		_trail = move_toward(_trail, _shown, delta * 0.7)
	_trail = maxf(_trail, _shown)
	_flash = maxf(0.0, _flash - delta * 1.6)
	queue_redraw()


func _draw() -> void:
	var left := size.y * 0.78 if badge != "" else 4.0
	var bar := Rect2(left, (size.y - bar_height) / 2.0, size.x - left - 4.0, bar_height)

	# Moldura.
	draw_rect(bar.grow(4.0), Color(0, 0, 0, 0.75))
	draw_rect(bar.grow(3.0), UiTheme.GOLD_DARK, false, 2.0)
	draw_rect(bar.grow(4.5), Color(UiTheme.GOLD, 0.45), false, 1.0)
	draw_rect(bar, Color(0.02, 0.02, 0.045, 0.95))

	# Preenchimento com gradiente vertical.
	var w := bar.size.x * _shown
	if w > 0.5:
		var r := Rect2(bar.position, Vector2(w, bar.size.y))
		var top := fill_color.lightened(0.3)
		var bottom := fill_color.darkened(0.4)
		draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]),
			PackedColorArray([top, top, bottom, bottom]))
		draw_rect(Rect2(r.position + Vector2(0, 2), Vector2(w, r.size.y * 0.28)), Color(1, 1, 1, 0.14))

	# Ganho a caminho (fantasma claro) e perda recente (rastro).
	var target := clampf(value / max_value, 0.0, 1.0)
	if target > _shown + 0.002:
		draw_rect(Rect2(bar.position.x + w, bar.position.y, bar.size.x * (target - _shown), bar.size.y), Color(fill_color.lightened(0.6), 0.45))
	if _trail > _shown + 0.002:
		draw_rect(Rect2(bar.position.x + w, bar.position.y, bar.size.x * (_trail - _shown), bar.size.y), trail_color)

	# Divisões, como as "bolhas" de XP dos RPGs.
	if segments > 1:
		for i in range(1, segments):
			var x := roundf(bar.position.x + bar.size.x * i / segments)
			draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(0, 0, 0, 0.6), 2.0)
			draw_line(Vector2(x + 1.5, bar.position.y + 2), Vector2(x + 1.5, bar.end.y - 2), Color(1, 1, 1, 0.06), 1.0)

	# Faísca pulsando na ponta.
	if _shown > 0.003 and _shown < 0.997:
		var head := Vector2(bar.position.x + w, bar.get_center().y)
		var pulse := 0.6 + 0.4 * sin(_time * 6.0)
		draw_circle(head, bar_height * 0.9, Color(fill_color.lightened(0.5), 0.18 * pulse))
		draw_line(head + Vector2(0, -bar_height * 0.5), head + Vector2(0, bar_height * 0.5), Color(1, 1, 1, 0.7 * pulse), 2.0)

	if _flash > 0.0:
		draw_rect(bar.grow(3.0), Color(UiTheme.GOLD, 0.55 * _flash))

	UiTheme.diamond(self, Vector2(bar.position.x - 4.0, bar.get_center().y), 5.0, UiTheme.GOLD)
	UiTheme.diamond(self, Vector2(bar.end.x + 4.0, bar.get_center().y), 5.0, UiTheme.GOLD)

	if text != "":
		UiTheme.draw_text(self, text, bar.get_center(), text_size, UiTheme.TEXT, null, bar.size.x)
	if badge != "":
		_draw_badge(Vector2(size.y * 0.5, size.y * 0.5), size.y * 0.5 - 1.0)


func _draw_badge(c: Vector2, r: float) -> void:
	if _flash > 0.0:
		draw_circle(c, r + 10.0 * _flash, Color(UiTheme.GOLD, 0.3 * _flash))
	draw_circle(c, r, Color(0, 0, 0, 0.8))
	draw_circle(c, r - 3.0, Color(0.1, 0.07, 0.16))
	draw_circle(c, r - 7.0, Color(fill_color.darkened(0.55), 0.9))
	draw_arc(c, r - 1.5, 0.0, TAU, 40, UiTheme.GOLD, 3.0)
	draw_arc(c, r - 6.0, 0.0, TAU, 40, Color(UiTheme.GOLD, 0.45), 1.0)
	for i in 4:
		UiTheme.diamond(self, c + Vector2.from_angle(i * PI / 2.0 - PI / 2.0) * (r - 1.5), 3.5, UiTheme.GOLD)
	UiTheme.draw_text(self, badge, c, int(r * 0.85), UiTheme.GOLD, UiTheme.heading_font())
