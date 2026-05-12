extends Node2D

func _ready():
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.show_dialogue_balloon_scene(
		preload("res://balloons/character_balloon.tscn"),
		preload("res://test.dialogue"),
		"start"
	)

func _on_dialogue_ended(_resource):
	get_tree().change_scene_to_file("res://scenes/step_1_weigh.tscn")
