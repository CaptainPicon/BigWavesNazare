extends Node


func play_sfx(stream: AudioStream):
	var sound := AudioStreamPlayer.new()
	sound.bus = "SFX"
	sound.stream = stream
	sound.pitch_scale = randf_range(0.9, 1.1)
	add_child(sound)

	sound.play()
	sound.finished.connect(sound.queue_free)
