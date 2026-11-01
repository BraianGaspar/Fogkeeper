class_name EndScreen
extends MenuScreen
## Fim de partida: resultado, pontuação detalhada e posição no ranking.

signal restart_pressed
signal ranking_pressed
signal menu_pressed

var run: Dictionary = {}


func _build() -> void:
	var victory: bool = run["victory"]
	var box := centered_panel(520)
	var head := title(box, tr("Amanheceu!") if victory else tr("A luz se apagou"), 44)
	if not victory:
		head.add_theme_color_override("font_color", UiTheme.DANGER)
	text(box, tr("O farol resistiu à noite inteira.") if victory else tr("A névoa tomou a ilha desta vez."), 18, UiTheme.TEXT_DIM)

	var pos := Records.position_of(run["id"], run["difficulty"])
	var total := Records.ranking(run["difficulty"]).size()
	if pos == 1 and total > 1:
		var record := UiTheme.label(tr("Novo recorde!"), 26, UiTheme.GOLD, true)
		record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(record)
		record.resized.connect(func() -> void: record.pivot_offset = record.size / 2.0)
		var tw := record.create_tween().set_loops()
		tw.tween_property(record, "modulate", Color(1.3, 1.2, 0.9), 0.6)
		tw.tween_property(record, "modulate", Color.WHITE, 0.6)

	stat_row(box, tr("Dificuldade"), difficulty_name(run["difficulty"]))
	stat_row(box, tr("Tempo"), Records.format_time(run["duration"]))
	stat_row(box, tr("Nível"), str(run["level"]))
	stat_row(box, tr("Criaturas queimadas"), Records.format_number(run["kills"]))
	var bd: Dictionary = run["breakdown"]
	var parts := "%s + %s" % [Records.format_number(bd["kills"]), Records.format_number(bd["survival"])]
	if victory:
		parts += " + %s + %s" % [Records.format_number(bd["victory"]), Records.format_number(bd["health"])]
	stat_row(box, tr("Pontos (criaturas + tempo%s)") % (tr(" + vitória + vida") if victory else ""), "%s  ×%s" % [parts, DifficultyScreen._mult_text(bd["multiplier"])], UiTheme.TEXT_DIM)

	var score := UiTheme.label(Records.format_number(run["score"]), 48, UiTheme.GOLD, true)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(score)
	_count_up(score, run["score"])
	if pos > 0:
		text(box, tr("Posição no ranking (%s): #%d de %d") % [difficulty_name(run["difficulty"]), pos, total], 17, UiTheme.GOLD)

	default_focus = add_button(box, tr("Jogar de novo"), func() -> void: restart_pressed.emit())
	add_button(box, tr("Ver ranking"), func() -> void: ranking_pressed.emit())
	add_button(box, tr("Menu principal"), func() -> void: menu_pressed.emit(), &"back")


## A pontuação sobe de 0 até o total, com som.
func _count_up(label: Label, total: int) -> void:
	label.text = "0"
	var tw := label.create_tween()
	tw.tween_interval(0.3)
	tw.tween_method(func(v: float) -> void: label.text = Records.format_number(int(v)), 0.0, float(total), 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func go_back() -> bool:
	return false
