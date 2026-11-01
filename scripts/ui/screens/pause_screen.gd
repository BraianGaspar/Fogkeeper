class_name PauseScreen
extends MenuScreen
## Pausa: resumo da partida, melhorias atuais e opções.

signal resume_pressed
signal settings_pressed
signal restart_pressed
signal menu_pressed
signal quit_pressed

var summary := "" ## Linha com tempo, nível e pontos.
var upgrades: Array = []
var events: Array[Dictionary] = [] ## Avisos recentes (mais novos primeiro).


func _build() -> void:
	var box := centered_panel(520)
	title(box, tr("Pausado"))
	text(box, summary, 17, UiTheme.TEXT_DIM)
	upgrade_chips(box, upgrades)
	if not events.is_empty():
		box.add_child(UiTheme.label(tr("Eventos recentes"), 16, UiTheme.GOLD, true))
		for i in mini(events.size(), 4):
			var e: Dictionary = events[i]
			var l := UiTheme.label("%s   %s" % [e["time"], e["text"]], 14, UiTheme.TEXT_DIM)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(l)
	default_focus = add_button(box, tr("Continuar"), func() -> void: resume_pressed.emit())
	add_button(box, tr("Configurações"), func() -> void: settings_pressed.emit())
	add_button(box, tr("Recomeçar"), func() -> void: restart_pressed.emit())
	add_button(box, tr("Menu principal"), func() -> void: menu_pressed.emit(), &"back")
	add_button(box, tr("Sair do jogo"), func() -> void: quit_pressed.emit(), &"back")


func go_back() -> bool:
	resume_pressed.emit()
	return true
