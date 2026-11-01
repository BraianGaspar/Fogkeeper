class_name SettingsScreen
extends MenuScreen
## Configurações em abas: Geral (idioma, nome), Gráficos e Áudio.
## Cada mudança é aplicada e salva na hora.

signal language_changed(tab: int)

const TABS := ["Geral", "Gráficos", "Áudio"]
const QUALITY_NAMES := ["Baixa", "Média", "Alta"]

var tab := 0

var _content: VBoxContainer
var _tab_buttons: Array[Button] = []


func _build() -> void:
	var box := centered_panel(620)
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

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_content.custom_minimum_size.y = 250
	box.add_child(_content)

	var back := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 220
	_tab_buttons[tab].button_pressed = true
	_show_tab(tab)
	default_focus = _tab_buttons[tab]


func _show_tab(i: int) -> void:
	tab = i
	for c in _content.get_children():
		c.queue_free()
	match i:
		0:
			var locales := I18n.LANGUAGE_NAMES.keys()
			_row(tr("Idioma"), _selector(I18n.LANGUAGE_NAMES.values(), locales.find(Settings.locale), _set_locale, false))
			_row(tr("Nome do faroleiro"), name_edit())
		1:
			_row(tr("Qualidade visual"), _selector(QUALITY_NAMES, Settings.quality, _set_quality))
			_row(tr("Tela cheia"), _toggle(Settings.fullscreen, _set_fullscreen))
			_row(tr("Sincronização vertical (VSync)"), _toggle(Settings.vsync, _set_vsync))
			_row(tr("Tremor de tela"), _toggle(Settings.screen_shake, _set_shake))
			var note := text(_content, tr("Qualidade baixa reduz névoa, ondas, chuva e faíscas para PCs mais fracos."), 14, UiTheme.TEXT_DIM)
			note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		2:
			_row(tr("Volume geral"), _slider(Settings.master_volume, _set_master))
			_row(tr("Trilha sonora"), _slider(Settings.music_volume, _set_music))
			_row(tr("Efeitos sonoros"), _slider(Settings.sfx_volume, _set_sfx))
			_row(tr("Som de dano"), _slider(Settings.damage_volume, _set_damage))
			var note := text(_content, tr("Arraste até 0% para desativar um canal."), 14, UiTheme.TEXT_DIM)
			note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _set_locale(k: int) -> void:
	Settings.locale = I18n.LANGUAGE_NAMES.keys()[k]
	_changed()
	language_changed.emit(tab)


func _set_quality(k: int) -> void:
	Settings.quality = k
	_changed()


func _set_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	_changed()


func _set_vsync(on: bool) -> void:
	Settings.vsync = on
	_changed()


func _set_shake(on: bool) -> void:
	Settings.screen_shake = on
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


func _changed(preview: StringName = &"") -> void:
	Settings.apply()
	Settings.save()
	if preview != &"":
		Sfx.play(preview)


func _row(label: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UiTheme.label(label, 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, 260)
	row.add_child(control)
	_content.add_child(row)


## Seletor "<  valor  >". `translate` = false para nomes de idioma.
func _selector(options: Array, current: int, on_change: Callable, translate: bool = true) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var value := UiTheme.label("", 18, UiTheme.GOLD)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var state := [maxi(0, current)]
	var refresh := func() -> void:
		var o: String = options[state[0]]
		value.text = tr(o) if translate else o
	var step := func(d: int) -> void:
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
	var value := UiTheme.label("%d%%" % current, 17, UiTheme.GOLD)
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
