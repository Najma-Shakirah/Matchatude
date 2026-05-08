extends Node2D

# --- Constants ---
const HOVER_RADIUS: float = 90.0
const REQUIRED_STROKES: int = 20        # horizontal direction changes needed
const MIN_MOVE_DISTANCE: float = 10.0   # px threshold to register a new stroke

# --- State ---
var strokes: int = 0
var last_x: float = 0.0
var moving_right: bool = true
var is_over_chawan: bool = false
var done: bool = false

# --- Node references ---
@onready var chasen: Sprite2D = $Chasen
@onready var chawan: Sprite2D = $Chawan
@onready var instruction_label: Label = $InstructionLabel

# Chawan frames: matcha paste → microfoam forming → full microfoam
var chawan_frames: Array[Texture2D] = [
	preload("res://assets/chawan_whisk1.png"),       # watery matcha from step 4
	preload("res://assets/chawan_whisk2.png"),      # starting to mix
	preload("res://assets/chawan_whisk3.png"),      # foam forming
	preload("res://assets/chawan_whisk4.png"),      # microfoam!
]

func _ready():
	chawan.texture = chawan_frames[0]
	instruction_label.text = "Whisk in a W or zig-zag motion over the bowl to build microfoam!"

func _process(_delta):
	chasen.global_position = get_global_mouse_position() + Vector2(0, -20)
	is_over_chawan = get_global_mouse_position().distance_to(chawan.global_position) < HOVER_RADIUS

func _input(event):
	if done:
		return
	if event is InputEventMouseMotion and is_over_chawan:
		var current_x = event.position.x
		var delta_x = current_x - last_x

		if delta_x > MIN_MOVE_DISTANCE and not moving_right:
			moving_right = true
			_register_stroke()
		elif delta_x < -MIN_MOVE_DISTANCE and moving_right:
			moving_right = false
			_register_stroke()

		last_x = current_x

func _register_stroke():
	if done:
		return
	strokes = min(strokes + 1, REQUIRED_STROKES)

	var progress = float(strokes) / float(REQUIRED_STROKES)

	# Update chawan texture as foam builds
	var idx = min(int(progress * chawan_frames.size()), chawan_frames.size() - 1)
	chawan.texture = chawan_frames[idx]

	var remaining = REQUIRED_STROKES - strokes
	if remaining > 0:
		if remaining > REQUIRED_STROKES / 2:
			instruction_label.text = "Keep whisking! %d strokes left." % remaining
		else:
			instruction_label.text = "Foam forming! %d more strokes." % remaining
	else:
		_on_complete()

func _on_complete():
	done = true
	instruction_label.text = "Beautiful microfoam! Moving on..."
	chasen.visible = false
	await get_tree().create_timer(1.5).timeout
	GameManager.complete_step(5)
	get_tree().change_scene_to_file("res://scenes/step_6_enjoy.tscn")
