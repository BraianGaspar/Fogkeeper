extends SceneTree
## Grava em WAV todos os sons e músicas que o jogo sintetiza (Sfx), para a
## versão Roblox, que só toca arquivos enviados à plataforma. Os mesmos sons,
## com a mesma semente: a trilha fica idêntica à do jogo em Godot.
##   godot --headless --path . --script tools/export_audio.gd
## Saída: build/audio_wav/<id>.wav (tools/export_audio.sh converte para OGG).

const OUT := "res://build/audio_wav/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sfx := Sfx.new()
	sfx._synthesize_all()
	var count := 0
	for id: StringName in sfx._pending:
		var stream: AudioStreamWAV = sfx._pending[id]
		var err := stream.save_to_wav(ProjectSettings.globalize_path(OUT + String(id) + ".wav"))
		if err != OK:
			push_error("falha ao gravar %s: %d" % [id, err])
		else:
			count += 1
	print("[export_audio] %d arquivos em %s" % [count, ProjectSettings.globalize_path(OUT)])
	sfx.free()
	quit()
