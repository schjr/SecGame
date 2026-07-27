class_name BackgroundMusic
extends Node

const MUSIC_STREAM: AudioStreamWAV = preload("res://assets/audio/background_loop.wav")

var player: AudioStreamPlayer

func _ready() -> void:
	var looped_stream := MUSIC_STREAM.duplicate() as AudioStreamWAV
	looped_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	looped_stream.loop_begin = 0
	looped_stream.loop_end = int(looped_stream.get_length() * looped_stream.mix_rate)

	player = AudioStreamPlayer.new()
	player.stream = looped_stream
	player.bus = &"Music"
	player.volume_db = -16.0
	add_child(player)

func set_enabled(enabled: bool) -> void:
	if enabled:
		if not player.playing:
			player.play()
	elif player.playing:
		player.stop()
