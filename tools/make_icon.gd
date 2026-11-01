extends SceneTree
## Gera icon.ico (16 a 256 px, entradas PNG) a partir de icon.svg, para o
## ícone do .exe. Uso: godot --headless --path . --script tools/make_icon.gd

const SIZES: Array[int] = [16, 24, 32, 48, 64, 128, 256]


func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://icon.svg")
	var pngs: Array[PackedByteArray] = []
	for s in SIZES:
		var img := Image.new()
		img.load_svg_from_string(svg, s / 128.0)
		pngs.append(img.save_png_to_buffer())

	var out := PackedByteArray()
	out.append_array(_u16([0, 1, SIZES.size()]))
	var offset := 6 + 16 * SIZES.size()
	for i in SIZES.size():
		var s := SIZES[i] % 256 # 256 é gravado como 0 no formato ICO.
		out.append_array(PackedByteArray([s, s, 0, 0]))
		out.append_array(_u16([1, 32]))
		out.append_array(_u32(pngs[i].size()))
		out.append_array(_u32(offset))
		offset += pngs[i].size()
	for png in pngs:
		out.append_array(png)

	var f := FileAccess.open("res://icon.ico", FileAccess.WRITE)
	f.store_buffer(out)
	f.close()
	print("icon.ico gerado (%d bytes)" % out.size())
	quit()


func _u16(values: Array) -> PackedByteArray:
	var b := PackedByteArray()
	for v: int in values:
		b.append_array(PackedByteArray([v & 0xFF, (v >> 8) & 0xFF]))
	return b


func _u32(v: int) -> PackedByteArray:
	return PackedByteArray([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
