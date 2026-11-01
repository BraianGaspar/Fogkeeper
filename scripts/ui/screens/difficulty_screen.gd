class_name DifficultyScreen
extends MenuScreen
## Última etapa antes da partida: nome do faroleiro e dificuldade.
## O quadro abaixo das cartas detalha as regras do modo selecionado.

signal start(difficulty: String)

const CARD := Vector2(212, 356)
const ACCENTS := {
	"easy": Color(0.55, 0.9, 0.6), "normal": UiTheme.GOLD, "medium": Color(1.0, 0.65, 0.3),
	"hard": Color(1.0, 0.42, 0.32), "impossible": Color(0.75, 0.3, 1.0),
}

var _rules: Label


func _build() -> void:
	var box := centered_panel(1160, 22)
	title(box, tr("Escolha a dificuldade"), 34)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 12)
	name_row.add_child(UiTheme.label(tr("Nome do faroleiro:"), 17, UiTheme.TEXT_DIM))
	name_row.add_child(SettingsScreen.name_edit())
	box.add_child(name_row)

	var cards: Array[ChoiceCard] = []
	var start_index := 1
	for i in Balance.DIFFICULTY_ORDER.size():
		var id: String = Balance.DIFFICULTY_ORDER[i]
		var d: Dictionary = Balance.DIFFICULTIES[id]
		var card := ChoiceCard.new(tr(d["name"]), tr("Pontuação ×%s") % _mult_text(d["score"]), tr(d["desc"]), CARD)
		card.icon_id = id
		card.accent = ACCENTS[id]
		cards.append(card)
		if id == Settings.difficulty:
			start_index = i
	var picker := CardPicker.new()
	picker.gap = 14.0
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picker)

	_rules = UiTheme.label("", 15, UiTheme.GOLD)
	_rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rules.custom_minimum_size = Vector2(1100, 44)
	box.add_child(_rules)

	picker.selection_changed.connect(func(i: int) -> void: _rules.text = rules_text(Balance.DIFFICULTY_ORDER[i]))
	picker.setup(cards, start_index)
	picker.chosen.connect(func(i: int) -> void: start.emit(Balance.DIFFICULTY_ORDER[i]))

	back_button(box)


## Resumo das regras de um modo, comparado ao Normal.
static func rules_text(id: String) -> String:
	var d: Dictionary = Balance.DIFFICULTIES[id]
	var parts: Array[String] = []
	parts.append(TranslationServer.translate("Vida das criaturas ×%s") % _mult_text(d["enemy_hp"]))
	parts.append(TranslationServer.translate("Dano ×%s") % _mult_text(d["enemy_damage"]))
	parts.append(TranslationServer.translate("Ritmo das hordas ×%s") % _mult_text(d["spawn"]))
	parts.append(TranslationServer.translate("XP por nível ×%s") % _mult_text(d["xp"]))
	parts.append(TranslationServer.translate("Brasas duram %d s") % int(d["ember_life"]))
	if float(d["elite"]) > 0.0:
		parts.append(TranslationServer.translate("Elites: %d%%") % roundi(float(d["elite"]) * 100.0))
	if float(d["lighthouse_hp"]) != 1.0:
		parts.append(TranslationServer.translate("Vida do farol ×%s") % _mult_text(d["lighthouse_hp"]))
	if d["enrage"]:
		parts.append(TranslationServer.translate("Chefes enfurecem"))
	if d["extra_boss"]:
		parts.append(TranslationServer.translate("Chefe extra às 7:00"))
	return "   •   ".join(parts)


static func _mult_text(m: float) -> String:
	var s := ("%.2f" % m).rstrip("0").rstrip(".")
	return s.replace(".", ",") if Settings.locale != "en" else s
