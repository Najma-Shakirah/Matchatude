extends Node

var player: AudioStreamPlayer

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	player.volume_db = -10

func play_bgm(stream: AudioStream):
	if player.stream == stream:
		return  # already playing, don't restart
	player.stream = stream
	player.play()

func stop_bgm():
	player.stop()

func set_volume(db: float):
	player.volume_db = db
