class_name GameInput
extends RefCounted
## Registra as ações de input em tempo de execução, para o project.godot
## ficar limpo. Teclado, mouse e controle são suportados.
## As ações de REBINDABLE têm duas teclas configuráveis pelo jogador
## (Settings.controls); o resto é fixo.

## Ação -> [tecla principal, alternativa]. A ordem define a tela de controles.
const REBINDABLE := {
	"rotate_left": [KEY_A, KEY_LEFT],
	"rotate_right": [KEY_D, KEY_RIGHT],
	"ability_1": [KEY_SPACE, KEY_Q],
	"ability_2": [KEY_SHIFT, KEY_E],
	"ability_3": [KEY_R, KEY_F],
}

## Nome visível de cada ação configurável (traduzido via I18n).
const ACTION_NAMES := {
	"rotate_left": "Girar o feixe para a esquerda",
	"rotate_right": "Girar o feixe para a direita",
	"ability_1": "Habilidade 1",
	"ability_2": "Habilidade 2",
	"ability_3": "Habilidade 3",
}

## Teclas que não podem ser usadas em ações configuráveis.
const RESERVED := [KEY_ESCAPE, KEY_P, KEY_ENTER, KEY_KP_ENTER, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_T, KEY_B]


static func setup() -> void:
	_keys(&"pause", [KEY_ESCAPE, KEY_P])
	_keys(&"choose_1", [KEY_1, KEY_KP_1])
	_keys(&"choose_2", [KEY_2, KEY_KP_2])
	_keys(&"choose_3", [KEY_3, KEY_KP_3])
	_keys(&"choose_4", [KEY_4, KEY_KP_4])
	_keys(&"choose_5", [KEY_5, KEY_KP_5])
	# Menus (cartas de melhoria, mapa, farol e dificuldade).
	_keys(&"menu_left", [KEY_A, KEY_LEFT])
	_keys(&"menu_right", [KEY_D, KEY_RIGHT])
	_keys(&"menu_confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_keys(&"menu_back", [])
	# Escolha de melhoria: trocar as cartas e banir uma.
	_keys(&"reroll", [KEY_T])
	_keys(&"banish", [KEY_B])
	_joy_button(&"reroll", JOY_BUTTON_X)
	_joy_button(&"banish", JOY_BUTTON_BACK)
	_joy_button(&"menu_left", JOY_BUTTON_DPAD_LEFT)
	_joy_button(&"menu_right", JOY_BUTTON_DPAD_RIGHT)
	_joy_button(&"menu_confirm", JOY_BUTTON_A)
	_joy_button(&"menu_back", JOY_BUTTON_B)
	_joy_button(&"pause", JOY_BUTTON_START)
	_joy_axis(&"aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_joy_axis(&"aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_joy_axis(&"aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_joy_axis(&"aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	# O analógico esquerdo também gira o feixe.
	_joy_axis(&"rotate_left", JOY_AXIS_LEFT_X, -1.0)
	_joy_axis(&"rotate_right", JOY_AXIS_LEFT_X, 1.0)
	_joy_button(&"ability_1", JOY_BUTTON_LEFT_SHOULDER)
	_joy_button(&"ability_2", JOY_BUTTON_RIGHT_SHOULDER)
	_joy_button(&"ability_3", JOY_BUTTON_Y)
	var rmb := InputEventMouseButton.new()
	rmb.button_index = MOUSE_BUTTON_RIGHT
	_ensure(&"ability_2")
	InputMap.action_add_event(&"ability_2", rmb)
	apply_controls(default_controls())


static func default_controls() -> Dictionary:
	var out := {}
	for action: String in REBINDABLE:
		out[action] = (REBINDABLE[action] as Array).duplicate()
	return out


## Troca as teclas configuráveis, mantendo mouse e controle.
static func apply_controls(controls: Dictionary) -> void:
	for action: String in REBINDABLE:
		var name := StringName(action)
		_ensure(name)
		for ev in InputMap.action_get_events(name):
			if ev is InputEventKey:
				InputMap.action_erase_event(name, ev)
		for k: Variant in controls.get(action, REBINDABLE[action]):
			if int(k) != KEY_NONE:
				var ev := InputEventKey.new()
				ev.physical_keycode = int(k) as Key
				InputMap.action_add_event(name, ev)


static func key_name(keycode: int) -> String:
	if keycode == KEY_NONE:
		return "—"
	match keycode:
		KEY_LEFT:
			return "←"
		KEY_RIGHT:
			return "→"
		KEY_UP:
			return "↑"
		KEY_DOWN:
			return "↓"
		KEY_SPACE:
			return TranslationServer.translate("Espaço")
	return OS.get_keycode_string(keycode as Key)


static func _ensure(action: StringName, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)


static func _keys(action: StringName, keys: Array) -> void:
	_ensure(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


static func _joy_button(action: StringName, button: JoyButton) -> void:
	_ensure(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


static func _joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	_ensure(action, 0.25)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
