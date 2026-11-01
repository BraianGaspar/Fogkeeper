class_name SettingsScreen
extends MenuScreen
## Configurações em abas: Geral, Controles, Gráficos e Áudio.
## Cada mudança é aplicada e salva na hora (dá para ajustar o volume pela
## pausa, no meio da partida, e ouvir o resultado).

signal language_changed(tab: int)

const TABS := ["Geral", "Controles", "Gráficos", "Áudio"]
const QUALITY_NAMES := ["Baixa", "Média", "Alta"]
const WINDOW_NAMES := ["Janela", "Tela cheia", "Tela cheia exclusiva"]
const FOG_NAMES := ["Leve", "Normal", "Densa"]

var tab := 0

var _content: VBoxContainer
var _tab_buttons: Array[Button] = []
var _status: Label
var _capturing := "" ## Ação esperando uma tecla ("" = nenhuma).
var _capture_slot := 0
var _capture_button: Button


func _build() -> void:
	var box := centered_panel(700)
	title(box, tr("Configurações"))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var group := ButtonGroup.new()
	for i in TABS.size():
		var b := UiTheme.small_button(tr(TABS[i]), _show_tab.bind(i), true)
		b.button_group = group
		b.custom_minimum_size.x = 150
		tabs.add_child(b)
		_tab_buttons.append(b)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

	_status = UiTheme.label("", 15, UiTheme.GOLD)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)

	var back := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 220
	_tab_buttons[tab].button_pressed = true
	_show_tab(tab)
	default_focus = _tab_buttons[tab]


func go_back() -> bool:
	if _capturing != "":
		_end_capture(tr("Troca de tecla cancelada."))
		return true
	return super.go_back()


func _show_tab(i: int) -> void:
	tab = i
	_capturing = ""
	_status.text = ""
	for c in _content.get_children():
		c.queue_free()
	match i:
		0:
			var locales := I18n.LANGUAGE_NAMES.keys()
			_row(tr("Idioma"), _selector(I18n.LANGUAGE_NAMES.values(), locales.find(Settings.locale), _set_locale, false))
			_row(tr("Nome do faroleiro"), name_edit())
		1:
			_build_controls()
		2:
			_row(tr("Qualidade visual"), _selector(QUALITY_NAMES, Settings.quality, _set_quality))
			_row(tr("Modo de tela"), _selector(WINDOW_NAMES, Settings.window_mode, _set_window_mode))
			_row(tr("Resolução (janela)"), _selector(Settings.RESOLUTIONS, maxi(0, Settings.RESOLUTIONS.find(Settings.resolution)), _set_resolution, false))
			_row(tr("Sincronização vertical (VSync)"), _toggle(Settings.vsync, _set_vsync))
			_row(tr("Tremor de tela"), _toggle(Settings.screen_shake, _set_shake))
			_row(tr("Partículas e faíscas"), _toggle(Settings.particles, _set_particles))
			_row(tr("Efeitos climáticos (chuva, neve)"), _toggle(Settings.weather, _set_weather))
			_row(tr("Clarões de relâmpago"), _toggle(Settings.lightning_flash, _set_lightning))
			_row(tr("Névoa"), _selector(FOG_NAMES, Settings.fog_level, _set_fog))
			_note(tr("Qualidade baixa reduz névoa, ondas, chuva e faíscas para PCs mais fracos."))
		3:
			_row(tr("Volume geral"), _slider(Settings.master_volume, _set_master))
			_row(tr("Trilha sonora"), _slider(Settings.music_volume, _set_music))
			_row(tr("Efeitos sonoros"), _slider(Settings.sfx_volume, _set_sfx))
			_row(tr("Som de dano"), _slider(Settings.damage_volume, _set_damage))
			var devices := Array(AudioServer.get_output_device_list())
			var names := devices.map(func(d: String) -> String: return tr("Padrão do sistema") if d == "Default" else d)
			_row(tr("Saída de áudio"), _selector(names, maxi(0, devices.find(Settings.output_device)), _set_device.bind(devices), false))
			_content.add_child(UiTheme.label(tr("Sons individuais"), 17, UiTheme.GOLD, true))
			for g: String in Sfx.GROUPS:
				_row(tr(Sfx.GROUP_NAMES[g]), _toggle(Settings.sound_enabled(g), _set_sound.bind(g)))
			_note(tr("Arraste até 0% para desativar um canal."))


# --- Controles --------------------------------------------------------------

func _build_controls() -> void:
	var head := HBoxContainer.new()
	var h1 := UiTheme.label(tr("Ação"), 15, UiTheme.GOLD)
	h1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(h1)
	for text_key: String in ["Principal", "Alternativa"]:
		var l := UiTheme.label(tr(text_key), 15, UiTheme.GOLD)
		l.custom_minimum_size.x = 150
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_child(l)
	_content.add_child(head)
	for action: String in GameInput.REBINDABLE:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var l := UiTheme.label(tr(GameInput.ACTION_NAMES[action]), 17)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		for slot in 2:
			var keys: Array = Settings.controls.get(action, GameInput.REBINDABLE[action])
			var b := UiTheme.small_button(GameInput.key_name(int(keys[slot])), func() -> void: pass)
			b.custom_minimum_size.x = 150
			b.pressed.connect(_begin_capture.bind(action, slot, b))
			row.add_child(b)
		_content.add_child(row)
	_note(tr("Clique numa tecla e pressione a nova. Esc cancela. Mouse direito e o controle também funcionam (LB, RB, Y)."))
	var reset := UiTheme.small_button(tr("Redefinir padrão"), _reset_controls)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset.custom_minimum_size.x = 220
	_content.add_child(reset)


func _begin_capture(action: String, slot: int, button: Button) -> void:
	_capturing = action
	_capture_slot = slot
	_capture_button = button
	button.text = tr("Pressione uma tecla...")
	_status.text = tr("Esperando a nova tecla para: %s") % tr(GameInput.ACTION_NAMES[action])


func _input(event: InputEvent) -> void:
	if _capturing == "":
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	var code := int(key.physical_keycode)
	if code == KEY_ESCAPE:
		_end_capture(tr("Troca de tecla cancelada."))
		return
	if code in GameInput.RESERVED:
		_status.text = tr("Essa tecla é reservada (pausa, menus e escolhas). Tente outra.")
		return
	# Evita conflito: se a tecla já estava em outro lugar, os dois trocam.
	var old: int = int(Settings.controls[_capturing][_capture_slot])
	var swapped := ""
	for action: String in Settings.controls:
		for slot in 2:
			if int(Settings.controls[action][slot]) == code and not (action == _capturing and slot == _capture_slot):
				Settings.controls[action][slot] = old
				swapped = action
	Settings.controls[_capturing][_capture_slot] = code
	_changed()
	var msg := tr("Tecla definida: %s") % GameInput.key_name(code)
	if swapped != "":
		msg = tr("%s estava em \"%s\"; as teclas foram trocadas.") % [GameInput.key_name(code), tr(GameInput.ACTION_NAMES[swapped])]
	_end_capture(msg)


func _end_capture(message: String) -> void:
	_capturing = ""
	_show_tab(1)
	_status.text = message


func _reset_controls() -> void:
	Settings.controls = GameInput.default_controls()
	_changed()
	_show_tab(1)
	_status.text = tr("Controles redefinidos para o padrão.")


# --- Setters ----------------------------------------------------------------

func _set_locale(k: int) -> void:
	Settings.locale = I18n.LANGUAGE_NAMES.keys()[k]
	_changed()
	language_changed.emit(tab)


func _set_quality(k: int) -> void:
	Settings.quality = k
	_changed()


func _set_window_mode(k: int) -> void:
	Settings.window_mode = k
	_changed()


func _set_resolution(k: int) -> void:
	Settings.resolution = Settings.RESOLUTIONS[k]
	_changed()


func _set_vsync(on: bool) -> void:
	Settings.vsync = on
	_changed()


func _set_shake(on: bool) -> void:
	Settings.screen_shake = on
	_changed()


func _set_particles(on: bool) -> void:
	Settings.particles = on
	_changed()


func _set_weather(on: bool) -> void:
	Settings.weather = on
	_changed()


func _set_lightning(on: bool) -> void:
	Settings.lightning_flash = on
	_changed()


func _set_fog(k: int) -> void:
	Settings.fog_level = k
	_changed()


func _set_master(v: int) -> void:
	Settings.master_volume = v
	_changed(&"hover")


func _set_music(v: int) -> void:
	Settings.music_volume = v
	_changed()


func _set_sfx(v: int) -> void:
	Settings.sfx_volume = v
	_changed(&"burn")


func _set_damage(v: int) -> void:
	Settings.damage_volume = v
	_changed(&"damage")


func _set_device(k: int, devices: Array) -> void:
	Settings.output_device = devices[k]
	_changed(&"confirm")


func _set_sound(on: bool, group: String) -> void:
	Settings.sounds[group] = on
	_changed()


func _changed(preview: StringName = &"") -> void:
	Settings.apply()
	Settings.save()
	if preview != &"":
		Sfx.play(preview)


# --- Controles da própria tela -----------------------------------------------

func _row(label: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UiTheme.label(label, 17)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, 300)
	row.add_child(control)
	_content.add_child(row)


func _note(value: String) -> void:
	var note := UiTheme.label(value, 14, UiTheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(note)


## Seletor "<  valor  >". `translate` = false para nomes próprios.
func _selector(options: Array, current: int, on_change: Callable, translate: bool = true) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var value := UiTheme.label("", 17, UiTheme.GOLD)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.clip_text = true
	var state := [clampi(current, 0, maxi(0, options.size() - 1))]
	var refresh := func() -> void:
		var o: String = options[state[0]] if not options.is_empty() else ""
		value.text = tr(o) if translate else o
	var step := func(d: int) -> void:
		if options.is_empty():
			return
		state[0] = posmod(state[0] + d, options.size())
		refresh.call()
		on_change.call(state[0])
	var left := UiTheme.small_button("<", func() -> void: step.call(-1))
	var right := UiTheme.small_button(">", func() -> void: step.call(1))
	left.custom_minimum_size.x = 40
	right.custom_minimum_size.x = 40
	row.add_child(left)
	row.add_child(value)
	row.add_child(right)
	refresh.call()
	return row


func _toggle(current: bool, on_change: Callable) -> Control:
	return _selector(["Desligado", "Ligado"], 1 if current else 0, func(k: int) -> void: on_change.call(k == 1))


func _slider(current: int, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.value = current
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.add_theme_stylebox_override("slider", UiTheme.flat(Color(0, 0, 0, 0.6), UiTheme.GOLD_DARK, 1, 3.0))
	s.add_theme_stylebox_override("grabber_area", UiTheme.flat(Color(UiTheme.GOLD, 0.75), Color.TRANSPARENT, 0, 3.0))
	s.add_theme_stylebox_override("grabber_area_highlight", UiTheme.flat(UiTheme.GOLD, Color.TRANSPARENT, 0, 3.0))
	var value := UiTheme.label("%d%%" % current, 16, UiTheme.GOLD)
	value.custom_minimum_size.x = 52
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	s.value_changed.connect(func(v: float) -> void:
		value.text = "%d%%" % int(v)
		on_change.call(int(v))
	)
	s.focus_entered.connect(func() -> void: Sfx.play(&"hover"))
	row.add_child(s)
	row.add_child(value)
	return row


## Campo do nome do jogador (usado aqui e na tela de dificuldade).
static func name_edit() -> LineEdit:
	var e := LineEdit.new()
	e.text = Settings.player_name
	e.placeholder_text = Settings.DEFAULT_NAME
	e.max_length = 16
	e.custom_minimum_size = Vector2(260, 38)
	e.add_theme_font_size_override("font_size", 18)
	e.add_theme_color_override("font_color", UiTheme.GOLD)
	e.add_theme_stylebox_override("normal", UiTheme.flat(Color(0, 0, 0, 0.5), UiTheme.GOLD_DARK, 1, 8.0))
	e.add_theme_stylebox_override("focus", UiTheme.flat(Color(0, 0, 0, 0.6), UiTheme.GOLD, 2, 8.0))
	e.text_changed.connect(func(t: String) -> void:
		Settings.player_name = t.strip_edges()
		Settings.save()
	)
	e.text_submitted.connect(func(_t: String) -> void: e.release_focus())
	return e
