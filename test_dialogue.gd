extends Node2D


# Called when the node enters the scene tree for the first time.


func _ready():
	DialogueManager.show_dialogue_balloon_scene(
		preload("res://balloon.tscn"),
		preload("res://test.dialogue"),
		"start"
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
