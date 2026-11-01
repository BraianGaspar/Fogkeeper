class_name HeroScreen
extends MenuScreen
## Escolha do faroleiro jogável: cada um muda as regras do farol
## (Balance.HEROES). Os bloqueados se compram com óleo ao serem escolhidos.

signal chosen(hero_id: String)

const CARD := Vector2(212, 340)
const ICONS := {"keeper": "repairs", "monk": "twin_lens", "pirate": "intense_flame", "astronomer": "pulse", "fisher": "magnet"}

var _status: Label


func _build() -> void:
	var box := centered_panel(1160, 22)
	title(box, tr("Escolha o faroleiro"), 36)
	text(box, tr("Cada faroleiro muda o jeito de usar a luz."), 15, UiTheme.TEXT_DIM)
	var cards: Array[ChoiceCard] = []
	var start := 0
	for i in Balance.HERO_ORDER.size():
		var id: String = Balance.HERO_ORDER[i]
		var h: Dictionary = Balance.HEROES[id]
		var card := ChoiceCard.new(tr(h["name"]), "", tr(h["desc"]), CARD)
		card.icon_id = ICONS[id]
		card.locked = not Progress.is_unlocked(id)
		if card.locked:
			card.lock_text = tr("%s de óleo") % Records.format_number(int(Progress.unlock_entry(id)["cost"]))
		cards.append(card)
		if id == Settings.hero and not card.locked:
			start = i
	var picker := CardPicker.new()
	picker.gap = 16.0
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picker)
	_status = text(box, "", 15, UiTheme.GOLD)
	picker.selection_changed.connect(_show_status)
	picker.setup(cards, start)
	picker.chosen.connect(_on_chosen.bind(picker))
	back_button(box)


func _show_status(i: int) -> void:
	var id: String = Balance.HERO_ORDER[i]
	_status.text = "" if Progress.is_unlocked(id) else tr("Escolha para comprar por %s de óleo (você tem %s).") % [
		Records.format_number(int(Progress.unlock_entry(id)["cost"])), Records.format_number(Progress.oil)]


func _on_chosen(i: int, picker: CardPicker) -> void:
	var id: String = Balance.HERO_ORDER[i]
	if Progress.is_unlocked(id):
		chosen.emit(id)
		return
	if Progress.buy_unlock(id):
		Sfx.play(&"relic")
		Settings.hero = id
		for c in get_children():
			c.queue_free()
		_build.call_deferred()
		return
	Sfx.play(&"denied")
	picker.rearm()
	_status.text = tr("Óleo insuficiente: você tem %s.") % Records.format_number(Progress.oil)
