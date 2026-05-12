extends Control

@onready var bgm: AudioStreamPlayer = $AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bgm.stream = preload("res://assets/audios/cafe.mp3")
	bgm.volume_db = -10  # adjust to taste
	bgm.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/intro_cutscene.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
