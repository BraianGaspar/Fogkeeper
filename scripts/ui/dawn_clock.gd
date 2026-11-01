class_name DawnClock
extends Control
## Relógio da noite: trilha da lua (início) ao sol (amanhecer), pintada com
## as cores reais do DayCycle, com marcas dos chefes e o tempo restante.

var progress := 0.0
var time_text := ""
var caption := ""
var show_marks := true ## Marcas dos chefes (escondidas no modo sem fim).

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(380, 62)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var track := Rect2(30, 12, size.x - 60, 8)
	var steps := 32
	for i in steps:
		var f := float(i) / steps
		var pal := DayCycle.sample(f)
		var col: Color = (pal["sea"] as Color).lerp(pal["wave"], 0.55)
		draw_rect(Rect2(track.position.x + track.size.x * f, track.position.y, track.size.x / steps + 1.0, track.size.y), col)
	draw_rect(track.grow(2.0), UiTheme.GOLD_DARK, false, 2.0)
	draw_rect(Rect2(track.position.x, track.position.y, track.size.x * progress, track.size.y), Color(1, 1, 1, 0.12))

	for t: float in (Balance.BOSS_TIMES if show_marks else []):
		var x := track.position.x + track.size.x * t / Balance.RUN_DURATION
		UiTheme.diamond(self, Vector2(x, track.position.y - 7.0), 4.0, UiTheme.DANGER)

	var mx := track.position.x + track.size.x * clampf(progress, 0.0, 1.0)
	var glow := 0.6 + 0.4 * sin(_time * 4.0)
	draw_circle(Vector2(mx, track.get_center().y), 10.0, Color(UiTheme.GOLD, 0.2 * glow))
	UiTheme.diamond(self, Vector2(mx, track.get_center().y), 7.0, UiTheme.GOLD)
	UiTheme.diamond(self, Vector2(mx, track.get_center().y), 3.0, Color.WHITE)

	# Lua crescente e sol nas pontas.
	var moon := Vector2(12, track.get_center().y)
	draw_circle(moon, 8.0, Color(0.85, 0.88, 1.0))
	draw_circle(moon + Vector2(3.5, -2.5), 7.0, UiTheme.INK)
	var sun := Vector2(size.x - 12, track.get_center().y)
	for i in 8:
		var d := Vector2.from_angle(i * TAU / 8.0 + _time * 0.3)
		draw_line(sun + d * 9.0, sun + d * 12.5, Color(1.0, 0.75, 0.35), 2.0)
	draw_circle(sun, 7.0, Color(1.0, 0.78, 0.4))

	UiTheme.draw_text(self, time_text, Vector2(size.x / 2.0, 40), 22, UiTheme.TEXT, UiTheme.heading_font())
	if caption != "":
		UiTheme.draw_text(self, caption, Vector2(size.x / 2.0, 58), 11, UiTheme.TEXT_DIM)
