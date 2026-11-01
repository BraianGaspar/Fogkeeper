class_name UiTheme
extends RefCounted
## Identidade visual da interface: paleta, fontes e fábricas de controles.
## Tudo que é visual na UI nasce aqui para manter as telas consistentes.

const GOLD := Color(1.0, 0.8, 0.42)
const GOLD_DARK := Color(0.52, 0.36, 0.15)
const INK := Color(0.035, 0.04, 0.075)
const PANEL := Color(0.05, 0.06, 0.1, 0.97)
const PANEL_LIGHT := Color(0.1, 0.11, 0.17)
const TEXT := Color(0.93, 0.9, 0.84)
const TEXT_DIM := Color(0.93, 0.9, 0.84, 0.6)
const DANGER := Color(0.95, 0.38, 0.32)
const GOOD := Color(0.55, 0.9, 0.6)
const XP := Color(0.62, 0.36, 0.95)
const HP := Color(0.88, 0.25, 0.22)

static var _heading: Font
static var _silent := false


## Fonte dos títulos: Cinzel (SIL OFL, em assets/fonts/), que vai junto com o
## jogo. Letras que ela não tem (cirílico, chinês, japonês, coreano) caem nas
## fontes do sistema.
static func heading_font() -> Font:
	if _heading == null:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "serif"])
		fallback.font_weight = 700
		var file: FontFile = load("res://assets/fonts/Cinzel.ttf")
		var f := FontVariation.new()
		f.base_font = file
		f.variation_opentype = {"weight": 700}
		f.fallbacks = [fallback]
		_heading = f
	return _heading


static func label(text: String, size: int, color: Color = TEXT, heading: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", Settings.font(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5 if heading else 4)
	if heading:
		l.add_theme_font_override("font", heading_font())
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("shadow_offset_y", 3)
	return l


static func panel_style(margin: float = 28.0, accent: Color = GOLD) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PANEL
	s.border_color = Color(accent, 0.6)
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 18
	s.set_content_margin_all(margin)
	return s


static func flat(bg: Color, border: Color = Color.TRANSPARENT, border_width: int = 0, margin: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(margin)
	return s


## Botão padrão: borda dourada, cresce e toca som ao receber foco/hover.
## O mouse dá foco ao botão, então mouse e teclado têm o mesmo destaque.
static func button(text: String, on_press: Callable, sound: StringName = &"confirm") -> Button:
	var b := Button.new()
	b.text = text
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_override("font", heading_font())
	b.add_theme_font_size_override("font_size", Settings.font(19))
	b.add_theme_color_override("font_color", TEXT)
	for state in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD.lightened(0.3))
	var normal := flat(PANEL_LIGHT, Color(GOLD_DARK, 0.6), 1, 12.0)
	normal.content_margin_left = 18.0
	normal.content_margin_right = 18.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.16, 0.1)
	hover.border_color = GOLD
	hover.set_border_width_all(2)
	hover.shadow_color = Color(GOLD, 0.22)
	hover.shadow_size = 8
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.3, 0.22, 0.1)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("disabled", normal)
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.focus_entered.connect(func() -> void: _hover_fx(b, true))
	b.focus_exited.connect(func() -> void: _hover_fx(b, false))
	b.mouse_entered.connect(func() -> void: _on_mouse_enter(b))
	b.mouse_exited.connect(func() -> void: _on_mouse_exit(b))
	b.pressed.connect(func() -> void: Sfx.play(sound))
	b.pressed.connect(on_press)
	return b


## Botão pequeno de abas e seletores (sem crescer ao focar).
static func small_button(text: String, on_press: Callable, toggle: bool = false) -> Button:
	var b := button(text, on_press, &"hover")
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_font_size_override("font_size", Settings.font(16))
	b.toggle_mode = toggle
	if toggle:
		var on := flat(Color(0.26, 0.19, 0.08), GOLD, 2, 12.0)
		b.add_theme_stylebox_override("pressed", on)
		b.add_theme_color_override("font_pressed_color", GOLD)
	return b


static func _on_mouse_enter(b: Button) -> void:
	if b.disabled:
		return
	if b.focus_mode != Control.FOCUS_NONE:
		b.grab_focus()
	else:
		_hover_fx(b, true)


static func _on_mouse_exit(b: Button) -> void:
	if b.focus_mode == Control.FOCUS_NONE:
		_hover_fx(b, false)


static func _hover_fx(b: Button, on: bool) -> void:
	if on and not _silent:
		Sfx.play(&"hover")
	# Só os botões de menu (centralizados e altos) crescem; abas e listas não.
	if b.custom_minimum_size.y < 40.0 or b.alignment != HORIZONTAL_ALIGNMENT_CENTER:
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE * (1.035 if on else 1.0), 0.1)


## Dá foco sem tocar o som de hover (ao abrir uma tela).
static func focus_silently(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_visible_in_tree():
		return
	_silent = true
	c.grab_focus()
	_silent = false


## Linha decorativa com losango no centro.
static func divider(width: float) -> Control:
	var d := Control.new()
	d.custom_minimum_size = Vector2(width, 14)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func() -> void:
		var c := d.size / 2.0
		var w := d.size.x / 2.0
		d.draw_polyline_colors(PackedVector2Array([Vector2(c.x - w, c.y), Vector2(c.x - 10, c.y)]),
			PackedColorArray([Color(GOLD, 0.0), Color(GOLD, 0.8)]), 1.5)
		d.draw_polyline_colors(PackedVector2Array([Vector2(c.x + 10, c.y), Vector2(c.x + w, c.y)]),
			PackedColorArray([Color(GOLD, 0.8), Color(GOLD, 0.0)]), 1.5)
		diamond(d, c, 5.0, GOLD)
	)
	return d


static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


## Texto centralizado com contorno, para controles desenhados à mão.
static func draw_text(ci: CanvasItem, text: String, center: Vector2, size: int, col: Color, font: Font = null, width: float = -1.0) -> void:
	size = Settings.font(size)
	var f := font if font else ThemeDB.fallback_font
	var w := width if width > 0.0 else f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 4.0
	var pos := Vector2(center.x - w / 2.0, center.y + (f.get_ascent(size) - f.get_descent(size)) / 2.0)
	ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, size, 4, Color(0, 0, 0, 0.85))
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)
