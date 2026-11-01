extends SceneTree
## Gera a arte da página da Steam em docs/store/, desenhada com a própria arte
## do jogo (farol, feixe, criaturas, névoa). Precisa de janela (não headless):
##   godot --path . --script tools/store_art.gd
## Tamanhos: os pedidos pelo Steamworks (capsules, biblioteca e ícone).

const OUT := "res://docs/store/"
const ASSETS := [
	{"file": "header_capsule.png", "size": Vector2i(920, 430), "layout": "wide", "logo": true},
	{"file": "small_capsule.png", "size": Vector2i(462, 174), "layout": "wide", "logo": true},
	{"file": "main_capsule.png", "size": Vector2i(1232, 706), "layout": "wide", "logo": true},
	{"file": "vertical_capsule.png", "size": Vector2i(748, 896), "layout": "tall", "logo": true},
	{"file": "library_capsule.png", "size": Vector2i(600, 900), "layout": "tall", "logo": true},
	{"file": "library_hero.png", "size": Vector2i(3840, 1240), "layout": "hero", "logo": false},
	{"file": "library_logo.png", "size": Vector2i(1280, 720), "layout": "logo", "logo": true},
	{"file": "community_icon.png", "size": Vector2i(184, 184), "layout": "icon", "logo": false},
]

## Criaturas em volta do farol: arte, ângulo, distância (fração do tamanho), raio.
const CREATURES := [
	["wraith", 0.25, 0.62, 13.0], ["kitsune", 0.75, 0.75, 12.0], ["mapinguari", 1.35, 0.7, 20.0],
	["harpy", 1.75, 0.8, 12.0], ["draugr", 2.1, 0.68, 13.0], ["mummy", 2.6, 0.78, 13.0], ["siren", 3.2, 0.6, 12.0],
	["minotaur", 3.55, 0.8, 18.0], ["oni", 3.9, 0.74, 18.0], ["kelpie", 4.2, 0.62, 12.0], ["curupira", 4.5, 0.66, 10.0],
	["crab", 5.1, 0.72, 18.0], ["banshee", 5.4, 0.8, 13.0], ["jackal", 5.7, 0.62, 11.0],
]
const BEAMS := [0.25, 3.0] ## Ângulos dos feixes (o primeiro é o principal).

var _asset: Dictionary = {}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_render_all.call_deferred()


func _render_all() -> void:
	I18n.setup()
	for a: Dictionary in ASSETS:
		await _render(a)
	print("[store_art] imagens em ", ProjectSettings.globalize_path(OUT))
	quit()


func _render(a: Dictionary) -> void:
	_asset = a
	var vp := SubViewport.new()
	vp.size = a["size"]
	vp.transparent_bg = a["layout"] == "logo"
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var canvas := Node2D.new()
	canvas.draw.connect(_draw_asset.bind(canvas))
	vp.add_child(canvas)
	# Criaturas em nós próprios (a arte delas desenha em volta da origem).
	var layout: String = a["layout"]
	if layout in ["wide", "tall", "hero"]:
		var size := Vector2(a["size"])
		var c := _center(size, layout)
		var s := _scale(size, layout)
		for cr: Array in CREATURES:
			var ang: float = cr[1]
			var node := Node2D.new()
			node.position = c + Vector2.from_angle(ang) * float(cr[2]) * 240.0 * s
			var lit := 0.0
			for b: float in BEAMS:
				if absf(angle_difference(ang, b)) < 0.3:
					lit = 0.75
			var r: float = cr[3] * s * 1.25
			node.draw.connect(func() -> void: CreatureArt.draw(node, cr[0], r, 1.3 + ang, ang, (c - node.position).normalized(), lit, 1.0))
			vp.add_child(node)
	if a["logo"] and layout != "logo":
		var logo := Node2D.new()
		logo.draw.connect(_draw_logo.bind(logo, Vector2(a["size"]), layout))
		vp.add_child(logo)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(OUT + a["file"])
	print("[store_art] ", a["file"])
	vp.queue_free()


func _draw_asset(ci: Node2D) -> void:
	var size := Vector2(_asset["size"])
	var layout: String = _asset["layout"]
	if layout == "logo":
		_logo(ci, size * 0.5, size.x * 0.9, size.y * 0.3, true)
		return
	_sky(ci, size)
	_scene(ci, _center(size, layout), _scale(size, layout), size)


func _center(size: Vector2, layout: String) -> Vector2:
	match layout:
		"tall":
			return size * Vector2(0.5, 0.66)
		"hero":
			return size * Vector2(0.62, 0.55)
		"icon":
			return size * 0.5
	return size * Vector2(0.76, 0.55)


## Pixels por unidade de arte do jogo.
func _scale(size: Vector2, layout: String) -> float:
	match layout:
		"tall":
			return size.x / 420.0
		"icon":
			return size.y / 110.0
	return size.y / 420.0


func _draw_logo(ci: Node2D, size: Vector2, layout: String) -> void:
	if layout == "tall":
		_logo(ci, Vector2(size.x * 0.5, size.y * 0.16), size.x * 0.9, size.x * 0.16, true)
	else:
		_logo(ci, Vector2(size.x * 0.3, size.y * 0.45), size.x * 0.55, size.y * 0.24, size.y > 300.0)


## Céu noturno sobre o mar: degradê, estrelas, lua e manchas de névoa.
func _sky(ci: Node2D, size: Vector2) -> void:
	var top := Color(0.03, 0.05, 0.12)
	var bottom := Color(0.06, 0.1, 0.18)
	ci.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), PackedColorArray([top, top, bottom, bottom]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in int(size.x * size.y / 2500.0):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		ci.draw_rect(Rect2(p, Vector2.ONE * rng.randf_range(1.0, 2.5)), Color(0.85, 0.9, 1.0, rng.randf_range(0.1, 0.5)))
	for i in 18:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var r := rng.randf_range(0.1, 0.3) * size.y
		for j in 5:
			ci.draw_circle(p, r * (1.0 - j * 0.15), Color(0.55, 0.55, 0.75, 0.025))


## O farol na ilha, com os feixes e criaturas da névoa queimando na luz.
func _scene(ci: Node2D, c: Vector2, s: float, size: Vector2) -> void:
	# Ondas.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in int(size.x * size.y / 9000.0):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		if p.distance_to(c) > 60.0 * s:
			ci.draw_arc(p, rng.randf_range(5.0, 12.0) * s * 0.5, -PI * 0.85, -PI * 0.15, 6, Color(0.45, 0.58, 0.8, 0.18), 1.5)
	# Feixes de luz.
	var reach := maxf(size.x, size.y) * 1.2
	for i in BEAMS.size():
		var a: float = BEAMS[i]
		var main := i == 0
		for layer in 3:
			var half := (0.2 if main else 0.14) * (1.0 - layer * 0.3)
			var pts := PackedVector2Array([c])
			var cols := PackedColorArray([Color(1.0, 0.9, 0.6, (0.4 if main else 0.25) * (1.0 - layer * 0.2))])
			for k in 13:
				pts.append(c + Vector2.from_angle(a - half + 2.0 * half * k / 12.0) * reach)
				cols.append(Color(1.0, 0.85, 0.5, 0.0))
			ci.draw_polygon(pts, cols)
	# Ilha.
	for k in 4:
		ci.draw_circle(c, (100.0 - k * 6.0) * s, Color(0.4, 0.55, 0.8, 0.04))
	ci.draw_circle(c, 62.0 * s, Color(0.55, 0.48, 0.36))
	ci.draw_circle(c, 52.0 * s, Color(0.2, 0.26, 0.18))
	for k in 6:
		ci.draw_circle(c + Vector2.from_angle(k * 1.1 + 0.4) * 38.0 * s, 8.0 * s, Color(0.12, 0.22, 0.13))
	for k in 5:
		ci.draw_circle(c, (40.0 + k * 18.0) * s, Color(1.0, 0.75, 0.4, 0.04))
	LighthouseArt.draw(ci, "classic", c, s * 0.9, 0.5, true)
	# Brilho da lanterna.
	for k in 6:
		ci.draw_circle(c, (14.0 + k * 9.0) * s, Color(1.0, 0.9, 0.6, 0.06))


## "FOGKEEPER" em dourado, com brilho de chama; `h` é a altura das letras.
func _logo(ci: Node2D, center: Vector2, max_w: float, h: float, tagline: bool) -> void:
	var font := UiTheme.heading_font()
	var text := "FOGKEEPER"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(h)).x
	if w > max_w:
		h *= max_w / w
		w = max_w
	var size := int(h)
	var pos := center + Vector2(-w / 2.0, h * 0.35)
	for k in 6:
		ci.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, int(h * 0.06) + k * int(h * 0.04), Color(1.0, 0.55, 0.15, 0.06))
	ci.draw_string_outline(font, pos + Vector2(0, h * 0.05), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, int(h * 0.12), Color(0, 0, 0, 0.7))
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 0.8, 0.42))
	if tagline:
		var sub := "HOLD THE LIGHT UNTIL DAWN"
		var ss := int(h * 0.22)
		var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
		var sp := center + Vector2(-sw / 2.0, h * 0.35 + h * 0.5)
		ci.draw_string_outline(font, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, int(h * 0.05), Color(0, 0, 0, 0.8))
		ci.draw_string(font, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(0.93, 0.9, 0.84))
