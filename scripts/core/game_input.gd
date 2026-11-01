class_name GameInput
extends RefCounted
## Registra as ações de input em tempo de execução, para o project.godot
## ficar limpo. Teclado, mouse e controle são suportados.


static func setup() -> void:
	_keys(&"rotate_left", [KEY_A, KEY_LEFT, KEY_Q])
	_keys(&"rotate_right", [KEY_D, KEY_RIGHT, KEY_E])
	_keys(&"pause", [KEY_ESCAPE, KEY_P])
	_keys(&"choose_1", [KEY_1, KEY_KP_1])
	_keys(&"choose_2", [KEY_2, KEY_KP_2])
	_keys(&"choose_3", [KEY_3, KEY_KP_3])
	_joy_button(&"pause", JOY_BUTTON_START)
	_joy_axis(&"aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_joy_axis(&"aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_joy_axis(&"aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_joy_axis(&"aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	# O analógico esquerdo também gira o feixe.
	_joy_axis(&"rotate_left", JOY_AXIS_LEFT_X, -1.0)
	_joy_axis(&"rotate_right", JOY_AXIS_LEFT_X, 1.0)


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
