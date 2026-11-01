class_name AbilityBar
extends Control
## Três espaços das habilidades ativas: ícone, tecla configurada, varredura
## de recarga com segundos restantes e brilho quando a habilidade fica pronta.
## Tocar ou clicar num espaço usa a habilidade (telas de toque).

const SLOT := 58.0
const GAP := 14.0

var abilities: Abilities

var _time := 0.0
var _was_ready: Array[bool] = [true, true, true]
var _ready_flash: Array[float] = [0.0, 0.0, 0.0]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(SLOT * 3 + GAP * 2, SLOT + 22)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if abilities == null or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var i := int(mb.position.x / (SLOT + GAP))
	if i >= 0 and i < 3 and mb.position.x - i * (SLOT + GAP) <= SLOT and mb.position.y <= SLOT:
		abilities.use(i)
		accept_event()


func _process(delta: float) -> void:
	_time += delta
	if abilities and abilities.cooldowns.size() == 3:
		for i in 3:
			var ready := abilities.is_ready(i)
			if ready and not _was_ready[i]:
				_ready_flash[i] = 1.0
			_was_ready[i] = ready
			_ready_flash[i] = maxf(0.0, _ready_flash[i] - delta * 2.0)
	queue_redraw()


func _draw() -> void:
	if abilities == null or abilities.cooldowns.size() < 3:
		return
	for i in 3:
		var a: Dictionary = Balance.ABILITIES[i]
		var r := Rect2(i * (SLOT + GAP), 0, SLOT, SLOT)
		var c := r.get_center()
		var ready := abilities.is_ready(i)
		draw_rect(r.grow(3.0), Color(0, 0, 0, 0.75))
		draw_rect(r, Color(0.08, 0.08, 0.13))
		Icons.draw(self, a["id"], c, SLOT * 0.32, UiTheme.GOLD if ready else Color(0.5, 0.5, 0.55))
		if not ready:
			var f := abilities.fraction(i)
			draw_rect(Rect2(r.position, Vector2(SLOT, SLOT * f)), Color(0, 0, 0, 0.65))
			UiTheme.draw_text(self, "%d" % ceili(abilities.cooldowns[i]), c, 20, UiTheme.TEXT, UiTheme.heading_font())
		var border := UiTheme.GOLD if ready else UiTheme.GOLD_DARK
		if ready:
			var pulse := 0.6 + 0.4 * sin(_time * 3.0 + i)
			draw_rect(r.grow(1.0), Color(UiTheme.GOLD, 0.25 * pulse), false, 4.0)
		draw_rect(r, border, false, 2.0)
		if _ready_flash[i] > 0.0:
			draw_rect(r.grow(6.0 * (1.0 - _ready_flash[i])), Color(1.0, 0.95, 0.7, _ready_flash[i]), false, 3.0)
		var keys: Array = Settings.controls.get("ability_%d" % (i + 1), GameInput.REBINDABLE["ability_%d" % (i + 1)])
		UiTheme.draw_text(self, GameInput.key_name(int(keys[0])), Vector2(c.x, r.end.y + 11.0), 12, UiTheme.TEXT_DIM)

