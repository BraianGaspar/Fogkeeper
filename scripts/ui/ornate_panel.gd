class_name OrnatePanel
extends PanelContainer
## Painel escuro com moldura dourada, filete interno e ornamentos nos cantos.


func _init(margin: float = 28.0) -> void:
	add_theme_stylebox_override("panel", UiTheme.panel_style(margin))
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var c := UiTheme.GOLD
	var inset := 7.0
	draw_rect(Rect2(Vector2.ZERO, size).grow(-inset), Color(c, 0.16), false, 1.0)
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var p := corner * size
		var dir := Vector2(1.0 - 2.0 * corner.x, 1.0 - 2.0 * corner.y)
		var a := p + dir * inset
		draw_line(a, a + Vector2(dir.x * 28.0, 0), c, 2.0)
		draw_line(a, a + Vector2(0, dir.y * 28.0), c, 2.0)
		UiTheme.diamond(self, p + dir * 2.0, 5.0, c)
	UiTheme.diamond(self, Vector2(size.x / 2.0, 0), 6.0, c)
	UiTheme.diamond(self, Vector2(size.x / 2.0, size.y), 6.0, c)
