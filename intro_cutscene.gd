extends Node2D

@onready var bg: TextureRect = $BackgroundImage

func _ready():
	MusicManager.play_bgm(preload("res://assets/audios/cafe.mp3"))
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.show_dialogue_balloon_scene(
		preload("res://balloons/intro_balloon.tscn"),
		preload("res://scripts/intro.dialogue"),
		"intro"
	)

func change_background(name: String):
	bg.texture = load("res://assets/%s.png" % name)

func _on_dialogue_ended(_resource):
	#GameManager.intro_seen = true
	get_tree().change_scene_to_file("res://scenes/intro_tutorial.tscn")
