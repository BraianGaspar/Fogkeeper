class_name CardPicker
extends Control
## Fileira de ChoiceCards navegável por mouse, teclado e controle:
##   A/D ou ←/→ (ou D-pad): muda a carta destacada
##   Enter, Espaço ou botão A: confirma a destacada
##   1, 2, 3: escolhe direto
## Emite `chosen(index)` depois de uma breve animação de confirmação.

signal chosen(index: int)

const GAP := 30.0

var index := 0

var _cards: Array[ChoiceCard] = []
var _armed := false
var _done := false


## `delay` impede escolher sem querer logo que a tela abre (no meio da ação).
func setup(cards: Array[ChoiceCard], start_index: int = 0, delay: float = 0.0) -> void:
	_cards = cards
	var w := ChoiceCard.SIZE.x
	custom_minimum_size = Vector2(cards.size() * w + (cards.size() - 1) * GAP, ChoiceCard.SIZE.y + 30.0)
	for i in cards.size():
		var card := cards[i]
		card.hotkey = str(i + 1)
		add_child(card)
		card.position = Vector2(i * (w + GAP), 60.0)
		card.modulate.a = 0.0
		var tw := card.create_tween().set_parallel()
		tw.tween_property(card, "position:y", 15.0, 0.35).set_delay(i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(i * 0.07)
		card.mouse_entered.connect(_on_card_hover.bind(i))
		card.gui_input.connect(_on_card_input.bind(i))
	select(start_index, false)
	if delay > 0.0:
		get_tree().create_timer(delay, true).timeout.connect(func() -> void: _armed = true)
	else:
		_armed = true


func select(i: int, with_sound: bool = true) -> void:
	if _cards.is_empty() or _done:
		return
	i = posmod(i, _cards.size())
	if with_sound and i != index:
		Sfx.play(&"hover")
	index = i
	for j in _cards.size():
		_cards[j].selected = j == index


func confirm(i: int) -> void:
	if not _armed or _done or i < 0 or i >= _cards.size():
		return
	select(i, false)
	_done = true
	Sfx.play(&"confirm")
	_cards[i].flash()
	for j in _cards.size():
		if j != i:
			_cards[j].create_tween().tween_property(_cards[j], "modulate:a", 0.35, 0.15)
	get_tree().create_timer(0.2, true).timeout.connect(func() -> void: chosen.emit(i))


func _on_card_hover(i: int) -> void:
	select(i)


func _on_card_input(event: InputEvent, i: int) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		confirm(i)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _done:
		return
	if event.is_action_pressed(&"menu_left", true):
		select(index - 1)
	elif event.is_action_pressed(&"menu_right", true):
		select(index + 1)
	elif event.is_action_pressed(&"menu_confirm"):
		confirm(index)
	else:
		var hit := -1
		for i in _cards.size():
			if event.is_action_pressed(StringName("choose_%d" % (i + 1))):
				hit = i
				break
		if hit == -1:
			return
		confirm(hit)
	get_viewport().set_input_as_handled()
