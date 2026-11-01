class_name MenuScreen
extends Control
## Base das telas: ocupa a tela toda, monta painéis centralizados e trata o
## "voltar" (Esc ou botão B do controle).

signal back_requested

## Controle que recebe foco ao abrir a tela (navegação por teclado/controle).
var default_focus: Control


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build()
	if default_focus:
		(func() -> void: UiTheme.focus_silently(default_focus)).call_deferred()


## Subclasses montam o conteúdo aqui.
func _build() -> void:
	pass


## Volta um nível. Retorna false quando a tela não tem para onde voltar.
func go_back() -> bool:
	Sfx.play(&"back")
	back_requested.emit()
	return true


## Painel centralizado com coluna vertical; devolve a coluna.
func centered_panel(width: float, margin: float = 30.0) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := OrnatePanel.new(margin)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return box


func title(box: Control, text: String, size: int = 40) -> Label:
	var l := UiTheme.label(text, size, UiTheme.GOLD, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var div := UiTheme.divider(320)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(div)
	return l


func text(box: Control, value: String, size: int = 18, color: Color = UiTheme.TEXT, centered: bool = true) -> Label:
	var l := UiTheme.label(value, size, color)
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return l


func add_button(box: Control, label: String, on_press: Callable, sound: StringName = &"confirm") -> Button:
	var b := UiTheme.button(label, on_press, sound)
	box.add_child(b)
	return b


## Linha "rótulo ........ valor" usada em resumos e detalhes.
func stat_row(box: Control, label: String, value: String, value_color: Color = UiTheme.TEXT) -> void:
	var row := HBoxContainer.new()
	var l := UiTheme.label(label, 17, UiTheme.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(UiTheme.label(value, 17, value_color))
	box.add_child(row)


## Etiquetas das melhorias escolhidas, agrupadas na ordem da primeira escolha.
func upgrade_chips(box: Control, ids: Array) -> void:
	var counts := {}
	for id: String in ids:
		counts[id] = int(counts.get(id, 0)) + 1
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for id: String in counts:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.14, 0.12, 0.1), Color(UiTheme.GOLD_DARK, 0.8), 1, 6.0))
		var count: int = counts[id]
		var label := tr(Upgrades.find(id)["name"]) + ("  ×%d" % count if count > 1 else "")
		chip.add_child(UiTheme.label(label, 14, UiTheme.GOLD))
		flow.add_child(chip)
	if counts.is_empty():
		flow.add_child(UiTheme.label(tr("Nenhuma"), 14, UiTheme.TEXT_DIM))
	box.add_child(flow)


static func difficulty_name(id: String) -> String:
	return TranslationServer.translate(Balance.DIFFICULTIES.get(id, {"name": id})["name"])


## Botão "Voltar" que não rouba o foco (para telas navegadas por cartas).
func back_button(box: Control) -> Button:
	var b := add_button(box, tr("Voltar"), func() -> void: go_back(), &"none")
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size.x = 200
	return b
