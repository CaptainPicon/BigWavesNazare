extends Node


func play_sfx(stream: AudioStream, volume_db := 0.0):
	var splash := AudioStreamPlayer.new()
	splash.stream = stream
	splash.volume_db = volume_db
	splash.pitch_scale = randf_range(0.9, 1.1)
	splash.bus = "SFX"
	add_child(splash)

	splash.play()
	splash.finished.connect(splash.queue_free)
