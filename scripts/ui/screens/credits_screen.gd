class_name CreditsScreen
extends MenuScreen
## Créditos e licenças: autoria, aviso de conteúdo feito com IA, e as
## licenças do motor Godot (lidas do próprio motor) e da fonte Cinzel.


func _build() -> void:
	var box := centered_panel(900, 26)
	box.add_theme_constant_override("separation", 10)
	title(box, tr("Créditos e licenças"), 34)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	_heading(col, "Fogkeeper")
	_body(col, tr("Criado por Braian Gaspar da Rosa.") + " © 2026. " + tr("Todos os direitos reservados."))
	_body(col, tr("Código, arte, sons e traduções feitos com assistência de IA (Claude, da Anthropic) e revisados pelo autor."))
	_body(col, tr("Criaturas e lendas inspiradas em mitos de domínio público das culturas grega, hebraica, nórdica, brasileira, japonesa e egípcia."))

	_heading(col, tr("Motor Godot"))
	_body(col, Engine.get_license_text())
	var parts := []
	for c: Dictionary in Engine.get_copyright_info():
		for p: Dictionary in c.get("parts", []):
			parts.append("%s — %s (%s)" % [c.get("name", ""), ", ".join(p.get("copyright", [])), p.get("license", "")])
	_body(col, "\n".join(parts), 12)
	var licenses: Dictionary = Engine.get_license_info()
	for name: String in licenses:
		_heading(col, name, 15)
		_body(col, str(licenses[name]), 11)

	_heading(col, tr("Fonte Cinzel"))
	_body(col, FileAccess.get_file_as_string("res://assets/fonts/OFL.txt"), 12)
	default_focus = back_button(box)
	default_focus.focus_mode = Control.FOCUS_ALL


func _heading(col: Control, value: String, size: int = 20) -> void:
	col.add_child(UiTheme.label(value, size, UiTheme.GOLD, true))


func _body(col: Control, value: String, size: int = 14) -> void:
	var l := UiTheme.label(value, size, UiTheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 820
	col.add_child(l)
