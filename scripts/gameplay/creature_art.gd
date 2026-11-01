class_name CreatureArt
extends RefCounted
## Desenho das criaturas comuns de cada mapa, em código.
## Coordenadas locais girando com `face`: +x aponta para o farol.
## `lit` (0..1) puxa as cores para o laranja da queima; `alpha` some na morte.

const BURN := Color(1.0, 0.55, 0.2)


## `extra` depende da criatura: abertura do espelho, crescimento da mariposa,
## brasas carregadas pela ladra ou vida restante da névoa (ver Enemy._art_extra).
static func draw(ci: CanvasItem, art: String, r: float, t: float, phase: float, face: Vector2, lit: float, alpha: float, extra: float = 0.0) -> void:
	ci.draw_set_transform(Vector2.ZERO, face.angle())
	match art:
		# Especiais de cada mapa.
		"ghost_gull":
			bird(ci, r, t, phase, lit, alpha, Color(0.82, 0.88, 0.96, 0.8), Color(0.6, 0.66, 0.78, 0.75), Color(0.95, 0.8, 0.35), Color(0.5, 1.0, 1.0), extra)
		"raven":
			bird(ci, r, t, phase, lit, alpha, Color(0.1, 0.1, 0.14), Color(0.17, 0.17, 0.24), Color(0.3, 0.3, 0.33), Color(1.0, 0.85, 0.3), extra)
		"saci":
			_saci(ci, r, t, phase, lit, alpha, extra)
		"oyster":
			shell(ci, r, t, lit, alpha, Color(0.48, 0.44, 0.5), Color(0.9, 0.75, 0.8), Color(0.3, 0.27, 0.32), extra)
		"ice_shell":
			shell(ci, r, t, lit, alpha, Color(0.62, 0.82, 0.95), Color(0.35, 0.45, 0.6), Color(0.88, 0.97, 1.0), extra)
		"jabuti":
			_jabuti(ci, r, t, phase, lit, alpha, extra)
		"jellyfish":
			_jellyfish(ci, r, t, phase, lit, alpha, extra)
		"frost_moth":
			moth(ci, r, t, phase, lit, alpha, extra, Color(0.82, 0.9, 1.0, 0.85), Color(0.35, 0.55, 0.85), Color(0.4, 0.95, 1.0))
		"mula":
			_mula(ci, r, t, phase, lit, alpha, extra)
		"fog_bay":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.16, 0.12, 0.24), Color(0.85, 0.4, 1.0))
		"fog_fjord":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.2, 0.26, 0.34), Color(0.5, 0.95, 1.0))
		"fog_amazon":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.1, 0.18, 0.12), Color(1.0, 0.85, 0.3))
		# Rio Encantado.
		"corpo_seco":
			_corpo_seco(ci, r, t, phase, lit, alpha)
		"curupira":
			_curupira(ci, r, t, phase, lit, alpha)
		"mapinguari":
			_mapinguari(ci, r, t, phase, lit, alpha)
		"boto":
			_boto(ci, r, t, phase, lit, alpha)
		"wisp":
			wisp(ci, r, t, phase, lit, alpha, Color(0.35, 0.95, 0.85), Color(0.9, 1.0, 0.95))
		# Mar dos Yōkai.
		"funayurei":
			_funayurei(ci, r, t, phase, lit, alpha)
		"kitsune":
			_kitsune(ci, r, t, phase, lit, alpha)
		"kyubi":
			kyubi(ci, r, t, phase, lit, alpha)
		"oni":
			_oni(ci, r, t, phase, lit, alpha)
		"tengu":
			bird(ci, r, t, phase, lit, alpha, Color(0.12, 0.1, 0.14), Color(0.08, 0.07, 0.1), Color(0.85, 0.2, 0.15), Color(1.0, 0.85, 0.3), extra, 0.7)
		"kappa":
			_kappa(ci, r, t, phase, lit, alpha, extra)
		"chochin":
			_chochin(ci, r, t, phase, lit, alpha, extra)
		"fog_japan":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.15, 0.12, 0.28), Color(1.0, 0.3, 0.3))
		"hitodama":
			wisp(ci, r, t, phase, lit, alpha, Color(0.55, 0.7, 1.0), Color(0.92, 0.96, 1.0))
		"wave":
			_wave(ci, r, t, phase, lit, alpha)
		# Farol de Alexandria.
		"mummy":
			_mummy(ci, r, t, phase, lit, alpha)
		"jackal":
			wolf(ci, r, t, phase, lit, alpha, Color(0.1, 0.09, 0.09), Color(0.75, 0.6, 0.2), Color(1.0, 0.8, 0.2))
		"sobek":
			_sobek(ci, r, t, phase, lit, alpha)
		"ibis":
			bird(ci, r, t, phase, lit, alpha, Color(0.95, 0.94, 0.9), Color(0.15, 0.15, 0.18), Color(0.2, 0.2, 0.22), Color(1.0, 0.7, 0.2), extra, 1.0)
		"scarab":
			shell(ci, r, t, lit, alpha, Color(0.85, 0.65, 0.15), Color(0.2, 0.35, 0.6), Color(0.55, 0.35, 0.08), extra)
		"ba":
			moth(ci, r, t, phase, lit, alpha, extra, Color(0.95, 0.78, 0.35, 0.9), Color(0.2, 0.4, 0.75), Color(1.0, 0.85, 0.4))
		"fog_egypt":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.45, 0.36, 0.22), Color(1.0, 0.75, 0.3))
		"cobra":
			_cobra(ci, r, t, phase, lit, alpha)
		"sandstone":
			boulder(ci, r, t, phase, lit, alpha, Color(0.75, 0.6, 0.38), Color(0.95, 0.85, 0.6), Color(0.45, 0.33, 0.2))
		# Mar Egeu.
		"shade":
			_shade(ci, r, t, phase, lit, alpha)
		"hellhound":
			wolf(ci, r, t, phase, lit, alpha, Color(0.16, 0.12, 0.12), Color(0.35, 0.1, 0.06), Color(1.0, 0.4, 0.15))
		"minotaur":
			_minotaur(ci, r, t, phase, lit, alpha)
		"harpy":
			_harpy(ci, r, t, phase, lit, alpha, extra)
		"bronze_shield":
			_bronze_shield(ci, r, t, phase, lit, alpha, extra)
		"lampad":
			_lampad(ci, r, t, phase, lit, alpha, extra)
		"fog_greece":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.12, 0.14, 0.2), Color(0.6, 1.0, 0.75))
		"gorgon_snake":
			_gorgon_snake(ci, r, t, phase, lit, alpha)
		"marble":
			boulder(ci, r, t, phase, lit, alpha, Color(0.88, 0.86, 0.82), Color(1.0, 1.0, 0.98), Color(0.55, 0.55, 0.6))
		# Costa Celta.
		"banshee":
			_banshee(ci, r, t, phase, lit, alpha)
		"kelpie":
			_kelpie(ci, r, t, phase, lit, alpha)
		"fomorian":
			_fomorian(ci, r, t, phase, lit, alpha)
		"pooka":
			_pooka(ci, r, t, phase, lit, alpha, extra)
		"selkie":
			_selkie(ci, r, t, phase, lit, alpha, extra)
		"fairy":
			moth(ci, r, t, phase, lit, alpha, extra, Color(0.75, 1.0, 0.8, 0.8), Color(0.95, 0.8, 0.3), Color(0.6, 1.0, 0.7))
		"fog_celtic":
			fogbank(ci, r, t, phase, lit, alpha, extra, Color(0.12, 0.2, 0.18), Color(0.55, 1.0, 0.85))
		"peist":
			_peist(ci, r, t, phase, lit, alpha)
		"ogham":
			_ogham(ci, r, t, phase, lit, alpha)
		"wraith":
			_wraith(ci, r, t, phase, lit, alpha)
		"siren":
			_siren(ci, r, t, phase, lit, alpha)
		"crab":
			_crab(ci, r, t, phase, lit, alpha)
		"draugr":
			_draugr(ci, r, t, phase, lit, alpha)
		"ice_wolf":
			wolf(ci, r, t, phase, lit, alpha, Color(0.78, 0.86, 0.95), Color(0.45, 0.55, 0.68), Color(0.5, 0.95, 1.0))
		"troll":
			_troll(ci, r, t, phase, lit, alpha)
		"tentacle":
			_tentacle(ci, r, t, phase, lit, alpha)
		"boulder":
			boulder(ci, r, t, phase, lit, alpha, Color(0.62, 0.8, 0.92), Color(0.9, 0.97, 1.0), Color(0.35, 0.5, 0.62))
		_:
			ci.draw_circle(Vector2.ZERO, r, Color(0.4, 0.3, 0.5, alpha))
	ci.draw_set_transform(Vector2.ZERO)


static func c(col: Color, lit: float, alpha: float) -> Color:
	var out := col.lerp(BURN, lit * 0.6)
	out.a = col.a * alpha
	return out


static func eyes(ci: CanvasItem, at: Vector2, gap: float, size: float, col: Color, lit: float, alpha: float) -> void:
	var e := Color(1.0, 1.0, 0.8, alpha) if lit > 0.0 else Color(col, alpha)
	for s: float in [-1.0, 1.0]:
		ci.draw_circle(at + Vector2(0, gap * s), size * 1.8, Color(e, 0.25 * alpha))
		ci.draw_circle(at + Vector2(0, gap * s), size, e)


## Como tail(), mas saindo de `origin` na direção `angle` (sem mexer na
## transformação do desenho, que já gira com a criatura).
static func tail_at(ci: CanvasItem, origin: Vector2, angle: float, length: float, width: float, t: float, phase: float, wave: float, col: Color, steps: int = 8) -> Vector2:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var end := origin
	for i in steps + 1:
		var k := float(i) / steps
		var p := Vector2(length * k, sin(t * 6.0 + phase + k * 4.0) * wave * k)
		var w := width * (1.0 - k * 0.9)
		top.append(origin + (p + Vector2(0, -w)).rotated(angle))
		bottom.append(origin + (p + Vector2(0, w)).rotated(angle))
		end = origin + p.rotated(angle)
	bottom.reverse()
	top.append_array(bottom)
	ci.draw_colored_polygon(top, col)
	return end


## Corpo cônico ao longo de uma espinha que ondula (caudas, tentáculos).
static func tail(ci: CanvasItem, from_x: float, length: float, width: float, t: float, phase: float, wave: float, col: Color, steps: int = 10) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var spine := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var x := from_x - length * k
		var y := sin(t * 6.0 + phase + k * 4.0) * wave * k
		var w := width * (1.0 - k * 0.9)
		spine.append(Vector2(x, y))
		top.append(Vector2(x, y - w))
		bottom.append(Vector2(x, y + w))
	bottom.reverse()
	top.append_array(bottom)
	ci.draw_colored_polygon(top, col)
	return spine


static func _wraith(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var body := c(Color(0.5, 0.45, 0.72, 0.85), lit, alpha)
	tail(ci, -r * 0.2, r * 2.6, r * 0.75, t, phase, r * 0.6, Color(body, body.a * 0.6))
	ci.draw_circle(Vector2.ZERO, r * 1.35, Color(body, 0.15 * alpha))
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, c(Color(0.8, 0.75, 1.0, 0.7), lit, alpha), 1.5)
	# Boca escura e olhos frios.
	ci.draw_arc(Vector2(r * 0.25, 0), r * 0.35, -0.9, 0.9, 8, Color(0.05, 0.03, 0.1, 0.7 * alpha), 2.0)
	eyes(ci, Vector2(r * 0.35, 0), r * 0.32, maxf(1.5, r * 0.14), Color(0.75, 0.95, 1.0), lit, alpha)


static func _siren(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var scales := c(Color(0.12, 0.45, 0.5), lit, alpha)
	var skin := c(Color(0.55, 0.72, 0.68), lit, alpha)
	var hair := c(Color(0.08, 0.2, 0.24), lit, alpha)
	var spine := tail(ci, -r * 0.2, r * 2.3, r * 0.55, t * 1.6, phase, r * 0.7, scales)
	var end := spine[spine.size() - 1]
	var fin := c(Color(0.25, 0.7, 0.72), lit, alpha)
	ci.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.7, -r * 0.8), end + Vector2(-r * 0.35, 0)]), fin)
	ci.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.35, 0), end + Vector2(-r * 0.7, r * 0.8)]), fin)
	ci.draw_circle(Vector2.ZERO, r * 0.62, skin)
	# Cabelo esvoaçando para trás.
	tail(ci, r * 0.45, r * 1.5, r * 0.5, t * 2.0, phase + 1.0, r * 0.4, hair, 6)
	ci.draw_circle(Vector2(r * 0.55, 0), r * 0.42, skin)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(0, r * 0.45 * s), Vector2(r * 0.9, r * 0.75 * s), skin, maxf(1.5, r * 0.22))
	eyes(ci, Vector2(r * 0.75, 0), r * 0.16, maxf(1.2, r * 0.1), Color(0.6, 1.0, 0.9), lit, alpha)


static func _crab(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var shell := c(Color(0.55, 0.2, 0.14), lit, alpha)
	var dark := c(Color(0.32, 0.1, 0.08), lit, alpha)
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var x := -r * 0.5 + i * r * 0.45
			var swing := sin(t * 9.0 + phase + i * 1.3) * r * 0.25
			var knee := Vector2(x + swing, s * r * 1.15)
			ci.draw_line(Vector2(x, s * r * 0.5), knee, dark, maxf(1.5, r * 0.14))
			ci.draw_line(knee, knee + Vector2(-r * 0.3, s * r * 0.45), dark, maxf(1.2, r * 0.1))
		# Pinças à frente.
		var arm := Vector2(r * 1.05, s * r * 0.65)
		ci.draw_line(Vector2(r * 0.5, s * r * 0.4), arm, dark, maxf(2.0, r * 0.18))
		var open := 0.3 + 0.25 * sin(t * 4.0 + phase + s)
		ci.draw_circle(arm, r * 0.38, shell)
		ci.draw_colored_polygon(PackedVector2Array([arm, arm + Vector2(r * 0.75, s * r * (0.05 + open)), arm + Vector2(r * 0.4, s * r * 0.1)]), shell)
		ci.draw_colored_polygon(PackedVector2Array([arm, arm + Vector2(r * 0.7, -s * r * open * 0.5), arm + Vector2(r * 0.35, -s * r * 0.05)]), shell)
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		pts.append(Vector2(cos(a) * r * 0.85, sin(a) * r * 1.05))
	ci.draw_colored_polygon(pts, shell)
	ci.draw_circle(Vector2(-r * 0.15, 0), r * 0.5, c(Color(0.7, 0.3, 0.2), lit, alpha))
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(r * 0.6, s * r * 0.25), Vector2(r * 0.95, s * r * 0.3), dark, 1.5)
	eyes(ci, Vector2(r * 0.98, 0), r * 0.3, maxf(1.5, r * 0.11), Color(1.0, 0.9, 0.5), lit, alpha)


static func _draugr(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var cloak := c(Color(0.16, 0.2, 0.26), lit, alpha)
	var armor := c(Color(0.38, 0.42, 0.46), lit, alpha)
	var skin := c(Color(0.45, 0.55, 0.58), lit, alpha)
	var step := sin(t * 5.0 + phase) * r * 0.15
	# Capa rasgada atrás.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 0.9), Vector2(-r * 1.3, -r * 0.7 + step), Vector2(-r * 1.1, 0), Vector2(-r * 1.4, r * 0.6 - step), Vector2(0, r * 0.9)]), cloak)
	var shoulders := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		shoulders.append(Vector2(cos(a) * r * 0.55, sin(a) * r * 0.95))
	ci.draw_colored_polygon(shoulders, armor)
	# Braço com machado.
	ci.draw_line(Vector2(0, r * 0.7), Vector2(r * 0.8 + step, r * 0.95), skin, maxf(1.5, r * 0.2))
	var axe := Vector2(r * 0.8 + step, r * 0.95)
	ci.draw_line(axe + Vector2(-r * 0.6, 0), axe + Vector2(r * 0.5, 0), c(Color(0.35, 0.25, 0.15), lit, alpha), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([axe + Vector2(r * 0.3, 0), axe + Vector2(r * 0.6, r * 0.45), axe + Vector2(r * 0.65, -r * 0.1)]), c(Color(0.6, 0.65, 0.7), lit, alpha))
	ci.draw_line(Vector2(0, -r * 0.7), Vector2(r * 0.7 - step, -r * 0.85), skin, maxf(1.5, r * 0.2))
	# Elmo com chifres curtos.
	ci.draw_circle(Vector2(r * 0.1, 0), r * 0.48, c(Color(0.5, 0.52, 0.55), lit, alpha))
	ci.draw_line(Vector2(r * 0.1, 0), Vector2(r * 0.58, 0), c(Color(0.3, 0.32, 0.35), lit, alpha), 2.0)
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.05, s * r * 0.35), Vector2(-r * 0.2, s * r * 0.9), Vector2(r * 0.25, s * r * 0.42)]), c(Color(0.85, 0.82, 0.7), lit, alpha))
	eyes(ci, Vector2(r * 0.45, 0), r * 0.18, maxf(1.3, r * 0.1), Color(0.4, 0.85, 1.0), lit, alpha)


## Lobo visto de cima; usado pelo lobo de gelo e por Fenrir (cores diferentes).
static func wolf(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, fur: Color, back: Color, eye: Color) -> void:
	var f := c(fur, lit, alpha)
	var b := c(back, lit, alpha)
	var gait := t * 11.0 + phase
	for i in 4:
		var x := r * (0.55 if i < 2 else -0.6)
		var s := -1.0 if i % 2 == 0 else 1.0
		var swing := sin(gait + i * PI * 0.5) * r * 0.35
		ci.draw_line(Vector2(x, s * r * 0.35), Vector2(x + swing, s * r * 0.75), b, maxf(1.5, r * 0.2))
	tail(ci, -r * 1.0, r * 1.2, r * 0.28, t * 0.8, phase, r * 0.35, f, 6)
	var body := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		body.append(Vector2(cos(a) * r * 1.2, sin(a) * r * 0.55))
	ci.draw_colored_polygon(body, f)
	ci.draw_line(Vector2(-r * 0.9, 0), Vector2(r * 0.7, 0), b, maxf(2.0, r * 0.3))
	var head := Vector2(r * 1.15, 0)
	ci.draw_circle(head, r * 0.45, f)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.2, -r * 0.25), head + Vector2(r * 0.8, 0), head + Vector2(r * 0.2, r * 0.25)]), f)
	ci.draw_circle(head + Vector2(r * 0.78, 0), r * 0.08, Color(0.05, 0.05, 0.08, alpha))
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-r * 0.25, s * r * 0.2), head + Vector2(-r * 0.45, s * r * 0.55), head + Vector2(0, s * r * 0.38)]), b)
	eyes(ci, head + Vector2(r * 0.25, 0), r * 0.18, maxf(1.2, r * 0.09), eye, lit, alpha)


static func _troll(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.38, 0.48, 0.52), lit, alpha)
	var dark := c(Color(0.22, 0.28, 0.32), lit, alpha)
	var sway := sin(t * 2.5 + phase) * 0.15
	# Clava arrastada de lado.
	var club := Vector2(-r * 0.2, r * 1.25)
	ci.draw_line(Vector2(r * 0.3, r * 0.75), club, c(Color(0.35, 0.24, 0.15), lit, alpha), maxf(2.0, r * 0.18))
	ci.draw_circle(club, r * 0.38, c(Color(0.4, 0.28, 0.18), lit, alpha))
	ci.draw_circle(Vector2(0, 0), r, skin)
	ci.draw_circle(Vector2(-r * 0.25, 0), r * 0.75, dark)
	# Manchas de gelo e musgo nas costas.
	for i in 4:
		var a := phase + i * 1.6
		ci.draw_circle(Vector2(-r * 0.3 + cos(a) * r * 0.4, sin(a) * r * 0.5), r * 0.16, c(Color(0.75, 0.88, 0.95, 0.8), lit, alpha))
	ci.draw_line(Vector2(0, -r * 0.8), Vector2(r * 0.8, -r * (0.7 + sway)), skin, maxf(2.0, r * 0.28))
	var head := Vector2(r * 0.7, 0)
	ci.draw_circle(head, r * 0.42, skin)
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.25, s * r * 0.15), head + Vector2(r * 0.65, s * r * 0.3), head + Vector2(r * 0.3, s * r * 0.3)]), c(Color(0.92, 0.9, 0.8), lit, alpha))
	eyes(ci, head + Vector2(r * 0.2, 0), r * 0.17, maxf(1.3, r * 0.08), Color(1.0, 0.75, 0.3), lit, alpha)


static func _tentacle(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var col := c(Color(0.5, 0.14, 0.25), lit, alpha)
	var spine := tail(ci, r * 1.0, r * 3.2, r * 0.8, t * 1.4, phase, r * 0.9, col, 12)
	for i in range(2, spine.size(), 2):
		ci.draw_circle(spine[i], maxf(1.0, r * 0.18 * (1.0 - float(i) / spine.size())), c(Color(0.85, 0.55, 0.6), lit, alpha))
	ci.draw_circle(Vector2(r * 0.9, 0), r * 0.3, col)


## Pedra que rola até o farol (gelo do Jötunn, arenito da Esfinge).
static func boulder(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, rock: Color, light: Color, crack: Color) -> void:
	ci.draw_set_transform(Vector2.ZERO, t * 3.0 + phase)
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * i / 9.0
		pts.append(Vector2.from_angle(a) * r * (0.8 + 0.25 * sin(a * 3.0 + phase)))
	ci.draw_circle(Vector2.ZERO, r * 1.4, Color(light, 0.12 * alpha))
	ci.draw_colored_polygon(pts, c(rock, lit, alpha))
	ci.draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.3, c(light, lit, alpha))
	ci.draw_line(Vector2(-r * 0.4, r * 0.1), Vector2(r * 0.3, r * 0.35), c(crack, lit, alpha), 1.5)


# --- Criaturas especiais ----------------------------------------------------------

## Ave vista de cima (gaivota-fantasma, corvo). `carried` > 0 mostra a brasa no bico.
static func bird(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, body: Color, wing: Color, beak: Color, eye: Color, carried: float, beak_len: float = 0.46) -> void:
	var flap := sin(t * 11.0 + phase)
	var b := c(body, lit, alpha)
	var w := c(wing, lit, alpha)
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.3, s * r * 0.22), Vector2(-r * 0.1, s * r * (1.5 + 0.5 * flap)),
			Vector2(-r * 0.85, s * r * (1.25 + 0.4 * flap)), Vector2(-r * 0.45, s * r * 0.18)]), w)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.55, -r * 0.22), Vector2(-r * 1.25, -r * 0.42), Vector2(-r * 1.15, 0),
		Vector2(-r * 1.25, r * 0.42), Vector2(-r * 0.55, r * 0.22)]), w)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * r * 0.85, sin(a) * r * 0.38))
	ci.draw_colored_polygon(pts, b)
	ci.draw_circle(Vector2(r * 0.68, 0), r * 0.34, b)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.92, -r * 0.1), Vector2(r * (0.92 + beak_len), 0), Vector2(r * 0.92, r * 0.1)]), c(beak, lit, alpha))
	eyes(ci, Vector2(r * 0.78, 0), r * 0.17, maxf(1.2, r * 0.08), eye, lit, alpha)
	if carried > 0.0:
		_ember_glow(ci, Vector2(r * (0.94 + beak_len), 0), r * 0.3, t, alpha)


## Brasa roubada, presa no bico ou na mão.
static func _ember_glow(ci: CanvasItem, at: Vector2, s: float, t: float, alpha: float) -> void:
	var pulse := 0.8 + 0.2 * sin(t * 9.0)
	ci.draw_circle(at, s * 2.2, Color(1.0, 0.5, 0.15, 0.2 * alpha * pulse))
	ci.draw_circle(at, s, Color(1.0, 0.8, 0.45, alpha))


## Saci: menino de uma perna só, gorro vermelho e cachimbo, dentro do redemoinho.
static func _saci(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, carried: float) -> void:
	for i in 4:
		var a0 := -t * 9.0 + i * 1.6 + phase
		ci.draw_arc(Vector2.ZERO, r * (1.0 + i * 0.22), a0, a0 + 2.2, 10, Color(0.8, 0.7, 0.55, 0.4 * alpha * (1.0 - i * 0.2)), 2.0)
	var skin := c(Color(0.36, 0.22, 0.15), lit, alpha)
	ci.draw_line(Vector2(-r * 0.1, r * 0.15), Vector2(-r * 0.55, r * 0.5), skin, maxf(2.0, r * 0.2))
	ci.draw_circle(Vector2(-r * 0.05, 0), r * 0.48, c(Color(0.55, 0.3, 0.2), lit, alpha))
	# Braço com o cachimbo e a fumaça indo para trás.
	ci.draw_line(Vector2(0, -r * 0.35), Vector2(r * 0.6, -r * 0.45), skin, maxf(1.5, r * 0.15))
	ci.draw_line(Vector2(r * 0.6, -r * 0.45), Vector2(r * 0.85, -r * 0.6), c(Color(0.4, 0.26, 0.15), lit, alpha), 2.0)
	for i in 3:
		var k := fmod(t * 0.8 + i / 3.0 + phase, 1.0)
		ci.draw_circle(Vector2(r * (0.85 - k * 1.8), -r * (0.6 + k * 0.5)), r * (0.12 + k * 0.2), Color(0.9, 0.9, 0.92, 0.35 * (1.0 - k) * alpha))
	ci.draw_circle(Vector2(r * 0.3, 0), r * 0.36, skin)
	var sway := sin(t * 6.0 + phase) * r * 0.15
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.48, -r * 0.33), Vector2(r * 0.48, r * 0.33), Vector2(-r * 0.75, sway)]), c(Color(0.85, 0.12, 0.1), lit, alpha))
	ci.draw_circle(Vector2(-r * 0.75, sway), r * 0.1, c(Color(0.95, 0.9, 0.85), lit, alpha))
	eyes(ci, Vector2(r * 0.55, 0), r * 0.13, maxf(1.2, r * 0.08), Color(1.0, 1.0, 0.9), lit, alpha)
	if carried > 0.0:
		_ember_glow(ci, Vector2(r * 0.5, r * 0.55), r * 0.28, t, alpha)


## Concha que abre e fecha (ostra, escudo de gelo). Fechada, brilha como espelho.
static func shell(ci: CanvasItem, r: float, t: float, lit: float, alpha: float, outer: Color, inner: Color, ridge: Color, open: float) -> void:
	var gap := open * r * 0.5
	if open > 0.05:
		ci.draw_circle(Vector2(r * 0.05, 0), r * 0.6, c(inner, lit, alpha))
		ci.draw_circle(Vector2(r * 0.35, 0), r * 0.22 * open, Color(1.0, 0.9, 0.4, alpha))
		ci.draw_circle(Vector2(r * 0.4, 0), r * 0.09 * open, Color(0.1, 0.05, 0.05, alpha))
	for s: float in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 13:
			var a := PI * i / 12.0
			pts.append(Vector2(cos(a) * r * 1.05, s * (sin(a) * r * 0.85 + gap)))
		ci.draw_colored_polygon(pts, c(outer, lit, alpha))
		for i in 5:
			var a := PI * (i + 1) / 6.0
			ci.draw_line(Vector2(0, s * gap), Vector2(cos(a) * r * 0.95, s * (sin(a) * r * 0.78 + gap)), c(ridge, lit, alpha * 0.8), 1.5)
	if open < 0.6:
		var k := (1.0 - open / 0.6) * (0.6 + 0.4 * sin(t * 3.0))
		ci.draw_line(Vector2(-r * 0.55, -r * 0.55), Vector2(r * 0.35, -r * 0.25), Color(1, 1, 1, 0.6 * k * alpha), 3.0)
		ci.draw_arc(Vector2.ZERO, r * 1.15, 0.0, TAU, 28, Color(1, 1, 0.9, 0.35 * k * alpha), 2.0)


## Jabuti encantado: casco dourado que reflete a luz; aberto, põe a cabeça para fora.
static func _jabuti(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, open: float) -> void:
	var skin := c(Color(0.45, 0.4, 0.25), lit, alpha)
	for i in 4:
		var x := r * (0.55 if i < 2 else -0.55)
		var s := -1.0 if i % 2 == 0 else 1.0
		ci.draw_circle(Vector2(x, s * r * 0.75) * (0.7 + 0.3 * open), r * 0.22, skin)
	ci.draw_circle(Vector2(r * (0.6 + 0.45 * open), 0), r * 0.28, skin)
	if open > 0.3:
		eyes(ci, Vector2(r * (0.75 + 0.45 * open), 0), r * 0.12, maxf(1.2, r * 0.06), Color(1.0, 0.9, 0.4), lit, alpha)
	var dome := PackedVector2Array()
	for i in 6:
		dome.append(Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * r * 0.95)
	ci.draw_colored_polygon(dome, c(Color(0.5, 0.35, 0.15), lit, alpha))
	for i in 6:
		var p := Vector2.from_angle(TAU * i / 6.0) * r * 0.55
		var hex := PackedVector2Array()
		for j in 6:
			hex.append(p + Vector2.from_angle(TAU * j / 6.0 + PI / 6.0) * r * 0.26)
		ci.draw_colored_polygon(hex, c(Color(0.68, 0.5, 0.2), lit, alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.3, c(Color(0.75, 0.58, 0.25), lit, alpha))
	if open < 0.6:
		var k := (1.0 - open / 0.6) * (0.6 + 0.4 * sin(t * 3.0 + phase))
		ci.draw_arc(Vector2.ZERO, r * 1.15, 0.0, TAU, 28, Color(1.0, 0.85, 0.4, 0.45 * k * alpha), 2.5)
		ci.draw_line(Vector2(-r * 0.5, -r * 0.5), Vector2(r * 0.3, -r * 0.2), Color(1, 1, 0.9, 0.6 * k * alpha), 2.5)


## Água-viva: brilha e cresce conforme se alimenta de luz (`g` 0..1).
static func _jellyfish(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, g: float) -> void:
	ci.draw_circle(Vector2.ZERO, r * (1.4 + 0.6 * g), Color(0.85, 0.55, 1.0, (0.06 + 0.16 * g) * alpha))
	var tentacle := c(Color(0.85, 0.65, 1.0, 0.6), lit, alpha)
	for i in 5:
		var y := (i - 2) * r * 0.24
		var pts := PackedVector2Array()
		for k in 7:
			var f := k / 6.0
			pts.append(Vector2(-r * 0.2 - f * r * (1.5 + 0.4 * (i % 2)), y + sin(t * 6.0 + phase + i + f * 4.0) * r * 0.3 * f))
		ci.draw_polyline(pts, tentacle, maxf(1.0, r * 0.1))
	ci.draw_circle(Vector2(r * 0.15, 0), r * 0.85, c(Color(0.7, 0.5, 0.95, 0.75), lit, alpha))
	ci.draw_circle(Vector2(r * 0.25, 0), r * 0.5, Color(1.0, 0.85, 1.0, (0.3 + 0.55 * g) * alpha))
	ci.draw_arc(Vector2(r * 0.15, 0), r * 0.85, 0.0, TAU, 24, Color(1.0, 0.9, 1.0, 0.5 * alpha), 1.5)


## Mariposa (de geada, Alma Ba): asas que se abrem mais conforme cresce.
static func moth(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, g: float, wing_col: Color, spot_col: Color, eye_col: Color) -> void:
	var flap := 0.75 + 0.25 * sin(t * 14.0 + phase)
	ci.draw_circle(Vector2.ZERO, r * (1.5 + 0.6 * g), Color(eye_col, (0.05 + 0.15 * g) * alpha))
	var wing := c(wing_col, lit, alpha)
	var spot := c(spot_col, lit, alpha)
	for s: float in [-1.0, 1.0]:
		var front := PackedVector2Array([Vector2(r * 0.2, s * r * 0.1), Vector2(r * 0.6, s * r * 1.3 * flap), Vector2(-r * 0.3, s * r * 1.4 * flap), Vector2(-r * 0.1, s * r * 0.1)])
		var back := PackedVector2Array([Vector2(-r * 0.1, s * r * 0.1), Vector2(-r * 0.4, s * r * 1.0 * flap), Vector2(-r * 0.9, s * r * 0.6 * flap)])
		ci.draw_colored_polygon(front, wing)
		ci.draw_colored_polygon(back, wing)
		ci.draw_circle(Vector2(r * 0.1, s * r * 0.8 * flap), r * 0.2, spot)
		ci.draw_line(Vector2(r * 0.45, s * r * 0.08), Vector2(r * 0.95, s * r * 0.4), c(Color(0.7, 0.8, 0.9), lit, alpha), 1.2)
	ci.draw_line(Vector2(-r * 0.6, 0), Vector2(r * 0.45, 0), c(Color(0.55, 0.6, 0.7), lit, alpha), maxf(2.0, r * 0.25))
	eyes(ci, Vector2(r * 0.45, 0), r * 0.1, maxf(1.0, r * 0.06), eye_col, lit, alpha)


## Mula sem cabeça: no lugar da cabeça, uma chama que cresce com a luz.
static func _mula(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, g: float) -> void:
	var hide := c(Color(0.32, 0.2, 0.12), lit, alpha)
	var dark := c(Color(0.18, 0.11, 0.07), lit, alpha)
	var gait := t * 12.0 + phase
	for i in 4:
		var x := r * (0.55 if i < 2 else -0.55)
		var s := -1.0 if i % 2 == 0 else 1.0
		ci.draw_line(Vector2(x, s * r * 0.3), Vector2(x + sin(gait + i * PI * 0.5) * r * 0.35, s * r * 0.7), dark, maxf(1.5, r * 0.18))
	tail(ci, -r * 0.95, r * 0.9, r * 0.15, t, phase, r * 0.3, dark, 6)
	var body := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		body.append(Vector2(cos(a) * r * 1.0, sin(a) * r * 0.48))
	ci.draw_colored_polygon(body, hide)
	ci.draw_line(Vector2(-r * 0.7, 0), Vector2(r * 0.6, 0), dark, maxf(1.5, r * 0.15))
	# Pescoço em chamas.
	var neck := Vector2(r * 1.0, 0)
	var size := r * (0.45 + 0.4 * g)
	for i in 5:
		var flick := sin(t * 18.0 + i * 1.7 + phase) * size * 0.2
		var col := Color(1.0, 0.35 + i * 0.12, 0.1 + i * 0.1, (0.75 - i * 0.1) * alpha)
		ci.draw_colored_polygon(PackedVector2Array([neck + Vector2(0, -size * (0.6 - i * 0.08)), neck + Vector2(size * (1.6 - i * 0.2), flick),
			neck + Vector2(0, size * (0.6 - i * 0.08))]), col)
	ci.draw_circle(neck, size * 1.6, Color(1.0, 0.5, 0.15, (0.08 + 0.12 * g) * alpha))


## Névoa devoradora: nuvem escura com olhos; encolhe enquanto a luz a dissipa.
static func fogbank(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, life: float, tint: Color, eye: Color) -> void:
	for i in 9:
		var a := TAU * i / 9.0 + t * 0.15
		var p := Vector2.from_angle(a) * r * (0.45 + 0.1 * sin(t * 0.8 + i * 1.3 + phase))
		ci.draw_circle(p, r * 0.55, Color(tint, 0.16 * alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.7, Color(tint.darkened(0.3), 0.3 * alpha))
	if lit > 0.0:
		ci.draw_arc(Vector2.ZERO, r * 0.95, 0.0, TAU, 40, Color(1.0, 0.7, 0.35, 0.35 * lit * alpha), 4.0)
	var blink := 1.0 if fmod(t + phase, 4.0) > 0.15 else 0.1
	var e := Color(eye, (0.35 + 0.4 * life) * alpha * blink)
	for s: float in [-1.0, 1.0]:
		ci.draw_circle(Vector2(r * 0.15, s * r * 0.16), maxf(2.0, r * 0.06), e)
		ci.draw_circle(Vector2(r * 0.15, s * r * 0.16), maxf(4.0, r * 0.14), Color(eye, 0.12 * alpha * blink))


# --- Rio Encantado ------------------------------------------------------------------

## Corpo-seco: morto ressecado, magro, de braços estendidos.
static func _corpo_seco(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.45, 0.4, 0.33), lit, alpha)
	var dark := c(Color(0.25, 0.21, 0.17), lit, alpha)
	var reach := sin(t * 4.0 + phase) * r * 0.15
	for s: float in [-1.0, 1.0]:
		var hand := Vector2(r * 0.9 + reach * s, s * r * 0.45)
		ci.draw_line(Vector2(0, s * r * 0.55), hand, skin, maxf(1.5, r * 0.13))
		for k in 3:
			ci.draw_line(hand, hand + Vector2(r * 0.25, s * r * (k - 1) * 0.1), dark, 1.0)
	var torso := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		torso.append(Vector2(cos(a) * r * 0.42, sin(a) * r * 0.75))
	ci.draw_colored_polygon(torso, skin)
	for i in 3:
		ci.draw_line(Vector2(-r * 0.05 - i * r * 0.12, -r * 0.5), Vector2(-r * 0.05 - i * r * 0.12, r * 0.5), dark, 1.2)
	ci.draw_circle(Vector2(r * 0.3, 0), r * 0.34, c(Color(0.62, 0.57, 0.48), lit, alpha))
	eyes(ci, Vector2(r * 0.45, 0), r * 0.14, maxf(1.3, r * 0.08), Color(1.0, 0.35, 0.2), lit, alpha)


## Curupira: pequeno guardião da mata, de cabelo de fogo e pés virados para trás.
static func _curupira(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.3, 0.45, 0.25), lit, alpha)
	var run := sin(t * 14.0 + phase)
	# Pés virados para trás: as pontas apontam para longe do farol.
	for s: float in [-1.0, 1.0]:
		var foot := Vector2(-r * (0.35 + 0.2 * run * s), s * r * 0.35)
		ci.draw_line(Vector2(0, s * r * 0.25), foot, skin, maxf(1.5, r * 0.18))
		ci.draw_colored_polygon(PackedVector2Array([foot + Vector2(0, -r * 0.1), foot + Vector2(-r * 0.4, 0), foot + Vector2(0, r * 0.1)]), c(Color(0.22, 0.32, 0.18), lit, alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.5, skin)
	# Cabelo de fogo esvoaçando.
	for i in 5:
		var y := (i - 2) * r * 0.16
		var length := r * (1.0 + 0.3 * sin(t * 16.0 + i * 1.9))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.35, y - r * 0.12), Vector2(r * 0.35 - length, y + sin(t * 12.0 + i) * r * 0.2),
			Vector2(r * 0.35, y + r * 0.12)]), Color(1.0, 0.3 + i * 0.08, 0.1, 0.85 * alpha))
	ci.draw_circle(Vector2(r * 0.45, 0), r * 0.32, skin)
	eyes(ci, Vector2(r * 0.62, 0), r * 0.13, maxf(1.2, r * 0.08), Color(1.0, 0.9, 0.3), lit, alpha)


## Mapinguari: gigante peludo de um olho só e boca na barriga.
static func _mapinguari(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var fur := c(Color(0.42, 0.22, 0.14), lit, alpha)
	var dark := c(Color(0.25, 0.12, 0.08), lit, alpha)
	var sway := sin(t * 2.5 + phase) * 0.1
	for i in 14:
		var a := TAU * i / 14.0
		ci.draw_circle(Vector2.from_angle(a) * r * 0.85, r * 0.3, dark)
	ci.draw_circle(Vector2.ZERO, r * 0.95, fur)
	# Garras para a frente.
	for s: float in [-1.0, 1.0]:
		var hand := Vector2(r * 0.95, s * r * (0.75 + sway))
		ci.draw_line(Vector2(r * 0.3, s * r * 0.7), hand, fur, maxf(2.0, r * 0.28))
		for k in 3:
			ci.draw_line(hand, hand + Vector2(r * 0.3, s * r * (k - 1) * 0.12), c(Color(0.9, 0.85, 0.75), lit, alpha), 1.5)
	# Boca na barriga, abrindo e fechando.
	var open := 0.35 + 0.2 * sin(t * 3.0 + phase)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.45, 0), Vector2(0, -r * open), Vector2(r * 0.35, 0), Vector2(0, r * open)]), Color(0.3, 0.02, 0.04, alpha))
	for i in 5:
		var x := -r * 0.35 + i * r * 0.15
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -r * open * 0.7), Vector2(x + r * 0.06, -r * open * 0.25), Vector2(x + r * 0.12, -r * open * 0.7)]), Color(0.95, 0.9, 0.8, alpha))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, r * open * 0.7), Vector2(x + r * 0.06, r * open * 0.25), Vector2(x + r * 0.12, r * open * 0.7)]), Color(0.95, 0.9, 0.8, alpha))
	# Um olho só, no alto da cabeça.
	ci.draw_circle(Vector2(r * 0.68, 0), r * 0.24, Color(0.95, 0.9, 0.7, alpha) if lit <= 0.0 else Color(1.0, 1.0, 0.8, alpha))
	ci.draw_circle(Vector2(r * 0.72, 0), r * 0.1, Color(0.15, 0.05, 0.02, alpha))


## Boto encantado: golfinho cor-de-rosa do rio, de chapéu branco.
static func _boto(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var pink := c(Color(0.92, 0.6, 0.66), lit, alpha)
	var spine := tail(ci, -r * 0.3, r * 1.4, r * 0.5, t * 1.4, phase, r * 0.35, pink, 8)
	var end := spine[spine.size() - 1]
	ci.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-r * 0.3, -r * 0.55), end + Vector2(-r * 0.15, 0), end + Vector2(-r * 0.3, r * 0.55)]), pink)
	var body := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		body.append(Vector2(cos(a) * r * 0.85, sin(a) * r * 0.5))
	ci.draw_colored_polygon(body, pink)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.7, -r * 0.12), Vector2(r * 1.45, 0), Vector2(r * 0.7, r * 0.12)]), pink)
	ci.draw_circle(Vector2(r * 0.15, 0), r * 0.36, c(Color(0.96, 0.95, 0.92), lit, alpha))
	ci.draw_arc(Vector2(r * 0.15, 0), r * 0.36, 0.0, TAU, 16, c(Color(0.3, 0.3, 0.32), lit, alpha), 1.5)
	ci.draw_circle(Vector2(r * 0.15, 0), r * 0.2, c(Color(0.88, 0.86, 0.8), lit, alpha))
	eyes(ci, Vector2(r * 0.6, 0), r * 0.22, maxf(1.1, r * 0.06), Color(0.25, 0.1, 0.12), lit, alpha)


## Fogo-fátuo do Boitatá e hitodama dos yōkai: bola de fogo com rastro.
static func wisp(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, col: Color, core: Color) -> void:
	for i in 6:
		var k := i / 6.0
		var p := Vector2(-r * (0.4 + k * 2.2), sin(t * 10.0 + phase + k * 4.0) * r * 0.3 * k)
		ci.draw_circle(p, r * (0.75 - k * 0.6), Color(col, 0.35 * (1.0 - k) * alpha))
	ci.draw_circle(Vector2.ZERO, r * 1.5, Color(col, 0.15 * alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.9, c(col, lit, alpha))
	ci.draw_circle(Vector2(r * 0.15, 0), r * 0.5, Color(core, alpha))


# --- Mar dos Yōkai ------------------------------------------------------------------

## Funayūrei: fantasma de marinheiro afogado, com faixa branca na testa e a
## concha (hishaku) com que enche os barcos de água.
static func _funayurei(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var body := c(Color(0.82, 0.86, 0.92, 0.8), lit, alpha)
	tail(ci, -r * 0.2, r * 2.4, r * 0.7, t, phase, r * 0.5, Color(body, body.a * 0.55))
	ci.draw_circle(Vector2.ZERO, r * 1.3, Color(body, 0.12 * alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.9, body)
	# Concha erguida na mão.
	var hand := Vector2(r * 0.9, r * 0.6 + sin(t * 4.0 + phase) * r * 0.15)
	ci.draw_line(Vector2(r * 0.2, r * 0.5), hand, body, maxf(1.5, r * 0.15))
	ci.draw_line(hand, hand + Vector2(r * 0.5, -r * 0.1), c(Color(0.45, 0.32, 0.2), lit, alpha), 2.0)
	ci.draw_circle(hand + Vector2(r * 0.6, -r * 0.12), r * 0.2, c(Color(0.5, 0.36, 0.22), lit, alpha))
	# Cabelo preto escorrido e a faixa triangular (hitaikakushi).
	ci.draw_circle(Vector2(-r * 0.15, 0), r * 0.6, c(Color(0.06, 0.06, 0.08), lit, alpha))
	ci.draw_circle(Vector2(r * 0.25, 0), r * 0.48, c(Color(0.9, 0.92, 0.95), lit, alpha))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.55, -r * 0.18), Vector2(r * 0.85, 0), Vector2(r * 0.55, r * 0.18)]), c(Color(1, 1, 1), lit, alpha))
	eyes(ci, Vector2(r * 0.45, 0), r * 0.17, maxf(1.3, r * 0.08), Color(0.3, 0.6, 1.0), lit, alpha)


## Kitsune: raposa com caudas de fogo-fátuo.
static func _kitsune(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	for i in 3:
		tail_at(ci, Vector2(-r * 0.9, 0), PI + (i - 1) * 0.5, r * 1.5, r * 0.32, t * 1.3, phase + i, r * 0.4, Color(0.55, 0.75, 1.0, 0.55 * alpha), 6)
	wolf(ci, r, t, phase, lit, alpha, Color(0.92, 0.55, 0.22), Color(0.98, 0.92, 0.85), Color(1.0, 0.85, 0.2))


## Kyūbi no kitsune: raposa branca de nove caudas (chefe e ilusões).
static func kyubi(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	for i in 9:
		var a := PI + (i - 4) * 0.28
		var tip := tail_at(ci, Vector2.from_angle(a) * r * 0.6, a, r * 2.1, r * 0.28, t * 0.9, phase + i * 0.7, r * 0.45, c(Color(0.96, 0.95, 1.0, 0.9), lit, alpha))
		ci.draw_circle(tip, r * 0.16, Color(0.55, 0.75, 1.0, 0.8 * alpha))
	wolf(ci, r, t, phase, lit, alpha, Color(0.97, 0.96, 0.98), Color(0.85, 0.3, 0.35), Color(1.0, 0.5, 0.2))


## Oni: ogro vermelho de chifres com o porrete de ferro (kanabō).
static func _oni(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.75, 0.2, 0.16), lit, alpha)
	var dark := c(Color(0.45, 0.1, 0.08), lit, alpha)
	var swing := sin(t * 2.5 + phase) * 0.3
	var club_end := Vector2(r * 0.4, r * 1.2).rotated(swing)
	ci.draw_line(Vector2(r * 0.2, r * 0.8), club_end + Vector2(r * 0.7, 0), c(Color(0.28, 0.28, 0.3), lit, alpha), maxf(3.0, r * 0.28))
	for k in 4:
		ci.draw_circle(Vector2(r * 0.2, r * 0.8).lerp(club_end + Vector2(r * 0.7, 0), 0.5 + k * 0.15), r * 0.08, c(Color(0.6, 0.6, 0.62), lit, alpha))
	ci.draw_circle(Vector2.ZERO, r, skin)
	# Tanga de pele de tigre.
	ci.draw_circle(Vector2(-r * 0.35, 0), r * 0.55, c(Color(0.9, 0.7, 0.2), lit, alpha))
	for i in 3:
		ci.draw_line(Vector2(-r * 0.7 + i * r * 0.25, -r * 0.4), Vector2(-r * 0.6 + i * r * 0.25, r * 0.4), Color(0.1, 0.08, 0.05, alpha), 2.0)
	ci.draw_line(Vector2(0, -r * 0.85), Vector2(r * 0.9, -r * 0.9), skin, maxf(2.0, r * 0.28))
	var head := Vector2(r * 0.6, 0)
	ci.draw_circle(head, r * 0.45, skin)
	ci.draw_circle(head + Vector2(-r * 0.15, 0), r * 0.35, c(Color(0.1, 0.08, 0.08), lit, alpha))
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.05, s * r * 0.2), head + Vector2(-r * 0.15, s * r * 0.7), head + Vector2(r * 0.25, s * r * 0.25)]), c(Color(0.95, 0.9, 0.75), lit, alpha))
	eyes(ci, head + Vector2(r * 0.25, 0), r * 0.17, maxf(1.3, r * 0.08), Color(1.0, 0.95, 0.3), lit, alpha)


## Kappa: casco de tartaruga; aberto, mostra o prato d'água na cabeça.
static func _kappa(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, open: float) -> void:
	var skin := c(Color(0.35, 0.6, 0.35), lit, alpha)
	for i in 4:
		var x := r * (0.55 if i < 2 else -0.55)
		var s := -1.0 if i % 2 == 0 else 1.0
		ci.draw_circle(Vector2(x, s * r * 0.75) * (0.7 + 0.3 * open), r * 0.22, skin)
	var head := Vector2(r * (0.55 + 0.5 * open), 0)
	ci.draw_circle(head, r * 0.32, skin)
	if open > 0.3:
		ci.draw_circle(head, r * 0.16, c(Color(0.75, 0.88, 0.95), lit, alpha))
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.25, -r * 0.08), head + Vector2(r * 0.45, 0), head + Vector2(r * 0.25, r * 0.08)]), c(Color(0.9, 0.75, 0.2), lit, alpha))
		eyes(ci, head + Vector2(r * 0.15, 0), r * 0.2, maxf(1.2, r * 0.06), Color(1.0, 0.95, 0.4), lit, alpha)
	var dome := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		dome.append(Vector2(cos(a) * r * 0.9, sin(a) * r * 0.8))
	ci.draw_colored_polygon(dome, c(Color(0.2, 0.38, 0.22), lit, alpha))
	for i in 3:
		ci.draw_line(Vector2(-r * 0.6, (i - 1) * r * 0.35), Vector2(r * 0.6, (i - 1) * r * 0.35), c(Color(0.32, 0.52, 0.3), lit, alpha), 2.0)
	if open < 0.6:
		var k := (1.0 - open / 0.6) * (0.6 + 0.4 * sin(t * 3.0 + phase))
		ci.draw_arc(Vector2.ZERO, r * 1.1, 0.0, TAU, 28, Color(0.7, 1.0, 0.8, 0.45 * k * alpha), 2.5)
		ci.draw_line(Vector2(-r * 0.5, -r * 0.45), Vector2(r * 0.3, -r * 0.2), Color(1, 1, 1, 0.55 * k * alpha), 2.5)


## Chōchin-obake: lanterna de papel com um olho e a língua de fora; a luz a faz crescer.
static func _chochin(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, g: float) -> void:
	ci.draw_circle(Vector2.ZERO, r * (1.5 + 0.6 * g), Color(1.0, 0.55, 0.2, (0.08 + 0.18 * g) * alpha))
	var paper := c(Color(0.95, 0.88 - 0.2 * g, 0.7 - 0.3 * g), lit, alpha)
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		pts.append(Vector2(cos(a) * r * 1.0, sin(a) * r * 0.85))
	ci.draw_colored_polygon(pts, paper)
	for i in 4:
		var x := -r * 0.6 + i * r * 0.4
		ci.draw_line(Vector2(x, -r * 0.8), Vector2(x, r * 0.8), c(Color(0.6, 0.45, 0.3), lit, alpha), 1.2)
	ci.draw_rect(Rect2(-r * 1.1, -r * 0.35, r * 0.2, r * 0.7), c(Color(0.15, 0.12, 0.1), lit, alpha))
	ci.draw_circle(Vector2(r * 0.3, -r * 0.1), r * 0.25, Color(1, 1, 1, alpha))
	ci.draw_circle(Vector2(r * 0.35, -r * 0.1), r * 0.12, Color(0.1, 0.02, 0.02, alpha))
	var lick := sin(t * 6.0 + phase) * r * 0.1
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.8, r * 0.1), Vector2(r * 1.4, r * 0.25 + lick), Vector2(r * 0.8, r * 0.4)]), Color(0.85, 0.2, 0.25, alpha))


## Onda que o Umibōzu lança contra o farol.
static func _wave(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	for k in 3:
		var rr := r * (1.4 - k * 0.3)
		ci.draw_arc(Vector2(-r * 0.6 + k * r * 0.25, 0), rr, -1.1, 1.1, 14, c(Color(0.6, 0.8, 0.95, 0.85 - k * 0.2), lit, alpha), maxf(2.0, r * (0.35 - k * 0.08)))
	for i in 5:
		var a := -0.9 + i * 0.45
		var p := Vector2(r * 0.25, 0) + Vector2.from_angle(a) * r * 0.75
		ci.draw_circle(p, r * 0.16 + sin(t * 9.0 + i + phase) * r * 0.04, Color(1, 1, 1, 0.85 * alpha))


# --- Farol de Alexandria ------------------------------------------------------------

## Múmia: corpo enfaixado de braços estendidos, faixas soltas atrás.
static func _mummy(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var wrap := c(Color(0.82, 0.76, 0.6), lit, alpha)
	var shade := c(Color(0.6, 0.54, 0.42), lit, alpha)
	tail(ci, -r * 0.3, r * 1.4, r * 0.1, t, phase, r * 0.5, Color(wrap, 0.7 * alpha), 6)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(0, s * r * 0.55), Vector2(r * 1.0, s * r * 0.4 + sin(t * 3.0 + phase) * r * 0.08 * s), wrap, maxf(1.5, r * 0.2))
	var body := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		body.append(Vector2(cos(a) * r * 0.5, sin(a) * r * 0.8))
	ci.draw_colored_polygon(body, wrap)
	for i in 4:
		ci.draw_line(Vector2(-r * 0.45, -r * 0.6 + i * r * 0.4), Vector2(r * 0.45, -r * 0.4 + i * r * 0.4), shade, 1.5)
	ci.draw_circle(Vector2(r * 0.35, 0), r * 0.36, wrap)
	ci.draw_line(Vector2(r * 0.15, -r * 0.3), Vector2(r * 0.55, r * 0.3), shade, 1.5)
	eyes(ci, Vector2(r * 0.5, 0), r * 0.14, maxf(1.3, r * 0.08), Color(0.4, 1.0, 0.5), lit, alpha)


## Crocodilo de Sobek: grande, de escamas verdes e mandíbula comprida.
static func _sobek(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var scales := c(Color(0.3, 0.42, 0.22), lit, alpha)
	var belly := c(Color(0.55, 0.6, 0.35), lit, alpha)
	tail(ci, -r * 0.6, r * 1.6, r * 0.45, t * 0.8, phase, r * 0.4, scales, 8)
	var gait := t * 6.0 + phase
	for i in 4:
		var x := r * (0.4 if i < 2 else -0.45)
		var s := -1.0 if i % 2 == 0 else 1.0
		ci.draw_line(Vector2(x, s * r * 0.45), Vector2(x + sin(gait + i * PI * 0.5) * r * 0.3, s * r * 0.85), scales, maxf(2.0, r * 0.18))
	var body := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		body.append(Vector2(cos(a) * r * 0.85, sin(a) * r * 0.55))
	ci.draw_colored_polygon(body, scales)
	ci.draw_circle(Vector2(0, 0), r * 0.35, belly)
	for i in 5:
		ci.draw_circle(Vector2(-r * 0.6 + i * r * 0.3, 0), r * 0.07, c(Color(0.2, 0.28, 0.14), lit, alpha))
	var open := 0.1 + 0.12 * absf(sin(t * 2.0 + phase))
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.6, s * r * 0.25), Vector2(r * 1.7, s * r * open), Vector2(r * 0.6, s * r * 0.02)]), scales)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.7, 0), Vector2(r * 1.6, -r * open * 0.6), Vector2(r * 1.6, r * open * 0.6)]), Color(0.4, 0.08, 0.06, alpha))
	eyes(ci, Vector2(r * 0.7, 0), r * 0.2, maxf(1.3, r * 0.08), Color(1.0, 0.85, 0.2), lit, alpha)


## Naja de Apep: cobra de capuz aberto que rasteja até o farol.
static func _cobra(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.35, 0.25, 0.4), lit, alpha)
	tail(ci, -r * 0.2, r * 2.6, r * 0.35, t * 1.6, phase, r * 0.7, skin, 10)
	ci.draw_circle(Vector2(r * 0.1, 0), r * 0.6, c(Color(0.45, 0.3, 0.5), lit, alpha))
	ci.draw_circle(Vector2(r * 0.1, 0), r * 0.3, c(Color(0.9, 0.75, 0.3), lit, alpha))
	ci.draw_circle(Vector2(r * 0.55, 0), r * 0.3, skin)
	eyes(ci, Vector2(r * 0.65, 0), r * 0.13, maxf(1.2, r * 0.07), Color(1.0, 0.3, 0.2), lit, alpha)


# --- Mar Egeu -----------------------------------------------------------------------

## Sombra do Hades: alma cinzenta com a moeda do barqueiro na mão.
static func _shade(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var body := c(Color(0.42, 0.48, 0.55, 0.8), lit, alpha)
	tail(ci, -r * 0.2, r * 2.4, r * 0.7, t * 0.9, phase, r * 0.5, Color(body, body.a * 0.55))
	ci.draw_circle(Vector2.ZERO, r * 1.3, Color(body, 0.12 * alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.95, body)
	# Manto com capuz e o óbolo dourado estendido.
	ci.draw_arc(Vector2(r * 0.05, 0), r * 0.7, PI * 0.55, PI * 1.45, 12, c(Color(0.22, 0.25, 0.3), lit, alpha), maxf(2.0, r * 0.3))
	var hand := Vector2(r * 0.95, r * 0.35 + sin(t * 3.0 + phase) * r * 0.1)
	ci.draw_line(Vector2(r * 0.3, r * 0.4), hand, body, maxf(1.5, r * 0.14))
	ci.draw_circle(hand, r * 0.16, c(Color(0.95, 0.78, 0.3), lit, alpha))
	eyes(ci, Vector2(r * 0.4, 0), r * 0.22, maxf(1.3, r * 0.1), Color(0.7, 0.85, 1.0), lit, alpha)


## Minotauro: corpo largo, cabeça de touro de chifres longos e um machado duplo.
static func _minotaur(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var hide := c(Color(0.42, 0.26, 0.16), lit, alpha)
	var dark := c(Color(0.25, 0.15, 0.09), lit, alpha)
	var swing := sin(t * 2.4 + phase) * 0.35
	# Lábris (machado de duas lâminas).
	var grip := Vector2(r * 0.2, r * 0.85)
	var head_axe := grip + Vector2(r * 0.9, r * 0.25).rotated(swing)
	ci.draw_line(grip, head_axe, c(Color(0.35, 0.25, 0.15), lit, alpha), maxf(2.0, r * 0.14))
	for s: float in [-1.0, 1.0]:
		var side := Vector2(r * 0.4, 0).rotated(swing + PI / 2.0) * s
		ci.draw_colored_polygon(PackedVector2Array([head_axe, head_axe + side + Vector2(r * 0.15, 0), head_axe + side - Vector2(r * 0.15, 0)]), c(Color(0.75, 0.68, 0.5), lit, alpha))
	ci.draw_circle(Vector2.ZERO, r, hide)
	ci.draw_circle(Vector2(-r * 0.3, 0), r * 0.7, dark)
	ci.draw_line(Vector2(0, -r * 0.85), Vector2(r * 0.85, -r * 0.8), hide, maxf(2.0, r * 0.26))
	var head := Vector2(r * 0.65, 0)
	ci.draw_circle(head, r * 0.45, hide)
	ci.draw_circle(head + Vector2(r * 0.35, 0), r * 0.25, c(Color(0.55, 0.38, 0.28), lit, alpha))
	ci.draw_arc(head + Vector2(r * 0.5, 0), r * 0.12, -1.2, 1.2, 8, c(Color(0.85, 0.75, 0.3), lit, alpha), 2.0)
	for s: float in [-1.0, 1.0]:
		ci.draw_polyline(PackedVector2Array([head + Vector2(0, s * r * 0.3), head + Vector2(-r * 0.05, s * r * 0.75), head + Vector2(r * 0.3, s * r * 0.95)]),
			c(Color(0.92, 0.88, 0.75), lit, alpha), maxf(2.0, r * 0.13))
	eyes(ci, head + Vector2(r * 0.2, 0), r * 0.2, maxf(1.3, r * 0.08), Color(1.0, 0.3, 0.15), lit, alpha)


## Harpia: ave de rapina de rosto humano e garras, que rouba as brasas.
static func _harpy(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, carried: float) -> void:
	bird(ci, r, t, phase, lit, alpha, Color(0.45, 0.35, 0.3), Color(0.3, 0.22, 0.18), Color(0.8, 0.7, 0.55), Color(1.0, 0.75, 0.3), 0.0, 0.0)
	# Rosto pálido e cabelo escuro sobre a cabeça da ave.
	ci.draw_circle(Vector2(r * 0.7, 0), r * 0.3, c(Color(0.85, 0.75, 0.68), lit, alpha))
	tail(ci, r * 0.55, r * 0.9, r * 0.35, t * 2.0, phase, r * 0.25, c(Color(0.12, 0.08, 0.08), lit, alpha), 5)
	eyes(ci, Vector2(r * 0.85, 0), r * 0.13, maxf(1.2, r * 0.07), Color(1.0, 0.4, 0.2), lit, alpha)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(r * 0.3, s * r * 0.25), Vector2(r * 0.95, s * r * 0.45), c(Color(0.75, 0.65, 0.3), lit, alpha), 1.5)
	if carried > 0.0:
		_ember_glow(ci, Vector2(r * 1.0, r * 0.45), r * 0.28, t, alpha)


## Escudo de bronze: hoplita agachado atrás do escudo redondo, que espelha a luz.
static func _bronze_shield(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, open: float) -> void:
	var bronze := c(Color(0.75, 0.55, 0.25), lit, alpha)
	var shine := c(Color(1.0, 0.85, 0.5), lit, alpha)
	# Guerreiro atrás: capacete de crista e lança, aparece quando o escudo baixa.
	var behind := Vector2(-r * 0.4 * (1.0 - open), 0)
	ci.draw_circle(behind, r * 0.6, c(Color(0.5, 0.38, 0.25), lit, alpha))
	ci.draw_line(behind + Vector2(-r * 0.5, 0), behind + Vector2(r * 0.2, 0), c(Color(0.75, 0.15, 0.12), lit, alpha), maxf(2.0, r * 0.25))
	ci.draw_line(behind + Vector2(-r * 0.3, r * 0.5), behind + Vector2(r * 1.6, r * 0.5), c(Color(0.4, 0.3, 0.2), lit, alpha), 1.8)
	if open > 0.3:
		eyes(ci, behind + Vector2(r * 0.35, 0), r * 0.15, maxf(1.2, r * 0.07), Color(1.0, 0.9, 0.5), lit, alpha)
	# O escudo gira de lado quando abre.
	var sx := lerpf(0.35, 0.12, open)
	var center := Vector2(r * (0.55 + 0.25 * open), -r * 0.45 * open)
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(center + Vector2(cos(a) * r * sx * 2.0, sin(a) * r * 1.05))
	ci.draw_colored_polygon(pts, bronze)
	var ring := PackedVector2Array(pts)
	ring.append(pts[0])
	ci.draw_polyline(ring, shine, 1.5)
	ci.draw_circle(center, r * 0.22 * (1.0 - open * 0.5), shine)
	if open < 0.6:
		var k := (1.0 - open / 0.6) * (0.6 + 0.4 * sin(t * 3.0 + phase))
		ci.draw_arc(Vector2.ZERO, r * 1.2, 0.0, TAU, 28, Color(1, 0.95, 0.8, 0.35 * k * alpha), 2.0)
		ci.draw_line(center + Vector2(-r * 0.1, -r * 0.7), center + Vector2(r * 0.1, -r * 0.1), Color(1, 1, 1, 0.6 * k * alpha), 2.5)


## Lâmpade: ninfa do submundo de manto roxo e tocha; a luz aviva a chama.
static func _lampad(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, g: float) -> void:
	ci.draw_circle(Vector2.ZERO, r * (1.5 + 0.7 * g), Color(1.0, 0.6, 0.3, (0.06 + 0.15 * g) * alpha))
	var robe := c(Color(0.5, 0.4, 0.68, 0.85), lit, alpha)
	tail(ci, -r * 0.1, r * 1.8, r * 0.6, t * 1.2, phase, r * 0.45, Color(robe, robe.a * 0.6), 7)
	ci.draw_circle(Vector2.ZERO, r * 0.7, robe)
	tail(ci, r * 0.2, r * 1.1, r * 0.4, t * 2.0, phase + 1.0, r * 0.3, c(Color(0.12, 0.08, 0.15), lit, alpha), 5)
	ci.draw_circle(Vector2(r * 0.45, 0), r * 0.36, c(Color(0.85, 0.82, 0.75), lit, alpha))
	# Tocha cuja chama cresce com a luz.
	var torch := Vector2(r * 0.9, r * 0.55)
	ci.draw_line(Vector2(r * 0.3, r * 0.4), torch, c(Color(0.45, 0.32, 0.2), lit, alpha), 2.0)
	var flame := r * (0.3 + 0.35 * g) * (0.85 + 0.15 * sin(t * 12.0 + phase))
	ci.draw_circle(torch + Vector2(r * 0.15, 0), flame * 1.6, Color(1.0, 0.55, 0.2, 0.25 * alpha))
	ci.draw_circle(torch + Vector2(r * 0.15, 0), flame, Color(1.0, 0.85, 0.5, alpha))
	eyes(ci, Vector2(r * 0.6, 0), r * 0.13, maxf(1.2, r * 0.07), Color(1.0, 0.7, 0.3), lit, alpha)


## Serpente da górgona: cobra verde de escamas claras, solta dos cabelos da Medusa.
static func _gorgon_snake(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.3, 0.5, 0.25), lit, alpha)
	var spine := tail(ci, -r * 0.1, r * 2.8, r * 0.38, t * 1.8, phase, r * 0.8, skin, 10)
	for i in range(1, spine.size(), 2):
		ci.draw_circle(spine[i], maxf(1.0, r * 0.1), c(Color(0.75, 0.85, 0.45), lit, alpha))
	ci.draw_circle(Vector2(r * 0.25, 0), r * 0.42, skin)
	ci.draw_line(Vector2(r * 0.6, 0), Vector2(r * 0.95, 0), Color(0.85, 0.15, 0.2, alpha), 1.5)
	eyes(ci, Vector2(r * 0.4, 0), r * 0.18, maxf(1.2, r * 0.08), Color(1.0, 0.9, 0.3), lit, alpha)


# --- Costa Celta --------------------------------------------------------------------

## Banshee: mulher pálida de cabelo longo, que lamenta de boca aberta.
static func _banshee(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var body := c(Color(0.78, 0.85, 0.82, 0.75), lit, alpha)
	tail(ci, -r * 0.2, r * 2.6, r * 0.75, t * 1.1, phase, r * 0.6, Color(body, body.a * 0.5))
	ci.draw_circle(Vector2.ZERO, r * 1.35, Color(0.6, 0.9, 0.8, 0.1 * alpha))
	ci.draw_circle(Vector2.ZERO, r * 0.9, body)
	# Cabelo branco esvoaçando e o grito em anéis.
	tail(ci, r * 0.2, r * 1.9, r * 0.65, t * 2.2, phase + 1.0, r * 0.5, c(Color(0.92, 0.95, 0.95, 0.85), lit, alpha), 7)
	ci.draw_circle(Vector2(r * 0.4, 0), r * 0.42, c(Color(0.85, 0.9, 0.88), lit, alpha))
	ci.draw_circle(Vector2(r * 0.7, 0), r * 0.14, Color(0.05, 0.08, 0.1, 0.85 * alpha))
	for k in 2:
		var rr := r * (1.0 + fmod(t * 1.5 + phase + k * 0.5, 1.0) * 0.8)
		ci.draw_arc(Vector2(r * 0.6, 0), rr, -0.6, 0.6, 8, Color(0.7, 1.0, 0.9, 0.3 * alpha), 1.5)
	eyes(ci, Vector2(r * 0.5, 0), r * 0.16, maxf(1.2, r * 0.08), Color(0.5, 1.0, 0.85), lit, alpha)


## Kelpie: cavalo da água, escuro, de crina de algas e sempre molhado.
static func _kelpie(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	wolf(ci, r, t, phase, lit, alpha, Color(0.16, 0.22, 0.24), Color(0.08, 0.12, 0.14), Color(0.6, 1.0, 0.9))
	# Crina de algas ao longo do pescoço e gotas que pingam.
	for i in 5:
		var at := Vector2(r * (0.95 - i * 0.28), 0)
		ci.draw_line(at, at + Vector2(-r * 0.3, sin(t * 6.0 + phase + i) * r * 0.35), c(Color(0.2, 0.45, 0.3), lit, alpha), maxf(1.5, r * 0.12))
	for i in 3:
		var k := fmod(t * 1.3 + i / 3.0 + phase, 1.0)
		ci.draw_circle(Vector2(-r * (0.4 + k * 1.2), (i - 1) * r * 0.4), r * 0.08, Color(0.6, 0.85, 1.0, 0.6 * (1.0 - k) * alpha))


## Fomoriano: gigante do mar de um olho só, um braço só e a pele de algas.
static func _fomorian(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var skin := c(Color(0.32, 0.42, 0.36), lit, alpha)
	var dark := c(Color(0.18, 0.25, 0.22), lit, alpha)
	var sway := sin(t * 2.2 + phase) * 0.2
	# O único braço, com uma âncora velha como clava.
	var hand := Vector2(r * 0.9, r * (0.85 + sway))
	ci.draw_line(Vector2(r * 0.1, r * 0.75), hand, skin, maxf(2.0, r * 0.28))
	ci.draw_line(hand, hand + Vector2(r * 0.7, 0), c(Color(0.35, 0.3, 0.28), lit, alpha), maxf(2.0, r * 0.12))
	ci.draw_arc(hand + Vector2(r * 0.7, 0), r * 0.3, -PI / 2.0, PI / 2.0, 10, c(Color(0.4, 0.35, 0.32), lit, alpha), maxf(2.0, r * 0.12))
	ci.draw_circle(Vector2.ZERO, r, skin)
	ci.draw_circle(Vector2(-r * 0.25, 0), r * 0.72, dark)
	for i in 4:
		var a := phase + i * 1.7
		var p := Vector2(-r * 0.3 + cos(a) * r * 0.4, sin(a) * r * 0.5)
		ci.draw_line(p, p + Vector2(-r * 0.3, r * 0.2), c(Color(0.25, 0.5, 0.3), lit, alpha), 2.0)
	var head := Vector2(r * 0.65, 0)
	ci.draw_circle(head, r * 0.42, skin)
	ci.draw_circle(head + Vector2(r * 0.2, 0), r * 0.18, Color(1.0, 0.95, 0.7, alpha))
	ci.draw_circle(head + Vector2(r * 0.25, 0), r * 0.09, Color(0.6, 0.1, 0.05, alpha) if lit <= 0.0 else Color(1.0, 0.6, 0.2, alpha))


## Púca: lebre negra de olhos dourados e orelhas compridas, que muda de forma e rouba.
static func _pooka(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, carried: float) -> void:
	var fur := c(Color(0.1, 0.09, 0.12), lit, alpha)
	var hop := absf(sin(t * 8.0 + phase))
	ci.draw_circle(Vector2.ZERO, r * (1.1 + 0.15 * hop), Color(0.3, 0.2, 0.45, 0.15 * alpha))
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(-r * 0.5, s * r * 0.4), Vector2(-r * (0.9 + 0.3 * hop), s * r * 0.6), fur, maxf(2.0, r * 0.25))
	var body := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		body.append(Vector2(cos(a) * r * 0.85, sin(a) * r * 0.6))
	ci.draw_colored_polygon(body, fur)
	ci.draw_circle(Vector2(-r * 0.85, 0), r * 0.2, c(Color(0.3, 0.28, 0.35), lit, alpha))
	var head := Vector2(r * 0.75, 0)
	ci.draw_circle(head, r * 0.4, fur)
	for s: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-r * 0.05, s * r * 0.12), head + Vector2(-r * 0.9, s * r * (0.4 + 0.1 * hop)), head + Vector2(-r * 0.15, s * r * 0.3)]), fur)
	eyes(ci, head + Vector2(r * 0.2, 0), r * 0.18, maxf(1.2, r * 0.09), Color(1.0, 0.8, 0.2), lit, alpha)
	if carried > 0.0:
		_ember_glow(ci, head + Vector2(r * 0.45, 0), r * 0.28, t, alpha)


## Selkie: foca encolhida na pele brilhante; ao tirar a pele, mostra o rosto de gente.
static func _selkie(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float, open: float) -> void:
	var skin := c(Color(0.42, 0.45, 0.5), lit, alpha)
	var spots := c(Color(0.28, 0.3, 0.35), lit, alpha)
	if open > 0.3:
		var face := Vector2(r * (0.4 + 0.5 * open), 0)
		tail_at(ci, face, PI, r * 1.0, r * 0.4, t * 1.5, phase, r * 0.3, c(Color(0.2, 0.12, 0.08), lit, alpha), 5)
		ci.draw_circle(face, r * 0.35, c(Color(0.85, 0.75, 0.65), lit, alpha))
		eyes(ci, face + Vector2(r * 0.15, 0), r * 0.14, maxf(1.2, r * 0.07), Color(0.4, 0.8, 1.0), lit, alpha)
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		pts.append(Vector2(cos(a) * r * (1.05 - 0.3 * open) - r * 0.2 * open, sin(a) * r * 0.75))
	ci.draw_colored_polygon(pts, skin)
	for i in 5:
		ci.draw_circle(Vector2(-r * 0.5 + i * r * 0.25 - r * 0.2 * open, sin(i * 2.1 + phase) * r * 0.35), r * 0.09, spots)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.9, 0), Vector2(-r * 1.4, -r * 0.4), Vector2(-r * 1.25, 0), Vector2(-r * 1.4, r * 0.4)]), skin)
	if open < 0.6:
		var k := (1.0 - open / 0.6) * (0.6 + 0.4 * sin(t * 3.0 + phase))
		ci.draw_circle(Vector2(r * 0.7, 0), r * 0.3, skin)
		ci.draw_arc(Vector2.ZERO, r * 1.15, 0.0, TAU, 28, Color(0.8, 0.95, 1.0, 0.35 * k * alpha), 2.0)
		ci.draw_line(Vector2(-r * 0.5, -r * 0.45), Vector2(r * 0.4, -r * 0.2), Color(1, 1, 1, 0.6 * k * alpha), 2.5)


## Péist: serpente dos lagos irlandeses, de corpo grosso e barbatanas.
static func _peist(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	var col := c(Color(0.2, 0.32, 0.3), lit, alpha)
	var spine := tail(ci, r * 0.6, r * 3.0, r * 0.75, t * 1.3, phase, r * 0.8, col, 12)
	for i in range(2, spine.size() - 2, 3):
		ci.draw_colored_polygon(PackedVector2Array([spine[i] + Vector2(0, -r * 0.2), spine[i] + Vector2(-r * 0.35, -r * 0.55), spine[i] + Vector2(-r * 0.2, 0)]), c(Color(0.35, 0.55, 0.45), lit, alpha))
	ci.draw_circle(Vector2(r * 0.65, 0), r * 0.42, col)
	eyes(ci, Vector2(r * 0.85, 0), r * 0.2, maxf(1.2, r * 0.08), Color(0.9, 1.0, 0.5), lit, alpha)


## Pedra de ogham: menir com entalhes, que a Cailleach faz rolar.
static func _ogham(ci: CanvasItem, r: float, t: float, phase: float, lit: float, alpha: float) -> void:
	ci.draw_set_transform(Vector2.ZERO, t * 3.0 + phase)
	ci.draw_circle(Vector2.ZERO, r * 1.4, Color(0.7, 1.0, 0.85, 0.1 * alpha))
	ci.draw_rect(Rect2(-r * 0.5, -r * 1.0, r * 1.0, r * 2.0), c(Color(0.5, 0.52, 0.5), lit, alpha))
	ci.draw_rect(Rect2(-r * 0.5, -r * 1.0, r * 0.3, r * 2.0), c(Color(0.62, 0.65, 0.6), lit, alpha))
	ci.draw_line(Vector2(r * 0.5, -r * 0.9), Vector2(r * 0.5, r * 0.9), c(Color(0.3, 0.32, 0.3), lit, alpha), 1.5)
	for i in 5:
		var y := -r * 0.7 + i * r * 0.35
		ci.draw_line(Vector2(r * 0.5, y), Vector2(r * (0.15 if i % 2 == 0 else 0.25), y), Color(0.6, 1.0, 0.8, 0.8 * alpha), 1.5)
