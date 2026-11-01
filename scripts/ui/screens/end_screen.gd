class_name EndScreen
extends MenuScreen
## Fim de partida: horário da derrota (ou do amanhecer), quanto faltava,
## estatísticas, pontuação separada por critério e posição no ranking.

signal restart_pressed
signal ranking_pressed
signal menu_pressed
signal endless_pressed

var run: Dictionary = {}
## Dados de apresentação vindos do Main: clock, hours_left, time_left, next,
## endless, nights, can_continue, oil, unlocks, achievements.
var context: Dictionary = {}


func _build() -> void:
	var dawn: bool = context.get("can_continue", false)
	var endless: bool = context.get("endless", false)
	var map := Maps.get_map(run["map"])
	var box := centered_panel(920, 22)
	box.add_theme_constant_override("separation", 8)
	var rush: bool = run.get("mode", "normal") == "boss_rush"
	var heading := tr("A luz se apagou")
	if rush:
		heading = tr("Todos os chefes caíram!") if run["victory"] else tr("Chefes derrotados: %d de %d") % [run["bosses"], int(context.get("rush_total", 0))]
	elif dawn:
		heading = tr("Amanheceu!")
	elif endless:
		heading = tr("A luz se apagou na noite %d") % int(context["nights"])
	var head := title(box, heading, 42)
	if not dawn and not (rush and run["victory"]):
		head.add_theme_color_override("font_color", UiTheme.DANGER)
	if rush:
		text(box, tr("Modo Chefões em %s.") % Records.format_time(run["duration"]), 17, UiTheme.TEXT)
	elif dawn:
		text(box, tr("O sol nasceu às 06:00 sobre %s. O farol resistiu à noite inteira.") % tr(map["name"]), 17, UiTheme.TEXT)
	elif endless:
		text(box, tr("Depois do amanhecer, o farol ainda resistiu até as %s da noite %d.") % [context["clock"], int(context["nights"])], 17, UiTheme.TEXT)
	else:
		text(box, tr("A luz se apagou às %s. Faltavam %s (%s de partida) para o amanhecer.") % [context["clock"], context["hours_left"], context["time_left"]], 17, UiTheme.TEXT)
		if context.get("next", "") != "":
			text(box, context["next"], 15, UiTheme.TEXT_DIM)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	box.add_child(cols)
	var stats := _column(cols, tr("Partida"))
	stat_row(stats, tr("Mapa"), tr(map["name"]))
	stat_row(stats, tr("Farol"), tr(Keepers.get_keeper(run["keeper"])["name"]))
	stat_row(stats, tr("Faroleiro"), tr(Balance.HEROES.get(run["hero"], Balance.HEROES["keeper"])["name"]))
	if int(run["tide"]) > 0:
		stat_row(stats, tr("Maré"), str(run["tide"]), Color(0.5, 0.85, 1.0))
	stat_row(stats, tr("Dificuldade"), difficulty_name(run["difficulty"]))
	stat_row(stats, tr("Tempo sobrevivido"), Records.format_time(run["duration"]))
	stat_row(stats, tr("Horário do amanhecer") if dawn else tr("Horário da derrota"), context["clock"])
	stat_row(stats, tr("Nível alcançado"), str(run["level"]))
	stat_row(stats, tr("Criaturas queimadas"), Records.format_number(run["kills"]))
	stat_row(stats, tr("Chefes derrotados"), str(run["bosses"]))

	var bd: Dictionary = run["breakdown"]
	var score_col := _column(cols, tr("Pontuação"))
	var rows: Array[Control] = []
	rows.append(_score_row(score_col, tr("Criaturas queimadas"), bd["kills"]))
	rows.append(_score_row(score_col, tr("Tempo sobrevivido"), bd["survival"]))
	if int(bd.get("endless", 0)) > 0:
		rows.append(_score_row(score_col, tr("Modo sem fim"), bd["endless"]))
	rows.append(_score_row(score_col, tr("Bônus de chefes"), bd["bosses"]))
	rows.append(_score_row(score_col, tr("Bônus de vitória"), bd["victory"]))
	rows.append(_score_row(score_col, tr("Bônus de vida restante"), bd["health"]))
	rows.append(_score_row(score_col, tr("Subtotal"), bd["subtotal"], UiTheme.TEXT))
	var mult_row := HBoxContainer.new()
	var ml := UiTheme.label(tr("Multiplicador (%s)") % difficulty_name(run["difficulty"]), 16, UiTheme.TEXT_DIM)
	ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mult_row.add_child(ml)
	mult_row.add_child(UiTheme.label("×%s" % DifficultyScreen._mult_text(bd["multiplier"]), 16, UiTheme.GOLD))
	score_col.add_child(mult_row)
	rows.append(mult_row)
	for i in rows.size():
		rows[i].modulate.a = 0.0
		rows[i].create_tween().tween_property(rows[i], "modulate:a", 1.0, 0.25).set_delay(0.2 + i * 0.12)
	var total := UiTheme.label("0", 40, UiTheme.GOLD, true)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_col.add_child(total)
	_count_up(total, run["score"], 0.2 + rows.size() * 0.12)

	var chips := VBoxContainer.new()
	chips.add_theme_constant_override("separation", 4)
	chips.add_child(UiTheme.label(tr("Habilidades adquiridas (%d)") % (run["upgrades"] as Array).size(), 15, UiTheme.GOLD, true))
	upgrade_chips(chips, run["upgrades"])
	if not (run["relics"] as Array).is_empty():
		var relics := []
		for r: String in run["relics"]:
			relics.append(tr(Balance.RELICS[r]["name"]))
		chips.add_child(UiTheme.label(tr("Relíquias: %s") % ", ".join(relics), 14, Color(0.7, 0.9, 1.0)))
	# Resumo: de onde veio o dano e quantas brasas se perderam.
	var parts := []
	for d: Array in run.get("damage", []):
		parts.append("%s %d%%" % [tr(DamageStats.NAMES.get(d[0], d[0])), roundi(float(d[1]) * 100.0)])
	var embers: Array = run.get("embers", [0, 0])
	if not parts.is_empty():
		chips.add_child(UiTheme.label(tr("Dano: %s") % "  ·  ".join(parts), 14, UiTheme.TEXT))
		chips.add_child(UiTheme.label(tr("Brasas: %d recolhidas, %d apagadas") % [int(embers[0]), int(embers[1])], 14, UiTheme.TEXT_DIM))
	box.add_child(chips)

	# Recompensas que ficam: óleo, desbloqueios e conquistas.
	var rewards: Array[String] = []
	if int(context.get("oil", 0)) > 0:
		rewards.append(tr("+%d de óleo (total: %s)") % [int(context["oil"]), Records.format_number(Progress.oil)])
	for u: String in context.get("unlocks", []):
		rewards.append(tr("Liberado: %s") % u)
	for a: String in context.get("achievements", []):
		rewards.append(tr("Conquista: %s") % a)
	if not rewards.is_empty():
		var r := UiTheme.label("   •   ".join(rewards), 15, Color(0.45, 0.95, 0.85))
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(r)

	var rank_map: String = run["map"] if run["mode"] == "normal" else ""
	var pos := Records.position_of(run["id"], run["difficulty"] if run["mode"] == "normal" else "", rank_map, run["mode"], run["daily"])
	var count := Records.ranking(run["difficulty"] if run["mode"] == "normal" else "", rank_map, run["mode"], run["daily"]).size()
	if pos > 0:
		var place := UiTheme.label(tr("%s no ranking (%s · %s), entre %d partidas") % [Records.ordinal(pos), difficulty_name(run["difficulty"]), tr(map["name"]), count], 17, UiTheme.GOLD)
		place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(place)
		if pos == 1 and count > 1:
			place.text = tr("Novo recorde!") + "   " + place.text
			var tw := place.create_tween().set_loops()
			tw.tween_property(place, "modulate", Color(1.3, 1.2, 0.9), 0.6)
			tw.tween_property(place, "modulate", Color.WHITE, 0.6)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	if dawn:
		default_focus = add_button(buttons, tr("Continuar noite adentro"), func() -> void: endless_pressed.emit())
		add_button(buttons, tr("Jogar de novo"), func() -> void: restart_pressed.emit())
	else:
		default_focus = add_button(buttons, tr("Jogar de novo"), func() -> void: restart_pressed.emit())
	add_button(buttons, tr("Ver ranking"), func() -> void: ranking_pressed.emit())
	add_button(buttons, tr("Menu principal"), func() -> void: menu_pressed.emit(), &"back")
	for b in buttons.get_children():
		(b as Control).custom_minimum_size.x = 200 if dawn else 230
	if dawn:
		text(box, tr("Modo sem fim: a névoa volta e as noites seguem, cada vez mais difíceis. Os pontos continuam somando nesta partida."), 13, UiTheme.TEXT_DIM)


func _column(parent: Control, heading: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.add_child(UiTheme.label(heading, 18, UiTheme.GOLD, true))
	parent.add_child(col)
	return col


func _score_row(col: Control, label: String, value: int, color: Color = UiTheme.TEXT_DIM) -> Control:
	var row := HBoxContainer.new()
	var l := UiTheme.label(label, 16, color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(UiTheme.label(("+" if value > 0 and color == UiTheme.TEXT_DIM else "") + Records.format_number(value), 16, UiTheme.TEXT))
	col.add_child(row)
	return row


## A pontuação sobe de 0 até o total depois que as linhas aparecem.
func _count_up(label: Label, total: int, delay: float) -> void:
	var tw := label.create_tween()
	tw.tween_interval(delay)
	tw.tween_method(func(v: float) -> void: label.text = Records.format_number(int(v)), 0.0, float(total), 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func go_back() -> bool:
	return false
