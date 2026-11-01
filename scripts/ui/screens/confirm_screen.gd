class_name ConfirmScreen
extends MenuScreen
## Caixa simples de título, texto e botões (convite ao tutorial, fim do
## tutorial). `options` = [[rótulo, Callable], ...]; Esc volta ao menu.

var heading := ""
var body := ""
var options: Array = []


func _build() -> void:
	var box := centered_panel(620)
	title(box, heading, 34)
	text(box, body, 18)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for i in options.size():
		var opt: Array = options[i]
		var b := add_button(row, opt[0], opt[1], &"confirm" if i == 0 else &"back")
		b.custom_minimum_size.x = 250
		if i == 0:
			default_focus = b
