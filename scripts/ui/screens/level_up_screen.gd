class_name LevelUpScreen
extends MenuScreen
## Escolha de melhoria ao subir de nível, em cartas navegáveis. Evoluções
## aparecem com destaque próprio. Dá para trocar a mão (tecla T) e banir uma carta
## da partida (tecla B, depois escolher a carta), enquanto houver usos.

signal upgrade_chosen(id: String)
signal reroll_pressed
signal banish_pressed(id: String)

const EVOLUTION_ACCENT := Color(0.85, 0.7, 1.0)

var level := 1
var choices: Array = []
var levels: Dictionary = {}
var rerolls := 0
var banishes := 0
var show_hints := false ## Dicas de teclas: só no tutorial.

var _ids: Array[String] = []
var _banishing := false
var _banish_button: Button
var _cards: Array[ChoiceCard] = []
var _evolution_notes: Array[String] = []


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

	var size := ChoiceCard.SIZE if choices.size() <= 3 else Vector2(225, 340)
	for u: Dictionary in choices:
		var id: String = u["id"]
		var evolution := Upgrades.is_evolution(id)
		var current := int(levels.get(id, 0))
		var max_level := int(u["max"]) if not evolution else 1
		var tag := tr("Novo!") if current == 0 else tr("Nível %d → %d") % [current, current + 1]
		if evolution:
			var needs: Array = u["needs"]
			tag = tr("EVOLUÇÃO")
			_evolution_notes.append(tr("%s + %s = %s") % [tr(Upgrades.find(needs[0])["name"]), tr(Upgrades.find(needs[1])["name"]), tr(u["name"])])
		var card := ChoiceCard.new(tr(u["name"]), tag, tr(u["desc"]), size)
		card.icon_id = id
		if evolution:
			card.accent = EVOLUTION_ACCENT
		elif max_level < 50:
			card.max_pips = max_level
			card.pips = current + 1
		_cards.append(card)
		_ids.append(id)
	var picker := CardPicker.new()
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if choices.size() > 3:
		picker.gap = 18.0
	root.add_child(picker)
	# Pequeno atraso evita escolher sem querer enquanto se joga.
	picker.setup(_cards, 0, 0.4)
	picker.chosen.connect(_on_chosen.bind(picker))
	if not _evolution_notes.is_empty():
		var note := UiTheme.label(tr("Evolução liberada: %s") % "   •   ".join(_evolution_notes), 16, EVOLUTION_ACCENT)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(note)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	var reroll := UiTheme.small_button(tr("Trocar cartas — %d") % rerolls, func() -> void: _reroll())
	reroll.focus_mode = Control.FOCUS_NONE
	reroll.custom_minimum_size.x = 240
	reroll.disabled = rerolls <= 0
	actions.add_child(reroll)
	_banish_button = UiTheme.small_button(tr("Banir uma carta — %d") % banishes, func() -> void: _toggle_banish(), true)
	_banish_button.focus_mode = Control.FOCUS_NONE
	_banish_button.custom_minimum_size.x = 240
	_banish_button.disabled = banishes <= 0
	actions.add_child(_banish_button)

	if show_hints:
		var hint := UiTheme.label(tr("A/D ou ←/→ para navegar   •   Enter, Espaço, 1-3 ou clique para escolher"), 14, UiTheme.TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(hint)
	Sfx.play(&"level_up")


func _on_chosen(i: int, picker: CardPicker) -> void:
	if _banishing:
		# Evoluções e o Óleo fresco não podem ser banidos.
		if Upgrades.is_evolution(_ids[i]) or _ids[i] == Upgrades.FALLBACK["id"]:
			Sfx.play(&"denied")
			picker.rearm()
			return
		banish_pressed.emit(_ids[i])
	else:
		upgrade_chosen.emit(_ids[i])


func _reroll() -> void:
	if rerolls > 0:
		reroll_pressed.emit()
	else:
		Sfx.play(&"denied")


func _toggle_banish() -> void:
	if banishes <= 0:
		Sfx.play(&"denied")
		_banish_button.button_pressed = false
		return
	_banishing = not _banishing
	_banish_button.button_pressed = _banishing
	for c in _cards:
		c.banish_mode = _banishing


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reroll"):
		_reroll()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"banish"):
		_toggle_banish()
		get_viewport().set_input_as_handled()


func go_back() -> bool:
	if _banishing:
		_toggle_banish()
		return true
	return false
