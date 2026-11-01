class_name LighthouseArt
extends RefCounted
## Desenho do farol visto de cima, para cada visual de Keepers.
## Usado no jogo e na prévia da tela de escolha do farol.


static func draw(ci: CanvasItem, keeper_id: String, c: Vector2, s: float, t: float, hot: bool = false) -> void:
	var k := Keepers.get_keeper(keeper_id)
	var base: Color = k["base"]
	var stripe: Color = k["stripe"]
	var roof: Color = k["roof"]
	var lamp: Color = k["lamp"]
	var trim: Color = k["trim"]
	var glow := 0.75 + 0.25 * sin(t * 3.0)
	ci.draw_circle(c + Vector2(3, 4) * s, 30.0 * s, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, 27.0 * s, base)
	match keeper_id:
		"stone":
			# Blocos de pedra e musgo.
			for i in 10:
				var a := TAU * i / 10.0
				ci.draw_line(c + Vector2.from_angle(a) * 15.0 * s, c + Vector2.from_angle(a) * 27.0 * s, base.darkened(0.3), 1.5 * s)
			for i in 5:
				var a := 0.6 + i * 1.25
				ci.draw_circle(c + Vector2.from_angle(a) * 22.0 * s, 4.0 * s, stripe)
		"iron":
			# Rebites e aro de latão.
			ci.draw_arc(c, 23.0 * s, 0.0, TAU, 40, stripe, 3.0 * s)
			for i in 12:
				ci.draw_circle(c + Vector2.from_angle(TAU * i / 12.0) * 25.0 * s, 1.3 * s, trim)
		"crystal":
			# Facetas de cristal.
			for i in 6:
				var a := TAU * i / 6.0 + t * 0.2
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2.from_angle(a) * 15.0 * s, c + Vector2.from_angle(a + 0.4) * 27.0 * s, c + Vector2.from_angle(a + 0.9) * 15.0 * s]), Color(stripe, 0.55))
		_:
			ci.draw_arc(c, 21.0 * s, 0.0, TAU, 40, stripe, 6.0 * s)
	ci.draw_arc(c, 27.0 * s, 0.0, TAU, 40, trim, 1.5 * s)
	ci.draw_circle(c, 14.0 * s, roof)
	var light := lamp.lerp(Color.WHITE, 0.5) if hot else lamp
	for i in 4:
		ci.draw_circle(c, (12.0 + i * 7.0) * s, Color(light, 0.07 * glow * (1.6 if hot else 1.0)))
	ci.draw_circle(c, 10.0 * s, light.lerp(Color.WHITE, 0.3 * glow))
