class_name LevelUpScreen
extends MenuScreen
## Escolha de melhoria ao subir de nível, em três cartas navegáveis.

signal upgrade_chosen(id: String)

var level := 1
var choices: Array = []
var levels: Dictionary = {}


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head := UiTheme.label(tr("Nível %d!") % level, 54, UiTheme.GOLD, true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_constant_override("outline_size", 8)
	root.add_child(head)
	head.resized.connect(func() -> void: head.pivot_offset = head.size / 2.0)
	head.scale = Vector2(1.4, 1.4)
	head.create_tween().tween_property(head, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var div := UiTheme.divider(380)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(div)
	var sub := UiTheme.label(tr("Escolha uma melhoria"), 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var cards: Array[ChoiceCard] = []
	var ids: Array[String] = []
	for u: Dictionary in choices:
		var id: String = u["id"]
		var current := int(levels.get(id, 0))
		var max_level := int(u["max"])
		var tag := tr("Novo!") if current == 0 else tr("Nível %d → %d") % [current, current + 1]
		var card := ChoiceCard.new(tr(u["name"]), tag, tr(u["desc"]))
		card.icon_id = id
		if max_level < 50:
			card.max_pips = max_level
			card.pips = current + 1
		cards.append(card)
		ids.append(id)
	var picker := CardPicker.new()
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(picker)
	# Pequeno atraso evita escolher sem querer enquanto se joga.
	picker.setup(cards, 0, 0.4)
	picker.chosen.connect(func(i: int) -> void: upgrade_chosen.emit(ids[i]))

	var hint := UiTheme.label(tr("A/D ou ←/→ para navegar   •   Enter, Espaço, 1-3 ou clique para escolher"), 14, UiTheme.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)
	Sfx.play(&"level_up")


func go_back() -> bool:
	return false
