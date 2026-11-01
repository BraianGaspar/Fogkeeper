class_name DifficultyScreen
extends MenuScreen
## Antes da partida: nome do faroleiro e escolha da dificuldade em cartas.

signal start(difficulty: String)

const ACCENTS := {"easy": Color(0.55, 0.9, 0.6), "normal": UiTheme.GOLD, "hard": Color(1.0, 0.45, 0.35)}


func _build() -> void:
	var box := centered_panel(860)
	title(box, tr("Escolha a dificuldade"))

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 12)
	name_row.add_child(UiTheme.label(tr("Nome do faroleiro:"), 18, UiTheme.TEXT_DIM))
	name_row.add_child(SettingsScreen.name_edit())
	box.add_child(name_row)

	var cards: Array[ChoiceCard] = []
	var start_index := 1
	for i in Balance.DIFFICULTY_ORDER.size():
		var id: String = Balance.DIFFICULTY_ORDER[i]
		var d: Dictionary = Balance.DIFFICULTIES[id]
		var tag := tr("Pontuação ×%s") % _mult_text(d["score"])
		var card := ChoiceCard.new(tr(d["name"]), tag, tr(d["desc"]))
		card.icon_id = id
		card.accent = ACCENTS[id]
		cards.append(card)
		if id == Settings.difficulty:
			start_index = i
	var picker := CardPicker.new()
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picker)
	picker.setup(cards, start_index)
	picker.chosen.connect(func(i: int) -> void: start.emit(Balance.DIFFICULTY_ORDER[i]))

	text(box, tr("A/D ou ←/→ para escolher   •   Enter ou clique para começar   •   Esc para voltar"), 14, UiTheme.TEXT_DIM)
	back_button(box)


static func _mult_text(m: float) -> String:
	var s := ("%.1f" % m).replace(".0", "")
	return s.replace(".", ",") if Settings.locale != "en" else s
